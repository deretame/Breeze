#!/usr/bin/env python3
"""把 JS_ThrowTypeError(ctx, X); 替换为 JS_Throw(ctx, JS_NewTypeError(ctx, X));
（JS_ThrowTypeError 的语义不明确，改用纯构造函数组合）"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2] / "quickjs-runtime"
FILES = [
    "include/qjsbind/web/encoding.hpp",
    "include/qjsbind/web/fetch.hpp",
    "include/qjsbind/web/headers.hpp",
    "include/qjsbind/web/request_response.hpp",
    "include/qjsbind/web/url.hpp",
]


def find_end(text: str, p: int) -> int:
    """从 p（'(' 位置）找匹配的 ')'，跳过字符串与嵌套"""
    depth = 1
    in_str = False
    while p < len(text):
        c = text[p]
        if in_str:
            if c == "\\":
                p += 2
                continue
            if c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return p
        p += 1
    raise RuntimeError("unbalanced")


def replace_in(text: str) -> str:
    out = []
    i = 0
    while True:
        j = text.find("JS_ThrowTypeError(", i)
        if j < 0:
            out.append(text[i:])
            break
        out.append(text[i:j])
        open_paren = j + len("JS_ThrowTypeError")
        end = find_end(text, open_paren + 1)  # +1：跳过 '(' 本身
        inner = text[open_paren + 1 : end]
        # 第一个顶层逗号分隔 ctx 表达式与格式串参数
        comma = -1
        in_str = False
        depth = 0
        for k, c in enumerate(inner):
            if in_str:
                if c == "\\":
                    continue
                if c == '"':
                    in_str = False
            elif c == '"':
                in_str = True
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif c == "," and depth == 0:
                comma = k
                break
        if comma < 0:
            raise RuntimeError(f"JS_ThrowTypeError 缺少 ctx 参数: {inner[:60]}")
        ctx_expr = inner[:comma].strip()
        args = inner[comma + 1 :].strip()
        out.append(f"JS_Throw({ctx_expr}, JS_NewTypeError({ctx_expr}, {args}))")
        i = end + 1
    return "".join(out)


def main() -> int:
    for rel in FILES:
        p = ROOT / rel
        data = p.read_text(encoding="utf-8-sig")
        new = replace_in(data)
        if new != data:
            p.write_text(new, encoding="utf-8-sig")
            print(f"fixed: {rel}")
        else:
            print(f"no change: {rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
