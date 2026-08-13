// qjsbind::web —— fetch() JS⇄C++ 适配层（fetch_cpp_decoupling.md v3 迁移后）
//
// 流程：input/init → RequestImpl（JS 规范语义）→ fetch::Request（核心值类型）
//   → fetch::Client::fetch（redirect 循环 / SRI / data: / 中间件链 / 传输全部
//   在核心库，见 include/fetch/client.hpp）→ fetch::Response → ResponseImpl。
// 本文件只做：JS 参数解析与头组装、核心异常 → JS 异常映射、响应转 JS 对象。
//
// 取消：AbortSignal.stop_source 的 token 传入 Client::fetch；abort() → 核心库
//   socket.cancel() → operation_aborted → set_stopped → 整个 task 链 stopped
//   → reject AbortError。
// 异常映射：fetch::Error / 网络错误 → reject TypeError("fetch failed: ...")。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/std_exec.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/web/errors.hpp>
#include <qjsbind/web/request_response.hpp>

#include <fmt/format.h> // fmt::format（错误消息拼接）

#include <fetch/client.hpp>

#include <stdexec/execution.hpp>

#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace qjsbind::web {

// 安装 fetch 全局函数。client 由 C++ 宿主装配（中间件在 install 之前经
// fetch::Client::use 完成；核心库链对 JS 是黑盒——JS 能感知的只是 fetch
// 行为本身）。client 必须比 ctx 及其运行时活得久。
inline void install_fetch(qjs::Context& ctx, fetch::Client& client) {
    ctx.globals().set(
        "fetch",
        qjs::func(ctx.raw(),
                  [&client](qjs::Ctx ctx, qjs::Value input, qjs::Opt<qjs::Value> init)
                      -> std_exec::task<qjs::Value> {
                      // 同步部分：解析 input/init → RequestImpl
                      RequestImpl req;
                      qjs::Opt<qjs::Value> input_opt;
                      input_opt.value.emplace(ctx.ctx, JS_DupValue(ctx.ctx, input.raw()));
                      // 规范：fetch(Request) 消费 input 的 body（bodyUsed=true；已消费 → TypeError）。
                      // 注意：init 提供 body 时 input 不被消费（qjs_init 覆盖语义）。
                      bool input_consumed = false;
                      if (input.is_object()) {
                          auto& reg = qjs::registry_of(ctx.ctx);
                          if (reg.is_registered<RequestImpl>() &&
                              reg.id_of<RequestImpl>(ctx.ctx) == JS_GetClassID(input.raw())) {
                              auto* src = reg.opaque<RequestImpl>(ctx.ctx, input.raw());
                              const bool init_has_body =
                                  init && init->is_object() &&
                                  !qjs::Context(ctx.ctx)
                                       .get_property(init->raw(), "body")
                                       .is_undefined();
                              if (!init_has_body) {
                                  // 已消费 → TypeError；未消费由 qjs_init 的
                                  // try_extract_init_body tee 提取（置 input disturbed）
                                  if (src->body_stream && src->body_stream->disturbed)
                                      throw_type_error(
                                          ctx.ctx, "fetch: Request body 已被消费");
                                  input_consumed = true;
                              }
                          }
                      }
                      req.qjs_init(ctx.ctx, input_opt, init);
                      (void)input_consumed; // req 是拷贝，body_used 语义属于 input 对象本身

                      // 同步 headers（用户可能通过 req.headers 修改过）
                      req.sync_headers(ctx.ctx);
                      // 组装请求头（guard=request 已做 forbidden 检查；再过滤一遍——
                      // headers_from 在 guard 置位前可能已存入了 forbidden 头/值）
                      std::vector<fetch::Header> hdrs;
                      for (const auto& [k, v] : req.headers.list) {
                          // Node(undici) 行为：referer/cookie/origin 等用户自定义头
                          // 正常发送（不做 forbidden 过滤）；host/content-length 由
                          // 运行时管理（用户设置被忽略，避免与连接/长度语义冲突）
                          if (k == "host" || k == "content-length")
                              continue;
                          if (qjsbind::web::is_method_override_header(k)) {
                              // 值含 forbidden method（逗号分列 + trim + 小写匹配）→ 不发
                              bool bad = false;
                              std::string part;
                              auto check = [&] {
                                  size_t b = 0, e = part.size();
                                  while (b < e && (part[b] == ' ' || part[b] == '\t')) ++b;
                                  while (e > b && (part[e - 1] == ' ' || part[e - 1] == '\t')) --e;
                                  std::string p = part.substr(b, e - b);
                                  std::transform(p.begin(), p.end(), p.begin(),
                                                 [](unsigned char c) {
                                                     return static_cast<char>(std::tolower(c));
                                                 });
                                  return p == "trace" || p == "track" || p == "connect";
                              };
                              for (char c : v) {
                                  if (c == ',') {
                                      if (check()) { bad = true; break; }
                                      part.clear();
                                  } else {
                                      part.push_back(c);
                                  }
                              }
                              if (!bad && check())
                                  bad = true;
                              if (bad)
                                  continue;
                          }
                          hdrs.push_back({k, v});
                      }
                      // 规范：非 GET/HEAD 请求带 Origin 头（值 = URL origin；Node/浏览器一致）
                      if (req.method != "GET" && req.method != "HEAD" &&
                          req.url.rfind("http", 0) == 0) {
                          UrlImpl u = UrlImpl::parse(ctx.ctx, req.url, "");
                          hdrs.push_back({"Origin", u.origin()});
                      }
                      // Content-Length 由核心 BodyLengthMiddleware 运行时重写
                      //（发送前按实际 body 重算；POST/PUT/PATCH 空 body 自动为 0）

                      const std::stop_token st =
                          req.signal ? req.signal->stop.get_token() : std::stop_token{};
                      // signal 已 abort → 立即 reject AbortError
                      if (req.signal && req.signal->aborted)
                          throw qjs::js_error(ctx.ctx, make_abort_error(ctx.ctx).take());

                      // 请求 body 读干（fetch 语义：消费 input 的 body；disturbed 已由
                      // 上面的 input 处理置位，这里实际读取 req 的拷贝流）
                      std::string body;
                      if (req.body_stream) {
                          std::shared_ptr<ReadableStreamImpl> bs = req.body_stream;
                          try {
                              for (;;) {
                                  auto block = co_await bs->read();
                                  if (!block)
                                      break;
                                  body += *block;
                              }
                          } catch (const qjs::js_error&) {
                              throw;
                          } catch (const std::exception& e) {
                              throw_type_error(
                                  ctx.ctx, fmt::format("fetch failed: {}", e.what()));
                          }
                      }

                      // 核心值类型请求（JS 规范语义已全部物化；重定向/完整性走核心管线）
                      fetch::Request core_req;
                      core_req.method = req.method;
                      core_req.url = req.url;
                      core_req.headers = std::move(hdrs);
                      core_req.body = std::move(body);
                      core_req.integrity = req.integrity;
                      core_req.redirect =
                          req.redirect == "error"
                              ? fetch::Request::Redirect::error
                              : (req.redirect == "manual" ? fetch::Request::Redirect::manual
                                                          : fetch::Request::Redirect::follow);

                      // 核心库管线（redirect/SRI/data:/中间件链/传输）
                      fetch::Response resp;
                      try {
                          resp = co_await client.fetch(std::move(core_req), st);
                      } catch (const qjs::js_error&) {
                          throw; // JS 异常原样透传
                      } catch (const fetch::Error& e) {
                          throw_type_error(ctx.ctx, fmt::format("{}", e.what()));
                      } catch (const std::exception& e) {
                          throw_type_error(ctx.ctx, fmt::format("fetch failed: {}", e.what()));
                      }

                      // opaqueredirect（redirect=manual 命中重定向）：核心库以
                      // status==0 且 url 空的哨兵响应表示（fetch_cpp_decoupling.md §4.6）
                      if (resp.status == 0 && resp.url.empty()) {
                          ResponseImpl r;
                          r.status = 0;
                          r.type = "opaqueredirect";
                          r.url = "";
                          co_return qjs::Value(ctx.ctx, qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, r));
                      }

                      // 构建 Response（headers guard=response；name 规范化由 append 完成）
                      ResponseImpl r;
                      r.status = resp.status;
                      r.status_text = resp.reason;
                      // 流式 body：204/205/304/HEAD → resp.body 为 null → body_stream 为 null
                      r.body_stream =
                          resp.body ? make_stream(io_of(ctx.ctx), std::move(resp.body), st)
                                    : nullptr;
                      r.type = "basic"; // 同源 fetch 响应（v1 无跨域，恒 basic）
                      r.url = resp.url;
                      r.redirected = resp.redirected; // 规范：经重定向的响应 redirected=true
                      r.headers.set_guard(HeadersImpl::Guard::Immutable); // 规范：fetch 响应 headers 不可变
                      for (const auto& h : resp.headers)
                          r.headers.append_raw(h.name, h.value); // 绕过 guard 检查（响应组装）
                      co_return qjs::Value(ctx.ctx, qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, r));
                  },
                  "fetch"));
}

} // namespace qjsbind::web
