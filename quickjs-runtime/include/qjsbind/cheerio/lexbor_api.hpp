// lexbor_api.hpp —— BreezeHtml 只读选择集方法（内部头文件）
//
// 全部方法直接在 lexbor C 树上执行：序列化（lxb_html_serialize_tree_str）、
// 文本拼接、属性读取、CSS 查询（lexbor_match.hpp）。选择集不可变，方法只
// 返回新选择集或读取值，不修改文档。
#pragma once

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <lexbor/html/html.h>

#include <qjsbind/binary.hpp> // qjs::Context::js_string / qjs::to_js
#include <qjsbind/cheerio/lexbor_handle.hpp>
#include <qjsbind/cheerio/lexbor_match.hpp>
#include <qjsbind/convert.hpp>

namespace qjsbind::cheerio {

// ---------------------------------------------------------------------------
// 小工具
// ---------------------------------------------------------------------------
using SelFn = JSValue (*)(JSContext*, JSValueConst, int, JSValueConst*);

inline Selection* sel_of(JSContext* ctx, JSValueConst this_val)
{
    return unwrap_sel(ctx, this_val);
}

// JS 值转 std::string；失败（含 pending exception）返回 false
// 转发到 qjs::Context::js_string（值语义提取，嵌入 '\0' 保留）
inline bool js_to_string(JSContext* ctx, JSValueConst v, std::string& out)
{
    auto s = qjs::Context(ctx).js_string(v);
    if (!s)
        return false;
    out = std::move(*s);
    return true;
}

inline JSValue js_new_string(JSContext* ctx, const std::string& s)
{
    return qjs::Context(ctx).to_js(s).take(); // JS_NewStringLen 包装
}

// 子树序列化（含 n 自身）
inline std::string c_serialize_tree(lxb_dom_node_t* n)
{
    lexbor_str_t str = {0};
    lxb_status_t st = lxb_html_serialize_tree_str(n, &str);
    if (st != LXB_STATUS_OK)
        return "";
    std::string out((const char*)str.data, str.length);
    // serialize_tree_str 内部用 doc->text 分配 str（见 lexbor serialize.c）
    lxb_dom_document_t* doc = n->owner_document;
    lexbor_str_destroy(&str, doc ? doc->text : nullptr, false);
    return out;
}

// 无效选择器 → JS TypeError（css-select 兼容消息），返回 JS_EXCEPTION
inline JSValue throw_invalid_selector(JSContext* ctx, const std::string& selector)
{
    std::string msg = "Invalid selector: " + selector;
    // 提取第一个 :name 片段（Unknown pseudo-class :bah 风格）
    size_t pos = selector.find(':');
    if (pos != std::string::npos && pos + 1 < selector.size()) {
        size_t end = pos + 1;
        while (end < selector.size() &&
               (std::isalnum((unsigned char)selector[end]) ||
                selector[end] == '-' || selector[end] == '_'))
            ++end;
        if (end > pos + 1)
            msg = "Unknown pseudo-class " + selector.substr(pos, end - pos);
    }
    return JS_ThrowTypeError(ctx, "%s", msg.c_str());
}

// el 自身是否匹配 selector（is 语义：不遍历子树）
inline bool c_matches(lxb_dom_node_t* el, const std::string& selector, bool* ok)
{
    lxb_css_selector_list_t* list = nullptr;
    lxb_css_parser_t* parser = parse_selectors(selector, &list);
    if (!parser) {
        if (ok)
            *ok = false;
        return false;
    }
    CTreeMatcher m{el};
    bool match = false;
    for (lxb_css_selector_list_t* l = list; l; l = l->next) {
        if (l->first != nullptr && m.match_chain(l->last, el)) {
            match = true;
            break;
        }
    }
    lxb_css_parser_destroy(parser, true);
    if (ok)
        *ok = true;
    return match;
}

// ---------------------------------------------------------------------------
// 集合工具：文档序、去重、可选选择器过滤
// ---------------------------------------------------------------------------
// 文档序比较：a 在 b 前 → -1；a 在 b 后 → 1；相同/无法比较 → 0
inline int c_doc_order_cmp(lxb_dom_node_t* a, lxb_dom_node_t* b)
{
    if (a == b)
        return 0;
    // 祖先链（含自身），末尾是文档根
    std::vector<lxb_dom_node_t*> pa, pb;
    for (lxb_dom_node_t* p = a; p; p = p->parent)
        pa.push_back(p);
    for (lxb_dom_node_t* p = b; p; p = p->parent)
        pb.push_back(p);
    size_t ia = pa.size(), ib = pb.size();
    while (ia > 0 && ib > 0 && pa[ia - 1] == pb[ib - 1]) {
        --ia;
        --ib;
    }
    if (ia == 0)
        return -1; // a 是 b 的祖先
    if (ib == 0)
        return 1; // b 是 a 的祖先
    if (ia >= pa.size() || ib >= pb.size() || pa[ia] != pb[ib])
        return 0; // 无公共祖先（不同树，防御）：视为等价，保持插入序
    // pa[ia-1] / pb[ib-1] 是最近公共祖先下的两个孩子：比较兄弟序
    lxb_dom_node_t* ca = pa[ia - 1];
    lxb_dom_node_t* cb = pb[ib - 1];
    for (lxb_dom_node_t* s = ca->prev; s; s = s->prev) {
        if (s == cb)
            return 1; // cb 在 ca 前 → a 在 b 后
    }
    return -1;
}

// uniqueSort：文档序排序 + 去重（domutils uniqueSort 等价）
inline std::vector<lxb_dom_node_t*> c_unique_sort(std::vector<lxb_dom_node_t*> nodes)
{
    std::stable_sort(nodes.begin(), nodes.end(),
                     [](lxb_dom_node_t* a, lxb_dom_node_t* b) {
                         return c_doc_order_cmp(a, b) < 0;
                     });
    nodes.erase(std::unique(nodes.begin(), nodes.end()), nodes.end());
    return nodes;
}

// 保持顺序去重
inline std::vector<lxb_dom_node_t*> c_remove_dups(std::vector<lxb_dom_node_t*> nodes)
{
    std::unordered_set<lxb_dom_node_t*> seen;
    std::vector<lxb_dom_node_t*> out;
    out.reserve(nodes.size());
    for (lxb_dom_node_t* n : nodes) {
        if (seen.insert(n).second)
            out.push_back(n);
    }
    return out;
}

// 可选选择器过滤（children/siblings/next/prev 的可选参数）：
// 非字符串/空值 → 原样返回；无效选择器 → 抛 JS 错误并置 *threw
inline std::vector<lxb_dom_node_t*> apply_opt_filter(
    JSContext* ctx, std::vector<lxb_dom_node_t*> nodes, JSValueConst arg,
    bool* threw)
{
    *threw = false;
    if (!JS_IsString(arg))
        return nodes;
    std::string selector;
    if (!js_to_string(ctx, arg, selector)) {
        *threw = true;
        return {};
    }
    std::vector<lxb_dom_node_t*> out;
    bool ok = true;
    for (lxb_dom_node_t* el : nodes) {
        if (c_node_is_element(el) && c_matches(el, selector, &ok))
            out.push_back(el);
        if (!ok) {
            throw_invalid_selector(ctx, selector);
            *threw = true;
            return {};
        }
    }
    return out;
}

// 调用回调：(index, 单元素选择集)，this = 同一选择集。
// 异常时置 *threw 并返回 JS_EXCEPTION。
inline JSValue call_node_cb(JSContext* ctx, JSValueConst cb, DomRef* ref,
                            lxb_dom_node_t* node, uint32_t index, bool* threw)
{
    JSValue el = make_sel(ctx, ref, {node});
    if (JS_IsException(el)) {
        *threw = true;
        return JS_EXCEPTION;
    }
    JSValue args[2] = {JS_NewUint32(ctx, index), el};
    JSValue r = JS_Call(ctx, cb, el, 2, args);
    JS_FreeValue(ctx, args[0]);
    JS_FreeValue(ctx, el);
    if (JS_IsException(r)) {
        JS_FreeValue(ctx, r);
        *threw = true;
        return JS_EXCEPTION;
    }
    *threw = false;
    return r;
}

// ---------------------------------------------------------------------------
// 遍历：find / first / last / eq / closest / parent / children / siblings /
//       next / prev / filter / has / slice
// ---------------------------------------------------------------------------
// find(selector)：后代匹配。相对选择器（> + ~ 开头）需要兄弟上下文 →
// 文档根遍历 + :scope 绑定每个选中元素；普通选择器只查每个元素的子树。
inline JSValue fn_find(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (argc > 0 && JS_IsString(argv[0])) {
        std::string selector;
        if (!js_to_string(ctx, argv[0], selector))
            return JS_EXCEPTION;
        bool ok = true;
        lxb_dom_node_t* doc_root = &s->ref->doc->dom_document.node;
        size_t sb = selector.find_first_not_of(" \t\r\n");
        bool relative = sb != std::string::npos && sb < selector.size() &&
                        (selector[sb] == '>' || selector[sb] == '+' ||
                         selector[sb] == '~');
        // :scope 匹配元素自身 → 查询需包含自身
        bool scoped = selector.find(":scope") != std::string::npos;
        for (lxb_dom_node_t* el : s->nodes) {
            std::vector<lxb_dom_node_t*> r = c_query_selector(
                relative ? doc_root : el, selector, scoped,
                relative ? el : nullptr, &ok);
            if (!ok)
                return throw_invalid_selector(ctx, selector);
            for (lxb_dom_node_t* n : r) {
                bool dup = false;
                for (lxb_dom_node_t* o : out) {
                    if (o == n) {
                        dup = true;
                        break;
                    }
                }
                if (!dup)
                    out.push_back(n);
            }
        }
    }
    return make_sel(ctx, s->ref, std::move(out));
}

inline JSValue fn_first(JSContext* ctx, JSValueConst this_val, int argc,
                        JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (!s->nodes.empty())
        out.push_back(s->nodes[0]);
    return make_sel(ctx, s->ref, std::move(out));
}

inline JSValue fn_last(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (!s->nodes.empty())
        out.push_back(s->nodes.back());
    return make_sel(ctx, s->ref, std::move(out));
}

inline JSValue fn_eq(JSContext* ctx, JSValueConst this_val, int argc,
                     JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s || argc < 1)
        return JS_UNDEFINED;
    int32_t idx = 0;
    JS_ToInt32(ctx, &idx, argv[0]);
    std::vector<lxb_dom_node_t*> out;
    if (idx < 0)
        idx = (int32_t)s->nodes.size() + idx;
    if (idx >= 0 && (size_t)idx < s->nodes.size())
        out.push_back(s->nodes[(size_t)idx]);
    return make_sel(ctx, s->ref, std::move(out));
}

