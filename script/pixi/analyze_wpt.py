#!/usr/bin/env python3
"""扫描 third_party/wpt/fetch/api，静态检查依赖，生成精选测试清单 JSON。

清单项：
  file         相对 wpt 根的路径（fetch/api/...）
  mode         html（提取内嵌 script）/ anyjs（.any.js 直接执行）/
               windowjs（.window.js，本运行器按 anyjs 执行）
  meta_scripts [META: script=...] 依赖列表（相对文件目录解析）
  skip         true/false
  reason       skip 原因（空串 = 不 skip）

skip 判定（v1 能力边界，全部静态检查，无网络）：
  1. 文件级：.sub.*（服务端模板）/ .https.*（需 TLS）/ .worker.js / .h2.*
  2. 目录级：crashtests/（浏览器崩溃回归，无意义）
  3. 内容级（源码正则）：
     - 未实现 JS API：Blob / FormData / ReadableStream / Worker / ServiceWorker /
       XMLHttpRequest / WebSocket / EventSource / MessageChannel / BroadcastChannel /
       FileReader / requestAnimationFrame / performance / navigator / document /
       window.open / fetch 的 duplex/cache/credentials/integrity/keepalive/priority/
       referrerPolicy/body 流
     - 未实现服务器端点：stash-put/stash-take（共享状态）、authentication、
       preflight、huge-response、infinite-slow-response、trickle、keepalive、
       sw-intercept（service worker）、cache.py、echo-content.h2、redirect.h2、
       script-with-header、sandboxed-iframe、bad-chunk-encoding、
       dump-authorization-header
  4. 目录级能力外：credentials/（cookie/凭证语义）、cors/（跨域）、policies/
     （CSP/权限策略）
"""
import json
import pathlib
import re
import sys
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[2] / "quickjs-runtime"
WPT = ROOT / "third_party" / "wpt"
API = WPT / "fetch" / "api"
OUT = ROOT / "build" / "wpt_manifest.json"

# ---- 文件级规则 ----
FILE_SKIP = (
    (".sub.", "服务端 .sub 模板"),
    (".https.", "需要 TLS 服务器"),
    (".worker.js", "worker 全局未实现"),
    (".h2.", "HTTP/2 专用"),
)
DIR_SKIP = (
    ("crashtests", "浏览器崩溃回归测试，无运行意义"),
    ("credentials", "credentials/cookie 语义未实现"),
    ("cors", "跨域（CORS）未实现"),
    ("policies", "CSP/权限策略未实现"),
)

# ---- 内容级规则：未实现的 JS API（\b 边界，避免误匹配注释里的词）----
JS_API_SKIP = [
    # v2 M2 起 ReadableStream/getReader 已实现（body getter 返回流）；
    # 未实现的子集（tee/pipeTo/asyncIterator）由 expected 清单兜底
    (r"\bnew\s+Worker\b", "Worker 未实现"),
    (r"\bServiceWorker\b", "ServiceWorker 未实现"),
    (r"\bXMLHttpRequest\b", "XMLHttpRequest 未实现"),
    (r"\bnew\s+WebSocket\b", "WebSocket 未实现"),
    (r"\bEventSource\b", "EventSource 未实现"),
    (r"\bMessageChannel\b", "MessageChannel 未实现"),
    (r"\bBroadcastChannel\b", "BroadcastChannel 未实现"),
    (r"\bFileReader\b", "FileReader 未实现"),
    (r"\brequestAnimationFrame\b", "requestAnimationFrame 未实现"),
    (r"\bperformance\b", "performance API 未实现"),
    (r"\bnavigator\b", "navigator 未实现"),
    (r"\bdocument\.", "DOM document 未实现"),
    (r"\bwindow\.open\b", "window.open 未实现"),
    (r"\bMediaSource\b", "MediaSource 未实现"),
    # RequestInit 未实现字段
    (r"['\"]keepalive['\"]\s*:", "keepalive 未实现"),
    (r"['\"]cache['\"]\s*:", "Request cache 模式未实现"),
    (r"['\"]credentials['\"]\s*:", "credentials 未实现"),
    (r"['\"]priority['\"]\s*:|\bpriority\s*:", "priority 未实现"),
    (r"['\"]duplex['\"]\s*:", "duplex 未实现"),
    (r"['\"]referrerPolicy['\"]\s*:|\breferrerPolicy\s*:", "referrerPolicy 未实现"),
    (r"['\"]referrer['\"]\s*:|\breferrer\s*:", "referrer 未实现"),
    (r"mode\s*:\s*['\"](?:no-cors|cors)['\"]", "CORS/no-cors 模式未实现"),
    # Response.json 静态方法未实现
    (r"Response\s*\.\s*json\s*\(", "Response.json() 未实现"),
]

