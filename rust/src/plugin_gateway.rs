use anyhow::{Context, Result, anyhow};
use serde::{Deserialize, Serialize};
use serde_bytes::ByteBuf;
use serde_json::Value as JsonValue;
use std::io::Cursor;

const PROTOCOL_VERSION: i64 = 1;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct GatewayBundle {
    bundle_name: String,
    bundle_js: String,
}

/// CBOR 请求 envelope。字段名和 Flutter 适配层保持一致，避免改变现有协议。
#[derive(Debug, Deserialize)]
#[serde(tag = "op", rename_all = "snake_case")]
enum GatewayRequest {
    TaskCall {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
        #[serde(rename = "taskGroupKey")]
        task_group_key: String,
        #[serde(rename = "isOnce")]
        is_once: bool,
        #[serde(rename = "bundleJs")]
        bundle_js: Option<String>,
        #[serde(rename = "bundleUrl")]
        bundle_url: Option<String>,
        #[serde(rename = "fnPath")]
        fn_path: String,
        args: JsonValue,
    },
    BuildRuntime {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
        #[serde(rename = "injectFilesystem")]
        inject_filesystem: bool,
        bundle: Option<GatewayBundle>,
    },
    IsRuntimeInitialized {
        version: i64,
        name: String,
    },
    CurrentBundle {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
    },
    DropRuntime {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
    },
    ClearBundle {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
    },
    ReplaceBundle {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
        #[serde(rename = "bundleName")]
        bundle_name: String,
        #[serde(rename = "bundleJs")]
        bundle_js: String,
    },
    CancelTasks {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
        #[serde(rename = "taskGroupKey")]
        task_group_key: String,
    },
    DebugSnapshot {
        version: i64,
        #[serde(rename = "runtimeName")]
        runtime_name: String,
    },
}

#[derive(Serialize)]
#[serde(untagged)]
enum GatewayValue {
    Void(()),
    Bool(bool),
    Text(String),
    Bytes(ByteBuf),
    Map(CancelTasksResult),
}

