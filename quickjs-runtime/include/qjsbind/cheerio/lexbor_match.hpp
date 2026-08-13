// lexbor_match.hpp —— CSS 选择器解析 + lexbor C 树匹配（内部头文件）
//
// 选择器由 lexbor CSS 解析为 lxb_css_selector_list_t，匹配直接在
// lxb_dom_node_t 树上进行（无 JS 属性访问）。语义对齐 css-select / cheerio：
// :contains → :lexbor-contains 映射、:scope 绑定匹配上下文、nth-child 只统计
// 元素兄弟、以组合器开头的相对选择器包装为 :scope <组合器> <rest>。
#pragma once

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <string>
#include <string_view>
#include <vector>

#include <lexbor/css/css.h>
#include <lexbor/dom/dom.h>

namespace qjsbind::cheerio {

// ---------------------------------------------------------------------------
// C 树访问辅助
// ---------------------------------------------------------------------------
inline bool c_node_is_element(lxb_dom_node_t* n)
{
    return n != nullptr && n->type == LXB_DOM_NODE_TYPE_ELEMENT;
}

// 属性值（元素无该属性返回 nullptr；裸属性如 selected/disabled 无值 → 空串，
// lexbor 此时 attr->value 为 NULL，lxb_dom_attr_value 会返回 nullptr）
inline const lxb_char_t* c_attr_value(lxb_dom_node_t* el, const char* name,
                                      size_t name_len, size_t* value_len)
{
    if (!c_node_is_element(el))
        return nullptr;
    lxb_dom_attr_t* a = lxb_dom_element_attr_by_name(
        lxb_dom_interface_element(el), (const lxb_char_t*)name, name_len);
    if (!a)
        return nullptr;
    if (a->value == nullptr) {
        static const lxb_char_t empty = 0;
        *value_len = 0;
        return &empty;
    }
    return lxb_dom_attr_value(a, value_len);
}

inline bool c_attr_exists(lxb_dom_node_t* el, const char* name)
{
    size_t vl = 0;
    return c_attr_value(el, name, strlen(name), &vl) != nullptr;
}

inline std::string c_node_name(lxb_dom_node_t* n)
{
    if (!c_node_is_element(n))
        return "";
    size_t len = 0;
    const lxb_char_t* nm =
        lxb_tag_name_by_id(lxb_dom_element_tag_id(lxb_dom_interface_element(n)),
                           &len);
    return std::string((const char*)nm, len);
}

// 元素在父元素子节点中的 1-based index（:nth-child 只统计元素兄弟）
inline int64_t c_child_index(lxb_dom_node_t* el)
{
    if (!el->parent)
        return -1;
    int64_t idx = 0;
    for (lxb_dom_node_t* c = el->parent->first_child; c; c = c->next) {
        if (!c_node_is_element(c))
            continue;
        ++idx;
        if (c == el)
            return idx;
    }
    return -1;
}

// 同 tag 兄弟中的序号（1-based）：沿 prev 链计数
inline int64_t c_type_index(lxb_dom_node_t* el)
{
    std::string name = c_node_name(el);
    int64_t idx = 0;
    for (lxb_dom_node_t* p = el->prev; p; p = p->prev) {
        if (c_node_is_element(p) && c_node_name(p) == name)
            ++idx;
    }
    return idx + 1;
}

// 位置 n（1-based）是否满足 a*m + b == n（m >= 0 整数）
inline bool c_anb_match(long a, long b, int64_t n)
{
    if (a == 0)
        return n == b;
    int64_t m = (n - b) / a;
    return m >= 0 && a * m + b == n;
}

// 节点文本内容（text/cdata 叶子拼接；注释不计）
inline void c_collect_text(lxb_dom_node_t* n, std::string& out, int depth)
{
    if (depth > 64) // 防御：lexbor 树无环，纯保险
        return;
    switch (n->type) {
        case LXB_DOM_NODE_TYPE_TEXT:
        case LXB_DOM_NODE_TYPE_CDATA_SECTION: {
            size_t len = 0;
            const lxb_char_t* d = lxb_dom_node_text_content(n, &len);
            out.append((const char*)d, len);
            return;
        }
        case LXB_DOM_NODE_TYPE_ELEMENT:
        case LXB_DOM_NODE_TYPE_DOCUMENT:
        case LXB_DOM_NODE_TYPE_DOCUMENT_TYPE:
        case LXB_DOM_NODE_TYPE_DOCUMENT_FRAGMENT:
            for (lxb_dom_node_t* c = n->first_child; c; c = c->next)
                c_collect_text(c, out, depth + 1);
            return;
        default:
            return;
    }
}

inline std::string c_text_content(lxb_dom_node_t* n)
{
    std::string out;
    c_collect_text(n, out, 0);
    return out;
}

// ---------------------------------------------------------------------------
// C 树匹配器。depth 防 :not/:is/:has 伪类相互递归栈溢出。
// ---------------------------------------------------------------------------
struct CTreeMatcher {
    lxb_dom_node_t* scope = nullptr; // :scope 匹配上下文

