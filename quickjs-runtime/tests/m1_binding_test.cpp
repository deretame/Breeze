// M1 基础层验收测试：RAII + js_convert 基础类型 + 同步函数绑定 + 异常边界
//
// 验收（设计文档 §12 M1）：
//   - JS 调用同步函数全类型往返正确
//   - C++ 异常正确变 JS 异常
//   - 所有权无泄漏（JS_FreeValue 配对；循环调用稳定性冒烟）
#include <cmath>
#include <map>
#include <optional>
#include <string>
#include <tuple>
#include <vector>

#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

// ---- 被测同步函数（签名无 qjs 类型）----
double add(double a, double b) { return a + b; }
std::string greet(std::string name) { return "hello, " + name; }
bool negate_bool(bool b) { return !b; }
int64_t twice64(int64_t v) { return v * 2; }
std::vector<int> reverse_vec(std::vector<int> v)
{
    std::reverse(v.begin(), v.end());
    return v;
}
std::map<std::string, int> bump_map(std::map<std::string, int> m)
{
    for (auto& [k, v] : m)
        v += 1;
    return m;
}
std::optional<int> maybe_plus(std::optional<int> v)
{
    return v ? std::optional<int>(*v + 1) : std::nullopt;
}
std::tuple<int, std::string> make_pair(int a, std::string b) { return {a, b}; }
std::string describe(Ctx, Opt<int> o, Rest<std::string> r)
{
    std::string s = "opt=";
    s += o ? std::to_string(*o) : "none";
    s += " rest=";
    for (auto& x : r)
        s += x + ",";
    return s;
}
void throw_runtime() { throw std::runtime_error("boom"); }

struct Point {
    double x, y;
};
double point_norm(This<Point> p) { return std::sqrt(p->x * p->x + p->y * p->y); }

struct Fixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();
    Object globals = ctx.globals();
};

// ---- 基础类型往返 ----
TEST_F(Fixture, AddFunction)
{
    globals.set("add", add);
    Value r = ctx.eval("add(2, 3)");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<double>(), 5.0);
}

TEST_F(Fixture, NTTPEntry)
{
    globals.set("add", func<&add>(ctx.raw()));
    EXPECT_EQ(ctx.eval("add(2.5, 1.5)").as<double>(), 4.0);
}

TEST_F(Fixture, LambdaEntry)
{
    globals.set("mul", func(ctx.raw(), [](double a, double b) { return a * b; }, "mul"));
    EXPECT_EQ(ctx.eval("mul(3, 4)").as<double>(), 12.0);
}

TEST_F(Fixture, StringBoolInt64)
{
    globals.set("greet", greet);
    globals.set("negate", negate_bool);
    globals.set("twice64", twice64);
    EXPECT_EQ(ctx.eval("greet('qjs')").as<std::string>(), "hello, qjs");
    EXPECT_EQ(ctx.eval("negate(true)").as<bool>(), false);
    EXPECT_EQ(ctx.eval("twice64(2147483648)").as<int64_t>(), 4294967296LL);
    EXPECT_TRUE(ctx.eval("greet('x')").is<std::string>());
    EXPECT_TRUE(ctx.eval("42").is<double>());
    EXPECT_TRUE(ctx.eval("true").is<bool>());
}

// ---- 容器往返 ----
TEST_F(Fixture, Containers)
{
    globals.set("rev", reverse_vec);
    globals.set("bump", bump_map);
    globals.set("maybe", maybe_plus);
    globals.set("mkPair", make_pair);

    auto v = ctx.eval("rev([1,2,3])").as<std::vector<int>>();
    ASSERT_EQ(v.size(), 3u);
    EXPECT_EQ(v[0], 3);
    EXPECT_EQ(v[2], 1);

    auto m = ctx.eval("bump({a:1,b:2})").as<std::map<std::string, int>>();
    ASSERT_EQ(m.size(), 2u);
    EXPECT_EQ(m["a"], 2);
    EXPECT_EQ(m["b"], 3);

    EXPECT_FALSE(ctx.eval("maybe(null)").as<std::optional<int>>().has_value());
    EXPECT_EQ(ctx.eval("maybe(41)").as<std::optional<int>>(), std::optional<int>(42));

    auto t = ctx.eval("mkPair(7, 'seven')").as<std::tuple<int, std::string>>();
    EXPECT_EQ(std::get<0>(t), 7);
    EXPECT_EQ(std::get<1>(t), "seven");
}