impl GatewayValue {
    fn kind(&self) -> &'static str {
        match self {
            Self::Void(()) => "void",
            Self::Bool(_) => "bool",
            Self::Text(_) => "text",
            Self::Bytes(_) => "bytes",
            Self::Map(_) => "map",
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CancelTasksResult {
    cancelled: i32,
    not_found: i32,
    failed_runtime_groups: Vec<String>,
}

#[derive(Serialize)]
struct GatewaySuccess {
    version: i64,
    ok: bool,
    kind: &'static str,
    value: GatewayValue,
}

#[derive(Serialize)]
struct GatewayError {
    version: i64,
    ok: bool,
    error: String,
}

#[derive(Serialize)]
#[serde(untagged)]
enum GatewayResponse {
    Success(GatewaySuccess),
    Error(GatewayError),
}

pub async fn plugin_gateway_call(request: Vec<u8>) -> Result<Vec<u8>> {
    let request: GatewayRequest =
        ciborium::de::from_reader(Cursor::new(request)).context("解码插件网关 CBOR 请求失败")?;

    let response = match dispatch(request).await {
        Ok(value) => GatewayResponse::Success(GatewaySuccess {
            version: PROTOCOL_VERSION,
            ok: true,
            kind: value.kind(),
            value,
        }),
        Err(error) => GatewayResponse::Error(GatewayError {
            version: PROTOCOL_VERSION,
            ok: false,
            error: error.to_string(),
        }),
    };

    encode_value(&response)
}

async fn dispatch(request: GatewayRequest) -> Result<GatewayValue> {
    match request {
        GatewayRequest::TaskCall {
            version,
            runtime_name,
            task_group_key,
            is_once,
            bundle_js,
            bundle_url,
            fn_path,
            args,
        } => {
            validate_version(version)?;
            let args_json = serde_json::to_string(&args).context("序列化插件调用参数失败")?;
            let result = crate::qjs::qjs_task_call(
                runtime_name,
                task_group_key,
                is_once,
                bundle_js,
                bundle_url,
                fn_path,
                args_json,
            )
            .await?;
            Ok(GatewayValue::Bytes(ByteBuf::from(result)))
        }
        GatewayRequest::BuildRuntime {
            version,
            runtime_name,
            inject_filesystem,
            bundle,
        } => {
            validate_version(version)?;
            crate::qjs::build_qjs_runtime(crate::qjs::QjsRuntimeBuildRequest {
                runtime_name,
                inject_filesystem,
                bundle: bundle.map(|bundle| crate::qjs::QjsRuntimeBundleBuild {
                    bundle_name: bundle.bundle_name,
                    bundle_js: bundle.bundle_js,
                }),
            })
            .await?;
            Ok(void_result())
        }
        GatewayRequest::IsRuntimeInitialized { version, name } => {
            validate_version(version)?;
            Ok(bool_result(
                crate::qjs::is_qjs_runtime_initialized(name).await?,
            ))
        }
        GatewayRequest::CurrentBundle {
            version,
            runtime_name,
        } => {
            validate_version(version)?;
            Ok(text_result(
                crate::qjs::qjs_current_bundle(runtime_name).await?,
            ))
        }
        GatewayRequest::DropRuntime {
            version,
            runtime_name,
        } => {
            validate_version(version)?;
            Ok(bool_result(
                crate::qjs::qjs_drop_runtime(runtime_name).await?,
            ))
        }
        GatewayRequest::ClearBundle {
            version,
            runtime_name,
        } => {
            validate_version(version)?;
            Ok(bool_result(
                crate::qjs::qjs_clear_bundle(runtime_name).await?,
            ))
        }
        GatewayRequest::ReplaceBundle {
            version,
            runtime_name,
            bundle_name,
            bundle_js,
        } => {
            validate_version(version)?;
            crate::qjs::qjs_replace_bundle(runtime_name, bundle_name, bundle_js).await?;
            Ok(void_result())
        }
        GatewayRequest::CancelTasks {
            version,
            runtime_name,
            task_group_key,
        } => {
            validate_version(version)?;
            let result =
                crate::qjs::qjs_cancel_tasks_by_group(runtime_name, task_group_key).await?;
            Ok(GatewayValue::Map(CancelTasksResult {
                cancelled: result.cancelled,
                not_found: result.not_found,
                failed_runtime_groups: result.failed_runtime_groups,
            }))
        }
        GatewayRequest::DebugSnapshot {
            version,
            runtime_name,
        } => {
            validate_version(version)?;
            Ok(text_result(
                crate::qjs::qjs_debug_snapshot(runtime_name).await?,
            ))
        }
    }
}

fn validate_version(version: i64) -> Result<()> {
    if version == PROTOCOL_VERSION {
        Ok(())
    } else {
        Err(anyhow!("不支持的插件网关协议版本: {version}"))
    }
}

fn encode_value<T: Serialize>(value: &T) -> Result<Vec<u8>> {
    let mut encoded = Vec::new();
    ciborium::ser::into_writer(value, &mut encoded).context("编码插件网关 CBOR 响应失败")?;
    Ok(encoded)
}

fn void_result() -> GatewayValue {
    GatewayValue::Void(())
}

fn bool_result(value: bool) -> GatewayValue {
    GatewayValue::Bool(value)
}

fn text_result(value: String) -> GatewayValue {
    GatewayValue::Text(value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use ciborium::Value;
    use serde_json::json;

    #[test]
    fn decodes_flat_task_call_request() {
        let request = json!({
            "version": 1,
            "op": "task_call",
            "runtimeName": "plugin",
            "taskGroupKey": "group",
            "isOnce": false,
            "bundleJs": null,
            "bundleUrl": null,
            "fnPath": "getInfo",
            "args": {"page": 1}
        });
        let mut encoded = Vec::new();
        ciborium::ser::into_writer(&request, &mut encoded).unwrap();

        let decoded: GatewayRequest = ciborium::de::from_reader(Cursor::new(encoded)).unwrap();
        match decoded {
            GatewayRequest::TaskCall {
                runtime_name,
                fn_path,
                args,
                ..
            } => {
                assert_eq!(runtime_name, "plugin");
                assert_eq!(fn_path, "getInfo");
                assert_eq!(args["page"], 1);
            }
            _ => panic!("expected task_call request"),
        }
    }

    #[test]
    fn encodes_binary_result_as_cbor_bytes() {
        let response = GatewayResponse::Success(GatewaySuccess {
            version: PROTOCOL_VERSION,
            ok: true,
            kind: "bytes",
            value: GatewayValue::Bytes(ByteBuf::from(vec![1, 2, 3])),
        });
        let encoded = encode_value(&response).unwrap();
        let decoded: Value = ciborium::de::from_reader(Cursor::new(encoded)).unwrap();
        let Value::Map(entries) = decoded else {
            panic!("expected response map");
        };
        let value = entries
            .iter()
            .find_map(|(key, value)| match key {
                Value::Text(key) if key == "value" => Some(value),
                _ => None,
            })
            .expect("response value");
        assert_eq!(value, &Value::Bytes(vec![1, 2, 3]));
    }
}
