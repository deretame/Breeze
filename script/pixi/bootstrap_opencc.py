#!/usr/bin/env python3
"""下载 OpenCC 官方词典数据（BYVoid/OpenCC），生成嵌入头文件 include/opencc/opencc_data.hpp。

用法:
    python scripts/bootstrap_opencc.py

生成物（不入库，构建产物）：
    include/opencc/opencc_data.hpp —— 正向词典 txt + 反向词典（Rev）的原始文本
    （raw string 常量），供 include/opencc/opencc.hpp 在运行时解析（懒加载）。

数据来源（Apache-2.0，与 OpenCC 项目一致；固定 ver.1.1.9 tag）：
    https://raw.githubusercontent.com/BYVoid/OpenCC ver.1.1.9 data/dictionary/{name}.txt

六种配置的对应关系（官方 ver.1.1.9 data/config/*.json 的组合；+ 表示 group
合并词典，匹配取所有词典中的最长匹配；Rev = 反向词典）：
    s2t.json  = [STPhrases + STCharacters]
    t2s.json  = [TSPhrases + TSCharacters]
    s2tw.json = [STPhrases + STCharacters] → [TWVariants]
    tw2s.json = [TWVariantsRevPhrases + TWVariantsRev] → [TSPhrases + TSCharacters]
    s2hk.json = [STPhrases + STCharacters] → [HKVariants]
    hk2s.json = [HKVariantsRevPhrases + HKVariantsRev] → [TSPhrases + TSCharacters]
    jp2t.json = [JPShinjitaiPhrases + JPShinjitaiCharacters + JPVariantsRev]
    t2jp.json = [JPVariants]

安全性：
    - 下载内容按 SHA-256 白名单（DICT_SHA256）校验（对处理后文本计算），
      主源/备源任何不一致都会拦截；
    - 生成时检查 raw string 分隔符序列（)opencc"），防止数据注入破坏头文件。

与 vcpkg 官方 opencc 库的取舍：官方库运行时按相对路径找配置/词典文件
（OPENCC_SYSTEM_CONFIG_PATH / cwd），在 Windows 嵌入场景定位不可靠；
本方案把数据直接嵌入二进制，运行时无外部文件依赖，C++ API（opencc::convert）
可供任意模块调用。转换语义与官方一致：链式 MaxMatch（每步一个词典，词组因
最长匹配自然优先；多候选取第一个）。
"""
from __future__ import annotations

import argparse
import sys
import time
import urllib.request
from pathlib import Path

# 主源 raw.githubusercontent.com + 备源 jsdelivr CDN（同一 OpenCC 仓库镜像）。
# ★ 固定到发布 tag ver.1.1.9：数据不可变（两源内容一致、可复现），
#   避免 master 分支数据漂移或 CDN 缓存不一致导致不同机器生成不同词典。
OPENCC_REF = "ver.1.1.9"
BASE_URLS = [
    f"https://raw.githubusercontent.com/BYVoid/OpenCC/{OPENCC_REF}/data/dictionary",
    f"https://cdn.jsdelivr.net/gh/BYVoid/OpenCC@{OPENCC_REF}/data/dictionary",
]

DICT_FILES = [
    "STCharacters",
    "STPhrases",
    "TSCharacters",
    "TSPhrases",
    "TWVariants",
    "HKVariants",
    # 反向词组变体：ver.1.1.9 仓库直接提供（多字词组的反向无法简单 swap）
    "TWVariantsRevPhrases",
    "HKVariantsRevPhrases",
    # 日本汉字：新字体→旧字体（jp2t 用）+ 旧字体→新字体（t2jp 用，JPVariants）
    "JPShinjitaiCharacters",
    "JPShinjitaiPhrases",
    "JPVariants",
]

# 反向单字变体：ver.1.1.9 仓库无现成文件，官方构建期由 data/scripts/reverse.py
# 从正向变体表生成（下方 reverse_swap 复刻其 Dict.swap() 语义）。生成物与
# 正向表一起嵌入。
REVERSE_OF = {
    "TWVariantsRev": "TWVariants",
    "HKVariantsRev": "HKVariants",
    "JPVariantsRev": "JPVariants",
}

