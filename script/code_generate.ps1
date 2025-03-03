$scriptPath = $PSScriptRoot

# 项目根目录
$projectRoot = Join-Path $scriptPath "..\"

Set-Location $projectRoot

dart run build_runner build

dart format ./lib/