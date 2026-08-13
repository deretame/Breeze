// qjsbind::web —— DOMException（Web IDL 语义：message/name/code）
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/context.hpp>

#include <string>
#include <unordered_map>

namespace qjsbind::web {

// DOMException code 映射（Web IDL 固定表）
inline int dom_exception_code(const std::string& name) {
    static const std::unordered_map<std::string, int> codes = {
        {"IndexSizeError", 1},         {"HierarchyRequestError", 3},
        {"WrongDocumentError", 4},     {"InvalidCharacterError", 5},
        {"NoModificationAllowedError", 7}, {"NotFoundError", 8},
        {"NotSupportedError", 9},      {"InUseAttributeError", 10},
        {"InvalidStateError", 11},     {"SyntaxError", 12},
        {"InvalidModificationError", 13}, {"NamespaceError", 14},
        {"InvalidAccessError", 15},    {"TypeMismatchError", 17},
        {"SecurityError", 18},         {"NetworkError", 19},
        {"AbortError", 20},            {"URLMismatchError", 21},
        {"QuotaExceededError", 22},    {"TimeoutError", 23},
        {"InvalidNodeTypeError", 24},  {"DataCloneError", 25},
    };
    const auto it = codes.find(name);
    return it == codes.end() ? 0 : it->second;
}

struct DomException {
    std::string message;
    std::string name;

    void qjs_init(JSContext*, qjs::Opt<std::string> msg, qjs::Opt<std::string> n) {
        if (msg)
            message = *msg;
        if (n)
            name = *n;
    }
    int code() const { return dom_exception_code(name); }
};

// new DOMException(message?, name?)；错误码按 name 自动映射。
inline void install_dom_exception(qjs::Context& ctx) {
    auto cls = qjs::class_<DomException>(ctx, "DOMException")
                   .constructor<qjs::Opt<std::string>, qjs::Opt<std::string>>()
                   .getter("message", [](qjs::This<DomException> self) { return self->message; })
                   .getter("name", [](qjs::This<DomException> self) { return self->name; })
                   .getter("code", [](qjs::This<DomException> self) { return self->code(); });
    ctx.globals().set("DOMException", cls.constructor_function());
}

} // namespace qjsbind::web
