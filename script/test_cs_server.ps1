#requires -Version 7.0

[CmdletBinding()]
param(
    [int]$Port = 18787
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ServerBinary = Join-Path $Root 'cs_server\target\debug\breeze_cs_server.exe'
$WebRoot = Join-Path $Root 'cs_web\dist'
$CloudPluginListUrl = 'https://api.windy-78.site/plugin-list'
$CdnMirrors = @(
    'https://jsdelivr.topthink.com/',
    'https://cdn.jsdmirror.com/',
    'https://cdn.jsdmirror.cn/',
    'https://www.webcache.cn/',
    'https://jsd.onmicrosoft.cn/',
    'https://cdn.jsdelivr.net/'
)
$AdminToken = 'cs-smoke-admin-token'
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('breeze-cs-smoke-' + [Guid]::NewGuid().ToString('N'))
$ServerProcess = $null
$ServerStdout = $null
$ServerStderr = $null
$TestWebSocket = $null
$Passed = 0
$Completed = $false

function Pass([string]$Name) {
    $script:Passed++ | Out-Null
    Write-Host "[PASS] $Name" -ForegroundColor Green
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "断言失败: $Message"
    }
}

function Assert-Status($Response, [int]$Expected, [string]$Name) {
    Assert-True ($Response.Status -eq $Expected) "${Name}: expected HTTP $Expected, got $($Response.Status), body=$($Response.Body)"
    Pass "$Name (HTTP $Expected)"
}

function Convert-JsonBody([string]$Body) {
    Assert-True (-not [string]::IsNullOrWhiteSpace($Body)) '响应 body 不能为空'
    return $Body | ConvertFrom-Json
}

function Invoke-Api {
    param(
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body,
        [string]$ContentType = 'application/json'
    )

    $request = @{
        Method = $Method
        Uri = $Url
        Headers = $Headers
        TimeoutSec = 45
        UseBasicParsing = $true
    }
    if ($null -ne $Body) {
        $request.Body = $Body
        $request.ContentType = $ContentType
    }

    try {
        $response = Invoke-WebRequest @request
        return [pscustomobject]@{
            Status = [int]$response.StatusCode
            Body = [string]$response.Content
            Headers = $response.Headers
        }
    } catch {
        $exception = $_.Exception
        $httpResponse = $null
        if ($exception.PSObject.Properties.Name -contains 'Response') {
            $httpResponse = $exception.Response
        }
        if ($null -eq $httpResponse) {
            throw
        }
        if ($httpResponse -is [System.Net.Http.HttpResponseMessage]) {
            try {
                $errorBody = $httpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            } catch {
                $errorBody = ''
            }
            $status = [int]$httpResponse.StatusCode
            $responseHeaders = @{}
            foreach ($header in $httpResponse.Headers) {
                $responseHeaders[$header.Key] = ($header.Value -join ',')
            }
        } else {
            $reader = [IO.StreamReader]::new($httpResponse.GetResponseStream())
            try {
                $errorBody = $reader.ReadToEnd()
            } finally {
                $reader.Dispose()
            }
            $status = [int]$httpResponse.StatusCode
            $responseHeaders = $httpResponse.Headers
        }
        return [pscustomobject]@{
            Status = $status
            Body = $errorBody
            Headers = $responseHeaders
        }
    }
}

function Open-TestWebSocket([string]$Url) {
    $socket = [Net.WebSockets.ClientWebSocket]::new()
    $socket.ConnectAsync(
        [Uri]$Url,
        [Threading.CancellationToken]::None
    ).GetAwaiter().GetResult() | Out-Null
    return $socket
}

function Receive-TestWebSocketText([Net.WebSockets.ClientWebSocket]$Socket) {
    $buffer = [byte[]]::new(4096)
    $stream = [IO.MemoryStream]::new()
    try {
        do {
            $result = $Socket.ReceiveAsync(
                [ArraySegment[byte]]::new($buffer),
                [Threading.CancellationToken]::None
            ).GetAwaiter().GetResult()
            if ($result.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) {
                throw '测试 WebSocket 被服务端关闭'
            }
            $stream.Write($buffer, 0, $result.Count)
        } while (-not $result.EndOfMessage)
        return [Text.Encoding]::UTF8.GetString($stream.ToArray())
    } finally {
        $stream.Dispose()
    }
}

