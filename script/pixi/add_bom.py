#!/usr/bin/env python3
"""给源码文件加 UTF-8 BOM（MSVC 在 GBK 代码页下解析无 BOM UTF-8 中文注释时，
某些汉字的 UTF-8 字节含 0x5C 会被当作行继续符吞掉下一行——加 BOM 根治）。
幂等：已有 BOM 的文件跳过。"""
import pathlib
import sys

FILES = [
    "include/fetch/beast_transport.hpp",
    "include/fetch/body.hpp",
    "include/fetch/client.hpp",
    "include/fetch/error.hpp",
    "include/fetch/middleware.hpp",
    "include/fetch/scheduler.hpp",
    "include/fetch/task.hpp",
    "include/fetch/transport.hpp",
    "include/fetch/types.hpp",
    "include/qjsbind/rt_value.hpp",
    "include/qjsbind/web/abort.hpp",
    "include/qjsbind/web/dom_exception.hpp",
    "include/qjsbind/web/encoding.hpp",
    "include/qjsbind/web/events.hpp",
    "include/qjsbind/web/fetch.hpp",
    "include/qjsbind/web/headers.hpp",
    "include/qjsbind/web/request_response.hpp",
    "include/qjsbind/web/timers.hpp",
    "include/qjsbind/web/url.hpp",
    "include/qjsbind/web/web.hpp",
    "src/fetch/beast_transport.cpp",
    "src/fetch/socks5.cpp",
    "src/fetch/socks5.hpp",
    "tests/fetch_test.cpp",
    "tests/fetchcore_test.cpp",
]

BOM = b"\xef\xbb\xbf"


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[2] / "quickjs-runtime"
    for rel in FILES:
        p = root / rel
        data = p.read_bytes()
        if data.startswith(BOM):
            print(f"skip (has BOM): {rel}")
            continue
        p.write_bytes(BOM + data)
        print(f"BOM added: {rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