# 下载内容的 SHA-256 白名单（对 download() 处理后的 UTF-8 文本计算：
# 去 BOM、\r\n→\n、末尾补 \n）。任何源（主源/备源）内容不一致都会在此拦截，
# 防止 CDN 漂移或上游被篡改导致生成物与预期不符（供应链完整性）。
# 刷新方法：用 tools/gen_hashes.tmp.py 重新计算后更新本表（并删除该临时脚本）。
DICT_SHA256 = {
    "STCharacters": "ed1d268e0ad028511dcf5b0089faed0a980ad332449ec11d481ceefde6879f41",
    "STPhrases": "17fece21a28f3db2dc32397abd73d21ae73261c3f295fa6a3fe64b5e8d8b554b",
    "TSCharacters": "6b5a0a799bea2bb22c001f635eaa3fc2904310f0c08addbff275477a80ecf09a",
    "TSPhrases": "504169029c43f7f234b8e2ae470720af3657675c5574ff8aa0feb257e1dc5ce2",
    "TWVariants": "30e6f8395edbfdd74e293fd8b9c62105d787c849fbb208d2a7832eac696734d7",
    "HKVariants": "c3c93c35885902ba2b12a3235a7761b00fb2b027f36aa8314db2f6b6ad51d374",
    "TWVariantsRevPhrases": "bef60ceb4e57b6b062351406cb5d4644875574231d64787e03711317b7e773f3",
    "HKVariantsRevPhrases": "c2da309afa7fdd9061f204664039d33b000a4dca0ecae4e7480dcbf9e20f658e",
    "JPShinjitaiCharacters": "0078ee41ff026f1cf05e4382e835baa9349f46ad32cd7fcc83baf736a4ff9b09",
    "JPShinjitaiPhrases": "c888eabc59da37b4b0e476669656d4415251261d6926a4285aa0a4c51ae81e97",
    "JPVariants": "db09543db11ffd42a2556070f3d0a8e2c0168726463bd5f8d530f3e54a5afab8",
}

RAW_DELIM = "opencc"  # raw string 分隔符：R"opencc(...)opencc"


def reverse_swap(text: str) -> str:
    """复刻 OpenCC data/scripts/common.py 的 Dict.swap()：
    - 每行 key\\tvalue1 value2... → 每个 value 反向映射回 key（保持源顺序）；
    - '# @reverse-prefer: a b' 注释：key a 的候选列表中把 b 移到最前
      （决定默认值，即转换时取第一个候选）。
    返回与官方 reverse.py 输出一致的词典文本（含排序：按 key 的首次出现序）。"""
    reverse_preferences: dict[str, str] = {}
    entries: list[tuple[str, list[str]]] = []
    for line in text.split("\n"):
        line = line.rstrip("\r")
        if line.startswith("# @reverse-prefer:"):
            fields = line[len("# @reverse-prefer:"):].split()
            if fields:
                reverse_preferences[fields[0]] = fields[-1]
            continue
        if line.startswith("#") or not line.strip():
            continue
        key, _, values = line.partition("\t")
        if values:
            entries.append((key, values.split(" ")))
    dic: dict[str, list[str]] = {}
    for key, values in entries:
        for value in values:
            dic.setdefault(value, []).append(key)
    for key, preferred in reverse_preferences.items():
        if key in dic and preferred in dic[key]:
            vals = dic[key]
            vals.insert(0, vals.pop(vals.index(preferred)))
    return "\n".join(key + "\t" + " ".join(values) for key, values in dic.items()) + "\n"


