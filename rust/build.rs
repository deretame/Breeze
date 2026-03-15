use std::env;
use std::fs;
use std::path::{Path, PathBuf};

const DOWNLOADS: [(&str, &str); 2] = [
    (
        "https://github.com/deretame/Breeze-plugin-JmComic/blob/main/verison/v0.0.1/JmComic.bundle.cjs",
        "JmComic.bundle.cjs",
    ),
    (
        "https://github.com/deretame/Breeze-plugin-bikaComic/blob/main/version/v0.0.1/bikaComic.bundle.cjs",
        "bikaComic.bundle.cjs",
    ),
];

fn main() {
    println!("cargo:rerun-if-env-changed=FORCE_PLUGIN_DOWNLOAD");

    let manifest_dir = PathBuf::from(
        env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR must be available"),
    );
    let assets_dir = manifest_dir.join("assets");

    fs::create_dir_all(&assets_dir)
        .unwrap_or_else(|err| panic!("failed to create assets dir {:?}: {err}", assets_dir));

    for (url, file_name) in DOWNLOADS {
        download_to_file(url, &assets_dir.join(file_name));
    }
}

fn download_to_file(url: &str, destination: &Path) {
    let resolved_url = to_raw_github_url(url);
    let response = ureq::get(&resolved_url)
        .call()
        .unwrap_or_else(|err| panic!("failed to download {resolved_url}: {err}"));

    let mut reader = response.into_reader();
    let mut bytes = Vec::new();
    std::io::copy(&mut reader, &mut bytes)
        .unwrap_or_else(|err| panic!("failed to read response from {resolved_url}: {err}"));

    fs::write(destination, bytes)
        .unwrap_or_else(|err| panic!("failed to write {:?}: {err}", destination));
}

fn to_raw_github_url(url: &str) -> String {
    if let Some(path) = url.strip_prefix("https://github.com/") {
        let mut parts = path.splitn(4, '/');
        if let (Some(owner), Some(repo), Some("blob"), Some(rest)) =
            (parts.next(), parts.next(), parts.next(), parts.next())
        {
            return format!("https://raw.githubusercontent.com/{owner}/{repo}/{rest}");
        }
    }

    url.to_owned()
}
