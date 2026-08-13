// class.hpp —— 类自动绑定：class_<T> 链式 DSL（设计文档 §6）
//
// 支持：constructor / method（成员函数指针或自由函数+This<T>糖）/
//       static_method / field / field_readonly / getter / setter。
// 所有权：JS 侧持有（opaque = new T，finalizer = delete）。
#pragma once

#include <cstddef>
#include <string>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <utility>

#include <quickjs.h>

#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/function.hpp>
#include <qjsbind/value.hpp>

namespace qjs {

// ---- js_convert<T>：bound class 值语义（非 builtin 类型走这里）----
// to_js：拷贝包装成 JS 实例（new T(v) 进 opaque）；from_js：GetOpaque2 取引用后拷贝。
// 运行期校验 T 已注册（须先 class_<T> 注册）。Opt<T> 排除（有专属特化，见 function.hpp）。
template <class T>
struct js_convert<T, std::enable_if_t<!is_builtin_convertible_v<T> && !is_opt_param<T>::value>> {
    static JSValue to_js(JSContext* ctx, const T& v)
    {
        JSClassID id = registry_of(ctx).id_of<T>(ctx);
        JSValue proto = JS_GetClassProto(ctx, id);
        JSValue obj = JS_NewObjectProtoClass(ctx, proto, id);
        JS_FreeValue(ctx, proto);
        if (JS_IsException(obj)) {
            // JS_EXCEPTION 只是返回 tag，真错误在 current_exception——取走交给 js_error
            throw js_error(ctx, JS_GetException(ctx));
        }
        JS_SetOpaque(obj, new T(v));
        return obj;
    }
    static T from_js(JSContext* ctx, JSValueConst v)
    {
        return *registry_of(ctx).opaque<T>(ctx, v); // 拷贝构造（T 需可拷贝）
    }
};

// ---- 构造器 thunk（JS_CFUNC_constructor：this_val 实为 new_target）----
namespace detail {

template <class T, class... Args, std::size_t... I>
JSValue ctor_impl(JSContext* ctx, JSValueConst new_target, int argc, JSValueConst* argv,
    std::index_sequence<I...>)
{
    try {
        // 最小必需参数 = 非 Opt 的普通参数个数；不足的槽位补 JS_UNDEFINED
        constexpr std::size_t min_args = ((!is_opt_param<Args>::value) + ... + 0);
        if (argc < static_cast<int>(min_args))
            return JS_ThrowTypeError(ctx, "missing argument(s): expected %d",
                static_cast<int>(min_args));
        auto get_arg = [&](std::size_t i) -> JSValueConst {
            return i < static_cast<std::size_t>(argc) ? argv[i] : JS_UNDEFINED;
        };

        // 参数包（Opt 槽位已补 undefined）
        auto tup = std::make_tuple(js_convert<Args>::from_js(ctx, get_arg(I))...);

        // 1. 构造 T：
        //    - 有 qjs_init 扩展点 → 默认构造 + qjs_init(ctx, args...)（init 参数转换）
        //    - 否则 → new T(args...)
        T* ptr = nullptr;
        if constexpr (requires(JSContext* c, T& t, Args&... a) { t.qjs_init(c, a...); }) {
            ptr = new T();
            std::apply([&](auto&... a) { ptr->qjs_init(ctx, a...); }, tup);
        } else {
            ptr = std::apply(
                [](auto&&... a) { return new T(std::forward<decltype(a)>(a)...); },
                std::move(tup));
        }

        // 2. prototype：new_target.prototype（支持 extends）失败回退 class proto
        JSClassID id = registry_of(ctx).id_of<T>(ctx);
        JSValue proto = JS_GetPropertyStr(ctx, new_target, "prototype");
        if (JS_IsException(proto) || !JS_IsObject(proto)) {
            if (!JS_IsException(proto))
                JS_FreeValue(ctx, proto);
            proto = JS_GetClassProto(ctx, id);
        }

        // 3. 建实例 + 挂 opaque
        JSValue obj = JS_NewObjectProtoClass(ctx, proto, id);
        JS_FreeValue(ctx, proto);
        if (JS_IsException(obj)) {
            delete ptr;
            throw js_error(ctx, JS_GetException(ctx));
        }
        JS_SetOpaque(obj, ptr);
        return obj;
    } catch (const js_error& e) {
        return JS_Throw(ctx, e.release_value());
    } catch (const type_error& e) {
        return JS_ThrowTypeError(ctx, "%s", e.what());
    } catch (const std::exception& e) {
        return JS_ThrowInternalError(ctx, "%s", e.what());
    } catch (...) {
        return JS_ThrowInternalError(ctx, "unknown C++ exception in constructor");
    }
}

template <class T, class... Args>
JSValue ctor_thunk(JSContext* ctx, JSValueConst new_target, int argc, JSValueConst* argv)
{
    return ctor_impl<T, Args...>(ctx, new_target, argc, argv,
        std::index_sequence_for<Args...>{});
}

} // namespace detail

// ---- class_<T> 链式 DSL ----
template <class T>
class class_ {
public:
    class_(Context ctx, std::string_view name)
        : ctx_(ctx.raw())
        , class_id_(ctx.registry().ensure<T>(ctx.raw(), std::string(name).c_str()))
        , name_(name)
        , proto_(Value(ctx.raw(), JS_NewObject(ctx.raw())))
    {
        // JS_SetClassProto 是 set_value 转移语义（不 dup，quickjs.c:2579）——
        // 必须 dup 传入，class_ 的 proto_ 才能在析构时安全 free
        JS_SetClassProto(ctx_, class_id_, JS_DupValue(ctx_, proto_.raw()));
    }

