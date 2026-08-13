// qjsbind —— QuickJS-NG 的 C++ 自动绑定层（header-only，namespace qjs）
//
// 设计文档：qjs_cpp_binding_design.md
// M1 范围：RAII 封装 + js_convert 基础类型 + 同步函数绑定 + 异常边界
#pragma once

#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp>
// 二进制 RAII 包装（js_bytes / new_uint8_array）：quickjs 原生 API 的收口，
// 供 blob_store 及各 web 实现使用。字符串取用走 convert.hpp 的 js_convert。
#include <qjsbind/binary.hpp>
#include <qjsbind/function.hpp>
#include <qjsbind/class.hpp>
#include <qjsbind/module.hpp>
#include <qjsbind/promise.hpp>
#include <qjsbind/loop.hpp>
// 动态调用（docs/dynamic_call_design.md）：call / callSync 全局函数 + 注册中心。
// 放在末尾：依赖 loop.hpp（Runtime::spawn 定义）与 promise.hpp（exception_to_js）。
// 注意：context.hpp 的 Runtime 析构引用 dyn::remove_host，其定义在本头——
// 凡构造 Runtime 的 TU 都需要本头（或 dynamic_call.hpp）可见。
#include <qjsbind/dynamic_call.hpp>
// 二进制暂存（docs/blob_store_design.md）：put/get 全局函数 + BlobStore 单例。
// 放在末尾：依赖 context.hpp（Runtime::id / runtime_of）与 error.hpp。
// 注意：context.hpp 的 Runtime 析构引用 dyn::remove_blob_host，其定义在本头——
// 凡构造 Runtime 的 TU 都需要本头（或 blob_store.hpp）可见。
#include <qjsbind/blob_store.hpp>
