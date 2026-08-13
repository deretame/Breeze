// function.hpp —— 同步函数自动绑定
//
// 设计文档 §4：签名拆解（function_traits）、参数个数折叠（arity_info）、
// thunk 生成（JS_NewCClosure，双入口：NTTP 函数指针 / 运行期可调用对象）、
// 特殊参数（Ctx / This<T> / Opt<T> / Rest<T>）、异常边界（全捕获）。
#pragma once

#include <array>
#include <cstddef>
#include <functional>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/promise.hpp>
#include <qjsbind/value.hpp>

namespace qjs {

// ================= function_traits =================
// 主模板（lambda/仿函数）：经 operator() 提取，is_member 显式置 false
// （lambda 的 operator() 虽是成员函数指针形态，但不是"成员绑定"）
template <class T>
struct function_traits : function_traits<decltype(&T::operator())> {
    static constexpr bool is_member = false;
};

template <class R, class... A>
struct function_traits<R(A...)> {
    using result = R;
    using args = std::tuple<A...>;
    static constexpr bool is_member = false;
};
template <class R, class... A>
struct function_traits<R (*)(A...)> : function_traits<R(A...)> {};
template <class R, class... A>
struct function_traits<R (*)(A...) noexcept> : function_traits<R(A...)> {};
template <class R, class... A>
struct function_traits<R (&)(A...)> : function_traits<R(A...)> {};

// 成员函数指针：M1 提取 traits（为 M2 class 系统铺路），func() 暂拒绝
template <class C, class R, class... A>
struct function_traits<R (C::*)(A...)> : function_traits<R(A...)> {
    using class_type = C;
    static constexpr bool is_member = true;
};
template <class C, class R, class... A>
struct function_traits<R (C::*)(A...) const> : function_traits<R(A...)> {
    using class_type = C;
    static constexpr bool is_member = true;
};
template <class C, class R, class... A>
struct function_traits<R (C::*)(A...) noexcept> : function_traits<R(A...)> {
    using class_type = C;
    static constexpr bool is_member = true;
};
template <class C, class R, class... A>
struct function_traits<R (C::*)(A...) const noexcept> : function_traits<R(A...)> {
    using class_type = C;
    static constexpr bool is_member = true;
};

// ================= 特殊参数（设计文档 §3.3）=================
// 注入当前 JSContext
struct Ctx {
    JSContext* ctx;
};

// 从 this_val 取 bound class 实例（T 必须已在 per-runtime 注册表注册）
template <class T>
struct This {
    using element_type = T;
    T* ptr;
    JSValueConst js = JS_UNDEFINED; // 本次调用的 this JS 值（联动/回写场景用）
    T* operator->() const noexcept { return ptr; }
    T& operator*() const noexcept { return *ptr; }
};

// 可选尾参：有剩参则取，否则空（参数个数层面）
template <class T>
struct Opt {
    using value_type = T;
    std::optional<T> value;
    explicit operator bool() const noexcept { return value.has_value(); }
    T& operator*() { return *value; }
    const T& operator*() const { return *value; }
    T* operator->() { return &*value; }
    const T* operator->() const { return &*value; }
};

// js_convert<Opt<T>>：undefined/null → 空；否则转 T（供 ctor 可选参数等场景）
template <class T>
struct js_convert<Opt<T>> {
    static Opt<T> from_js(JSContext* ctx, JSValueConst v)
    {
        if (JS_IsUndefined(v) || JS_IsNull(v))
            return {};
        Opt<T> o;
        o.value.emplace(js_convert<T>::from_js(ctx, v));
        return o;
    }
};

// 特化：Opt<Value> 保留 null（Headers(null) 需抛 TypeError 等场景；
// undefined 仍表示"缺参"）。各 qjs_init 自行处理 null 语义。
template <>
struct js_convert<Opt<Value>> {
    static Opt<Value> from_js(JSContext* ctx, JSValueConst v)
    {
        if (JS_IsUndefined(v))
            return {};
        Opt<Value> o;
        o.value.emplace(ctx, JS_DupValue(ctx, v));
        return o;
    }
};

// 排空剩余参数
template <class T>
struct Rest {
    using value_type = T;
    std::vector<T> items;
    auto begin() { return items.begin(); }
    auto end() { return items.end(); }
    auto begin() const { return items.begin(); }
    auto end() const { return items.end(); }
    std::size_t size() const noexcept { return items.size(); }
    bool empty() const noexcept { return items.empty(); }
    const T& operator[](std::size_t i) const { return items[i]; }
    T& operator[](std::size_t i) { return items[i]; }
};

// ---- 参数分类 ----
template <class T>
struct is_ctx_param : std::is_same<T, Ctx> {};
template <class T>
struct is_this_param : std::false_type {};
template <class T>
struct is_this_param<This<T>> : std::true_type {};
template <class T>
struct is_opt_param : std::false_type {};
template <class T>
struct is_opt_param<Opt<T>> : std::true_type {};
template <class T>
struct is_rest_param : std::false_type {};
template <class T>
struct is_rest_param<Rest<T>> : std::true_type {};
template <class T>
struct is_special_param
    : std::disjunction<is_ctx_param<T>, is_this_param<T>, is_opt_param<T>, is_rest_param<T>> {};

template <class T>
struct is_string_view_param : std::is_same<T, std::string_view> {};

// 该参数是否消耗 argv 槽位（Ctx/This 不消耗）
template <class T>
inline constexpr bool consumes_argv_v =
    !is_special_param<T>::value || is_opt_param<T>::value || is_rest_param<T>::value;

// ================= arity 折叠（设计文档 §4.2）=================
template <class Tuple>
struct arity_info;

template <class... A>
struct arity_info<std::tuple<A...>> {
    static constexpr bool valid_order = [] {
        bool seen_opt_rest = false;
        constexpr std::array<bool, sizeof...(A)> opt_rest = {
            (is_opt_param<A>::value || is_rest_param<A>::value)...};
        constexpr std::array<bool, sizeof...(A)> ordinary = { (!is_special_param<A>::value)... };
        for (std::size_t i = 0; i < sizeof...(A); ++i) {
            if (opt_rest[i])
                seen_opt_rest = true;
            else if (ordinary[i] && seen_opt_rest)
                return false; // Opt/Rest 之后出现普通参数
        }
        return true;
    }();
    static_assert(valid_order, "qjs: Opt<T>/Rest<T> 必须是尾参数");

