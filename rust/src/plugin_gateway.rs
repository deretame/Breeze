use anyhow::{Context, Result, anyhow};
use ciborium::Value;
use serde_json::{Map as JsonMap, Number, Value as JsonValue};
use std::io::Cursor;

const PROTOCOL_VERSION: i64 = 1;

struct GatewayResult {
    kind: &'static str,
    value: Value,
}

pub async fn plugin_gateway_call(request: Vec<u8>) -> Result<Vec<u8>> {
    let request: Value =
        ciborium::de::from_reader(Cursor::new(request)).context("解码插件网关 CBOR 请求失败")?;

    let response = match dispatch(request).await {
        Ok(result) => success_response(result),
        Err(error) => error_response(error.to_string()),
    };

    encode_value(response)
}

async fn dispatch(request: Value) -> Result<GatewayResult> {
    let request = expect_map_ref(&request, "请求")?;
    let version = required_integer(request, "version")?;
    if version != PROTOCOL_VERSION {
        return Err(anyhow!("不支持的插件网关协议版本: {version}"));
    }

    let operation = required_text(request, "op")?;
    match operation.as_str() {
        "task_call" => {
            let args = cbor_to_json(required_value(request, "args")?)?;
            let args_json = serde_json::to_string(&args).context("序列化插件调用参数失败")?;
            let result = crate::qjs::qjs_task_call(
                required_text(request, "runtimeName")?,
                required_text(request, "taskGroupKey")?,
                required_bool(request, "isOnce")?,
                optional_text(request, "bundleJs")?,
                optional_text(request, "bundleUrl")?,
                required_text(request, "fnPath")?,
                args_json,
            )
            .await?;
            Ok(GatewayResult {
                kind: "bytes",
                value: Value::Bytes(result),
            })
        }
        "build_runtime" => {
            let bundle = match optional_value(request, "bundle")? {
                None | Some(Value::Null) => None,
                Some(value) => {
                    let bundle = expect_map_ref(value, "bundle")?;
                    Some(crate::qjs::QjsRuntimeBundleBuild {
                        bundle_name: required_text(bundle, "bundleName")?,
                        bundle_js: required_text(bundle, "bundleJs")?,
                    })
                }
            };
            crate::qjs::build_qjs_runtime(crate::qjs::QjsRuntimeBuildRequest {
                runtime_name: required_text(request, "runtimeName")?,
                inject_filesystem: required_bool(request, "injectFilesystem")?,
                bundle,
            })
            .await?;
            Ok(void_result())
        }
        "is_runtime_initialized" => Ok(bool_result(
            crate::qjs::is_qjs_runtime_initialized(required_text(request, "name")?).await?,
        )),
        "current_bundle" => Ok(text_result(
            crate::qjs::qjs_current_bundle(required_text(request, "runtimeName")?).await?,
        )),
        "drop_runtime" => Ok(bool_result(
            crate::qjs::qjs_drop_runtime(required_text(request, "runtimeName")?).await?,
        )),
        "clear_bundle" => Ok(bool_result(
            crate::qjs::qjs_clear_bundle(required_text(request, "runtimeName")?).await?,
        )),
        "replace_bundle" => {
            crate::qjs::qjs_replace_bundle(
                required_text(request, "runtimeName")?,
                required_text(request, "bundleName")?,
                required_text(request, "bundleJs")?,
            )
            .await?;
            Ok(void_result())
        }
        "cancel_tasks" => {
            let result = crate::qjs::qjs_cancel_tasks_by_group(
                required_text(request, "runtimeName")?,
                required_text(request, "taskGroupKey")?,
            )
            .await?;
            let mut value = Vec::with_capacity(3);
            value.push((
                Value::Text("cancelled".to_string()),
                Value::Integer(result.cancelled.into()),
            ));
            value.push((
                Value::Text("notFound".to_string()),
                Value::Integer(result.not_found.into()),
            ));
            value.push((
                Value::Text("failedRuntimeGroups".to_string()),
                Value::Array(
                    result
                        .failed_runtime_groups
                        .into_iter()
                        .map(Value::Text)
                        .collect(),
                ),
            ));
            Ok(map_result(value))
        }
        "debug_snapshot" => Ok(text_result(
            crate::qjs::qjs_debug_snapshot(required_text(request, "runtimeName")?).await?,
        )),
        other => Err(anyhow!("未知的插件网关操作: {other}")),
    }
}

fn success_response(result: GatewayResult) -> Value {
    Value::Map(vec![
        (
            Value::Text("version".to_string()),
            Value::Integer(PROTOCOL_VERSION.into()),
        ),
        (Value::Text("ok".to_string()), Value::Bool(true)),
        (
            Value::Text("kind".to_string()),
            Value::Text(result.kind.to_string()),
        ),
        (Value::Text("value".to_string()), result.value),
    ])
}