    // 从右向左匹配一条 selector 链；el 为当前候选元素。
    // lexbor 语义：selector->combinator = 该 selector 与 prev selector 的关系
    // （CLOSE = 复合段内；CHILD/SIBLING/FOLLOWING/DESCENDANT = 与左边段的关系）。
    bool match_chain(lxb_css_selector_t* sel, lxb_dom_node_t* el, int depth = 0)
    {
        if (depth > 64)
            return false;
        lxb_css_selector_t* head = sel;
        while (head->prev != nullptr &&
               head->combinator == LXB_CSS_SELECTOR_COMBINATOR_CLOSE)
            head = head->prev;
        for (lxb_css_selector_t* s = head;; s = s->next) {
            if (!match_simple(s, el, depth))
                return false;
            if (s == sel)
                break;
        }
        lxb_css_selector_t* left = head->prev;
        if (left == nullptr)
            return true;

        switch (head->combinator) {
            case LXB_CSS_SELECTOR_COMBINATOR_DESCENDANT: {
                for (lxb_dom_node_t* p = el->parent; p; p = p->parent) {
                    if (c_node_is_element(p) && match_chain(left, p, depth + 1))
                        return true;
                }
                return false;
            }
            case LXB_CSS_SELECTOR_COMBINATOR_CHILD: {
                lxb_dom_node_t* p = el->parent;
                if (!c_node_is_element(p))
                    return false;
                return match_chain(left, p, depth + 1);
            }
            case LXB_CSS_SELECTOR_COMBINATOR_SIBLING: {
                for (lxb_dom_node_t* p = el->prev; p; p = p->prev) {
                    if (c_node_is_element(p))
                        return match_chain(left, p, depth + 1);
                }
                return false;
            }
            case LXB_CSS_SELECTOR_COMBINATOR_FOLLOWING: {
                for (lxb_dom_node_t* p = el->prev; p; p = p->prev) {
                    if (c_node_is_element(p) && match_chain(left, p, depth + 1))
                        return true;
                }
                return false;
            }
            default:
                return false;
        }
    }