def download(name: str, urls: list[str] | None = None, timeout: float = 30, retries: int = 3) -> str:
    last: Exception | None = None
    bases = urls if urls else BASE_URLS
    want = DICT_SHA256.get(name)
    for attempt in range(retries):
        for base in bases:
            url = f"{base}/{name}.txt"
            try:
                req = urllib.request.Request(
                    url, headers={"User-Agent": "quickjs-runtime-bootstrap"}
                )
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    if resp.status != 200:
                        raise RuntimeError(f"HTTP {resp.status}")
                    data = resp.read()
                # 统一换行/去 BOM；按行保留（txt 词典格式：KEY\tVALUE）
                text = data.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
                if not text.endswith("\n"):
                    text += "\n"
                # 完整性校验：处理后的文本必须与白名单 SHA-256 一致（防 CDN 漂移/篡改）
                if want:
                    import hashlib

                    got = hashlib.sha256(text.encode("utf-8")).hexdigest()
                    if got != want:
                        raise RuntimeError(
                            f"SHA-256 不匹配（期望 {want[:16]}…，实际 {got[:16]}…）"
                        )
                return text
            except Exception as exc:  # noqa: BLE001 —— 换备源/重试
                last = exc
        if attempt + 1 < retries:
            time.sleep(1 + attempt)  # 退避后重试
    raise RuntimeError(f"下载失败（已重试 {retries} 次）: {name}.txt: {last}")


def main() -> int:
    parser = argparse.ArgumentParser(description="下载 OpenCC 词典数据并生成嵌入头文件")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "quickjs-runtime" / "include" / "opencc" / "opencc_data.hpp",
        help="输出头文件路径（默认 include/opencc/opencc_data.hpp）",
    )
    parser.add_argument(
        "--base-urls",
        nargs="+",
        default=BASE_URLS,
        help="词典 txt 的 base URL 列表（测试用；默认主源+备源）",
    )
    args = parser.parse_args()

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    # 幂等：产物已存在则跳过下载（网络不可达时复用已有数据，configure 可离线跑通）
    if out.exists() and out.stat().st_size > 0:
        print(f"SKIP: {out} 已存在（如需刷新数据请先删除后重跑）")
        return 0

    chunks: list[str] = []
    total_bytes = 0
    marker = f"){RAW_DELIM}\""
    for name in DICT_FILES:
        text = download(name, args.base_urls)
        if marker in text:  # 防 raw string 分隔符注入（数据含 )opencc" 会破坏头文件）
            raise RuntimeError(f"{name}.txt 包含 raw string 分隔符序列，拒绝生成")
        total_bytes += len(text)
        lines = text.count("\n")
        chunks.append(
            f"// ---- {name}.txt（{lines} 行）----\n"
            f"inline constexpr std::string_view {name}_txt = R\"{RAW_DELIM}(\n"
            f"{text}"
            f"){RAW_DELIM}\";\n"
        )
        print(f"  {name}.txt: {len(text)} bytes, {lines} lines")
    for rev_name, src_name in REVERSE_OF.items():
        text = download(src_name, args.base_urls)
        rev = reverse_swap(text)
        if marker in rev:
            raise RuntimeError(f"{rev_name}.txt 包含 raw string 分隔符序列，拒绝生成")
        total_bytes += len(rev)
        lines = rev.count("\n")
        chunks.append(
            f"// ---- {rev_name}.txt（{lines} 行，reverse_swap 生成）----\n"
            f"inline constexpr std::string_view {rev_name}_txt = R\"{RAW_DELIM}(\n"
            f"{rev}"
            f"){RAW_DELIM}\";\n"
        )
        print(f"  {rev_name}.txt: {len(rev)} bytes, {lines} lines (from {src_name}.txt)")

    header = (
        "// 由 scripts/bootstrap_opencc.py 生成（不入库，构建产物）。\n"
        f"// 数据来源: BYVoid/OpenCC {OPENCC_REF} data/dictionary（Apache-2.0），共 {total_bytes} bytes。\n"
        "// 重新生成: pixi run fetch-opencc\n"
        "#pragma once\n"
        "\n"
        "#include <string_view>\n"
        "\n"
        "namespace opencc_data {\n"
        "\n"
        + "\n".join(chunks)
        + "\n} // namespace opencc_data\n"
    )

    out.write_text(header, encoding="utf-8")
    print(f"生成 {out}（{total_bytes} bytes 数据）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
