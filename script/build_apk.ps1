# 用来在windows环境下构建flutter项目的APK

# 获取脚本所在目录
$scriptPath = $PSScriptRoot

# 项目根目录
$projectRoot = Join-Path $scriptPath "..\"

# AndroidManifest.xml 完整路径
$manifestPath = Join-Path $projectRoot "android\app\src\main\AndroidManifest.xml"

try {
    # 0. 验证文件存在性
    if (-not (Test-Path $manifestPath)) {
        throw "无法找到 AndroidManifest.xml：$manifestPath"
    }

    # 1. 备份原始文件
    $backupFile = "$manifestPath.bak"
    Copy-Item -Path $manifestPath -Destination $backupFile -Force
    Write-Host "已创建备份文件：$backupFile"

    # 2. 修改配置
    $content = Get-Content $manifestPath -Raw
    $modified = $content -replace '(android:name="io\.flutter\.embedding\.android\.EnableImpeller"\s+android:value=")false(")', '$1true$2'

    if ($content -ne $modified) {
        $modified | Set-Content $manifestPath
        Write-Host "已启用 Impeller 渲染引擎"
    } else {
        Write-Warning "未找到需要修改的配置项"
    }

    # 3. 构建 APK
    Set-Location $projectRoot
    flutter build apk --split-per-abi

} catch {
    Write-Host "发生错误：$_" -ForegroundColor Red
    exit 1
} finally {
    # 4. 恢复原始文件
    if (Test-Path $backupFile) {
        Move-Item -Path $backupFile -Destination $manifestPath -Force
        Write-Host "已恢复原始配置文件"
    }
}

Write-Host "构建流程完成" -ForegroundColor Green