    bool match_simple(lxb_css_selector_t* sel, lxb_dom_node_t* el, int depth = 0)
    {
        switch (sel->type) {
            case LXB_CSS_SELECTOR_TYPE_ANY:
                return true;

            case LXB_CSS_SELECTOR_TYPE_ELEMENT: {
                std::string_view want((const char*)sel->name.data,
                                      sel->name.length);
                return c_node_name(el) == want;
            }

            case LXB_CSS_SELECTOR_TYPE_ID: {
                size_t vl = 0;
                const lxb_char_t* v = c_attr_value(el, "id", 2, &vl);
                if (!v)
                    return false;
                std::string_view want((const char*)sel->name.data,
                                      sel->name.length);
                return std::string_view((const char*)v, vl) == want;
            }

            case LXB_CSS_SELECTOR_TYPE_CLASS: {
                std::string_view want((const char*)sel->name.data,
                                      sel->name.length);
                if (want == "__lexbor_scope__")
                    return el == scope; // :scope 映射
                return c_has_class(el, want);
            }

            case LXB_CSS_SELECTOR_TYPE_ATTRIBUTE:
                return match_attribute(sel, el);

            case LXB_CSS_SELECTOR_TYPE_PSEUDO_CLASS:
                return match_pseudo(sel->u.pseudo.type, sel, el, depth);

            case LXB_CSS_SELECTOR_TYPE_PSEUDO_CLASS_FUNCTION:
                return match_pseudo_function(sel->u.pseudo.type, sel, el, depth);

            case LXB_CSS_SELECTOR_TYPE_PSEUDO_ELEMENT:
            case LXB_CSS_SELECTOR_TYPE_PSEUDO_ELEMENT_FUNCTION:
                // css-select 不匹配伪元素
                return false;

            default:
                return false;
        }
    }

    // class 匹配：空格分隔词列表（大小写敏感）
    bool c_has_class(lxb_dom_node_t* el, std::string_view want)
    {
        size_t vl = 0;
        const lxb_char_t* v = c_attr_value(el, "class", 5, &vl);
        if (!v)
            return false;
        std::string_view attr((const char*)v, vl);
        size_t pos = 0;
        while (pos <= attr.size()) {
            size_t end = attr.find(' ', pos);
            if (end == std::string_view::npos)
                end = attr.size();
            if (attr.substr(pos, end - pos) == want)
                return true;
            if (end == attr.size())
                break;
            pos = end + 1;
        }
        return false;
    }

    bool match_attribute(lxb_css_selector_t* sel, lxb_dom_node_t* el)
    {
        std::string name((const char*)sel->name.data, sel->name.length);
        size_t vl = 0;
        const lxb_char_t* v = c_attr_value(el, name.data(), name.size(), &vl);
        if (!v)
            return false;
        std::string attr((const char*)v, vl);
        const lxb_css_selector_attribute_t& a = sel->u.attribute;
        if (a.match == LXB_CSS_SELECTOR_MATCH_EQUAL) {
            if (a.value.data == nullptr)
                return true; // [attr] 无值 = 存在性检查
            return attr == std::string((const char*)a.value.data, a.value.length);
        }
        std::string value((const char*)a.value.data, a.value.length);
        bool insensitive = a.modifier == LXB_CSS_SELECTOR_MODIFIER_I;
        auto eq = [&](const std::string& x, const std::string& y) {
            if (!insensitive)
                return x == y;
            if (x.size() != y.size())
                return false;
            for (size_t i = 0; i < x.size(); ++i)
                if (std::tolower((unsigned char)x[i]) !=
                    std::tolower((unsigned char)y[i]))
                    return false;
            return true;
        };
        switch (a.match) {
            case LXB_CSS_SELECTOR_MATCH_INCLUDE: {
                // ~= 空格分词
                size_t pos = 0;
                while (pos <= attr.size()) {
                    size_t end = attr.find(' ', pos);
                    if (end == std::string::npos)
                        end = attr.size();
                    if (eq(attr.substr(pos, end - pos), value))
                        return true;
                    if (end == attr.size())
                        break;
                    pos = end + 1;
                }
                return false;
            }
            case LXB_CSS_SELECTOR_MATCH_DASH: {
                if (eq(attr, value))
                    return true;
                std::string prefix = value + "-";
                return attr.size() > prefix.size() &&
                       eq(attr.substr(0, prefix.size()), prefix);
            }
            case LXB_CSS_SELECTOR_MATCH_PREFIX:
                return attr.size() >= value.size() &&
                       eq(attr.substr(0, value.size()), value);
            case LXB_CSS_SELECTOR_MATCH_SUFFIX:
                return attr.size() >= value.size() &&
                       eq(attr.substr(attr.size() - value.size()), value);
            case LXB_CSS_SELECTOR_MATCH_SUBSTRING: {
                if (insensitive) {
                    std::string lo_attr = attr, lo_val = value;
                    for (auto& c : lo_attr)
                        c = (char)std::tolower((unsigned char)c);
                    for (auto& c : lo_val)
                        c = (char)std::tolower((unsigned char)c);
                    return lo_attr.find(lo_val) != std::string::npos;
                }
                return attr.find(value) != std::string::npos;
            }
            default:
                return false;
        }
    }