// ---- 特殊参数：Ctx / Opt / Rest ----
TEST_F(Fixture, SpecialParams)
{
    globals.set("describe", describe);
    EXPECT_EQ(ctx.eval("describe(5, 'a', 'b')").as<std::string>(), "opt=5 rest=a,b,");
    EXPECT_EQ(ctx.eval("describe()").as<std::string>(), "opt=none rest=");
}

// ---- 异常边界 ----
TEST_F(Fixture, CppExceptionBecomesJsError)
{
    globals.set("boom", throw_runtime);
    Value r = ctx.eval("try { boom(); 'no' } catch (e) { e.message }");
    std::string msg = r.as<std::string>();
    EXPECT_NE(msg.find("boom"), std::string::npos);
}

TEST_F(Fixture, MissingArgumentTypeError)
{
    globals.set("add", add);
    Value r = ctx.eval("try { add(1); 'no' } catch (e) { e.name }");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(Fixture, ConvertFailureTypeError)
{
    globals.set("describe", describe);
    // Object.create(null) 无 toString/valueOf → ToString 必然抛（注意 Symbol→int 在 ng 不抛）
    Value r = ctx.eval("try { describe(1, Object.create(null)); 'no' } catch (e) { e.name }");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

// ---- This<T>：方法糖（M1 用 C API 手动构造类实例）----
TEST_F(Fixture, ThisParam)
{
    JSClassID id = ctx.registry().ensure<Point>(ctx.raw());
    JSValue proto = JS_NewObject(ctx.raw());
    JSValue inst = JS_NewObjectProtoClass(ctx.raw(), proto, id);
    JS_SetOpaque(inst, new Point{3.0, 4.0});
    JS_FreeValue(ctx.raw(), proto); // proto 只是模板，不再持有
    globals.set("g_point", Value(ctx.raw(), inst));
    globals.set("pointNorm", point_norm);
    Value r = ctx.eval("pointNorm.call(g_point)");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<double>(), 5.0);
}

// ---- Runtime 实例 id（boost::uuids）----
TEST_F(Fixture, RuntimeId)
{
    std::string id = rt.id();
    ASSERT_EQ(id.size(), 36u);
    // UUID v4 布局 8-4-4-4-12（boost::uuids::to_string：小写 hex + 连字符）
    for (size_t i = 0; i < id.size(); ++i) {
        char c = id[i];
        bool is_dash = (i == 8 || i == 13 || i == 18 || i == 23);
        if (is_dash) {
            EXPECT_EQ(c, '-');
        } else {
            EXPECT_TRUE((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) << "pos " << i;
        }
    }
    // 自定义 id
    Runtime custom("worker-1");
    EXPECT_EQ(custom.id(), "worker-1");
    // 自动生成唯一性
    Runtime a, b;
    EXPECT_NE(a.id(), b.id());
    EXPECT_NE(a.id(), custom.id());
}

// ---- Object::set 自动包装 + Function::call ----
TEST_F(Fixture, ObjectSetAutoWrapAndCall)
{
    globals.set("add", add);
    Value fn = globals.get("add");
    ASSERT_TRUE(fn.is_function());
    Value r = fn.as<Function>().call(20.0, 22.0);
    EXPECT_EQ(r.as<double>(), 42.0);
}

// ---- 所有权冒烟：重复调用稳定 ----
TEST_F(Fixture, OwnershipSmoke)
{
    globals.set("add", add);
    globals.set("rev", reverse_vec);
    for (int i = 0; i < 200; ++i) {
        EXPECT_EQ(ctx.eval("add(1, 2)").as<double>(), 3.0);
        EXPECT_EQ(ctx.eval("rev([1,2,3])").as<std::vector<int>>()[0], 3);
    }
}

} // namespace