// closest(selector)：自身起向上第一个匹配的元素（每选中元素取一个）
inline JSValue fn_closest(JSContext* ctx, JSValueConst this_val, int argc,
                          JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (argc > 0 && JS_IsString(argv[0])) {
        std::string selector;
        if (!js_to_string(ctx, argv[0], selector))
            return JS_EXCEPTION;
        bool ok = true;
        for (lxb_dom_node_t* el : s->nodes) {
            for (lxb_dom_node_t* p = el; p; p = p->parent) {
                if (!c_node_is_element(p))
                    continue;
                if (c_matches(p, selector, &ok)) {
                    out.push_back(p);
                    break;
                }
                if (!ok)
                    return throw_invalid_selector(ctx, selector);
            }
        }
    }
    return make_sel(ctx, s->ref, c_unique_sort(std::move(out)));
}

// parent()：直接父元素（保持顺序去重）
inline JSValue fn_parent(JSContext* ctx, JSValueConst this_val, int argc,
                         JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    for (lxb_dom_node_t* el : s->nodes) {
        if (el->parent && c_node_is_element(el->parent))
            out.push_back(el->parent);
    }
    return make_sel(ctx, s->ref, c_remove_dups(std::move(out)));
}

// children([selector])：元素子节点
inline JSValue fn_children(JSContext* ctx, JSValueConst this_val, int argc,
                           JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    for (lxb_dom_node_t* el : s->nodes) {
        for (lxb_dom_node_t* c = el->first_child; c; c = c->next) {
            if (c_node_is_element(c))
                out.push_back(c);
        }
    }
    bool threw = false;
    out = apply_opt_filter(ctx, std::move(out), argc > 0 ? argv[0] : JS_UNDEFINED,
                           &threw);
    if (threw)
        return JS_EXCEPTION;
    return make_sel(ctx, s->ref, std::move(out));
}

