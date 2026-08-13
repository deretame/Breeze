// value.hpp —— JSValue 的 RAII 封装（Value / Object / Array / Function / Persistent）
//
// 所有权规则照 quickjs.h:203-227 注释：
//   JSValue 参数 = 移交；JSValueConst = 借用；返回值 = 调用方负责 free。
// Value 持有「已 dup/新建」的 JSValue，析构时 JS_FreeValue。
#pragma once

#include <cstddef>
#include <string>
#include <string_view>
#include <utility>

#include <quickjs.h>

namespace qjs {

class Value {
public:
    // 默认构造：空（无 ctx），不持有任何值
    Value() = default;
    // 接管所有权（JSValue 参数 = 移交）
    explicit Value(JSContext* ctx, JSValue v) : ctx_(ctx), v_(v) {}
    Value(const Value& o) : ctx_(o.ctx_), v_(o.ctx_ ? JS_DupValue(o.ctx_, o.v_) : JS_UNDEFINED) {}
    Value(Value&& o) noexcept : ctx_(o.ctx_), v_(o.v_)
    {
        o.ctx_ = nullptr;
        o.v_ = JS_UNDEFINED;
    }
    Value& operator=(const Value& o)
    {
        if (this != &o) {
            Value tmp(o);
            swap(tmp);
        }
        return *this;
    }
    Value& operator=(Value&& o) noexcept
    {
        Value tmp(std::move(o));
        swap(tmp);
        return *this;
    }
    ~Value()
    {
        if (ctx_)
            JS_FreeValue(ctx_, v_);
    }

    JSContext* ctx() const noexcept { return ctx_; }
    JSValue raw() const noexcept { return v_; }
    explicit operator bool() const noexcept { return ctx_ != nullptr; }

    // 转移底层 JSValue 所有权给调用方（此后本对象为空）
    JSValue take() noexcept
    {
        JSValue v = v_;
        ctx_ = nullptr;
        v_ = JS_UNDEFINED;
        return v;
    }

    // ---- 类型谓词 ----
    bool is_exception() const noexcept { return ctx_ && JS_IsException(v_); }
    bool is_undefined() const noexcept { return ctx_ && JS_IsUndefined(v_); }
    bool is_null() const noexcept { return ctx_ && JS_IsNull(v_); }
    bool is_bool() const noexcept { return ctx_ && JS_IsBool(v_); }
    bool is_number() const noexcept { return ctx_ && JS_IsNumber(v_); }
    bool is_string() const noexcept { return ctx_ && JS_IsString(v_); }
    bool is_object() const noexcept { return ctx_ && JS_IsObject(v_); }
    bool is_array() const noexcept { return ctx_ && JS_IsArray(v_); }
    bool is_function() const noexcept { return ctx_ && JS_IsFunction(ctx_, v_); }
    bool is_promise() const noexcept { return ctx_ && JS_IsPromise(v_); }
    // 二进制类型谓词（quickjs-ng 原生判断的成员化包装）
    bool is_array_buffer() const noexcept { return ctx_ && JS_IsArrayBuffer(v_); }
    bool is_data_view() const noexcept { return ctx_ && JS_IsDataView(v_); }
    // 任意 TypedArray（含 BigInt 变体）：JS_GetTypedArrayType >= 0
    bool is_typed_array() const noexcept
    {
        return ctx_ && JS_GetTypedArrayType(v_) >= 0;
    }

    // 转换入口（依赖 js_convert<T>，定义见 convert.hpp；使用处需包含 qjsbind.hpp）
    template <class T>
    bool is() const;
    template <class T>
    T as() const;

private:
    void swap(Value& o) noexcept
    {
        std::swap(ctx_, o.ctx_);
        std::swap(v_, o.v_);
    }

    JSContext* ctx_ = nullptr;
    JSValue v_ = JS_UNDEFINED;
};

class Object : public Value {
public:
    using Value::Value;
    Object(Value v) : Value(std::move(v)) {}

    Value get(std::string_view name) const;
    // 可调用对象自动走 func() 包装（§4.4），定义见 function.hpp
    template <class T>
    void set(std::string_view name, T&& v);
};

class Array : public Value {
public:
    using Value::Value;
    Array(Value v) : Value(std::move(v)) {}

    Value get(std::size_t index) const
    {
        return Value(ctx(), JS_GetPropertyUint32(ctx(), raw(), static_cast<uint32_t>(index)));
    }
    void set(std::size_t index, Value v)
    {
        JS_SetPropertyUint32(ctx(), raw(), static_cast<uint32_t>(index), v.take());
    }
    std::size_t length() const
    {
        Value len = Value(ctx(), JS_GetPropertyStr(ctx(), raw(), "length"));
        uint32_t n = 0;
        JS_ToUint32(ctx(), &n, len.raw());
        return n;
    }
};

class Function : public Value {
public:
    using Value::Value;
    Function(Value v) : Value(std::move(v)) {}

    // 可变参数调用（参数自动 js_convert 转 JSValue），定义见 function.hpp
    template <class... Args>
    Value call(Args&&... args) const;
    // 原生调用（argv 借用）
    Value call_raw(int argc, JSValueConst* argv, JSValueConst this_val = JS_UNDEFINED) const
    {
        return Value(ctx(), JS_Call(ctx(), raw(), this_val, argc, argv));
    }
};

// Persistent<T>：移动语义持有（拷贝被禁用——拷贝不 dup 是 rquickjs 的语义，
// M1 用 move-only 表达"唯一所有权"）。
template <class T>
class Persistent {
public:
    explicit Persistent(T v) : v_(std::move(v)) {}
    Persistent(const Persistent&) = delete;
    Persistent& operator=(const Persistent&) = delete;
    Persistent(Persistent&&) noexcept = default;
    Persistent& operator=(Persistent&&) noexcept = default;

    const T& get() const noexcept { return v_; }
    T& get() noexcept { return v_; }
    T& operator*() noexcept { return v_; }
    const T& operator*() const noexcept { return v_; }

private:
    T v_;
};

} // namespace qjs
