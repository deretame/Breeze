"""项目测试驱动脚本：一个入口跑全部测试，支持分组与筛选。

用法:
    python scripts/test.py                    # 跑全部测试
    python scripts/test.py --group core fetch # 只跑指定分组（可多个）
    python scripts/test.py --filter 'Stream.*'  # 直接按 gtest filter 跑（与 --group 互斥）
    python scripts/test.py --list             # 列出分组与其包含的测试套件
    python scripts/test.py --with-3proxy      # 由脚本拉起 3proxy 并跑对打测试
    python scripts/test.py --doh-e2e          # 放开 DoH 真实外网 E2E 用例

说明:
- 直接调用 build/quickjs_runtime_tests.exe（单一 gtest 可执行文件），
  分组靠 --gtest_filter 按套件名匹配，不依赖 ctest。
- 新增测试文件时：加入 CMakeLists.txt 的 quickjs_runtime_tests 源列表，
  并在下方 GROUPS 里把新套件名归入对应分组（套件名 = TEST() 的第一个参数）。
- 外部服务（目前只有 3proxy）由本脚本统一拉起/回收，C++ 测试只消费
  环境变量标记（QJS_3PROXY_UP=1），不做进程管理，便于跨平台扩展。
  不加 --with-3proxy 时 Proxy3proxyTest 自动 GTEST_SKIP。
"""
from __future__ import annotations

import argparse
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "quickjs-runtime"
TEST_EXE = ROOT / "build" / "quickjs_runtime_tests.exe"
WPT_ROOT = ROOT / "third_party" / "wpt"
WPT_TESTS_TXT = ROOT / "build" / "wpt_tests.txt"  # analyze_wpt.py 生成的精选清单
THREE_PROXY_CFG = ROOT / "tests" / "proxy" / "3proxy.cfg"
# 3proxy 监听端口（与 tests/proxy/3proxy.cfg 一致；改动 cfg 时同步）
THREE_PROXY_PORTS = (11080, 11081, 13128, 13129)

# 分组 → gtest 套件名（gtest_list_tests 的顶层名字）。
# all = 全部分组的并集；不在任何分组里的套件只属于 all。
GROUPS: dict[str, list[str]] = {
    # 纯 C++ 异步设施与通用组件（不碰网络、不碰 JS 绑定）
    "core": [
        "Quickjs", "Stdexec", "Stream", "Channel", "Sleep",
        "MiniTask", "RunnerFixture", "TaskPoolTest",
        "LogTest", "DynFixture", "DynTest", "DynBlobFixture", "BlobFixture", "BlobTest",
        "HostRuntimeTest", "OpenccTest", "GzipTest",
    ],
    # qjsbind 绑定层（m1-m4 + Breeze 风格运行时 API）
    "binding": ["Fixture", "M2Fixture", "M3Fixture", "M4Fixture",
                "RuntimeApiFixture", "RuntimeApiFallbackFixture", "CryptoFixture"],
    # fetch/fetchcore 直连与连接池、DNS/DoH
    "fetch": [
        "FetchFixture", "FetchcoreDirect", "Easy",
        "PoolReuse", "PoolState",
        "DnsResolver", "DohWire", "DohResolver", "DohResolverE2E",
    ],
    # 代理：内嵌 socks5/http 代理对打 + 真实 3proxy 对打 + 代理解析
    "proxy": [
        "Socks5Fixture", "HttpProxyFixture", "Proxy3proxyTest",
        "ProxyParse", "ProxyConfigTest", "UrlTools", "WindowsProxyServer",
    ],
    # cheerio（lexbor）HTML 解析
    "cheerio": ["BreezeHtmlBench", "BreezeHtmlFixture"],
    # WPT 精选子集运行器
    "wpt": ["WptRunner"],
}


def build_filter(groups: list[str], extra: str | None) -> str:
    if extra:
        # --filter 直接作为 gtest filter（支持 gtest 自身的 'positive-negative' 语法）
        return extra
    suites: list[str] = []
    for g in groups:
        suites.extend(GROUPS[g])
    return ":".join(f"{s}.*" for s in suites) if suites else "*"


def find_3proxy() -> Path | None:
    """按平台约定在 third_party/3proxy 下找二进制（Windows: 3proxy.exe）。"""
    for name in ("3proxy.exe", "3proxy"):
        p = ROOT / "third_party" / "3proxy" / name
        if p.exists():
            return p
    return None


