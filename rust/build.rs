use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

const PLUGIN_ASSETS: [(&str, &str); 2] = [
    (
        "https://cdn.jsdelivr.net/npm/breeze-plugin-jm-comic@latest/dist/breeze-plugin-jm-comic.bundle.cjs",
        "jm-comic.bundle.cjs",
    ),
    (
        "https://cdn.jsdelivr.net/npm/breeze-plugin-bika-comic@latest/dist/breeze-plugin-bika-comic.bundle.cjs",
        "bika-comic.bundle.cjs",
    ),
];
const USER_AGENT: &str = "Breeze-build-script";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    let manifest_dir = PathBuf::from(
        env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR must be available"),
    );
    let assets_dir = manifest_dir.join("assets");

    fs::create_dir_all(&assets_dir)
        .unwrap_or_else(|err| panic!("failed to create assets dir {:?}: {err}", assets_dir));

    for (url, file_name) in PLUGIN_ASSETS {
        let destination = assets_dir.join(file_name);
        if let Err(err) = download_to(url, &destination) {
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

fn download_to(url: &str, destination: &Path) -> Result<(), String> {
    let response = ureq::get(url)
        .header("User-Agent", USER_AGENT)
        .call()
        .map_err(|err| format!("failed to download {url}: {err}"))?;

    let mut body = response.into_body();
    let mut reader = body.as_reader();
    let mut bytes = Vec::new();
    io::copy(&mut reader, &mut bytes)
        .map_err(|err| format!("failed to read response body from {url}: {err}"))?;

    fs::write(destination, bytes)
        .map_err(|err| format!("failed to write {:?}: {err}", destination))?;

    Ok(())
}
