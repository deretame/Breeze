// module.hpp —— ES Module 原生导出（设计文档 §7）
//
// ng 的 C 模块两阶段 API：
//   JS_NewCModule(ctx, name, init)（:1396）→ JS_AddModuleExport（实例化前，:1399）
//   → init 回调里 JS_SetModuleExport（:1403）
// JS 侧：`import { f } from "my:native";`
//
// 注意：JS_NewCModule 的 init 回调没有 opaque 参数，Module 实例经
// 静态注册表（JSModuleDef* → Module*）反查；所有 JS 操作都在 JS 线程，
// 注册表用互斥锁保护（跨运行时创建也安全）。
#pragma once

#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <qjsbind/class.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/function.hpp>
#include <qjsbind/value.hpp>

namespace qjs {

class Module {
public:
    Module(JSContext* ctx, std::string_view name) : ctx_(ctx), module_(JS_NewCModule(ctx, name.data(), &init_thunk))
    {
        if (!module_)
            throw std::runtime_error("qjs: JS_NewCModule failed for '" + std::string(name) + "'");
        std::lock_guard lock(mutex());
        registry().emplace(module_, this);
    }
    ~Module()
    {
        {
            std::lock_guard lock(mutex());
            registry().erase(module_);
        }
        for (auto& [name, value] : exports_)
            JS_FreeValue(ctx_, value);
        // module_ 是 JSModuleDef*（非 JSValue），由引擎管理，不 free
    }
    Module(const Module&) = delete;
    Module& operator=(const Module&) = delete;

    // 导出自由函数/可调用对象（入口 B 语义，设计文档 §4.4）
    template <class F>
    void function(std::string_view name, F&& f)
    {
        // take()：Function 临时析构不 free，所有权转移给 exports_
        add_export(name, func(ctx_, std::forward<F>(f), name).take());
    }
    template <auto F>
    void function(std::string_view name)
    {
        add_export(name, func<F>(ctx_).take());
    }

    // 导出类（构造器挂为模块导出，设计文档 §7）
    template <class T>
    void class_(class_<T>&& cls)
    {
        add_export(cls.name(), cls.constructor_function().take());
    }

private:
    static int init_thunk(JSContext* ctx, JSModuleDef* m)
    {
        std::lock_guard lock(mutex());
        auto it = registry().find(m);
        if (it == registry().end())
            return -1;
        for (const auto& [name, value] : it->second->exports_) {
            // dup 传入：JS_SetModuleExport 语义随引擎版本，保留本侧所有权最稳
            if (JS_SetModuleExport(ctx, m, name.c_str(), JS_DupValue(ctx, value)) < 0)
                return -1;
        }
        return 0;
    }

    void add_export(std::string_view name, JSValue value)
    {
        if (JS_AddModuleExport(ctx_, module_, name.data()) < 0) {
            JS_FreeValue(ctx_, value);
            throw std::runtime_error("qjs: JS_AddModuleExport failed for '" + std::string(name) + "'");
        }
        exports_.emplace_back(std::string(name), value);
    }

    static std::unordered_map<JSModuleDef*, Module*>& registry()
    {
        static std::unordered_map<JSModuleDef*, Module*> reg;
        return reg;
    }
    static std::mutex& mutex()
    {
        static std::mutex mtx;
        return mtx;
    }

    JSContext* ctx_;
    JSModuleDef* module_;
    std::vector<std::pair<std::string, JSValue>> exports_;
};

} // namespace qjs