def wait_port(port: int, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                return True
        except OSError:
            time.sleep(0.05)
    return False


def start_3proxy() -> subprocess.Popen:
    exe = find_3proxy()
    if exe is None:
        raise RuntimeError("找不到 3proxy 二进制（third_party/3proxy/3proxy.exe）")
    # cwd=ROOT：cfg 内的 log 相对路径（tests/proxy/...）基于此解析
    proc = subprocess.Popen([str(exe), str(THREE_PROXY_CFG)], cwd=ROOT)
    if not wait_port(THREE_PROXY_PORTS[0], timeout=10):
        proc.kill()
        raise RuntimeError(f"3proxy 未在 10s 内就绪（SOCKS5 {THREE_PROXY_PORTS[0]}）")
    return proc


def stop_3proxy(proc: subprocess.Popen) -> None:
    # 3proxy 日志按 ~1s 周期 flush，强杀会丢最后一批记录
    #（日志是「请求确实经过代理」的人工抽查证据，见 proxy_test_plan.md §3.3.3）
    time.sleep(2)
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        print("警告: 3proxy terminate 后 5s 内未退出，强制 kill", file=sys.stderr)
        proc.kill()


def main() -> int:
    parser = argparse.ArgumentParser(description="运行 quickjs-runtime 测试")
    parser.add_argument("--group", nargs="+", choices=sorted(GROUPS), metavar="NAME",
                        help="只跑指定分组（默认全部）：" + ", ".join(sorted(GROUPS)))
    parser.add_argument("--filter", metavar="PATTERN",
                        help="直接作为 gtest filter（覆盖 --group），支持 gtest 的 "
                             "'positive-negative' 语法，如 'Fetch*.*-*.Slow*'")
    parser.add_argument("--list", action="store_true", help="列出分组与套件，不运行")
    parser.add_argument("--with-3proxy", action="store_true",
                        help="由脚本拉起真实 3proxy 进程，跑 Proxy3proxyTest 对打测试"
                             "（默认跳过）")
    parser.add_argument("--doh-e2e", action="store_true",
                        help="放开 DoH 真实外网 E2E 用例（设置 DOH_E2E=1）")
    args, passthrough = parser.parse_known_args()

    if args.list:
        for name in sorted(GROUPS):
            print(f"{name}:")
            for suite in GROUPS[name]:
                print(f"  {suite}")
        return 0

    if not TEST_EXE.exists():
        print(f"测试二进制不存在: {TEST_EXE}\n请先运行 pixi run build", file=sys.stderr)
        return 1

    if args.group and args.filter:
        parser.error("--group 与 --filter 互斥")

    gtest_filter = build_filter(args.group or [], args.filter)

    # wpt 资产缺失时排除 WptRunner（C++ 侧无存在性检查，缺失会直接挂）
    wants_wpt = (not args.group and not args.filter) or \
                (args.group and "wpt" in args.group)
    if wants_wpt:
        if not any(WPT_ROOT.glob("*")):
            print("警告: third_party/wpt 资产缺失，排除 WptRunner"
                  "（拉取资产: pixi run setup-wpt）", file=sys.stderr)
            gtest_filter += "-WptRunner.*"
        elif not WPT_TESTS_TXT.exists():
            # 清单由 analyze_wpt.py 从 wpt 资产生成，缺失时顺手补生成
            print(">> 生成 wpt 精选清单: python scripts/analyze_wpt.py", flush=True)
            rc = subprocess.run([sys.executable, str(ROOT / "scripts" / "analyze_wpt.py")],
                                cwd=ROOT).returncode
            if rc != 0:
                print("警告: analyze_wpt.py 失败，排除 WptRunner", file=sys.stderr)
                gtest_filter += "-WptRunner.*"

    env = os.environ.copy()
    if args.doh_e2e:
        env["DOH_E2E"] = "1"

    proxy_proc = None
    if args.with_3proxy:
        try:
            proxy_proc = start_3proxy()
        except RuntimeError as e:
            print(f"错误: {e}", file=sys.stderr)
            return 1
        env["QJS_3PROXY_UP"] = "1"

    cmd = [str(TEST_EXE), f"--gtest_filter={gtest_filter}", *passthrough]
    print(f">> {' '.join(cmd)}", flush=True)
    try:
        return subprocess.run(cmd, cwd=ROOT, env=env).returncode
    finally:
        if proxy_proc is not None:
            stop_3proxy(proxy_proc)


if __name__ == "__main__":
    sys.exit(main())