# ---- 内容级规则：未实现的服务器端点 ----
ENDPOINT_SKIP = [
    (r"stash-(?:put|take)\.py", "stash 共享状态端点未实现"),
    (r"authentication\.py", "认证端点未实现"),
    (r"preflight\.py", "CORS preflight 端点未实现"),
    (r"huge-response\.py", "huge-response 端点未实现"),
    (r"infinite-slow-response\.py", "infinite-slow-response 端点未实现"),
    (r"trickle\.py", "trickle 端点未实现"),
    (r"keepalive", "keepalive 未实现"),
    (r"sw-intercept", "service worker 拦截未实现"),
    (r"cache\.py", "cache 端点未实现"),
    (r"echo-content\.h2\.py", "HTTP/2 echo 端点未实现"),
    (r"redirect\.h2\.py", "HTTP/2 redirect 端点未实现"),
    (r"script-with-header\.py", "script-with-header 端点未实现"),
    (r"sandboxed-iframe", "sandboxed iframe 未实现"),
    (r"bad-chunk-encoding\.py", "bad-chunk-encoding 端点未实现"),
    (r"dump-authorization-header\.py", "认证端点未实现"),
]


def file_mode(path: pathlib.Path) -> str:
    name = path.name
    if name.endswith(".html"):
        return "html"
    if name.endswith(".window.js"):
        return "windowjs"
    return "anyjs"


def extract_meta_scripts(text: str) -> list:
    """提取 META: script=... 依赖（.any.js 的 // 注释与 .html 的 <!-- --> 注释）"""
    out = []
    for m in re.finditer(r"META:\s*script=([^\s]+)", text):
        out.append(m.group(1))
    return out


def check_skip(path: pathlib.Path, text: str) -> tuple[bool, str]:
    rel = path.relative_to(WPT).as_posix()
    parts = [p for p in path.relative_to(API).parts]
    # 1. 文件级
    for suffix, reason in FILE_SKIP:
        if suffix in path.name:
            return True, reason
    # 2. 目录级
    for d, reason in DIR_SKIP:
        if d in parts:
            return True, reason
    # 文件名规则（语义明确的未实现特性）
    if path.name.startswith("request-cache-"):
        return True, "Request cache 语义未实现"
    if path.name.startswith("forbidden-method"):
        return True, "forbidden method 校验未实现"
    if path.name == "header-value-combining.any.js":
        return True, "重复 content-length/控制字符头值超出 beast 严格解析范围"
    if path.name == "headers-record.any.js":
        return True, "Proxy 反射操作顺序/活迭代器语义超出 v1 范围"
    # 3. 内容级：JS API
    for pat, reason in JS_API_SKIP:
        if re.search(pat, text):
            return True, reason
    # 4. 内容级：服务器端点
    for pat, reason in ENDPOINT_SKIP:
        if re.search(pat, text):
            return True, reason
    # 5. meta_scripts 依赖 .sub 模板资源（服务端替换，本运行器不提供）
    for s in extract_meta_scripts(text):
        if ".sub." in s:
            return True, f"meta 依赖 .sub 模板资源: {s}"
    # 6. 引用的 python 端点不在白名单（echo/status/redirect/inspect-headers/method）
    for m in re.finditer(r"([A-Za-z0-9_\-/]+\.py)", text):
        base = pathlib.Path(m.group(1)).name
        if base not in ("echo-content.py", "status.py", "redirect.py",
                        "inspect-headers.py", "method.py"):
            return True, f"未实现的 python 端点: {m.group(1)}"
    return False, ""


def main() -> int:
    if not API.is_dir():
        print(f"错误: 未找到 {API}\n请先 sparse clone: "
              f"git clone --depth 1 --filter=blob:none --sparse https://github.com/web-platform-tests/wpt.git "
              f"third_party/wpt && cd third_party/wpt && "
              f"git sparse-checkout set --no-cone '/fetch/api' '/resources/testharness.js' "
              f"'/resources/testharnessreport.js' '/resources/testharness.css' '/common'",
              file=sys.stderr)
        return 1

    tests = []
    skipped = 0
    for path in sorted(API.rglob("*")):
        if not path.is_file() or path.suffix not in (".js", ".html"):
            continue
        # 只收测试入口：.any.js / .window.js / .html；helper 文件（resources/ 下）不收
        if "resources" in path.parts:
            continue
        if not (path.name.endswith(".any.js") or path.name.endswith(".window.js")
                or path.name.endswith(".html")):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        skip, reason = check_skip(path, text)
        tests.append({
            "file": path.relative_to(WPT).as_posix(),
            "mode": file_mode(path),
            "meta_scripts": extract_meta_scripts(text),
            "skip": skip,
            "reason": reason,
        })
        if skip:
            skipped += 1

    OUT.parent.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "wpt_root": str(WPT),
        "total": len(tests),
        "skipped": skipped,
        "tests": tests,
    }
    OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    # TSV 简化清单（wpt_runner 直接读）：file<TAB>mode<TAB>meta(逗号分隔)
    # newline="\n"：禁止 Windows 把 \n 转成 \r\n（runner 的 getline 会残留 \r）
    tsv = OUT.with_name("wpt_tests.txt")
    with tsv.open("w", encoding="utf-8", newline="\n") as f:
        for t in tests:
            if t["skip"]:
                continue
            f.write(f"{t['file']}\t{t['mode']}\t{','.join(t['meta_scripts'])}\n")
    print(f"manifest: {OUT}")
    print(f"tsv: {tsv}")
    print(f"total={len(tests)} skipped={skipped} runnable={len(tests) - skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