// siblings([selector])：除自身外的元素兄弟（文档序去重）
inline JSValue fn_siblings(JSContext* ctx, JSValueConst this_val, int argc,
                           JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    for (lxb_dom_node_t* el : s->nodes) {
        if (!el->parent)
            continue;
        for (lxb_dom_node_t* c = el->parent->first_child; c; c = c->next) {
            if (c_node_is_element(c) && c != el)
                out.push_back(c);
        }
    }
    bool threw = false;
    out = apply_opt_filter(ctx, std::move(out), argc > 0 ? argv[0] : JS_UNDEFINED,
                           &threw);
    if (threw)
        return JS_EXCEPTION;
    return make_sel(ctx, s->ref, c_unique_sort(std::move(out)));
}

// next / prev([selector])：方向上第一个元素兄弟
inline JSValue fn_sibling_step(JSContext* ctx, JSValueConst this_val, int argc,
                               JSValueConst* argv, bool forward)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    for (lxb_dom_node_t* el : s->nodes) {
        for (lxb_dom_node_t* p = forward ? el->next : el->prev; p;
             p = forward ? p->next : p->prev) {
            if (c_node_is_element(p)) {
                out.push_back(p);
                break;
            }
        }
    }
    bool threw = false;
    out = apply_opt_filter(ctx, std::move(out), argc > 0 ? argv[0] : JS_UNDEFINED,
                           &threw);
    if (threw)
        return JS_EXCEPTION;
    return make_sel(ctx, s->ref, std::move(out));
}

