$scriptPath = $PSScriptRoot

# 项目根目录
$projectRoot = Join-Path $scriptPath "..\"

Set-Location $projectRoot

dart run build_runner build

# 安装工具来添加rust的支持
cargo install flutter_rust_bridge_codegen

flutter_rust_bridge_codegen generate

dart format ./lib/