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
    println!("cargo::rustc-check-cfg=cfg(frb_expand)");

    // NDK r29 在目标 API >= 28 时默认输出 DT_ANDROID_RELR(0x6fffe000) 压缩相对重定位，
    // 而 bionic 要到 Android 10 (API 29) 才认识这个 tag；旧 linker 把它当作未知 DT 项跳过
    // （日志里就是 "unused DT entry"），整表不应用，.init_array / .data.rel.ro 里的函数指针
    // 保持链接期地址，System.loadLibrary("windcore") 在 call_constructors 阶段直接 SIGSEGV。
    // --pack-dyn-relocs=android 回退到旧版 DT_ANDROID_REL(0x60000011)，bionic 自 API 21 起
    // 支持，同时仍保留压缩收益。已在 Likebook T80D (Android 8.1 / API 27) 实测：
    // 默认(=android+relr) 崩溃，android 与 none 均加载且重定位结果正确。
    if env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("android") {
        println!("cargo:rustc-link-arg=-Wl,--pack-dyn-relocs=android");
    }

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