    bool match_pseudo(unsigned type, lxb_css_selector_t* sel, lxb_dom_node_t* el,
                      int depth = 0)
    {
        switch (type) {
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FIRST_CHILD:
                return c_child_index(el) == 1;
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_LAST_CHILD: {
                for (lxb_dom_node_t* nx = el->next; nx; nx = nx->next) {
                    if (c_node_is_element(nx))
                        return false;
                }
                return true;
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_ONLY_CHILD: {
                for (lxb_dom_node_t* p = el->prev; p; p = p->prev) {
                    if (c_node_is_element(p))
                        return false;
                }
                for (lxb_dom_node_t* nx = el->next; nx; nx = nx->next) {
                    if (c_node_is_element(nx))
                        return false;
                }
                return true;
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FIRST_OF_TYPE: {
                std::string name = c_node_name(el);
                for (lxb_dom_node_t* p = el->prev; p; p = p->prev) {
                    if (c_node_is_element(p) && c_node_name(p) == name)
                        return false;
                }
                return true;
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_LAST_OF_TYPE: {
                std::string name = c_node_name(el);
                for (lxb_dom_node_t* nx = el->next; nx; nx = nx->next) {
                    if (c_node_is_element(nx) && c_node_name(nx) == name)
                        return false;
                }
                return true;
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_ONLY_OF_TYPE:
                return match_pseudo(LXB_CSS_SELECTOR_PSEUDO_CLASS_FIRST_OF_TYPE,
                                    sel, el, depth) &&
                       match_pseudo(LXB_CSS_SELECTOR_PSEUDO_CLASS_LAST_OF_TYPE,
                                    sel, el, depth);
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_EMPTY:
                return el->first_child == nullptr;
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_ROOT: {
                // 文档根元素：parent 是 document
                if (!el->parent || el->parent->parent)
                    return false;
                return el->parent->type == LXB_DOM_NODE_TYPE_DOCUMENT;
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_SCOPE:
                return el == scope;
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_LINK: {
                std::string name = c_node_name(el);
                return (name == "a" || name == "area" || name == "link") &&
                       c_attr_exists(el, "href");
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_CHECKED:
                return c_attr_exists(el, "checked") ||
                       c_attr_exists(el, "selected");
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_DISABLED:
                return c_attr_exists(el, "disabled");
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_ENABLED:
                return !c_attr_exists(el, "disabled");
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_REQUIRED:
                return c_attr_exists(el, "required");
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_OPTIONAL:
                return !c_attr_exists(el, "required");
            default:
                return false;
        }
    }

    bool match_pseudo_function(unsigned type, lxb_css_selector_t* sel,
                               lxb_dom_node_t* el, int depth = 0)
    {
        switch (type) {
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_CHILD:
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_LAST_CHILD: {
                auto* anb = (lxb_css_selector_anb_of_t*)sel->u.pseudo.data;
                if (!anb)
                    return false;
                int64_t idx = c_child_index(el);
                if (idx < 0)
                    return false;
                int64_t pos = idx;
                if (type == LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_LAST_CHILD) {
                    // 从后数：沿 next 链数元素兄弟
                    pos = 1;
                    for (lxb_dom_node_t* nx = el->next; nx; nx = nx->next) {
                        if (c_node_is_element(nx))
                            ++pos;
                    }
                }
                return c_anb_match(anb->anb.a, anb->anb.b, pos);
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_OF_TYPE:
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_LAST_OF_TYPE: {
                auto* anb = (lxb_css_selector_anb_of_t*)sel->u.pseudo.data;
                if (!anb)
                    return false;
                int64_t idx = c_type_index(el);
                if (idx < 0)
                    return false;
                if (type == LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NTH_LAST_OF_TYPE) {
                    std::string name = c_node_name(el);
                    int64_t total = 0;
                    for (lxb_dom_node_t* nx = el->next; nx; nx = nx->next) {
                        if (c_node_is_element(nx) && c_node_name(nx) == name)
                            ++total;
                    }
                    idx = total + 1; // 从后数位置 = 后续同类型兄弟数 + 1
                }
                return c_anb_match(anb->anb.a, anb->anb.b, idx);
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_NOT: {
                auto* list = (lxb_css_selector_list_t*)sel->u.pseudo.data;
                if (!list)
                    return true;
                return !match_any_list(list, el, depth + 1);
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_IS:
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_WHERE: {
                auto* list = (lxb_css_selector_list_t*)sel->u.pseudo.data;
                if (!list)
                    return false;
                return match_any_list(list, el, depth + 1);
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_HAS: {
                // :has(sel)：el 的后代中任一匹配
                auto* list = (lxb_css_selector_list_t*)sel->u.pseudo.data;
                if (!list)
                    return false;
                return has_descendant_match(list, el, depth + 1);
            }
            case LXB_CSS_SELECTOR_PSEUDO_CLASS_FUNCTION_LEXBOR_CONTAINS: {
                auto* c = (lxb_css_selector_contains_t*)sel->u.pseudo.data;
                if (!c)
                    return false;
                std::string needle((const char*)c->str.data, c->str.length);
                std::string hay = c_text_content(el);
                if (c->insensitive) {
                    for (auto& ch : hay)
                        ch = (char)std::tolower((unsigned char)ch);
                    for (auto& ch : needle)
                        ch = (char)std::tolower((unsigned char)ch);
                }
                return hay.find(needle) != std::string::npos;
            }
            default:
                return false;
        }
    }

    // selector list（逗号分隔）任一链匹配 el；depth 透传
    bool match_any_list(lxb_css_selector_list_t* list, lxb_dom_node_t* el,
                        int depth = 0)
    {
        if (depth > 64)
            return false;
        for (lxb_css_selector_list_t* l = list; l; l = l->next) {
            if (l->first != nullptr && match_chain(l->last, el, depth))
                return true;
        }
        return false;
    }

    // :has：el 后代（不含自身）中任一元素匹配
    bool has_descendant_match(lxb_css_selector_list_t* list, lxb_dom_node_t* el,
                              int depth = 0)
    {
        if (depth > 64)
            return false;
        for (lxb_dom_node_t* c = el->first_child; c; c = c->next) {
            if (c_node_is_element(c) &&
                (match_any_list(list, c, depth) ||
                 has_descendant_match(list, c, depth + 1)))
                return true;
        }
        return false;
    }
};

// ---------------------------------------------------------------------------
// CSS 选择器解析 + 查询（parser 生命周期覆盖 list 使用期）
// ---------------------------------------------------------------------------
// 解析选择器（含 cheerio 兼容映射）；list 归 parser 所有。
// 失败返回 nullptr——不抛 C++ 异常（本模块由裸 C 函数回调调用，异常穿
// quickjs C 栈是 UB），由调用方设置 JS exception。
inline lxb_css_parser_t* parse_selectors(const std::string& selector,
                                         lxb_css_selector_list_t** out_list)
{
    lxb_css_parser_t* parser = lxb_css_parser_create();
    if (!parser)
        return nullptr;
    lxb_status_t st = lxb_css_parser_init(parser, nullptr);
    if (st != LXB_STATUS_OK) {
        lxb_css_parser_destroy(parser, true);
        return nullptr;
    }
    std::string mapped = selector;
    // 相对选择器（css-select 特性）：以组合器开头 → 包装为 :scope <组合器> <rest>
    // （如 find('> bar') / find('+.b')）；:scope 由匹配器映射为匹配上下文
    {
        size_t b = mapped.find_first_not_of(" \t\r\n");
        if (b != std::string::npos && b < mapped.size() &&
            (mapped[b] == '>' || mapped[b] == '+' || mapped[b] == '~')) {
            mapped = ":scope " + mapped;
        }
    }
    lxb_css_selector_list_t* list = lxb_css_selectors_parse(
        parser, (const lxb_char_t*)mapped.data(), mapped.size());
    if (list == nullptr) {
        // 兼容 css-select 伪类名：:contains → :lexbor-contains；:scope 映射
        size_t pos = 0;
        while ((pos = mapped.find(":contains(", pos)) != std::string::npos) {
            mapped.replace(pos, 10, ":lexbor-contains(");
            pos += 17;
        }
        pos = 0;
        while ((pos = mapped.find(":scope", pos)) != std::string::npos) {
            mapped.replace(pos, 6, ".__lexbor_scope__");
            pos += 16;
        }
        if (mapped != selector) {
            list = lxb_css_selectors_parse(
                parser, (const lxb_char_t*)mapped.data(), mapped.size());
        }
        if (list == nullptr) {
            lxb_css_parser_destroy(parser, true);
            return nullptr;
        }
    }
    *out_list = list;
    return parser;
}

// 查询：root 后代中匹配 selector 的元素（文档序）；include_self 时 root
// 本身也参与；scope 为匹配上下文（:scope 伪类绑定，null 时用 root）。
// list 由调用方持有（parser 生命周期内）。
inline std::vector<lxb_dom_node_t*> c_query_all(lxb_dom_node_t* root,
                                                lxb_css_selector_list_t* list,
                                                bool include_self,
                                                lxb_dom_node_t* scope = nullptr)
{
    CTreeMatcher m{scope ? scope : root};
    std::vector<lxb_dom_node_t*> out;

    auto matches_any = [&](lxb_dom_node_t* el) {
        for (lxb_css_selector_list_t* l = list; l; l = l->next) {
            if (l->first != nullptr && m.match_chain(l->last, el))
                return true;
        }
        return false;
    };

    constexpr size_t kMaxNodes = 100000; // 防御（lexbor 树无环，纯保险）
    size_t visited = 0;
    std::vector<lxb_dom_node_t*> stack;
    // 子节点逆序入栈保持文档序（栈 LIFO：最后的先出）
    auto push_children = [&](lxb_dom_node_t* n) {
        size_t base = stack.size();
        for (lxb_dom_node_t* c = n->first_child; c; c = c->next)
            stack.push_back(c);
        std::reverse(stack.begin() + (ptrdiff_t)base, stack.end());
    };
    if (include_self && c_node_is_element(root) && matches_any(root))
        out.push_back(root);
    push_children(root);
    while (!stack.empty() && visited++ < kMaxNodes) {
        lxb_dom_node_t* n = stack.back();
        stack.pop_back();
        if (c_node_is_element(n) && matches_any(n))
            out.push_back(n);
        push_children(n);
    }
    return out;
}

// 完整查询：root 后代中匹配 selector 的元素（文档序）。
// 选择器无效时返回空并置 *ok=false（调用方如需抛 JS 错误自行判断）。
inline std::vector<lxb_dom_node_t*> c_query_selector(lxb_dom_node_t* root,
                                                     const std::string& selector,
                                                     bool include_self,
                                                     lxb_dom_node_t* scope,
                                                     bool* ok)
{
    lxb_css_selector_list_t* list = nullptr;
    lxb_css_parser_t* parser = parse_selectors(selector, &list);
    if (!parser) {
        if (ok)
            *ok = false;
        return {};
    }
    if (ok)
        *ok = true;
    std::vector<lxb_dom_node_t*> out =
        c_query_all(root, list, include_self, scope);
    lxb_css_parser_destroy(parser, true);
    return out;
}

} // namespace qjsbind::cheerio
