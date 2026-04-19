use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use serde_json::Value;

const GITHUB_RELEASE_APIS: [(&str, &str); 2] = [
    (
        "https://api.github.com/repos/deretame/Breeze-plugin-JmComic/releases/latest",
        "jm-comic.bundle.cjs",
    ),
    (
        "https://api.github.com/repos/deretame/Breeze-plugin-bikaComic/releases/latest",
        "bika-comic.bundle.cjs",
    ),
];
const USER_AGENT: &str = "Breeze-build-script";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-env-changed=BREEZE_PLUGIN_GITHUB_TOKEN");
    println!("cargo:rerun-if-env-changed=GITHUB_TOKEN");
    println!("cargo:rerun-if-env-changed=GH_TOKEN");

    let manifest_dir = PathBuf::from(
        env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR must be available"),
    );
    let assets_dir = manifest_dir.join("assets");
    let token = github_token();

    fs::create_dir_all(&assets_dir)
        .unwrap_or_else(|err| panic!("failed to create assets dir {:?}: {err}", assets_dir));

    for (api_url, file_name) in GITHUB_RELEASE_APIS {
        let destination = assets_dir.join(file_name);
        if let Err(err) =
            download_latest_release_asset(api_url, file_name, &destination, token.as_deref())
        {
            if destination.exists() {
                println!(
                    "cargo:warning=failed to refresh {file_name} ({err}), fallback to cached file"
                );
            } else {
                panic!("{err}");
            }
        }
    }
}

fn download_latest_release_asset(
    api_url: &str,
    expected_asset_name: &str,
    destination: &Path,
    token: Option<&str>,
) -> Result<(), String> {
    let mut release_request = ureq::get(api_url)
        .header("Accept", "application/vnd.github+json")
        .header("User-Agent", USER_AGENT);

    if let Some(token) = token {
        release_request = release_request.header("Authorization", &format!("Bearer {token}"));
    }

    let release_response = release_request
        .call()
        .map_err(|err| format!("failed to request latest release from {api_url}: {err}"))?;

    let release_json_bytes = read_response_bytes(release_response, api_url)?;
    let release_json: Value = serde_json::from_slice(&release_json_bytes)
        .map_err(|err| format!("failed to parse latest release json from {api_url}: {err}"))?;

    let assets = release_json
        .get("assets")
        .and_then(Value::as_array)
        .ok_or_else(|| format!("invalid latest release response from {api_url}: missing assets"))?;

    let download_url = assets
        .iter()
        .find_map(|asset| {
            let name = asset.get("name")?.as_str()?;
            if name == expected_asset_name {
                asset
                    .get("browser_download_url")
                    .and_then(Value::as_str)
                    .map(str::to_owned)
            } else {
                None
            }
        })
        .ok_or_else(|| {
            format!("asset {expected_asset_name} not found in latest release from {api_url}")
        })?;

    let mut download_request = ureq::get(&download_url)
        .header("Accept", "application/octet-stream")
        .header("User-Agent", USER_AGENT);

    if let Some(token) = token {
        download_request = download_request.header("Authorization", &format!("Bearer {token}"));
    }

    let download_response = download_request
        .call()
        .map_err(|err| format!("failed to download {download_url}: {err}"))?;

    let bytes = read_response_bytes(download_response, &download_url)?;

    fs::write(destination, bytes)
        .map_err(|err| format!("failed to write {:?}: {err}", destination))?;

    Ok(())
}

fn read_response_bytes(
    response: ureq::http::Response<ureq::Body>,
    source: &str,
) -> Result<Vec<u8>, String> {
    let mut body = response.into_body();
    let mut reader = body.as_reader();
    let mut bytes = Vec::new();
    std::io::copy(&mut reader, &mut bytes)
        .map_err(|err| format!("failed to read response body from {source}: {err}"))?;
    Ok(bytes)
}

fn github_token() -> Option<String> {
    ["BREEZE_PLUGIN_GITHUB_TOKEN", "GITHUB_TOKEN", "GH_TOKEN"]
        .into_iter()
        .find_map(|name| env::var(name).ok().filter(|value| !value.trim().is_empty()))
}
