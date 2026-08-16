use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use anyhow::{Result, anyhow};
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::http::{HeaderMap, HeaderValue, header::AUTHORIZATION};
use axum::response::{IntoResponse, Response};
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use serde_json::{Value, json};
use tokio::sync::{mpsc, oneshot};
use tokio::time::timeout;
use uuid::Uuid;

use crate::api::{auth::current_user, error::ApiError};
use crate::app_state::AppState;

const BRIDGE_REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

#[derive(Clone, Default)]
pub struct WebSocketHub {
    clients: Arc<Mutex<HashMap<String, Vec<Arc<ClientConnection>>>>>,
}

struct ClientConnection {
    id: String,
    sender: mpsc::UnboundedSender<Message>,
    pending: Mutex<HashMap<String, oneshot::Sender<Result<Value, String>>>>,
}

#[derive(Deserialize, Default)]
pub struct WebSocketAuthQuery {
    pub access_token: Option<String>,
    pub token: Option<String>,
}

pub async fn upgrade(
    State(state): State<AppState>,
    Query(query): Query<WebSocketAuthQuery>,
    headers: HeaderMap,
    websocket: WebSocketUpgrade,
) -> Result<Response, ApiError> {
    let token = query
        .access_token
        .or(query.token)
        .or_else(|| bearer_token(&headers).map(ToOwned::to_owned))
        .filter(|value| !value.trim().is_empty())
        .ok_or(ApiError::Unauthorized)?;
    let mut auth_headers = HeaderMap::new();
    auth_headers.insert(
        AUTHORIZATION,
        HeaderValue::from_str(&format!("Bearer {token}")).map_err(|_| ApiError::Unauthorized)?,
    );
    let user = current_user(&state, &auth_headers)?;
    let hub = Arc::clone(&state.websocket_hub);
    Ok(websocket
        .on_upgrade(move |socket| async move {
            hub.serve(user.id, socket).await;
        })
        .into_response())
}