inline JSValue fn_next(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    return fn_sibling_step(ctx, this_val, argc, argv, true);
}

inline JSValue fn_prev(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    return fn_sibling_step(ctx, this_val, argc, argv, false);
}

// filter(selector|fn)：保留匹配项；fn 形式回调 (index, 单元素选择集)
inline JSValue fn_filter(JSContext* ctx, JSValueConst this_val, int argc,
                         JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (argc > 0 && JS_IsString(argv[0])) {
        std::string selector;
        if (!js_to_string(ctx, argv[0], selector))
            return JS_EXCEPTION;
        bool ok = true;
        for (lxb_dom_node_t* el : s->nodes) {
            if (c_node_is_element(el) && c_matches(el, selector, &ok))
                out.push_back(el);
            if (!ok)
                return throw_invalid_selector(ctx, selector);
        }
    } else if (argc > 0 && JS_IsFunction(ctx, argv[0])) {
        for (size_t i = 0; i < s->nodes.size(); ++i) {
            bool threw = false;
            JSValue r =
                call_node_cb(ctx, argv[0], s->ref, s->nodes[i], (uint32_t)i, &threw);
            if (threw)
                return JS_EXCEPTION;
            bool keep = JS_ToBool(ctx, r);
            JS_FreeValue(ctx, r);
            if (keep)
                out.push_back(s->nodes[i]);
        }
    }
    return make_sel(ctx, s->ref, std::move(out));
}

// has(selector)：保留含匹配后代的元素
inline JSValue fn_has(JSContext* ctx, JSValueConst this_val, int argc,
                      JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::vector<lxb_dom_node_t*> out;
    if (argc > 0 && JS_IsString(argv[0])) {
        std::string selector;
        if (!js_to_string(ctx, argv[0], selector))
            return JS_EXCEPTION;
        bool ok = true;
        for (lxb_dom_node_t* el : s->nodes) {
            if (!c_node_is_element(el))
                continue;
            std::vector<lxb_dom_node_t*> r =
                c_query_selector(el, selector, false, nullptr, &ok);
            if (!ok)
                return throw_invalid_selector(ctx, selector);
            if (!r.empty())
                out.push_back(el);
        }
    }
    return make_sel(ctx, s->ref, std::move(out));
}

// slice(start[, end])：支持负数下标
inline JSValue fn_slice(JSContext* ctx, JSValueConst this_val, int argc,
                        JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    int32_t start = 0, end = (int32_t)s->nodes.size();
    if (argc > 0 && !JS_IsUndefined(argv[0]))
        JS_ToInt32(ctx, &start, argv[0]);
    if (argc > 1 && !JS_IsUndefined(argv[1]))
        JS_ToInt32(ctx, &end, argv[1]);
    if (start < 0)
        start = (int32_t)s->nodes.size() + start;
    if (end < 0)
        end = (int32_t)s->nodes.size() + end;
    if (start < 0)
        start = 0;
    if (end > (int32_t)s->nodes.size())
        end = (int32_t)s->nodes.size();
    std::vector<lxb_dom_node_t*> out;
    for (int32_t i = start; i < end; ++i)
        out.push_back(s->nodes[(size_t)i]);
    return make_sel(ctx, s->ref, std::move(out));
}