function Send-TestWebSocketJson(
    [Net.WebSockets.ClientWebSocket]$Socket,
    [hashtable]$Payload
) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($Payload | ConvertTo-Json -Compress -Depth 10))
    $Socket.SendAsync(
        [ArraySegment[byte]]::new($bytes),
        [Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        [Threading.CancellationToken]::None
    ).GetAwaiter().GetResult() | Out-Null
}

function Start-AsyncPluginInvoke(
    [string]$PluginId,
    [string]$Function,
    [hashtable]$Headers
) {
    $client = [Net.Http.HttpClient]::new()
    $request = [Net.Http.HttpRequestMessage]::new(
        [Net.Http.HttpMethod]::Post,
        "$BaseUrl/api/v1/plugins/$([Uri]::EscapeDataString($PluginId))/invoke"
    )
    foreach ($header in $Headers.GetEnumerator()) {
        if ($header.Key -eq 'Authorization') {
            $request.Headers.TryAddWithoutValidation($header.Key, $header.Value) | Out-Null
        } else {
            $request.Headers.TryAddWithoutValidation($header.Key, $header.Value) | Out-Null
        }
    }
    $body = @{ function = $Function; args = @() } | ConvertTo-Json -Compress -Depth 5
    $request.Content = [Net.Http.StringContent]::new(
        $body,
        [Text.Encoding]::UTF8,
        'application/json'
    )
    return [pscustomobject]@{
        Client = $client
        Request = $request
        Task = $client.SendAsync($request)
    }
}

function Invoke-PluginThroughTestWebSocket(
    [string]$PluginId,
    [string]$Function,
    [hashtable]$Headers,
    [string]$ExpectedBridgeMethod,
    [string]$BridgeResult
) {
    $pending = Start-AsyncPluginInvoke -PluginId $PluginId -Function $Function -Headers $Headers
    try {
        $bridgeRequest = Convert-JsonBody (Receive-TestWebSocketText $TestWebSocket)
        Assert-True ($bridgeRequest.type -eq 'bridge.request') 'WebSocket 应收到 bridge.request'
        Assert-True ($bridgeRequest.method -eq $ExpectedBridgeMethod) "WebSocket bridge method 应为 $ExpectedBridgeMethod"
        Assert-True (@($bridgeRequest.args).Count -ge 1) 'WebSocket bridge args 应包含 runtime'
        Send-TestWebSocketJson -Socket $TestWebSocket -Payload @{
            type = 'bridge.response'
            requestId = [string]$bridgeRequest.requestId
            ok = $true
            result = $BridgeResult
        }
        $httpResponse = $pending.Task.GetAwaiter().GetResult()
        $body = $httpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $response = [pscustomobject]@{
            Status = [int]$httpResponse.StatusCode
            Body = $body
            Headers = @{}
        }
        Assert-Status $response 200 "WebSocket bridge 后的插件调用 $Function"
        return Convert-JsonBody $body
    } finally {
        $pending.Request.Dispose()
        $pending.Client.Dispose()
    }
}

function New-Session([string]$Username, [string]$Password) {
    $body = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
    $response = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/auth/register" -Body $body
    Assert-Status $response 200 '注册用户'
    return Convert-JsonBody $response.Body
}

function Login([string]$Username, [string]$Password) {
    $body = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
    $response = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/auth/login" -Body $body
    Assert-Status $response 200 '登录用户'
    return Convert-JsonBody $response.Body
}

function Read-BrotliFile([string]$Path) {
    $inputStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes($Path))
    $decoder = [IO.Compression.BrotliStream]::new(
        $inputStream,
        [IO.Compression.CompressionMode]::Decompress
    )
    $outputStream = [IO.MemoryStream]::new()
    try {
        $decoder.CopyTo($outputStream)
        return [Text.Encoding]::UTF8.GetString($outputStream.ToArray())
    } finally {
        $decoder.Dispose()
        $inputStream.Dispose()
        $outputStream.Dispose()
    }
}