fn bearer_token(headers: &HeaderMap) -> Option<&str> {
    headers
        .get(AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "))
}

impl WebSocketHub {
    async fn serve(self: Arc<Self>, user_id: String, socket: WebSocket) {
        let (mut sink, mut stream) = socket.split();
        let (sender, mut outgoing) = mpsc::unbounded_channel();
        let connection = Arc::new(ClientConnection {
            id: Uuid::new_v4().to_string(),
            sender,
            pending: Mutex::new(HashMap::new()),
        });
        self.add_client(&user_id, Arc::clone(&connection));

        let write_task = async move {
            while let Some(message) = outgoing.recv().await {
                if sink.send(message).await.is_err() {
                    break;
                }
            }
        };
        let read_task = {
            let hub = Arc::clone(&self);
            let connection = Arc::clone(&connection);
            async move {
                while let Some(result) = stream.next().await {
                    match result {
                        Ok(Message::Text(text)) => {
                            hub.handle_message(&connection, text.as_str());
                        }
                        Ok(Message::Close(_)) | Err(_) => break,
                        Ok(Message::Ping(_)) | Ok(Message::Pong(_)) | Ok(Message::Binary(_)) => {}
                    }
                }
            }
        };

        tokio::select! {
            _ = write_task => {},
            _ = read_task => {},
        }
        self.remove_client(&user_id, &connection.id);
        if let Ok(mut pending) = connection.pending.lock() {
            for (_, response) in pending.drain() {
                let _ = response.send(Err("WebSocket 客户端已断开".to_owned()));
            }
        }
    }

    fn add_client(&self, user_id: &str, connection: Arc<ClientConnection>) {
        if let Ok(mut clients) = self.clients.lock() {
            clients
                .entry(user_id.to_owned())
                .or_default()
                .push(connection);
        }
    }

    fn remove_client(&self, user_id: &str, connection_id: &str) {
        if let Ok(mut clients) = self.clients.lock() {
            let Some(user_clients) = clients.get_mut(user_id) else {
                return;
            };
            user_clients.retain(|client| client.id != connection_id);
            if user_clients.is_empty() {
                clients.remove(user_id);
            }
        }
    }

    fn clients_for(&self, user_id: &str) -> Vec<Arc<ClientConnection>> {
        self.clients
            .lock()
            .ok()
            .and_then(|clients| clients.get(user_id).cloned())
            .unwrap_or_default()
    }

    fn handle_message(&self, connection: &ClientConnection, raw: &str) {
        let Ok(value) = serde_json::from_str::<Value>(raw) else {
            return;
        };
        if value.get("type").and_then(Value::as_str) != Some("bridge.response") {
            return;
        }
        let request_id = value
            .get("requestId")
            .or_else(|| value.get("id"))
            .and_then(Value::as_str)
            .unwrap_or_default();
        if request_id.is_empty() {
            return;
        }
        let response = connection
            .pending
            .lock()
            .ok()
            .and_then(|mut pending| pending.remove(request_id));
        let Some(response) = response else {
            return;
        };
        let result = if value.get("ok").and_then(Value::as_bool) == Some(true) {
            Ok(value.get("result").cloned().unwrap_or(Value::Null))
        } else {
            Err(value
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("WebSocket bridge 调用失败")
                .to_owned())
        };
        let _ = response.send(result);
    }

    async fn request(&self, user_id: &str, method: &str, args: Vec<Value>) -> Result<Value> {
        let mut last_error = None;
        for client in self.clients_for(user_id) {
            match client.request(method, args.clone()).await {
                Ok(value) => return Ok(value),
                Err(error) => last_error = Some(error),
            }
        }
        Err(last_error.unwrap_or_else(|| anyhow!("用户没有连接可用的 WebSocket bridge")))
    }

    pub fn register_bridge_routes(self: &Arc<Self>) -> Result<()> {
        for method in ["dart.getAppVersion", "dart.getLocaleInfo"] {
            let hub = Arc::clone(self);
            let method_name = method.to_owned();
            rquickjs_playground::register_bridge_route_async_handler(
                method_name.clone(),
                move |runtime, args| {
                    let hub = Arc::clone(&hub);
                    let method_name = method_name.clone();
                    async move {
                        let user_id = runtime_user_id(&runtime)?;
                        let mut full_args = vec![Value::String(runtime)];
                        full_args.extend(args);
                        let value = hub
                            .request(&user_id, &method_name, full_args)
                            .await
                            .map_err(|error| anyhow!(error))?;
                        Ok(callback_result(value))
                    }
                },
            )?;
        }

        let hub = Arc::clone(self);
        rquickjs_playground::register_bridge_route_async_handler(
            "flutter.showToast",
            move |runtime, args| {
                let hub = Arc::clone(&hub);
                async move {
                    let user_id = runtime_user_id(&runtime)?;
                    let mut full_args = vec![Value::String(runtime)];
                    full_args.extend(args);
                    let value = hub
                        .request(&user_id, "flutter.showToast", full_args)
                        .await
                        .map_err(|error| anyhow!(error))?;
                    Ok(callback_result(value))
                }
            },
        )?;
        Ok(())
    }
}

impl ClientConnection {
    async fn request(&self, method: &str, args: Vec<Value>) -> Result<Value> {
        let request_id = Uuid::new_v4().to_string();
        let (sender, receiver) = oneshot::channel();
        self.pending
            .lock()
            .map_err(|_| anyhow!("WebSocket pending request lock poisoned"))?
            .insert(request_id.clone(), sender);
        let message = Message::text(
            json!({
                "type": "bridge.request",
                "requestId": request_id,
                "method": method,
                "args": args,
            })
            .to_string(),
        );
        if self.sender.send(message).is_err() {
            self.pending
                .lock()
                .map_err(|_| anyhow!("WebSocket pending request lock poisoned"))?
                .remove(&request_id);
            return Err(anyhow!("WebSocket 客户端已断开"));
        }
        timeout(BRIDGE_REQUEST_TIMEOUT, receiver)
            .await
            .map_err(|_| anyhow!("WebSocket bridge 请求超时: {method}"))?
            .map_err(|_| anyhow!("WebSocket bridge 响应通道已关闭"))?
            .map_err(|error| anyhow!(error))
    }
}

fn runtime_user_id(runtime: &str) -> Result<String> {
    let user_id = runtime
        .strip_prefix("cs-server-user-")
        .and_then(|value| value.split_once("--plugin-").map(|(user_id, _)| user_id))
        .filter(|value| !value.is_empty())
        .ok_or_else(|| anyhow!("无法从插件 runtime 解析用户 ID"))?;
    Ok(user_id.to_owned())
}

fn callback_result(value: Value) -> Value {
    match value {
        Value::String(value) if value.is_empty() => Value::Null,
        Value::String(value) => Value::String(value),
        value => Value::String(value.to_string()),
    }
}
