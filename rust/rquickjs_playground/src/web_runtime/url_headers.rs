fn parse_query_pairs(query: &str) -> Vec<(String, String)> {
    let raw = query.strip_prefix('?').unwrap_or(query);
    form_urlencoded::parse(raw.as_bytes())
        .map(|(k, v)| (k.into_owned(), v.into_owned()))
        .collect()
}

fn serialize_query_pairs(pairs: &[(String, String)]) -> String {
    let mut serializer = form_urlencoded::Serializer::new(String::new());
    for (k, v) in pairs {
        serializer.append_pair(k, v);
    }
    serializer.finish()
}

pub fn urlsp_rewrite(
    op: String,
    query: String,
    key: Option<String>,
    value: Option<String>,
) -> String {
    let mut pairs = parse_query_pairs(&query);
    match op.as_str() {
        "append" => {
            if let (Some(k), Some(v)) = (key, value) {
                pairs.push((k, v));
            }
        }
        "set" => {
            if let (Some(k), Some(v)) = (key, value) {
                pairs.retain(|(ek, _)| ek != &k);
                pairs.push((k, v));
            }
        }
        "delete" => {
            if let Some(k) = key {
                if let Some(v) = value {
                    pairs.retain(|(ek, ev)| !(ek == &k && ev == &v));
                } else {
                    pairs.retain(|(ek, _)| ek != &k);
                }
            }
        }
        "sort" => {
            pairs.sort_by(|(ak, _), (bk, _)| ak.cmp(bk));
        }
        _ => {}
    }
    serialize_query_pairs(&pairs)
}

pub fn urlsp_query(
    op: String,
    query: String,
    key: Option<String>,
    value: Option<String>,
) -> String {
    let pairs = parse_query_pairs(&query);
    match op.as_str() {
        "toString" => json!({ "ok": true, "data": serialize_query_pairs(&pairs) }).to_string(),
        "get" => {
            if let Some(k) = key {
                let val = pairs
                    .iter()
                    .find(|(ek, _)| ek == &k)
                    .map(|(_, ev)| ev.clone());
                json!({ "ok": true, "data": val }).to_string()
            } else {
                json!({ "ok": true, "data": Value::Null }).to_string()
            }
        }
        "getAll" => {
            if let Some(k) = key {
                let vals: Vec<String> = pairs
                    .iter()
                    .filter(|(ek, _)| ek == &k)
                    .map(|(_, ev)| ev.clone())
                    .collect();
                json!({ "ok": true, "data": vals }).to_string()
            } else {
                json!({ "ok": true, "data": Vec::<String>::new() }).to_string()
            }
        }
        "has" => {
            if let Some(k) = key {
                let has = if let Some(v) = value {
                    pairs.iter().any(|(ek, ev)| ek == &k && ev == &v)
                } else {
                    pairs.iter().any(|(ek, _)| ek == &k)
                };
                json!({ "ok": true, "data": has }).to_string()
            } else {
                json!({ "ok": true, "data": false }).to_string()
            }
        }
        _ => json!({ "ok": false, "error": "unsupported urlsp query op" }).to_string(),
    }
}

fn parse_headers_json(headers_json: &str) -> Map<String, Value> {
    match serde_json::from_str::<Value>(headers_json) {
        Ok(Value::Object(obj)) => obj,
        _ => Map::new(),
    }
}

fn headers_to_json(map: &Map<String, Value>) -> String {
    Value::Object(map.clone()).to_string()
}

pub fn headers_rewrite(
    op: String,
    headers_json: String,
    name: Option<String>,
    value: Option<String>,
) -> String {
    let mut map = parse_headers_json(&headers_json);
    let key = name.map(|n| n.to_ascii_lowercase());
    match op.as_str() {
        "append" => {
            if let (Some(k), Some(v)) = (key, value) {
                if let Some(existing) = map.get(&k).and_then(Value::as_str) {
                    map.insert(k, Value::String(format!("{existing}, {v}")));
                } else {
                    map.insert(k, Value::String(v));
                }
            }
        }
        "set" => {
            if let (Some(k), Some(v)) = (key, value) {
                map.insert(k, Value::String(v));
            }
        }
        "delete" => {
            if let Some(k) = key {
                map.remove(&k);
            }
        }
        _ => {}
    }
    headers_to_json(&map)
}

pub fn headers_query(op: String, headers_json: String, name: Option<String>) -> String {
    let map = parse_headers_json(&headers_json);
    let key = name.map(|n| n.to_ascii_lowercase());
    match op.as_str() {
        "get" => {
            let val = key
                .as_ref()
                .and_then(|k| map.get(k))
                .and_then(Value::as_str)
                .map(|s| s.to_string());
            json!({ "ok": true, "data": val }).to_string()
        }
        "has" => {
            let has = key.as_ref().map(|k| map.contains_key(k)).unwrap_or(false);
            json!({ "ok": true, "data": has }).to_string()
        }
        "entries" => {
            let mut entries: Vec<(String, String)> = Vec::new();
            for (k, v) in map {
                if let Some(s) = v.as_str() {
                    entries.push((k, s.to_string()));
                }
            }
            json!({ "ok": true, "data": entries }).to_string()
        }
        _ => json!({ "ok": false, "error": "unsupported headers query op" }).to_string(),
    }
}
use super::*;