    // min = 首个 Opt/Rest 之前的普通参数个数（This/Ctx 不计）
    static constexpr std::size_t min_arity = [] {
        std::size_t n = 0;
        constexpr std::array<bool, sizeof...(A)> opt_rest = {
            (is_opt_param<A>::value || is_rest_param<A>::value)...};
        constexpr std::array<bool, sizeof...(A)> ordinary = { (!is_special_param<A>::value)... };
        for (std::size_t i = 0; i < sizeof...(A); ++i) {
            if (opt_rest[i])
                break;
            if (ordinary[i])
                ++n;
        }
        return n;
    }();

    // max = 普通 + Opt 总数；有 Rest 则无穷
    static constexpr bool max_infinite = (is_rest_param<A>::value || ...);
    static constexpr std::size_t max_arity = [] {
        if constexpr (max_infinite)
            return std::numeric_limits<std::size_t>::max();
        else {
            std::size_t n = 0;
            constexpr std::array<bool, sizeof...(A)> consumes = { consumes_argv_v<A>... };
            for (std::size_t i = 0; i < sizeof...(A); ++i)
                if (consumes[i])
                    ++n;
            return n;
        }
    }();

    // 每个参数位置的 argv 起点偏移（Ctx/This 不消耗 argv，Opt/Rest/普通消耗）
    // 例：describe(Ctx, Opt<int>, Rest<string>) 调用 describe(5,'a','b')
    //     → Opt 从 argv[0] 取（5），Rest 从 argv[1] 取（'a','b'）
    template <std::size_t... I>
    static constexpr std::array<std::size_t, sizeof...(A)> make_offsets(std::index_sequence<I...>)
    {
        std::array<std::size_t, sizeof...(A)> o{};
        std::size_t cur = 0;
        ((o[I] = cur,
             cur += consumes_argv_v<std::tuple_element_t<I, std::tuple<A...>>> ? 1 : 0),
            ...);
        return o;
    }
    static constexpr std::array<std::size_t, sizeof...(A)> offsets =
        make_offsets(std::make_index_sequence<sizeof...(A)>{});
};

// ================= 参数转换 =================
// offset：该参数在 argv 中的起点（编译期算好，见 arity_info::offsets）

// tuple 存储类型：
//   - bound class 引用参数（非 builtin）→ 保留引用（GetOpaque2 零拷贝，改值反映 JS 对象）
//   - string_view → std::string（convert_arg 返回 std::string，防悬垂）
//   - 其余（值 / builtin 引用）→ decay 值（invoke 时引用自动绑 tuple 左值）
// 注意不能用 make_tuple：它会把左值引用实参 decay 成值，丢失引用语义。
template <class A>
using tuple_storage_t = std::conditional_t<
    is_string_view_param<A>::value, std::string,
    std::conditional_t<
        std::is_lvalue_reference_v<A> && !is_builtin_convertible_v<std::decay_t<A>>, A,
        std::decay_t<A>>>;

template <class A>
decltype(auto) convert_arg(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv,
    std::size_t offset)
{
    if constexpr (std::is_same_v<A, Ctx>) {
        return Ctx{ctx};
    } else if constexpr (is_this_param<A>::value) {
        using T = typename A::element_type;
        return A{registry_of(ctx).opaque<T>(ctx, this_val), this_val};
    } else if constexpr (is_opt_param<A>::value) {
        using T = typename A::value_type;
        if (offset < static_cast<std::size_t>(argc))
            return A{js_convert<T>::from_js(ctx, argv[offset])};
        return A{std::nullopt};
    } else if constexpr (is_rest_param<A>::value) {
        using T = typename A::value_type;
        std::vector<T> out;
        for (std::size_t i = offset; i < static_cast<std::size_t>(argc); ++i)
            out.push_back(js_convert<T>::from_js(ctx, argv[i]));
        return A{std::move(out)};
    } else if constexpr (is_string_view_param<A>::value) {
        // string_view 入参：转 std::string（tuple_storage 存 std::string，生命周期由 tuple 保证）
        return js_convert<std::string>::from_js(ctx, argv[offset]);
    } else if constexpr (std::is_lvalue_reference_v<A>) {
        // 引用参数：bound class（非 builtin）→ GetOpaque2 取引用（零拷贝，改值反映 JS 对象）；
        // builtin 类型 → 按值转换（tuple 存值，invoke 时引用绑临时，帧内安全）
        using V = std::decay_t<A>;
        if constexpr (is_string_view_param<V>::value) {
            return js_convert<std::string>::from_js(ctx, argv[offset]);
        } else if constexpr (is_builtin_convertible_v<V>) {
            return js_convert<V>::from_js(ctx, argv[offset]);
        } else {
            return static_cast<A>(*registry_of(ctx).opaque<V>(ctx, argv[offset]));
        }
    } else {
        return js_convert<A>::from_js(ctx, argv[offset]);
    }
}

// ================= 调用分派（重载决议，避开 MSVC 实例化 discarded 分支）=================
// 成员（true_type）× void（true_type）四组合，全部用重载表达：
// 非成员 + void
template <class F, class... Args>
JSValue call_dispatch(F& f, std::false_type /*member*/, std::true_type /*is_void*/,
    JSContext*, JSValueConst, Args&&... args)
{
    std::invoke(f, std::forward<Args>(args)...);
    return JS_UNDEFINED;
}
// 成员 + void（this 从 this_val 注入）
template <class F, class... Args>
JSValue call_dispatch(F& f, std::true_type /*member*/, std::true_type /*is_void*/,
    JSContext* ctx, JSValueConst this_val, Args&&... args)
{
    using C = typename function_traits<std::decay_t<F>>::class_type;
    C* self = registry_of(ctx).opaque<C>(ctx, this_val);
    std::invoke(f, self, std::forward<Args>(args)...);
    return JS_UNDEFINED;
}
// 非成员 + 非 void + 非 sender
template <class R, class F, class... Args>
JSValue call_dispatch_value_impl(F& f, std::false_type /*is_sender*/, JSContext* ctx,
    Args&&... args)
{
    return js_convert<R>::to_js(ctx, std::invoke(f, std::forward<Args>(args)...));
}
// 非成员 + 非 void + sender（异步 → Promise，设计文档 §5）
template <class R, class F, class... Args>
JSValue call_dispatch_value_impl(F& f, std::true_type /*is_sender*/, JSContext* ctx,
    Args&&... args)
{
    return promise_from_sender(ctx, std::invoke(f, std::forward<Args>(args)...));
}
// 成员 + 非 void + 非 sender
template <class R, class F, class... Args>
JSValue call_dispatch_value_member(F& f, std::false_type /*is_sender*/, JSContext* ctx,
    JSValueConst this_val, Args&&... args)
{
    using C = typename function_traits<std::decay_t<F>>::class_type;
    C* self = registry_of(ctx).opaque<C>(ctx, this_val);
    return js_convert<R>::to_js(ctx, std::invoke(f, self, std::forward<Args>(args)...));
}
// 成员 + 非 void + sender
template <class R, class F, class... Args>
JSValue call_dispatch_value_member(F& f, std::true_type /*is_sender*/, JSContext* ctx,
    JSValueConst this_val, Args&&... args)
{
    using C = typename function_traits<std::decay_t<F>>::class_type;
    C* self = registry_of(ctx).opaque<C>(ctx, this_val);
    return promise_from_sender(ctx, std::invoke(f, self, std::forward<Args>(args)...));
}
// 非成员 + 非 void（按 sender 与否分派）
template <class R, class F, class... Args>
JSValue call_dispatch_value(F& f, std::false_type /*member*/, JSContext* ctx, JSValueConst,
    Args&&... args)
{
    return call_dispatch_value_impl<R>(f, std::bool_constant<stdexec::sender<R>>{}, ctx,
        std::forward<Args>(args)...);
}
// 成员 + 非 void（按 sender 与否分派）
template <class R, class F, class... Args>
JSValue call_dispatch_value(F& f, std::true_type /*member*/, JSContext* ctx,
    JSValueConst this_val, Args&&... args)
{
    return call_dispatch_value_member<R>(f, std::bool_constant<stdexec::sender<R>>{}, ctx,
        this_val, std::forward<Args>(args)...);
}

// ================= thunk 骨架（设计文档 §4.3）=================
// 铁律：C++ 异常绝不允许穿过 QuickJS 的 C 帧，出口全捕获。
template <class F>
JSValue invoke_impl(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv, F& f)
{
    using traits = function_traits<std::decay_t<F>>;
    using args_t = typename traits::args;
    using info = arity_info<args_t>;

    try {
        if (argc < static_cast<int>(info::min_arity))
            return JS_ThrowTypeError(ctx, "missing argument(s): expected at least %d",
                static_cast<int>(info::min_arity));

        auto unpack = [&]<std::size_t... I>(std::index_sequence<I...>) -> JSValue {
            // tuple 存储按参数类型定制（tuple_storage_t）：引用参数保留引用、值参数存值
            using storage = std::tuple<tuple_storage_t<std::tuple_element_t<I, args_t>>...>;
            auto tup = storage{convert_arg<std::tuple_element_t<I, args_t>>(
                ctx, this_val, argc, argv, info::offsets[I])...};
            return std::apply(
                [&](auto&&... args) -> JSValue {
                    using member_tag = std::bool_constant<traits::is_member>;
                    using void_tag = std::bool_constant<std::is_void_v<typename traits::result>>;
                    if constexpr (void_tag::value) {
                        return call_dispatch(f, member_tag{}, void_tag{}, ctx, this_val,
                            std::forward<decltype(args)>(args)...);
                    } else {
                        return call_dispatch_value<typename traits::result>(f, member_tag{}, ctx,
                            this_val, std::forward<decltype(args)>(args)...);
                    }
                },
                std::move(tup));
        };
        return unpack(std::make_index_sequence<std::tuple_size_v<args_t>>{});
    } catch (const js_error& e) {
        return JS_Throw(ctx, e.release_value());
    } catch (const type_error& e) {
        return JS_ThrowTypeError(ctx, "%s", e.what());
    } catch (const std::exception& e) {
        return JS_ThrowInternalError(ctx, "%s", e.what());
    } catch (...) {
        return JS_ThrowInternalError(ctx, "unknown C++ exception");
    }
}

// ================= 入口 A：编译期函数指针（NTTP，零间接）=================
template <auto F>
JSValue c_closure_entry(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv,
    int /*magic*/, void* /*opaque*/)
{
    // F 是 constexpr 对象（const），invoke_impl 要非 const F&——本地拷贝
    auto fn = F;
    return invoke_impl(ctx, this_val, argc, argv, fn);
}

// ================= 入口 B：运行期可调用对象 =================
template <class F>
struct closure_holder {
    F f;
};

template <class F>
JSValue c_closure_opaque(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv,
    int /*magic*/, void* opaque)
{
    auto* h = static_cast<closure_holder<F>*>(opaque);
    return invoke_impl(ctx, this_val, argc, argv, h->f);
}

template <class F>
void c_closure_finalize(void* opaque)
{
    delete static_cast<closure_holder<F>*>(opaque);
}

// ================= func() 注册入口 =================
// 入口 A：qjs::func<&add>(ctx)
template <auto F>
Function func(JSContext* ctx)
{
    using fn_t = decltype(F);
    using traits = function_traits<fn_t>;
    using info = arity_info<typename traits::args>;
    JSValue fn = JS_NewCClosure(ctx, &c_closure_entry<F>, "cpp_function", nullptr,
        static_cast<int>(info::min_arity), 0, nullptr);
    return Function(Value(ctx, fn));
}

// 入口 B：qjs::func(ctx, f, name)
template <class F>
Function func(JSContext* ctx, F&& f, std::string_view name = "cpp_function")
{
    using fn_t = std::decay_t<F>;
    using traits = function_traits<fn_t>;
    using info = arity_info<typename traits::args>;
    auto* holder = new closure_holder<fn_t>{std::forward<F>(f)};
    JSValue fn = JS_NewCClosure(ctx, &c_closure_opaque<fn_t>, std::string(name).c_str(),
        &c_closure_finalize<fn_t>, static_cast<int>(info::min_arity), 0, holder);
    return Function(Value(ctx, fn));
}

// ================= Object::set（声明见 value.hpp）=================
// 可调用对象自动走 func() 包装（设计文档 §4.4）
// 注意：不能用 is_invocable_v<D> 检测——它对「无参调用」求值，
// 带参数的函数指针会误判为 false。改为「函数类型 || 有 operator()」。
template <class T>
void Object::set(std::string_view name, T&& v)
{
    using D = std::decay_t<T>;
    std::string n(name);
    if constexpr (std::is_function_v<std::remove_pointer_t<D>> || requires { &D::operator(); }) {
        Function fn = func(ctx(), std::forward<T>(v), n);
        JS_SetPropertyStr(ctx(), raw(), n.c_str(), fn.take());
    } else {
        JSValue jv = js_convert<D>::to_js(ctx(), v);
        JS_SetPropertyStr(ctx(), raw(), n.c_str(), jv);
    }
}

// ================= Function::call（声明见 value.hpp）=================
template <class... Args>
Value Function::call(Args&&... args) const
{
    JSValue argv[sizeof...(Args)] = {
        js_convert<std::decay_t<Args>>::to_js(ctx(), std::forward<Args>(args))...};
    JSValue r = JS_Call(ctx(), raw(), JS_UNDEFINED, static_cast<int>(sizeof...(Args)), argv);
    for (auto& a : argv)
        JS_FreeValue(ctx(), a);
    if (JS_IsException(r)) {
        // JS_Call 返回 JS_EXCEPTION 只是 tag：真正的错误对象在 current_exception，
        // 取走交给 js_error（否则 JS_Throw(JS_EXCEPTION) 会丢掉真错误）
        throw js_error(ctx(), JS_GetException(ctx()));
    }
    return Value(ctx(), r);
}

} // namespace qjs