    // 构造器：qjs::class_<Point>(ctx, "Point").constructor<double, double>()
    // static_method 依赖构造器（挂到 ctor 上），须先调用
    template <class... Args>
    class_& constructor()
    {
        JSValue ctor = JS_NewCFunction2(ctx_, &detail::ctor_thunk<T, Args...>, name_.c_str(),
            static_cast<int>(sizeof...(Args)), JS_CFUNC_constructor, 0);
        JS_SetConstructor(ctx_, ctor, proto_.raw());
        ctor_ = Value(ctx_, ctor);
        return *this;
    }

    // 方法：成员函数指针（&T::method）或自由函数（第一个参数 This<T> / const T&）
    template <class F>
    class_& method(std::string_view name, F&& f)
    {
        Function fn = func(ctx_, std::forward<F>(f), name);
        JS_SetPropertyStr(ctx_, proto_.raw(), std::string(name).c_str(), fn.take());
        return *this;
    }

    template <class F>
    class_& static_method(std::string_view name, F&& f)
    {
        if (!ctor_)
            throw std::runtime_error("qjs: static_method 需要在 constructor() 之后调用");
        Function fn = func(ctx_, std::forward<F>(f), name);
        JS_SetPropertyStr(ctx_, ctor_.raw(), std::string(name).c_str(), fn.take());
        return *this;
    }

    // 字段：成员对象指针 → getter + setter 两个 closure
    template <class M>
    class_& field(std::string_view name, M T::*mem)
    {
        return define_field(name, mem, true);
    }

    template <class M>
    class_& field_readonly(std::string_view name, M T::*mem)
    {
        return define_field(name, mem, false);
    }

    // 显式 getter / setter（自由函数或 lambda，第一个参数 This<T>）
    template <class F>
    class_& getter(std::string_view name, F&& f)
    {
        Function fn = func(ctx_, std::forward<F>(f), name);
        return define_getset(name, fn.take(), JS_UNDEFINED);
    }

    template <class F>
    class_& setter(std::string_view name, F&& f)
    {
        Function fn = func(ctx_, std::forward<F>(f), name);
        return define_getset(name, JS_UNDEFINED, fn.take());
    }

    JSClassID class_id() const noexcept { return class_id_; }

    // 暴露构造器给 JS：globals.set("Point", cls.constructor_function())
    // （class_ 注册只建类，不自动挂全局——模块场景要导出到 module 而非全局）
    Function constructor_function() const
    {
        if (!ctor_)
            throw std::runtime_error("qjs: constructor_function() 需要在 constructor() 之后调用");
        return Function(Value(ctx_, JS_DupValue(ctx_, ctor_.raw())));
    }
    // 注册的类名（模块导出用，设计文档 §7）
    const std::string& name() const noexcept { return name_; }

private:
    template <class M>
    class_& define_field(std::string_view name, M T::*mem, bool writable)
    {
        std::string n(name);
        // getter：This<T> 特殊参数（不消耗 argv）
        Function get = func(ctx_, [mem](This<T> self) -> M { return self.ptr->*mem; },
            "get_" + n);
        JSValue setv = JS_UNDEFINED;
        if (writable) {
            Function set = func(ctx_, [mem](This<T> self, M v) { self.ptr->*mem = v; },
                "set_" + n);
            setv = set.take();
        }
        return define_getset(n, get.take(), setv);
    }

    class_& define_getset(std::string_view name, JSValue getv, JSValue setv)
    {
        std::string n(name);
        JSAtom atom = JS_NewAtomLen(ctx_, n.data(), n.size());
        // 不用 JS_DefinePropertyGetSet：它强制 HAS_GET|HAS_SET（quickjs.c:11127），
        // getter()/setter() 分开注册会互相覆盖。用 JS_DefineProperty 精确控制 flags：
        // getter/setter 参数是借用（内部 dup 持有），调用方负责 free。
        int flags = JS_PROP_CONFIGURABLE;
        if (!JS_IsUndefined(getv))
            flags |= JS_PROP_HAS_GET;
        if (!JS_IsUndefined(setv))
            flags |= JS_PROP_HAS_SET;
        int rc = JS_DefineProperty(ctx_, proto_.raw(), atom, JS_UNDEFINED, getv, setv, flags);
        if (!JS_IsUndefined(getv))
            JS_FreeValue(ctx_, getv);
        if (!JS_IsUndefined(setv))
            JS_FreeValue(ctx_, setv);
        JS_FreeAtom(ctx_, atom);
        if (rc < 0)
            throw js_error(ctx_, JS_GetException(ctx_));
        return *this;
    }

    JSContext* ctx_;
    JSClassID class_id_;
    std::string name_;
    Value proto_;
    Value ctor_; // 空直到 constructor()
};

} // namespace qjs
