use axum::{Json, Router, routing::get};
use get_if_addrs::get_if_addrs;
use serde::Serialize;
use std::net::SocketAddr;
use tower_http::services::{ServeDir, ServeFile};

#[derive(Serialize)]
struct ApiManifest {
    bika: Vec<String>,
    jm: Vec<String>,
}

#[tokio::main]
async fn main() {
    const PORT: u16 = 8080;

    println!("Starting up web server...");

    let static_service = ServeDir::new(".").not_found_service(ServeFile::new("index.html"));

    let app = Router::new()
        .route("/api/list-comics", get(list_comics_api))
        .fallback_service(static_service);

    println!("\nAvailable on:");

    println!("  http://127.0.0.1:{}", PORT);

    match get_if_addrs() {
        Ok(interfaces) => {
            for iface in interfaces {
                let ip = iface.ip();

                if !iface.is_loopback() && ip.is_ipv4() {
                    println!("  http://{}:{}", ip, PORT);
                }
            }
        }
        Err(e) => {
            eprintln!("[WARN] Could not get network interfaces: {}", e);
            eprintln!("[INFO] Listening on 0.0.0.0:{}, try 127.0.0.1.", PORT);
        }
    }

    println!("\nHit CTRL-C to stop the server");

    let addr = SocketAddr::from(([0, 0, 0, 0], PORT)); // [!code focus]

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn list_comics_api() -> Json<ApiManifest> {
    println!("Serving dynamic API: /api/list-comics");

    let bika_path = "comics/bika".to_string();
    let jm_path = "comics/jm".to_string();

    let (bika, jm) = tokio::join!(get_folders(bika_path), get_folders(jm_path));

    Json(ApiManifest { bika, jm })
}

async fn get_folders(sub_dir: String) -> Vec<String> {
    tokio::task::spawn_blocking(move || {
        let path = std::path::Path::new(&sub_dir);
        match std::fs::read_dir(path) {
            Ok(entries) => entries
                .filter_map(Result::ok)
                .filter(|entry| entry.path().is_dir())
                .filter_map(|entry| entry.file_name().into_string().ok())
                .collect(),
            Err(e) => {
                eprintln!("[ERROR] Failed to read directory '{}': {}", sub_dir, e);
                Vec::new()
            }
        }
    })
    .await
    .unwrap_or_else(|_| Vec::new())
}
