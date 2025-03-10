# 用来在windows环境下构建flutter项目的APK

# 获取脚本所在目录
$scriptPath = $PSScriptRoot

# 项目根目录
$projectRoot = Join-Path $scriptPath "..\"

# AndroidManifest.xml 完整路径
$manifestPath = Join-Path $projectRoot "android\app\src\main\AndroidManifest.xml"

# 定义目录路径
$releaseDir = Join-Path $projectRoot "build\app\outputs\apk\release"
$skiaDir = Join-Path $projectRoot "build\app\outputs\apk\skia"

try
{
    Set-Location $projectRoot

    # 0. 验证文件存在性
    if (-not (Test-Path $manifestPath))
    {
        throw "无法找到 AndroidManifest.xml：$manifestPath"
    }

    # 1. 备份原始文件
    $backupFile = "$manifestPath.bak"
    Copy-Item -Path $manifestPath -Destination $backupFile -Force
    Write-Host "已创建备份文件：$backupFile"

    # 2. 第一次构建：使用 Skia
    Write-Host "第一次构建：使用 Skia" -ForegroundColor Cyan
    flutter build apk --split-per-abi --dart-define=use_skia=true

    # 3. 复制第一次构建的文件到 skia 目录
    if (Test-Path $releaseDir)
    {
        if (-not (Test-Path $skiaDir))
        {
            New-Item -ItemType Directory -Path $skiaDir | Out-Null
        }
        Copy-Item -Path "$releaseDir\*" -Destination $skiaDir -Recurse -Force
        Write-Host "已将第一次构建的文件复制到 $skiaDir"
    }
    else
    {
        Write-Warning "未找到第一次构建的输出目录：$releaseDir"
    }

    # 4. 修改配置
    $content = Get-Content $manifestPath -Raw
    $modified = $content -replace '(android:name="io\.flutter\.embedding\.android\.EnableImpeller"\s+android:value=")false(")', '$1true$2'

    if ($content -ne $modified)
    {
        $modified | Set-Content $manifestPath
        Write-Host "已启用 Impeller 渲染引擎"
    }
    else
    {
        Write-Warning "未找到需要修改的配置项"
    }

    # 5. 第二次构建：不使用 Skia
    Write-Host "第二次构建：不使用 Skia" -ForegroundColor Cyan
    flutter build apk --split-per-abi
}
catch
{
    Write-Host "发生错误：$_" -ForegroundColor Red
    exit 1
}
finally
{
    # 7. 恢复原始文件
    if (Test-Path $backupFile)
    {
        Move-Item -Path $backupFile -Destination $manifestPath -Force
        Write-Host "已恢复原始配置文件"
    }
}

Write-Host "构建流程完成" -ForegroundColor Green