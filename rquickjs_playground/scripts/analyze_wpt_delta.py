import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).parent.parent


def parse_per_file(text: str):
    """Parse the 'Per file:' section from test output."""
    results = {}
    in_per_file = False
    for line in text.splitlines():
        if line.strip() == "Per file:":
            in_per_file = True
            continue
        if not in_per_file:
            continue
        if line.strip().startswith("===") or line.strip().startswith("="):
            break
        m = re.match(r"\s*(\S+): passed=(\d+) failed=(\d+) harness_ok=(\w+)", line)
        if m:
            results[m.group(1)] = {
                "passed": int(m.group(2)),
                "failed": int(m.group(3)),
                "harness_ok": m.group(4) == "true",
            }
    return results


def main():
    rust_text = (ROOT / "target/rust_wpt_results.txt").read_text(encoding="utf-8")
    node_text = (ROOT / "target/node_wpt_results.txt").read_text(encoding="utf-8")

    rust = parse_per_file(rust_text)
    node = parse_per_file(node_text)

    print("=" * 80)
    print("rquickjs_playground vs Node.js WPT fetch 差距分析")
    print("=" * 80)

    # Files where Rust has more failures (same or fewer total tests)
    deltas = []
    for f in sorted(set(rust) | set(node)):
        r = rust.get(f, {"passed": 0, "failed": 0, "harness_ok": False})
        n = node.get(f, {"passed": 0, "failed": 0, "harness_ok": False})
        r_total = r["passed"] + r["failed"]
        n_total = n["passed"] + n["failed"]
        if r_total == 0 or n_total == 0:
            continue
        r_rate = r["passed"] / r_total
        n_rate = n["passed"] / n_total
        delta = n_rate - r_rate
        deltas.append((f, delta, r["passed"], r["failed"], n["passed"], n["failed"], r["harness_ok"], n["harness_ok"]))

    deltas.sort(key=lambda x: x[1], reverse=True)

    print("\n差距最大的文件（Node 通过率高 - Rust 通过率高，降序）：")
    print(f"{'文件':<60} {'Δ通过率':>8} {'Rust':>12} {'Node':>12}")
    for f, delta, rp, rf, np, nf, rh, nh in deltas[:20]:
        print(f"{f:<60} {delta*100:>7.1f}%  {rp}/{rp+rf:>3}  {np}/{np+nf:>3}")

    print("\n\n按 Rust 失败数排序（绝对数量大的短板）：")
    by_fail = sorted(rust.items(), key=lambda x: x[1]["failed"], reverse=True)
    print(f"{'文件':<60} {'失败数':>8} {'Rust':>12} {'Node':>12}")
    for f, r in by_fail[:20]:
        n = node.get(f, {"passed": 0, "failed": 0})
        print(f"{f:<60} {r['failed']:>7}  {r['passed']}/{r['passed']+r['failed']:>3}  {n['passed']}/{n['passed']+n['failed']:>3}")

    # Categorize failures
    print("\n\n主要缺失类别估算：")
    categories = {
        "Headers 校验/规范化/合并/guard": [
            "fetch/api/headers/headers-basic.any.js",
            "fetch/api/headers/headers-errors.any.js",
            "fetch/api/headers/headers-normalize.any.js",
            "fetch/api/headers/headers-record.any.js",
            "fetch/api/headers/headers-no-cors.any.js",
            "fetch/api/headers/header-setcookie.any.js",
            "fetch/api/headers/headers-forbidden-override.any.js",
            "fetch/api/request/request-headers.any.js",
            "fetch/api/basic/header-value-combining.any.js",
            "fetch/api/basic/request-headers-case.any.js",
            "fetch/api/basic/request-headers-nonascii.any.js",
        ],
        "Response 静态方法与初始化校验": [
            "fetch/api/response/response-error.any.js",
            "fetch/api/response/response-init-001.any.js",
            "fetch/api/response/response-static-error.any.js",
            "fetch/api/response/response-static-json.any.js",
            "fetch/api/response/response-static-redirect.any.js",
        ],
        "Request/Response body MIME 类型与 Content-Type": [
            "fetch/api/request/request-init-002.any.js",
            "fetch/api/request/request-init-contenttype.any.js",
            "fetch/api/response/response-init-contenttype.any.js",
            "fetch/api/body/mime-type.any.js",
            "fetch/api/request/request-constructor-init-body-override.any.js",
        ],
        "body 消费方法 (formData/text/arrayBuffer/blob/json/clone)": [
            "fetch/api/body/formdata.any.js",
            "fetch/api/request/request-consume-empty.any.js",
            "fetch/api/response/response-consume-empty.any.js",
            "fetch/api/abort/request.any.js",
        ],
        "浏览器全局对象缺失 / 需要服务器": [
            "fetch/api/request/request-bad-port.any.js",
            "fetch/api/headers/header-values-normalize.any.js",
            "fetch/api/basic/response-null-body.any.js",
            "fetch/api/basic/request-head.any.js",
        ],
        "Request 属性/结构不符合规范": [
            "fetch/api/request/request-structure.any.js",
            "fetch/api/request/request-init-priority.any.js",
        ],
    }

    for cat, files in categories.items():
        r_fail = sum(rust.get(f, {"failed": 0})["failed"] for f in files)
        n_fail = sum(node.get(f, {"failed": 0})["failed"] for f in files)
        print(f"  {cat:<45} Rust 失败 {r_fail:>3}  |  Node 失败 {n_fail:>3}")


if __name__ == "__main__":
    main()
