// convert.hpp —— js_convert<T>：C++ 类型 ⇄ JSValue
//
// 主模板未定义（static_assert 报错）= 该类型不可转换；
// 每个特化提供 to_js / from_js，from_js 失败抛 qjs::type_error。
#pragma once

#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <qjsbind/context.hpp> // Context 成员方法定义（context.hpp 不包含本头，无循环）
#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>

namespace qjs {

// is_optional 检测辅助（供 Value::is 使用，须在使用点之前声明）
template <class T>
struct is_optional : std::false_type {};
template <class T>
struct is_optional<std::optional<T>> : std::true_type {};
template <class T>
inline constexpr bool is_optional_v = is_optional<T>::value;

// Object::get 定义（声明见 value.hpp）
inline Value Object::get(std::string_view name) const
{
    std::string n(name);
    return Value(ctx(), JS_GetPropertyStr(ctx(), raw(), n.c_str()));
}

// ================= js_convert<T> 主模板 =================
template <class T, class Enable = void>
struct js_convert {
    // 主模板成员用 = delete：只在真正调用时（惰性）报错，错误信息指向可读注释
    static JSValue to_js(JSContext*, const T&) = delete;
    static T from_js(JSContext*, JSValueConst) = delete;
};

// 自由函数形式
template <class T>
JSValue to_js(JSContext* ctx, const T& v)
{
    return js_convert<T>::to_js(ctx, v);
}
template <class T>
T from_js(JSContext* ctx, JSValueConst v)
{
    return js_convert<T>::from_js(ctx, v);
}

// ================= bool =================
template <>
struct js_convert<bool> {
    static JSValue to_js(JSContext* ctx, bool v) { return JS_NewBool(ctx, v); }
    static bool from_js(JSContext* ctx, JSValueConst v)
    {
        int r = JS_ToBool(ctx, v);
        if (r < 0)
            throw_type_error(ctx, "expected boolean");
        return r != 0;
    }
};

// ================= 数值 =================
template <>
struct js_convert<int32_t> {
    static JSValue to_js(JSContext* ctx, int32_t v) { return JS_NewInt32(ctx, v); }
    static int32_t from_js(JSContext* ctx, JSValueConst v)
    {
        int32_t r = 0;
        if (JS_ToInt32(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected int32");
        return r;
    }
};

// 原生整数（int/long/long long 等）在 MSVC 下与 int32_t/uint32_t/int64_t 同型，
// 由上述特化覆盖，无需重复定义（其他平台如 LP64 需按需补充）。

template <>
struct js_convert<uint32_t> {
    static JSValue to_js(JSContext* ctx, uint32_t v) { return JS_NewInt32(ctx, static_cast<int32_t>(v)); }
    static uint32_t from_js(JSContext* ctx, JSValueConst v)
    {
        uint32_t r = 0;
        if (JS_ToUint32(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected uint32");
        return r;
    }
};

template <>
struct js_convert<int64_t> {
    static JSValue to_js(JSContext* ctx, int64_t v) { return JS_NewInt64(ctx, v); }
    static int64_t from_js(JSContext* ctx, JSValueConst v)
    {
        int64_t r = 0;
        if (JS_ToInt64(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected int64");
        return r;
    }
};

// uint64_t：MSVC 下是 unsigned long long，与 int64_t 特化不匹配，需独立特化
template <>
struct js_convert<uint64_t> {
    static JSValue to_js(JSContext* ctx, uint64_t v) { return JS_NewBigInt64(ctx, static_cast<int64_t>(v)); }
    static uint64_t from_js(JSContext* ctx, JSValueConst v)
    {
        int64_t r = 0;
        if (JS_ToInt64(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected uint64");
        return static_cast<uint64_t>(r);
    }
};

template <>
struct js_convert<double> {
    static JSValue to_js(JSContext* ctx, double v) { return JS_NewFloat64(ctx, v); }
    static double from_js(JSContext* ctx, JSValueConst v)
    {
        double r = 0;
        if (JS_ToFloat64(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected number");
        return r;
    }
};

template <>
struct js_convert<float> {
    static JSValue to_js(JSContext* ctx, float v) { return JS_NewFloat64(ctx, static_cast<double>(v)); }
    static float from_js(JSContext* ctx, JSValueConst v)
    {
        double r = 0;
        if (JS_ToFloat64(ctx, &r, v) < 0)
            throw_type_error(ctx, "expected number");
        return static_cast<float>(r);
    }
};

// ================= 字符串 =================
template <>
struct js_convert<std::string> {
    static JSValue to_js(JSContext* ctx, const std::string& v)
    {
        return JS_NewStringLen(ctx, v.data(), v.size());
    }
    static std::string from_js(JSContext* ctx, JSValueConst v)
    {
        size_t len = 0;
        const char* s = JS_ToCStringLen2(ctx, &len, v, false);
        if (!s)
            throw_type_error(ctx, "expected string");
        std::string out(s, len);
        JS_FreeCString(ctx, s);
        return out;
    }
};

// const char* / char*：只支持 to_js（返回侧），入参请用 std::string（悬垂风险，设计文档 §3.1）
// 注意：显式特化的成员函数体是普通代码（非惰性），禁止入参只能用 = delete 表达
template <>
struct js_convert<const char*> {
    static JSValue to_js(JSContext* ctx, const char* v) { return JS_NewString(ctx, v); }
    static const char* from_js(JSContext*, JSValueConst) = delete; // 入参悬垂，请用 std::string
};
template <>
struct js_convert<char*> {
    static JSValue to_js(JSContext* ctx, char* v) { return JS_NewString(ctx, v); }
    static char* from_js(JSContext*, JSValueConst) = delete; // 入参悬垂，请用 std::string
};

// std::string_view：to_js 直接引用（帧内拷贝）；from_js 由 thunk 特化处理
// （转 std::string 临时并提升生命周期，见 function.hpp 的 convert_arg）
template <>
struct js_convert<std::string_view> {
    static JSValue to_js(JSContext* ctx, std::string_view v)
    {
        return JS_NewStringLen(ctx, v.data(), v.size());
    }
    static std::string_view from_js(JSContext*, JSValueConst) =
        delete; // 由 thunk 的 convert_arg 特化处理，不要直接调用
};

// ================= void =================
template <>
struct js_convert<void> {
    static JSValue to_js(JSContext*) { return JS_UNDEFINED; }
};

// ================= std::optional<T> =================
template <class T>
struct js_convert<std::optional<T>> {
    static JSValue to_js(JSContext* ctx, const std::optional<T>& v)
    {
        if (!v)
            return JS_NULL;
        return js_convert<T>::to_js(ctx, *v);
    }
    static std::optional<T> from_js(JSContext* ctx, JSValueConst v)
    {
        if (JS_IsNull(v) || JS_IsUndefined(v))
            return std::nullopt;
        return js_convert<T>::from_js(ctx, v);
    }
};

// ================= std::vector<T> =================
template <class T>
struct js_convert<std::vector<T>> {
    static JSValue to_js(JSContext* ctx, const std::vector<T>& v)
    {
        JSValue arr = JS_NewArray(ctx);
        for (size_t i = 0; i < v.size(); ++i)
            JS_SetPropertyUint32(ctx, arr, static_cast<uint32_t>(i),
                js_convert<T>::to_js(ctx, v[i]));
        return arr;
    }
    static std::vector<T> from_js(JSContext* ctx, JSValueConst v)
    {
        if (!JS_IsArray(v))
            throw_type_error(ctx, "expected array");
        uint32_t len = 0;
        {
            Value lenv(ctx, JS_GetPropertyStr(ctx, v, "length"));
            if (JS_ToUint32(ctx, &len, lenv.raw()) < 0)
                throw_type_error(ctx, "invalid array length");
        }
        std::vector<T> out;
        out.reserve(len);
        for (uint32_t i = 0; i < len; ++i)
            out.push_back(elem_from<T>(ctx, v, i));
        return out;
    }

private:
    template <class U>
    static U elem_from(JSContext* ctx, JSValueConst arr, uint32_t i)
    {
        JSValue e = JS_GetPropertyUint32(ctx, arr, i);
        try {
            U out = js_convert<U>::from_js(ctx, e);
            JS_FreeValue(ctx, e);
            return out;
        } catch (...) {
            JS_FreeValue(ctx, e);
            throw;
        }
    }
};

// ================= map / unordered_map =================
template <class T>
struct js_convert<std::map<std::string, T>> {
    static JSValue to_js(JSContext* ctx, const std::map<std::string, T>& v)
    {
        JSValue obj = JS_NewObject(ctx);
        for (const auto& [k, val] : v)
            JS_SetPropertyStr(ctx, obj, k.c_str(), js_convert<T>::to_js(ctx, val));
        return obj;
    }
    static std::map<std::string, T> from_js(JSContext* ctx, JSValueConst v)
    {
        if (!JS_IsObject(v))
            throw_type_error(ctx, "expected object");
        JSPropertyEnum* tab = nullptr;
        uint32_t len = 0;
        if (JS_GetOwnPropertyNames(ctx, &tab, &len, v, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) < 0)
            throw_type_error(ctx, "failed to enumerate object");
        std::map<std::string, T> out;
        for (uint32_t i = 0; i < len; ++i) {
            size_t klen = 0;
            const char* ks = JS_AtomToCStringLen(ctx, &klen, tab[i].atom);
            std::string key = ks ? std::string(ks, klen) : std::string();
            if (ks)
                JS_FreeCString(ctx, ks);
            JSValue val = JS_GetProperty(ctx, v, tab[i].atom);
            try {
                out.emplace(std::move(key), js_convert<T>::from_js(ctx, val));
                JS_FreeValue(ctx, val);
            } catch (...) {
                JS_FreeValue(ctx, val);
                throw;
            }
        }
        JS_FreePropertyEnum(ctx, tab, len);
        return out;
    }
};

template <class T>
struct js_convert<std::unordered_map<std::string, T>> {
    static JSValue to_js(JSContext* ctx, const std::unordered_map<std::string, T>& v)
    {
        JSValue obj = JS_NewObject(ctx);
        for (const auto& [k, val] : v)
            JS_SetPropertyStr(ctx, obj, k.c_str(), js_convert<T>::to_js(ctx, val));
        return obj;
    }
    static std::unordered_map<std::string, T> from_js(JSContext* ctx, JSValueConst v)
    {
        auto m = js_convert<std::map<std::string, T>>::from_js(ctx, v);
        return std::unordered_map<std::string, T>(m.begin(), m.end());
    }
};

// ================= std::tuple<...> =================
template <class... Ts>
struct js_convert<std::tuple<Ts...>> {
    static JSValue to_js(JSContext* ctx, const std::tuple<Ts...>& t)
    {
        JSValue arr = JS_NewArray(ctx);
        std::apply(
            [&](const auto&... elems) {
                std::size_t i = 0;
                (JS_SetPropertyUint32(ctx, arr, static_cast<uint32_t>(i++),
                     js_convert<std::decay_t<decltype(elems)>>::to_js(ctx, elems)),
                    ...);
            },
            t);
        return arr;
    }
    static std::tuple<Ts...> from_js(JSContext* ctx, JSValueConst v)
    {
        if (!JS_IsArray(v))
            throw_type_error(ctx, "expected array");
        uint32_t len = 0;
        {
            Value lenv(ctx, JS_GetPropertyStr(ctx, v, "length"));
            if (JS_ToUint32(ctx, &len, lenv.raw()) < 0)
                throw_type_error(ctx, "invalid array length");
        }
        if (len != sizeof...(Ts))
            throw_type_error(ctx, "tuple arity mismatch");
        return from_impl(ctx, v, std::index_sequence_for<Ts...>{});
    }

private:
    template <std::size_t... I>
    static std::tuple<Ts...> from_impl(JSContext* ctx, JSValueConst arr, std::index_sequence<I...>)
    {
        return std::make_tuple(elem_from<Ts>(ctx, arr, static_cast<uint32_t>(I))...);
    }

    template <class U>
    static U elem_from(JSContext* ctx, JSValueConst arr, uint32_t i)
    {
        JSValue e = JS_GetPropertyUint32(ctx, arr, i);
        try {
            U out = js_convert<U>::from_js(ctx, e);
            JS_FreeValue(ctx, e);
            return out;
        } catch (...) {
            JS_FreeValue(ctx, e);
            throw;
        }
    }
};

// ================= qjs::Value 逃生舱 =================
template <>
struct js_convert<Value> {
    static JSValue to_js(JSContext* ctx, const Value& v) { return JS_DupValue(ctx, v.raw()); }
    static Value from_js(JSContext* ctx, JSValueConst v) { return Value(ctx, JS_DupValue(ctx, v)); }
};

// Value 子类：与 Value 同规则（dup 往返）
template <>
struct js_convert<Object> {
    static JSValue to_js(JSContext* ctx, const Object& v) { return JS_DupValue(ctx, v.raw()); }
    static Object from_js(JSContext* ctx, JSValueConst v)
    {
        return Object(Value(ctx, JS_DupValue(ctx, v)));
    }
};
template <>
struct js_convert<Array> {
    static JSValue to_js(JSContext* ctx, const Array& v) { return JS_DupValue(ctx, v.raw()); }
    static Array from_js(JSContext* ctx, JSValueConst v)
    {
        return Array(Value(ctx, JS_DupValue(ctx, v)));
    }
};
template <>
struct js_convert<Function> {
    static JSValue to_js(JSContext* ctx, const Function& v) { return JS_DupValue(ctx, v.raw()); }
    static Function from_js(JSContext* ctx, JSValueConst v)
    {
        // 回调逃生舱（设计文档 §0/§3）：校验是函数，非函数 → TypeError
        if (!JS_IsFunction(ctx, v))
            throw_type_error(ctx, "expected a function");
        return Function(Value(ctx, JS_DupValue(ctx, v)));
    }
};

// ================= Value::is / as（声明见 value.hpp）=================
template <class T>
bool Value::is() const
{
    if (!ctx_)
        return false;
    if constexpr (std::is_same_v<T, bool>)
        return is_bool();
    else if constexpr (std::is_arithmetic_v<T>)
        return is_number();
    else if constexpr (std::is_same_v<T, std::string> || std::is_same_v<T, std::string_view> ||
                       std::is_same_v<T, const char*>)
        return is_string();
    else if constexpr (std::is_same_v<T, Value> || std::is_same_v<T, Object> ||
                       std::is_same_v<T, Array> || std::is_same_v<T, Function>)
        return is_object();
    else if constexpr (is_optional_v<T>)
        return is_null() || is_undefined() || Value(ctx(), JS_DupValue(ctx(), v_)).is<typename T::value_type>();
    else
        return is_object();
}

template <class T>
T Value::as() const
{
    if (!ctx_)
        throw type_error("qjs::Value is empty");
    return js_convert<T>::from_js(ctx_, v_);
}

// ================= is_builtin_convertible =================
// 已有显式特化的类型集合：js_convert<T> 的 bound class 值特化（class.hpp）用它排除，
// convert_arg 的引用参数分支也用它区分「按值」与「取引用」。
// 算术类型（bool/整数/浮点，含原生 int/long/long long——MSVC 下与 int32_t/int64_t 同型）
// 默认 builtin，无需逐个特化。
template <class T>
struct is_builtin_convertible : std::bool_constant<std::is_arithmetic_v<T>> {};
template <>
struct is_builtin_convertible<std::string> : std::true_type {};
template <>
struct is_builtin_convertible<const char*> : std::true_type {};
template <>
struct is_builtin_convertible<char*> : std::true_type {};
template <>
struct is_builtin_convertible<std::string_view> : std::true_type {};
template <>
struct is_builtin_convertible<void> : std::true_type {};
template <>
struct is_builtin_convertible<Value> : std::true_type {};
template <>
struct is_builtin_convertible<Object> : std::true_type {};
template <>
struct is_builtin_convertible<Array> : std::true_type {};
template <>
struct is_builtin_convertible<Function> : std::true_type {};
template <class T>
struct is_builtin_convertible<std::optional<T>> : std::true_type {};
template <class T>
struct is_builtin_convertible<std::vector<T>> : std::true_type {};
template <class K, class V>
struct is_builtin_convertible<std::map<K, V>> : std::true_type {};
template <class K, class V>
struct is_builtin_convertible<std::unordered_map<K, V>> : std::true_type {};
template <class... Ts>
struct is_builtin_convertible<std::tuple<Ts...>> : std::true_type {};
template <class T>
inline constexpr bool is_builtin_convertible_v = is_builtin_convertible<T>::value;

// ================= Context::to_js / from_js（声明见 context.hpp） =================
// js_convert<T> 的门面：业务代码直接 ctx.to_js(v) / ctx.from_js<T>(v)，不再碰
// 自由函数与 JSContext* 参数。定义在文件末尾：模板实例化时自由函数已可见。
template <class T>
Value Context::to_js(const T& v) const
{
    return Value(ctx_, qjs::to_js(ctx_, v));
}
template <class T>
T Context::from_js(JSValueConst v) const
{
    return qjs::from_js<T>(ctx_, v);
}

} // namespace qjs