// index()：首元素在父元素元素兄弟中的序号（无 → -1）
inline JSValue fn_index(JSContext* ctx, JSValueConst this_val, int argc,
                        JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    if (s->nodes.empty() || !s->nodes[0]->parent)
        return JS_NewInt32(ctx, -1);
    lxb_dom_node_t* needle = s->nodes[0];
    int32_t idx = 0;
    for (lxb_dom_node_t* c = needle->parent->first_child; c; c = c->next) {
        if (c == needle)
            return JS_NewInt32(ctx, idx);
        if (c_node_is_element(c))
            ++idx;
    }
    return JS_NewInt32(ctx, -1);
}

// is(selector)：任一元素匹配
inline JSValue fn_is(JSContext* ctx, JSValueConst this_val, int argc,
                     JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s || argc < 1 || !JS_IsString(argv[0]))
        return JS_FALSE;
    std::string selector;
    if (!js_to_string(ctx, argv[0], selector))
        return JS_EXCEPTION;
    bool ok = true;
    for (lxb_dom_node_t* el : s->nodes) {
        if (c_node_is_element(el) && c_matches(el, selector, &ok))
            return JS_TRUE;
        if (!ok)
            return throw_invalid_selector(ctx, selector);
    }
    return JS_FALSE;
}

// ---------------------------------------------------------------------------
// 读取：attr / text / html / val
// ---------------------------------------------------------------------------
// attr(name)：首元素属性；属性缺失或空集 → undefined
inline JSValue fn_attr(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s || argc < 1)
        return JS_UNDEFINED;
    std::string name;
    if (!js_to_string(ctx, argv[0], name))
        return JS_EXCEPTION;
    if (s->nodes.empty())
        return JS_UNDEFINED;
    size_t vl = 0;
    const lxb_char_t* v =
        c_attr_value(s->nodes[0], name.data(), name.size(), &vl);
    if (!v)
        return JS_UNDEFINED;
    return JS_NewStringLen(ctx, (const char*)v, (int)vl);
}

// text()：所有选中元素的文本拼接（空集 → ""）
inline JSValue fn_text(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    std::string out;
    for (lxb_dom_node_t* n : s->nodes)
        out += c_text_content(n);
    return js_new_string(ctx, out);
}

// html()：首元素 innerHTML（空集 → undefined）
inline JSValue fn_html(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    if (s->nodes.empty() || !c_node_is_element(s->nodes[0]))
        return JS_UNDEFINED;
    std::string inner;
    for (lxb_dom_node_t* c = s->nodes[0]->first_child; c; c = c->next)
        inner += c_serialize_tree(c);
    return js_new_string(ctx, inner);
}

// val()：首元素表单值（cheerio 语义：textarea → 文本；select → 选中/首个
// option；option → value 属性或文本；checkbox/radio 无 value → 'on'；
// 其他 → value 属性，无 → undefined）
inline JSValue option_value(JSContext* ctx, lxb_dom_node_t* opt)
{
    size_t vl = 0;
    const lxb_char_t* v = c_attr_value(opt, "value", 5, &vl);
    if (v)
        return JS_NewStringLen(ctx, (const char*)v, (int)vl);
    return js_new_string(ctx, c_text_content(opt));
}

// 文档序找 option：selected 优先，否则第一个（返回值经 out 参数）
inline lxb_dom_node_t* walk_options(lxb_dom_node_t* n, lxb_dom_node_t*& first)
{
    for (lxb_dom_node_t* c = n->first_child; c; c = c->next) {
        if (!c_node_is_element(c))
            continue;
        if (c_node_name(c) == "option") {
            if (!first)
                first = c;
            if (c_attr_exists(c, "selected"))
                return c;
        }
        if (lxb_dom_node_t* hit = walk_options(c, first))
            return hit;
    }
    return nullptr;
}

