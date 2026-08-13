// 端到端演示（设计文档 §11）：同步函数 + 异步协程函数 + 类 + 事件循环
#include <chrono>
#include <qjsbind/std_exec.hpp>
#include <memory>
#include <numeric>
#include <string>

#include <boost/asio/steady_timer.hpp>
#include <exec/asio/use_sender.hpp>
#include <glaze/glaze.hpp>
#include <stdexec/execution.hpp>
#include <qjsbind/qjsbind.hpp>
#include <log.hpp>

using qjs::This;

// ---- 同步自由函数：签名无 qjs 类型 ----
double add(double a, double b) { return a + b; }

// ---- 异步自由函数（★ 自由函数，不是 lambda —— 见 known_issues KI-001）----
// 无 Ctx 参数：经 qjs::current_io() 拿当前 JS 线程的事件循环
std_exec::task<std::string> greet_after(std::string name, double ms)
{
    auto timer = std::make_shared<boost::asio::steady_timer>(
        qjs::current_io(), boost::asio::chrono::milliseconds(static_cast<long long>(ms)));
    co_await timer->async_wait(exec::asio::use_sender);
    co_return "hello, " + name;
}

// ---- 类 ----
struct Counter {
    int value = 0;
    int add(int d) { return value += d; }
};

// 异步方法糖：This<Counter> + std_exec::task 自由函数，经 method() 注册
std_exec::task<int> counter_add_later(This<Counter> self, int d, double ms)
{
    auto timer = std::make_shared<boost::asio::steady_timer>(
        qjs::current_io(), boost::asio::chrono::milliseconds(static_cast<long long>(ms)));
    co_await timer->async_wait(exec::asio::use_sender);
    co_return self->add(d);
}

int main()
{
    qjs::Runtime rt;
    qjs::Context ctx = rt.main_context();

    auto globals = ctx.globals();
    globals.set("add", add);
    globals.set("greetAfter", greet_after);
    globals.set("log", qjs::func(ctx.raw(), [](const std::string& s) { QLOG_INFO("{}", s); }));

    qjs::class_<Counter> counter_cls(ctx, "Counter");
    counter_cls.constructor<>()
        .method("add", &Counter::add)
        .method("addLater", counter_add_later) // 异步方法（自由函数糖）
        .field("value", &Counter::value);
    globals.set("Counter", counter_cls.constructor_function());

    // ---- 动态调用（docs/dynamic_call_design.md）：call / callSync ----
    qjs::dyn::install_dynamic_call(ctx);
    // 同步 handler：JSON 进（参数数组），JSON 出（返回值）
    qjs::dyn::register_global(
        "add", [](std::string_view, std::string_view, std::string_view args) -> std::string {
            auto v = glz::read_json<std::vector<double>>(args);
            if (!v)
                throw std::runtime_error(glz::format_error(v.error(), args));
            auto out = glz::write_json(std::accumulate(v->begin(), v->end(), 0.0));
            return std::move(*out);
        });
    // 异步 handler：co_await 挂起后返回（Promise 结算回 JS 线程）。
    // "add" 同名双注册：callSync 走 sync 版、call 走 async 版（两表独立，互不回落）
    qjs::dyn::register_global_async(
        "add", [](std::string, std::string, std::string args) -> std_exec::task<std::string> {
            auto v = glz::read_json<std::vector<double>>(args);
            if (!v)
                throw std::runtime_error("bad args");
            auto timer = std::make_shared<boost::asio::steady_timer>(
                qjs::current_io(), std::chrono::milliseconds(5));
            co_await timer->async_wait(exec::asio::use_sender);
            auto out = glz::write_json(std::accumulate(v->begin(), v->end(), 0.0));
            co_return std::move(*out);
        });
    // 异步 handler：co_await 挂起后返回（Promise 结算回 JS 线程）
    qjs::dyn::register_global_async(
        "greetAsync",
        [](std::string, std::string, std::string args) -> std_exec::task<std::string> {
            auto v = glz::read_json<std::vector<std::string>>(args);
            if (!v)
                throw std::runtime_error("bad args");
            auto timer = std::make_shared<boost::asio::steady_timer>(
                qjs::current_io(), std::chrono::milliseconds(20));
            co_await timer->async_wait(exec::asio::use_sender);
            auto out = glz::write_json("hello, " + v->at(0));
            co_return std::move(*out);
        });

    qjs::Value r = ctx.eval(R"(
        const c = new Counter();
        c.add(5);
        const syncSum = callSync("add", 1, 2, 3);
        Promise.all([greetAfter("qjs", 30), c.addLater(2, 30), call("greetAsync", "dyn"),
                     call("add", 10, 20)])
          .then(([g, total, gd, sum]) => {
              log(g + " total=" + total + " value=" + c.value
                  + " | callSync add=" + syncSum
                  + " | call greetAsync=" + gd
                  + " | call add=" + sum);
              globalThis.__done = true;
          });
        'ok';
    )");
    if (r.is_exception())
        QLOG_ERROR("脚本执行失败");

    rt.run_to_completion(); // 脚本模式：Promise.all 完成后 pending==0 退出（§8 模式 B）
    QLOG_INFO("qjsbind 端到端演示完成");
    return 0;
}
