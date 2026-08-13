// qjsbind::web —— TextEncoder / TextDecoder（UTF-8）
//
// 注意：不能直接用 JS_ToCString 做 encode —— quickjs-ng 对孤立代理不做替换
//（保留 CESU-8 风格编码），与 TextEncoder 规范（→ U+FFFD）不符。
// 正确路径：JS_ToCStringLenUTF16 取 UTF-16 单元 → utf16_to_utf8。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/web/errors.hpp>
#include <qjsbind/web/utf8.hpp>

#include <string>

namespace qjsbind::web {

struct TextEncoderImpl {
    std::string encoding() const { return "utf-8"; }
};

struct TextDecoderImpl {
    bool fatal = false;
    bool ignore_bom = false;

    std::string encoding() const { return "utf-8"; }

    // 构造 options：{fatal, ignoreBOM}（decode() 的 options 参数在方法内另读）
    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> options) {
        if (options && options->is_object()) {
            qjs::Object obj(*options);
            qjs::Value fatal = obj.get("fatal");
            if (!fatal.is_undefined())
                this->fatal = fatal.as<bool>();
            qjs::Value ignore_bom = obj.get("ignoreBOM");
            if (!ignore_bom.is_undefined())
                this->ignore_bom = ignore_bom.as<bool>();
        }
    }
};

// 从 JS 值提取字节（TypedArray/ArrayBuffer/DataView → 拷贝；其他 → TypeError）
// 转发到 qjs::Context::js_bytes（值语义 + detached/resize 守卫）
inline std::string js_bytes_from(JSContext* ctx, JSValueConst v) {
    std::vector<std::byte> b = qjs::Context(ctx).js_bytes(v);
    return std::string(reinterpret_cast<const char*>(b.data()), b.size());
}

inline void install_text_encoder(qjs::Context& ctx) {
    auto cls = qjs::class_<TextEncoderImpl>(ctx, "TextEncoder")
                   .constructor<>()
                   .getter("encoding", [](qjs::This<TextEncoderImpl> self) { return self->encoding(); })
                   .method("encode",
                [](qjs::Ctx ctx, qjs::This<TextEncoderImpl>, qjs::Value input) -> qjs::Value {
                    // Context 成员：js_utf8（JS_ToCStringLenUTF16 内部做 ToString
                    // 转换，含非字符串参数；UTF-16 → UTF-8 值语义）
                    qjs::Context cx(ctx.ctx);
                    auto utf8 = cx.js_utf8(input.raw());
                    if (!utf8)
                        throw qjs::js_error(ctx.ctx, JS_GetException(ctx.ctx));
                    return cx.new_uint8_array(
                        reinterpret_cast<const std::byte*>(utf8->data()), utf8->size());
                });
    ctx.globals().set("TextEncoder", cls.constructor_function());
}

inline void install_text_decoder(qjs::Context& ctx) {
    auto cls = qjs::class_<TextDecoderImpl>(ctx, "TextDecoder")
                   .constructor<qjs::Opt<qjs::Value>>()
                   .getter("encoding", [](qjs::This<TextDecoderImpl> self) { return self->encoding(); })
                   .method("decode",
                [](qjs::Ctx ctx, qjs::This<TextDecoderImpl> self, qjs::Opt<qjs::Value> input,
                   qjs::Opt<qjs::Value> options) -> std::string {
                    if (options && options->is_object()) {
                        qjs::Object obj(*options);
                        qjs::Value fatal = obj.get("fatal");
                        if (!fatal.is_undefined())
                            self->fatal = fatal.as<bool>();
                        qjs::Value ignore_bom = obj.get("ignoreBOM");
                        if (!ignore_bom.is_undefined())
                            self->ignore_bom = ignore_bom.as<bool>();
                    }
                    if (!input || input->is_undefined() || input->is_null())
                        return {};
                    std::string bytes = js_bytes_from(ctx.ctx, input->raw());
                    // 规范：decode() 默认剥离 UTF-8 BOM；ignoreBOM: true 时保留
                    if (!self->ignore_bom && bytes.size() >= 3 &&
                        static_cast<uint8_t>(bytes[0]) == 0xEF &&
                        static_cast<uint8_t>(bytes[1]) == 0xBB &&
                        static_cast<uint8_t>(bytes[2]) == 0xBF)
                        bytes.erase(0, 3);
                    return bytes_to_valid_utf8(bytes);
                });
    ctx.globals().set("TextDecoder", cls.constructor_function());
}

} // namespace qjsbind::web