inline JSValue fn_val(JSContext* ctx, JSValueConst this_val, int argc,
                      JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    if (s->nodes.empty() || !c_node_is_element(s->nodes[0]))
        return JS_UNDEFINED;
    lxb_dom_node_t* el = s->nodes[0];
    std::string name = c_node_name(el);
    if (name == "textarea")
        return js_new_string(ctx, c_text_content(el));
    if (name == "option")
        return option_value(ctx, el);
    if (name == "select") {
        lxb_dom_node_t* first = nullptr;
        lxb_dom_node_t* hit = walk_options(el, first);
        if (!hit)
            hit = first;
        if (!hit)
            return JS_UNDEFINED;
        return option_value(ctx, hit);
    }
    size_t vl = 0;
    const lxb_char_t* v = c_attr_value(el, "value", 5, &vl);
    if (v)
        return JS_NewStringLen(ctx, (const char*)v, (int)vl);
    if (name == "input") {
        size_t tl = 0;
        const lxb_char_t* t = c_attr_value(el, "type", 4, &tl);
        std::string type = t ? std::string((const char*)t, tl) : "";
        for (auto& c : type)
            c = (char)std::tolower((unsigned char)c);
        if (type == "checkbox" || type == "radio")
            return JS_NewStringLen(ctx, "on", 2);
    }
    return JS_UNDEFINED;
}

// ---------------------------------------------------------------------------
// 迭代：toArray / each / map
// ---------------------------------------------------------------------------
// toArray()：单元素选择集数组
inline JSValue fn_to_array(JSContext* ctx, JSValueConst this_val, int argc,
                           JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    JSValue arr = JS_NewArray(ctx);
    uint32_t i = 0;
    for (lxb_dom_node_t* n : s->nodes)
        JS_SetPropertyUint32(ctx, arr, i++, make_sel(ctx, s->ref, {n}));
    return arr;
}

// each(fn)：fn(index, 单元素选择集)，this = 同一选择集；返回 === false 中断
inline JSValue fn_each(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    if (argc < 1 || !JS_IsFunction(ctx, argv[0]))
        return JS_DupValue(ctx, this_val);
    for (size_t i = 0; i < s->nodes.size(); ++i) {
        bool threw = false;
        JSValue r =
            call_node_cb(ctx, argv[0], s->ref, s->nodes[i], (uint32_t)i, &threw);
        if (threw)
            return JS_EXCEPTION;
        // 仅严格 === false 中断（jQuery/cheerio 语义）
        bool strict_false =
            JS_VALUE_GET_TAG(r) == JS_TAG_BOOL && !JS_VALUE_GET_BOOL(r);
        JS_FreeValue(ctx, r);
        if (strict_false)
            break;
    }
    return JS_DupValue(ctx, this_val);
}

// map(fn)：收集回调返回值（跳过 null/undefined），返回 { length, get() }
inline JSValue fn_mapped_get(JSContext* ctx, JSValueConst this_val, int argc,
                             JSValueConst* argv, int magic, JSValueConst* data)
{
    return JS_DupValue(ctx, data[0]);
}

inline JSValue make_mapped_result(JSContext* ctx, JSValue arr)
{
    JSValue obj = JS_NewObject(ctx);
    uint32_t len = 0;
    JSValue lv = JS_GetPropertyStr(ctx, arr, "length");
    JS_ToUint32(ctx, &len, lv);
    JS_FreeValue(ctx, lv);
    JS_SetPropertyStr(ctx, obj, "length", JS_NewUint32(ctx, len));
    // JS_NewCFunctionData 会 dup data；get() 返回结果数组
    JSValue get = JS_NewCFunctionData(ctx, fn_mapped_get, 0, 0, 1, &arr);
    JS_SetPropertyStr(ctx, obj, "get", get);
    JS_FreeValue(ctx, arr);
    return obj;
}

inline JSValue fn_map(JSContext* ctx, JSValueConst this_val, int argc,
                      JSValueConst* argv)
{
    Selection* s = sel_of(ctx, this_val);
    if (!s)
        return JS_UNDEFINED;
    JSValue arr = JS_NewArray(ctx);
    if (argc > 0 && JS_IsFunction(ctx, argv[0])) {
        uint32_t out_idx = 0;
        for (size_t i = 0; i < s->nodes.size(); ++i) {
            bool threw = false;
            JSValue r =
                call_node_cb(ctx, argv[0], s->ref, s->nodes[i], (uint32_t)i, &threw);
            if (threw) {
                JS_FreeValue(ctx, arr);
                return JS_EXCEPTION;
            }
            if (!JS_IsNull(r) && !JS_IsUndefined(r))
                JS_SetPropertyUint32(ctx, arr, out_idx++, r); // 接管引用
            else
                JS_FreeValue(ctx, r);
        }
    }
    return make_mapped_result(ctx, arr);
}