function Download-RealPluginBundle($Manifest) {
    $npmName = [string]$Manifest.npmName
    $version = [string]$Manifest.version
    Assert-True (-not [string]::IsNullOrWhiteSpace($npmName)) '云端插件 manifest.npmName 不能为空'
    Assert-True (-not [string]::IsNullOrWhiteSpace($version)) '云端插件 manifest.version 不能为空'

    foreach ($extension in @('.cjs.br', '.cjs')) {
        $assetPath = "npm/$npmName@$version/dist/$npmName.bundle$extension"
        foreach ($mirror in $CdnMirrors) {
            $url = "$mirror$assetPath"
            $downloadPath = Join-Path $TempRoot ('plugin-' + [Guid]::NewGuid().ToString('N') + $extension)
            try {
                Invoke-WebRequest `
                    -Uri $url `
                    -Headers @{ Accept = '*/*' } `
                    -TimeoutSec 45 `
                    -UseBasicParsing `
                    -OutFile $downloadPath | Out-Null

                $bundle = if ($extension -eq '.cjs.br') {
                    Read-BrotliFile $downloadPath
                } else {
                    [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($downloadPath))
                }
                if (-not [string]::IsNullOrWhiteSpace($bundle) -and $bundle.Contains('getInfo')) {
                    $size = [IO.File]::ReadAllBytes($downloadPath).Length
                    Write-Host "[INFO] 真实插件下载成功: $url ($size bytes compressed/raw)" -ForegroundColor Cyan
                    return [pscustomobject]@{
                        Bundle = $bundle
                        Url = $url
                        Version = $version
                        NpmName = $npmName
                        Uuid = [string]$Manifest.uuid
                        Name = [string]$Manifest.name
                    }
                }
            } catch {
                Write-Host "[INFO] 下载通道失败，继续尝试: $url ($($_.Exception.Message))" -ForegroundColor DarkGray
            } finally {
                if (Test-Path -LiteralPath $downloadPath) {
                    Remove-Item -LiteralPath $downloadPath -Force
                }
            }
        }
    }

    throw "按照 Flutter 本体的 CDN 顺序无法下载插件: $npmName@$version"
}

function Start-TestServer {
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    Assert-True (Test-Path -LiteralPath $ServerBinary) "找不到服务端二进制，请先 cargo build --manifest-path cs_server/Cargo.toml"
    Assert-True (Test-Path -LiteralPath $WebRoot) '找不到 cs_web/dist，请先 pnpm --dir cs_web build'

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $ServerBinary
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.EnvironmentVariables['BREEZE_SERVER_HOST'] = '127.0.0.1'
    $startInfo.EnvironmentVariables['BREEZE_SERVER_PORT'] = [string]$Port
    $startInfo.EnvironmentVariables['BREEZE_DATA_DIR'] = (Join-Path $TempRoot 'data')
    $startInfo.EnvironmentVariables['BREEZE_PLUGIN_ROOT'] = (Join-Path $TempRoot 'plugins')
    $startInfo.EnvironmentVariables['BREEZE_WEB_ROOT'] = $WebRoot
    $startInfo.EnvironmentVariables['BREEZE_ADMIN_TOKEN'] = $AdminToken
    $startInfo.EnvironmentVariables['BREEZE_SERVER_DOWNLOAD'] = 'true'
    $startInfo.EnvironmentVariables['BREEZE_ALLOW_REGISTRATION'] = 'true'
    $startInfo.EnvironmentVariables['RUST_LOG'] = 'breeze_cs_server=warn'

    $script:ServerProcess = [Diagnostics.Process]::Start($startInfo)
    $script:ServerStdout = $ServerProcess.StandardOutput.ReadToEndAsync()
    $script:ServerStderr = $ServerProcess.StandardError.ReadToEndAsync()
}

function Wait-ForServer {
    $health = $null
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        if ($ServerProcess.HasExited) {
            throw "服务端提前退出: $($ServerStderr.Result)"
        }
        try {
            $health = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/health"
            if ($health.Status -eq 200) {
                break
            }
        } catch {
            # 服务端启动阶段端口尚未监听。
        }
        Start-Sleep -Milliseconds 100
    }
    Assert-True ($null -ne $health -and $health.Status -eq 200) '服务端在 10 秒内没有连通'
    Pass '服务端 TCP/API 连通'
    return Convert-JsonBody $health.Body
}

function Stop-TestServer {
    if ($null -ne $ServerProcess -and -not $ServerProcess.HasExited) {
        try {
            $ServerProcess.Kill($true)
            $ServerProcess.WaitForExit(5000) | Out-Null
        } catch {
            Write-Host "[WARN] 停止测试服务端失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

try {
    $BaseUrl = "http://127.0.0.1:$Port"
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

    $occupied = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    Assert-True ($null -eq $occupied) "测试端口 $Port 已被占用"
    $preflightFailed = $false
    try {
        Invoke-WebRequest -Uri "$BaseUrl/api/v1/health" -TimeoutSec 1 -UseBasicParsing | Out-Null
    } catch {
        $preflightFailed = $true
    }
    Assert-True $preflightFailed "测试端口 $Port 在服务端启动前已经可以访问"
    Pass '服务端启动前的不可达连接失败路径'

    $catalogResponse = Invoke-Api -Method GET -Url $CloudPluginListUrl -Headers @{ Accept = 'application/json, text/plain, */*' }
    Assert-Status $catalogResponse 200 '真实云端插件列表连通'
    $catalog = @(Convert-JsonBody $catalogResponse.Body)
    Assert-True ($catalog.Count -ge 1) '真实云端插件列表至少应有一个插件'
    Pass "读取真实云端插件目录 ($($catalog.Count) 个插件)"

    $cloudItem = $catalog | Where-Object {
        $null -ne $_.manifest -and
        -not [string]::IsNullOrWhiteSpace([string]$_.manifest.npmName) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.manifest.version) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.manifest.uuid)
    } | Select-Object -First 1
    Assert-True ($null -ne $cloudItem) '云端插件目录中没有可下载的 manifest'
    $realPlugin = Download-RealPluginBundle $cloudItem.manifest
    Assert-True ($realPlugin.Bundle.Length -gt 10KB) '真实插件 bundle 太小，疑似下载到了错误页面'
    Pass "沿用 Flutter CDN 顺序下载真实插件 $($realPlugin.Name)"

    Start-TestServer
    $health = Wait-ForServer
    Assert-True ($health.status -eq 'ok') 'health.status 应为 ok'
    Assert-True ($health.server_download -eq $true) '测试服务端应声明开启服务端下载'
    Pass 'health 内容正确'

    $capabilitiesResponse = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/capabilities"
    Assert-Status $capabilitiesResponse 200 '读取服务端能力'
    $capabilities = Convert-JsonBody $capabilitiesResponse.Body
    Assert-True ($capabilities.protocol_version -eq 'v1') '协议版本应为 v1'
    Assert-True ($capabilities.plugin_runtime.quickjs -eq $true) 'QuickJS 能力应开启'
    Assert-True ($capabilities.plugin_runtime.filesystem -eq $false) '插件文件系统能力应关闭'
    Assert-True ($capabilities.http.shared_reqwest_client -eq $true) '共享 reqwest 能力应开启'
    Pass 'capabilities 内容正确'

    $webResponse = Invoke-Api -Method GET -Url "$BaseUrl/"
    Assert-Status $webResponse 200 '服务端直接提供 Web HTML'
    Assert-True ($webResponse.Body.Contains('<div id="root">')) 'Web HTML 应包含 React root'
    Pass '服务端静态 HTML/前端回退连通'

    $unauthorized = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/auth/me"
    Assert-Status $unauthorized 401 '无 Bearer token 被拒绝'
    $wrongAdmin = Invoke-Api -Method PUT -Url "$BaseUrl/api/v1/admin/plugins/cs-smoke" -Body (@{ version = '1.0.0'; bundle = 'module.exports={}' } | ConvertTo-Json -Compress)
    Assert-Status $wrongAdmin 401 '无管理令牌不能安装插件'

    $suffix = [Guid]::NewGuid().ToString('N').Substring(0, 12)
    $userAName = "cs_a_$suffix"
    $userBName = "cs_b_$suffix"
    $password = 'BreezeTest123!'
    $sessionA = New-Session $userAName $password
    $tokenA = [string]$sessionA.access_token
    Assert-True (-not [string]::IsNullOrWhiteSpace($tokenA)) '用户 A token 不能为空'
    $duplicateRegister = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/auth/register" -Body (@{ username = $userAName; password = $password } | ConvertTo-Json -Compress)
    Assert-Status $duplicateRegister 409 '重复注册被拒绝'
    $wrongPassword = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/auth/login" -Body (@{ username = $userAName; password = 'WrongPassword123!' } | ConvertTo-Json -Compress)
    Assert-Status $wrongPassword 401 '错误密码被拒绝'
    $meA = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/auth/me" -Headers @{ Authorization = "Bearer $tokenA" }
    Assert-Status $meA 200 '用户 A 会话有效'
    Assert-True ((Convert-JsonBody $meA.Body).username -eq $userAName) 'me 应返回用户 A'
    Pass '用户 A 身份信息正确'

    $sessionB = New-Session $userBName $password
    $tokenB = [string]$sessionB.access_token
    $authA = @{ Authorization = "Bearer $tokenA" }
    $authB = @{ Authorization = "Bearer $tokenB" }

    $installBody = @{
        version = '1.0.0'
        bundle = @'
module.exports = {
  getInfo: async () => ({ uuid: "cs-smoke", name: "CS Smoke", version: "1.0.0", icon: "", description: "test" }),
  echo: async (value) => ({ value }),
  getLocaleInfo: async () => await bridge.call("dart.getLocaleInfo"),
  getAppVersion: async () => await bridge.call("dart.getAppVersion"),
  showToast: async () => { await bridge.call("flutter.showToast", { message: "CS bridge toast", level: "info" }); return { ok: true }; },
  configRoundTrip: async () => { await bridge.call("save_plugin_config", "bridge-key", "bridge-value"); return JSON.parse(await bridge.call("load_plugin_config", "bridge-key", "fallback")); },
  searchComic: async (request) => ({ data: { comics: [{ id: "comic-1", title: request.keyword || "smoke" }] } }),
  getComicDetail: async (request) => ({ data: { comic: { id: request.comicId, title: "Smoke Comic", chapters: [{ id: "chapter-1", title: "Chapter 1" }] } } }),
  getChapter: async (request) => ({ data: { chapter: { id: request.chapterId, pages: [{ url: "https://example.invalid/smoke", name: "1" }] } } }),
  getReadSnapshot: async (request) => ({ data: { chapter: { pages: [{ url: "https://example.invalid/smoke", name: "1" }] } } }),
  fetchImageBytes: async () => new Uint8Array([66, 114, 101, 101, 122, 101, 45, 67, 83])
};
'@
        enabled = $true
    } | ConvertTo-Json -Compress -Depth 4
    $installSmoke = Invoke-Api -Method PUT -Url "$BaseUrl/api/v1/admin/plugins/cs-smoke" -Headers @{ 'X-Breeze-Admin-Token' = $AdminToken } -Body $installBody
    Assert-Status $installSmoke 200 '安装确定性下载测试插件'

    $webSocketBaseUrl = $BaseUrl -replace '^http://', 'ws://' -replace '^https://', 'wss://'
    $TestWebSocket = Open-TestWebSocket "$webSocketBaseUrl/api/v1/ws?access_token=$([Uri]::EscapeDataString($tokenA))"
    Pass '用户 A WebSocket bridge 连通'
    $localeBridgeResult = Invoke-PluginThroughTestWebSocket `
        -PluginId 'cs-smoke' `
        -Function 'getLocaleInfo' `
        -Headers $authA `
        -ExpectedBridgeMethod 'dart.getLocaleInfo' `
        -BridgeResult '{"language":"zh","locale":"zh-CN","timezoneName":"Asia/Shanghai"}'
    Assert-True ([string]$localeBridgeResult -like '*language*') '插件应收到 WebSocket 返回的本地化信息'
    Pass 'dart.getLocaleInfo 通过 WebSocket 往返'
    $versionBridgeResult = Invoke-PluginThroughTestWebSocket `
        -PluginId 'cs-smoke' `
        -Function 'getAppVersion' `
        -Headers $authA `
        -ExpectedBridgeMethod 'dart.getAppVersion' `
        -BridgeResult '"test-app-version"'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$versionBridgeResult)) '插件应收到 WebSocket 返回的应用版本'
    Pass 'dart.getAppVersion 通过 WebSocket 往返'
    $toastBridgeResult = Invoke-PluginThroughTestWebSocket `
        -PluginId 'cs-smoke' `
        -Function 'showToast' `
        -Headers $authA `
        -ExpectedBridgeMethod 'flutter.showToast' `
        -BridgeResult ''
    Assert-True (([string]($toastBridgeResult | ConvertTo-Json -Compress -Depth 5)).Contains('ok')) '插件通知调用应返回成功'
    Pass 'flutter.showToast 通过 WebSocket 往返'

    $configBridge = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/invoke" -Headers $authA -Body (@{ function = 'configRoundTrip'; args = @() } | ConvertTo-Json -Compress)
    Assert-Status $configBridge 200 '插件配置 bridge 调用'
    Assert-True ((Convert-JsonBody $configBridge.Body).value -eq 'bridge-value') '插件配置 bridge 应支持保存后读取'
    Pass 'load_plugin_config/save_plugin_config 由服务端 SQLite 处理'

    $realInstallBody = @{ version = $realPlugin.Version; bundle = $realPlugin.Bundle; enabled = $true } | ConvertTo-Json -Compress -Depth 4
    $installReal = Invoke-Api -Method PUT -Url "$BaseUrl/api/v1/admin/plugins/$($realPlugin.Uuid)" -Headers @{ 'X-Breeze-Admin-Token' = $AdminToken } -Body $realInstallBody
    Assert-Status $installReal 200 "安装真实插件 $($realPlugin.Name)"
    $pluginsResponse = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/plugins"
    Assert-Status $pluginsResponse 200 '读取已安装插件列表'
    $plugins = Convert-JsonBody $pluginsResponse.Body
    Assert-True ((@($plugins.items) | Where-Object plugin_id -eq 'cs-smoke').Count -eq 1) '已安装列表应包含 cs-smoke'
    Assert-True ((@($plugins.items) | Where-Object plugin_id -eq $realPlugin.Uuid).Count -eq 1) '已安装列表应包含真实插件'
    Pass 'SQLite 插件目录持久化正确'

    $smokeDetail = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/plugins/cs-smoke"
    Assert-Status $smokeDetail 200 '读取插件详情'
    Assert-True ((Convert-JsonBody $smokeDetail.Body).bundle_hash.Length -eq 64) '插件 bundle hash 应为 SHA-256'
    Pass '插件详情和 hash 正确'

    $invalidInvoke = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/invoke" -Headers $authA -Body (@{ function = ''; args = @{} } | ConvertTo-Json -Compress)
    Assert-Status $invalidInvoke 400 '插件调用参数校验'
    $echo = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/invoke" -Headers $authA -Body (@{ function = 'echo'; args = @('hello') } | ConvertTo-Json -Compress)
    Assert-Status $echo 200 'QuickJS JSON 插件调用'
    Assert-True ((Convert-JsonBody $echo.Body).value -eq 'hello') 'echo 应返回 hello'
    Pass 'QuickJS 用户运行时调用正确'

    $realInfo = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/$($realPlugin.Uuid)/invoke" -Headers $authA -Body (@{ function = 'getInfo'; args = @() } | ConvertTo-Json -Compress)
    Assert-Status $realInfo 200 '真实插件 getInfo 调用'
    $realInfoJson = Convert-JsonBody $realInfo.Body
    Assert-True (([string]$realInfoJson.uuid) -eq $realPlugin.Uuid) '真实插件 getInfo uuid 应匹配云端 manifest'
    Pass '真实插件已在服务端 QuickJS 中加载并执行'

    $realSearch = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/$($realPlugin.Uuid)/search" -Headers $authA -Body (@{ core = @{ keyword = '海'; page = 1 }; extern = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $realSearch 200 '真实插件搜索调用'
    Assert-True (-not [string]::IsNullOrWhiteSpace($realSearch.Body)) '真实插件搜索响应不能为空'
    Pass '真实插件搜索基本功能连通'

    $semanticSearch = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/search" -Headers $authA -Body (@{ core = @{ keyword = 'smoke'; page = 1 }; extern = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $semanticSearch 200 '语义搜索路由'
    $detail = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/comic/comic-1/detail" -Headers $authA -Body (@{ core = @{}; extern = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $detail 200 '漫画详情路由'
    $chapter = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/comic/comic-1/chapter/chapter-1" -Headers $authA -Body (@{ core = @{}; extern = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $chapter 200 '章节详情路由'
    $read = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/comic/comic-1/read" -Headers $authA -Body (@{ core = @{ chapterId = 'chapter-1' }; extern = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $read 200 '阅读快照路由'
    $bytes = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/plugins/cs-smoke/invoke-bytes" -Headers $authA -Body (@{ function = 'fetchImageBytes'; args = @(@{ url = 'https://example.invalid/smoke' }) } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $bytes 200 '插件二进制调用路由'
    Pass '搜索/详情/章节/阅读/二进制接口均可用'

    $configBefore = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/plugins/cs-smoke/config" -Headers $authA
    Assert-Status $configBefore 200 '读取用户 A 插件配置'
    $configRevision = (Convert-JsonBody $configBefore.Body).revision
    $configUpdate = Invoke-Api -Method PATCH -Url "$BaseUrl/api/v1/plugins/cs-smoke/config" -Headers $authA -Body (@{ config = @{ endpoint = 'a'; enabled = $true }; expected_revision = $configRevision } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $configUpdate 200 '更新用户 A 插件配置'
    $configConflict = Invoke-Api -Method PATCH -Url "$BaseUrl/api/v1/plugins/cs-smoke/config" -Headers $authA -Body (@{ config = @{ endpoint = 'stale' }; expected_revision = $configRevision } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $configConflict 409 '插件配置 revision 冲突'
    $configB = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/plugins/cs-smoke/config" -Headers $authB
    Assert-Status $configB 200 '读取用户 B 插件配置'
    Assert-True ((Convert-JsonBody $configB.Body).revision -eq 0) '用户 B 插件配置不能看到用户 A 的 revision'
    Pass '插件配置按用户隔离且有乐观锁'

    $settingsBefore = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/settings/account" -Headers $authA
    Assert-Status $settingsBefore 200 '读取账号设置'
    $settingsRevision = (Convert-JsonBody $settingsBefore.Body).revision
    $settingsUpdate = Invoke-Api -Method PATCH -Url "$BaseUrl/api/v1/settings/account" -Headers $authA -Body (@{ settings = @{ csMode = $true; server = $BaseUrl }; expected_revision = $settingsRevision } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $settingsUpdate 200 '更新账号设置'
    $settingsConflict = Invoke-Api -Method PATCH -Url "$BaseUrl/api/v1/settings/account" -Headers $authA -Body (@{ settings = @{ stale = $true }; expected_revision = $settingsRevision } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $settingsConflict 409 '账号设置 revision 冲突'
    Pass '账号设置持久化和冲突检测正确'

    foreach ($kind in @('favorites', 'history', 'follows')) {
        $libraryBody = @{ unique_key = "cs-smoke-$kind"; source = 'cs-smoke'; comic_id = 'comic-1'; payload = @{ kind = $kind; title = 'Smoke Comic' } } | ConvertTo-Json -Compress -Depth 5
        $upsert = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/library/$kind" -Headers $authA -Body $libraryBody
        Assert-Status $upsert 200 "写入 $kind"
        $listA = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/library/$kind" -Headers $authA
        Assert-Status $listA 200 "读取用户 A $kind"
        Assert-True ((@((Convert-JsonBody $listA.Body).items) | Where-Object unique_key -eq "cs-smoke-$kind").Count -eq 1) "用户 A $kind 应包含测试记录"
        $listB = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/library/$kind" -Headers $authB
        Assert-Status $listB 200 "读取用户 B $kind"
        Assert-True ((@((Convert-JsonBody $listB.Body).items)).Count -eq 0) "用户 B $kind 不应看到用户 A 数据"
        $remove = Invoke-Api -Method DELETE -Url "$BaseUrl/api/v1/library/$kind/cs-smoke-$kind" -Headers $authA
        Assert-Status $remove 200 "删除 $kind"
    }
    Pass '收藏/历史/关注三类 SQLite 业务数据均按用户隔离'

    $downloadInvalid = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/downloads/tasks" -Headers $authA -Body (@{ plugin_id = 'cs-smoke'; comic_id = 'comic-1'; chapter_ids = @(); options = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $downloadInvalid 400 '下载任务参数校验'
    $downloadCreate = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/downloads/tasks" -Headers $authA -Body (@{ plugin_id = 'cs-smoke'; comic_id = 'comic-1'; chapter_ids = @('chapter-1'); options = @{} } | ConvertTo-Json -Compress -Depth 5)
    Assert-Status $downloadCreate 200 '创建服务端下载任务'
    $taskId = [string](Convert-JsonBody $downloadCreate.Body).task_id
    Assert-True (-not [string]::IsNullOrWhiteSpace($taskId)) '下载任务 ID 不能为空'

    $task = $null
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        $taskResponse = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/downloads/tasks/$taskId" -Headers $authA
        Assert-Status $taskResponse 200 '查询服务端下载任务'
        $task = Convert-JsonBody $taskResponse.Body
        if ($task.status -in @('completed', 'failed', 'cancelled')) { break }
        Start-Sleep -Milliseconds 150
    }
    Assert-True ($task.status -eq 'completed') "服务端下载任务应完成，实际状态=$($task.status)，error=$($task.error)"
    Pass '服务端下载 worker 完成任务'

    $manifestResponse = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/downloads/comics/cs-smoke:comic-1/manifest" -Headers $authA
    Assert-Status $manifestResponse 200 '读取服务端下载 manifest'
    $manifest = Convert-JsonBody $manifestResponse.Body
    $assetId = [string]$manifest.manifest.pages[0].asset_id
    Assert-True (-not [string]::IsNullOrWhiteSpace($assetId)) 'manifest 应包含 asset_id'
    $assetPath = Join-Path $TempRoot 'downloaded-asset.bin'
    $assetWebResponse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/downloads/assets/$assetId" -Headers $authA -TimeoutSec 15 -UseBasicParsing
    [IO.File]::WriteAllBytes($assetPath, $assetWebResponse.RawContentStream.ToArray())
    Assert-Status ([pscustomobject]@{ Status = [int]$assetWebResponse.StatusCode; Body = '' }) 200 '读取服务端图片资源'
    $assetBytes = [IO.File]::ReadAllBytes($assetPath)
    Assert-True (($assetBytes -join ',') -eq '66,114,101,101,122,101,45,67,83') '图片资源内容应来自插件 fetchImageBytes'
    Assert-True ([int]([string]$assetWebResponse.Headers['content-length']) -eq $assetBytes.Length) '图片资源 content-length 应正确'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$assetWebResponse.Headers['etag'])) '图片资源应返回 ETag'
    Pass '服务端图片资源、长度和 ETag 正确'

    $assetOtherUser = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/downloads/assets/$assetId" -Headers $authB
    Assert-Status $assetOtherUser 404 '其他用户不能读取下载资源'
    $finishedCancel = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/downloads/tasks/$taskId/cancel" -Headers $authA
    Assert-Status $finishedCancel 200 '已完成任务取消请求幂等'
    Assert-True ((Convert-JsonBody $finishedCancel.Body).status -eq 'completed') '已完成任务取消后状态不应改变'
    Pass '下载任务取消边界正确'

    $tasksB = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/downloads/tasks" -Headers $authB
    Assert-Status $tasksB 200 '读取用户 B 下载任务列表'
    Assert-True (@((Convert-JsonBody $tasksB.Body).items).Count -eq 0) '用户 B 不应看到用户 A 下载任务'
    Pass '下载任务按用户隔离'

    $logout = Invoke-Api -Method POST -Url "$BaseUrl/api/v1/auth/logout" -Headers $authA
    Assert-Status $logout 200 '注销用户 A'
    $afterLogout = Invoke-Api -Method GET -Url "$BaseUrl/api/v1/auth/me" -Headers $authA
    Assert-Status $afterLogout 401 '注销后旧 token 失效'

    $Completed = $true
    Write-Host "`nCS server smoke test 完成：$Passed 项断言全部通过。" -ForegroundColor Green
} finally {
    if ($null -ne $TestWebSocket) {
        try {
            $TestWebSocket.Abort()
            $TestWebSocket.Dispose()
        } catch {
            Write-Host "[WARN] 停止测试 WebSocket 失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Stop-TestServer
    if (-not $Completed -and $null -ne $ServerStderr) {
        try {
            if ($null -ne $ServerStdout) {
                Write-Host "`n[SERVER STDOUT]" -ForegroundColor Yellow
                Write-Host $ServerStdout.Result -ForegroundColor Yellow
            }
            Write-Host "`n[SERVER STDERR]" -ForegroundColor Yellow
            Write-Host $ServerStderr.Result -ForegroundColor Yellow
        } catch {
            Write-Host "[WARN] 无法读取服务端 stderr: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