fn error_response(message: String) -> Value {
    Value::Map(vec![
        (
            Value::Text("version".to_string()),
            Value::Integer(PROTOCOL_VERSION.into()),
        ),
        (Value::Text("ok".to_string()), Value::Bool(false)),
        (Value::Text("error".to_string()), Value::Text(message)),
    ])
}

fn encode_value(value: Value) -> Result<Vec<u8>> {
    let mut encoded = Vec::new();
    ciborium::ser::into_writer(&value, &mut encoded).context("编码插件网关 CBOR 响应失败")?;
    Ok(encoded)
}

fn void_result() -> GatewayResult {
    GatewayResult {
        kind: "void",
        value: Value::Null,
    }
}

fn bool_result(value: bool) -> GatewayResult {
    GatewayResult {
        kind: "bool",
        value: Value::Bool(value),
    }
}

fn text_result(value: String) -> GatewayResult {
    GatewayResult {
        kind: "text",
        value: Value::Text(value),
    }
}

fn map_result(value: Vec<(Value, Value)>) -> GatewayResult {
    GatewayResult {
        kind: "map",
        value: Value::Map(value),
    }
}

fn expect_map_ref<'a>(value: &'a Value, name: &str) -> Result<&'a [(Value, Value)]> {
    match value {
        Value::Map(map) => Ok(map),
        _ => Err(anyhow!("{name}必须是 CBOR map")),
    }
}

fn find_value<'a>(map: &'a [(Value, Value)], key: &str) -> Option<&'a Value> {
    map.iter().find_map(|(candidate, value)| match candidate {
        Value::Text(candidate) if candidate == key => Some(value),
        _ => None,
    })
}

fn required_value<'a>(map: &'a [(Value, Value)], key: &str) -> Result<&'a Value> {
    find_value(map, key).ok_or_else(|| anyhow!("缺少插件网关字段: {key}"))
}

fn optional_value<'a>(map: &'a [(Value, Value)], key: &str) -> Result<Option<&'a Value>> {
    Ok(find_value(map, key))
}

fn required_text(map: &[(Value, Value)], key: &str) -> Result<String> {
    match required_value(map, key)? {
        Value::Text(value) => Ok(value.clone()),
        _ => Err(anyhow!("插件网关字段 {key} 必须是文本")),
    }
}

fn optional_text(map: &[(Value, Value)], key: &str) -> Result<Option<String>> {
    match optional_value(map, key)? {
        None | Some(Value::Null) => Ok(None),
        Some(Value::Text(value)) => Ok(Some(value.clone())),
        Some(_) => Err(anyhow!("插件网关字段 {key} 必须是文本或 null")),
    }
}

fn required_bool(map: &[(Value, Value)], key: &str) -> Result<bool> {
    match required_value(map, key)? {
        Value::Bool(value) => Ok(*value),
        _ => Err(anyhow!("插件网关字段 {key} 必须是布尔值")),
    }
}

fn required_integer(map: &[(Value, Value)], key: &str) -> Result<i64> {
    match required_value(map, key)? {
        Value::Integer(value) => {
            i64::try_from(*value).map_err(|_| anyhow!("插件网关字段 {key} 超出 i64 范围"))
        }
        _ => Err(anyhow!("插件网关字段 {key} 必须是整数")),
    }
}

fn cbor_to_json(value: &Value) -> Result<JsonValue> {
    match value {
        Value::Integer(value) => {
            let value = i128::from(*value);
            if let Ok(value) = i64::try_from(value) {
                Ok(JsonValue::Number(value.into()))
            } else if let Ok(value) = u64::try_from(value) {
                Ok(JsonValue::Number(value.into()))
            } else {
                Err(anyhow!("插件参数整数超出 JSON 范围"))
            }
        }
        Value::Bytes(value) => Ok(JsonValue::Array(
            value
                .iter()
                .map(|value| JsonValue::Number((*value).into()))
                .collect(),
        )),
        Value::Float(value) => Ok(JsonValue::Number(
            Number::from_f64(*value).ok_or_else(|| anyhow!("插件参数包含无效浮点数"))?,
        )),
        Value::Text(value) => Ok(JsonValue::String(value.clone())),
        Value::Bool(value) => Ok(JsonValue::Bool(*value)),
        Value::Null => Ok(JsonValue::Null),
        Value::Tag(_, value) => cbor_to_json(value),
        Value::Array(value) => Ok(JsonValue::Array(
            value.iter().map(cbor_to_json).collect::<Result<Vec<_>>>()?,
        )),
        Value::Map(value) => {
            let mut map = JsonMap::new();
            for (key, value) in value {
                let Value::Text(key) = key else {
                    return Err(anyhow!("插件参数 map 的 key 必须是文本"));
                };
                map.insert(key.clone(), cbor_to_json(value)?);
            }
            Ok(JsonValue::Object(map))
        }
        _ => Err(anyhow!("插件参数包含不支持的 CBOR 类型")),
    }
}