// ---------------------------------------------------------------------------
// load(html) → $（可调用）：$(selector) / $(selection)
// ---------------------------------------------------------------------------
inline JSValue fn_api_call(JSContext* ctx, JSValueConst this_val, int argc,
                           JSValueConst* argv, int magic, JSValueConst* data)
{
    Selection* root = unwrap_sel(ctx, data[0]);
    if (!root || root->nodes.empty())
        return JS_ThrowTypeError(ctx, "BreezeHtml: invalid load context");
    if (argc > 0) {
        // $(selector)：文档后代中查询
        if (JS_IsString(argv[0])) {
            std::string selector;
            if (!js_to_string(ctx, argv[0], selector))
                return JS_EXCEPTION;
            bool ok = true;
            std::vector<lxb_dom_node_t*> nodes = c_query_selector(
                root->nodes[0], selector, false, nullptr, &ok);
            if (!ok)
                return throw_invalid_selector(ctx, selector);
            return make_sel(ctx, root->ref, std::move(nodes));
        }
        // $(selection)：原样返回
        if (unwrap_sel(ctx, argv[0]))
            return JS_DupValue(ctx, argv[0]);
    }
    // $(其他值)：空选择集
    return make_sel(ctx, root->ref, {});
}

inline JSValue fn_load(JSContext* ctx, JSValueConst this_val, int argc,
                       JSValueConst* argv)
{
    if (argc < 1 || !JS_IsString(argv[0]))
        return JS_ThrowTypeError(ctx, "BreezeHtml.load() expects a string");
    std::string html;
    if (!js_to_string(ctx, argv[0], html))
        return JS_EXCEPTION;
    DomRef* ref = parse_document(ctx, html);
    if (!ref)
        return JS_EXCEPTION;
    // $ 为 C 函数，func_data 持有根选择集（引用计数保住文档）。
    // JS_NewCFunctionData 会 dup data，故创建后释放本地引用。
    JSValue root = make_sel(ctx, ref, {&ref->doc->dom_document.node});
    if (JS_IsException(root)) {
        // make_sel 失败时未 retain：直接销毁（refs 仍为 0，不能走 release）
        lxb_html_document_destroy(ref->doc);
        delete ref;
        return JS_EXCEPTION;
    }
    JSValue api = JS_NewCFunctionData(ctx, fn_api_call, 1, 0, 1, &root);
    JS_FreeValue(ctx, root);
    return api;
}

// ---------------------------------------------------------------------------
// 方法注册（install 时调用；proto 由 register_sel_class 创建）
// ---------------------------------------------------------------------------
inline void register_sel_methods(JSContext* ctx)
{
    JSValue proto = sel_class(JS_GetRuntime(ctx)).proto;
    auto reg = [&](const char* name, SelFn fn, int nargs) {
        // JS_SetPropertyStr 接管 value 引用，无需 FreeValue
        JS_SetPropertyStr(ctx, proto, name, JS_NewCFunction(ctx, fn, name, nargs));
    };
    // 遍历
    reg("find", fn_find, 1);
    reg("first", fn_first, 0);
    reg("last", fn_last, 0);
    reg("eq", fn_eq, 1);
    reg("closest", fn_closest, 1);
    reg("parent", fn_parent, 0);
    reg("children", fn_children, 0);
    reg("siblings", fn_siblings, 0);
    reg("next", fn_next, 0);
    reg("prev", fn_prev, 0);
    reg("filter", fn_filter, 1);
    reg("has", fn_has, 1);
    reg("slice", fn_slice, 2);
    reg("index", fn_index, 0);
    reg("is", fn_is, 1);
    // 读取
    reg("attr", fn_attr, 1);
    reg("text", fn_text, 0);
    reg("html", fn_html, 0);
    reg("val", fn_val, 0);
    // 迭代
    reg("toArray", fn_to_array, 0);
    reg("each", fn_each, 1);
    reg("map", fn_map, 1);
}

} // namespace qjsbind::cheerio
