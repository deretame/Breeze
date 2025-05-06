$scriptPath = $PSScriptRoot

# 项目根目录
$projectRoot = Join-Path $scriptPath "..\"

Set-Location $projectRoot

dart run build_runner build

flutter_rust_bridge_codegen generate --watch

dart format ./lib/