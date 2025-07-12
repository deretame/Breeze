# --- 1. 初始化路径 ---
# 获取脚本所在的确切目录
$scriptPath = $PSScriptRoot

# 解析项目根目录的绝对路径 (脚本所在目录的上一级)
$projectRoot = (Resolve-Path (Join-Path $scriptPath "..")).Path

# AndroidManifest.xml 完整路径
$manifestPath = Join-Path $projectRoot "android\app\src\main\AndroidManifest.xml"

# 备份文件名
$backupFile = "$manifestPath.bak"

# 定义输出目录路径
$releaseDir = Join-Path $projectRoot "build\app\outputs\apk\release"
$skiaDir = Join-Path $projectRoot "build\app\outputs\apk\skia" # 用于存放Skia构建产物

# 符号更新脚本的路径
$updateSymbolsScriptFolderPath = Join-Path $projectRoot "symbols"
$updateSymbolsScriptPath = Join-Path $updateSymbolsScriptFolderPath "update_symbols.ps1"


# --- 2. 主流程 ---
try {
    # 切换当前工作目录到项目根目录，这是执行 flutter 命令的前提
    Set-Location $projectRoot
    Write-Host "当前工作目录: $(Get-Location)" -ForegroundColor Yellow

    # 验证 AndroidManifest.xml 文件是否存在
    if (-not (Test-Path $manifestPath)) {
        throw "无法找到 AndroidManifest.xml 文件，请检查路径：$manifestPath"
    }

    # 备份原始的 AndroidManifest.xml 文件
    Write-Host "--- 正在备份 AndroidManifest.xml ---"
    Copy-Item -Path $manifestPath -Destination $backupFile -Force
    Write-Host "已创建备份文件：$backupFile"

    # --- 第一次构建：使用 Skia 渲染引擎 ---
    Write-Host "`n--- (1/4) 开始第一次构建：使用 Skia 渲染引擎 ---" -ForegroundColor Cyan
    flutter build apk --split-per-abi --dart-define=use_skia=true
    # 检查上一个命令是否成功
    if ($LASTEXITCODE -ne 0) { throw "第一次构建 (Skia) 失败！" }


    # --- 复制第一次构建的产物到 skia 目录 ---
    Write-Host "`n--- (2/4) 正在整理 Skia 构建产物 ---" -ForegroundColor Cyan
    if (Test-Path $releaseDir) {
        if (-not (Test-Path $skiaDir)) {
            New-Item -ItemType Directory -Path $skiaDir | Out-Null
        }
        Copy-Item -Path "$releaseDir\*" -Destination $skiaDir -Recurse -Force
        Write-Host "已将 Skia 构建的 APK 复制到: $skiaDir"
    }
    else {
        Write-Warning "未找到第一次构建的输出目录：$releaseDir"
    }

    # --- 修改配置文件以启用 Impeller ---
    # Impeller 是默认引擎，只需注释掉或删除禁用它的配置即可
    Write-Host "`n--- (3/4) 正在修改配置以启用 Impeller 引擎 ---" -ForegroundColor Cyan
    $content = Get-Content $manifestPath -Raw
    # 匹配禁用 Impeller 的 meta-data 标签
    $pattern = '<meta-data\s+android:name="io\.flutter\.embedding\.android\.EnableImpeller"\s+android:value="false"\s*/>'
    # 准备替换为注释掉的内容
    $replacement = '<!--        <meta-data
                android:name="io.flutter.embedding.android.EnableImpeller"
                android:value="false"/>-->'
    
    if ($content -match $pattern) {
        $modified = $content -replace $pattern, $replacement
        $modified | Set-Content -Path $manifestPath -Encoding UTF8
        Write-Host "已注释 AndroidManifest.xml 中的 EnableImpeller=false 配置，以启用 Impeller."
    }
    else {
        Write-Warning "在 AndroidManifest.xml 中未找到需要注释的 Impeller 配置项，将继续使用默认配置构建。"
    }

    # --- 第二次构建：使用 Impeller (默认) ---
    Write-Host "`n--- (4/4) 开始第二次构建：使用 Impeller 渲染引擎 ---" -ForegroundColor Cyan
    flutter build apk --split-per-abi --split-debug-info="$($projectRoot)\symbols"
    # 检查上一个命令是否成功
    if ($LASTEXITCODE -ne 0) { throw "第二次构建 (Impeller) 失败！" }

    # --- 可选：运行符号更新脚本 ---
 
    if (Test-Path $updateSymbolsScriptPath) {
        # 弹出 Y/N 选项，需要输入 y 或 yes 才会执行，不区分大小写
        $choice = Read-Host "`n是否要运行符号更新脚本 '$updateSymbolsScriptPath'? (y/N)"
        if ($choice.ToLower() -in 'y', 'yes') {
            Write-Host "--- 正在执行符号更新脚本... ---" -ForegroundColor Cyan
            Set-Location $updateSymbolsScriptFolderPath
            & .\update_symbols.ps1
            if ($LASTEXITCODE -ne 0) { throw "符号更新脚本执行失败！" }
        }
        else {
            Write-Host "已跳过执行符号更新脚本。" -ForegroundColor Yellow
        }
    }
    else {
        Write-Warning "找不到符号更新脚本: $updateSymbolsScriptPath"
    }
} 
catch {
    # 如果过程中发生任何错误，打印错误信息
    Write-Host "`n构建过程中发生错误！" -ForegroundColor Red
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Red
    # 退出脚本并返回非零退出码，表示失败
    exit 1
}
finally {
    # 这个块会在脚本被 Ctrl+C 中断时执行，从而清理子进程
    Write-Host "`n--- 正在精确查找并停止任何残留的构建进程 ---" -ForegroundColor Yellow
    
    # 1. 精确停止 Flutter Build 的 Dart 进程
    try {
        # 使用 Get-CimInstance 查找 CommandLine 包含 'build' 和 'apk' 的 dart.exe 进程
        $dartBuildProcess = Get-CimInstance Win32_Process | Where-Object { 
            $_.Name -eq 'dart.exe' -and $_.CommandLine -like '*build*apk*'
        }
        
        if ($dartBuildProcess) {
            foreach ($process in $dartBuildProcess) {
                Write-Host "正在停止 Flutter build 进程 (PID: $($process.ProcessId))..." -ForegroundColor Magenta
                Stop-Process -Id $process.ProcessId -Force
            }
        }
        else {
            Write-Host "未找到残留的 Flutter build Dart 进程。"
        }
    }
    catch {
        Write-Host "检查 Dart 进程时出错: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 2. 精确停止 Gradle 的 Java 进程
    try {
        # 查找命令行包含 'gradle' 的 Java 进程
        $gradleProcess = Get-CimInstance Win32_Process | Where-Object {
            ($_.Name -eq 'java.exe' -or $_.Name -eq 'OpenJDK Platform binary') -and $_.CommandLine -like '*gradle*'
        }

        if ($gradleProcess) {
            foreach ($process in $gradleProcess) {
                Write-Host "正在停止 Gradle 进程 (PID: $($process.ProcessId))..." -ForegroundColor Magenta
                Stop-Process -Id $process.ProcessId -Force
            }
        }
        else {
            Write-Host "未找到残留的 Gradle 进程。"
        }
    }
    catch {
        Write-Host "检查 Gradle 进程时出错: $($_.Exception.Message)" -ForegroundColor Red
    }

    if (Test-Path $backupFile) {
        Write-Host "`n--- 正在恢复原始 AndroidManifest.xml 文件 ---"
        Move-Item -Path $backupFile -Destination $manifestPath -Force
        Write-Host "已从备份恢复原始配置文件。"
    }
    Set-Location $projectRoot
}

Write-Host "`n构建流程全部完成！" -ForegroundColor Green