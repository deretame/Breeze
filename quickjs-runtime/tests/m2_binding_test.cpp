// M2 类绑定验收测试：class_<T> DSL
//
// 验收（设计文档 §12 M2）：
//   - JS 侧 new / 方法 / 字段全通
//   - 静态方法、只读字段、getter/setter
//   - 自由函数方法糖（This<T>）、引用参数（const T& / T&）
//   - GC 后无泄漏（finalizer 正确回收）
#include <cmath>
#include <string>

#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

struct Point {
    double x = 0, y = 0;
    Point() = default;
    Point(double x_, double y_) : x(x_), y(y_) {}
    double norm() const { return std::sqrt(x * x + y * y); }
    void move_by(double dx, double dy)
    {
        x += dx;
        y += dy;
    }
    static Point origin() { return Point(0, 0); }
    double tag = -1; // 只读字段演示
};

// 自由函数形态的方法糖：第一个参数 This<T>（this 注入）
double distance(This<Point> self, const Point& other)
{
    return std::sqrt((self->x - other.x) * (self->x - other.x) +
                     (self->y - other.y) * (self->y - other.y));
}

// 全局函数收类实例：const T& 引用参数（GetOpaque2 取引用，零拷贝）
double point_x(const Point& p) { return p.x; }
// T& 可变引用：改值反映 JS 对象
void set_x(Point& p, double v) { p.x = v; }

// 自定义 getter/setter（lambda + This<T>）
struct Box {
    double v = 0;
};

// finalizer 回收计数
struct Tracked {
    static int alive;
    int v;
    explicit Tracked(int x) : v(x) { ++alive; }
    ~Tracked() { --alive; }
};
int Tracked::alive = 0;

struct M2Fixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();
    Object globals = ctx.globals();
};

TEST_F(M2Fixture, ConstructorAndMethods)
{
    qjs::class_<Point> cls(ctx, "Point");
    cls.constructor<double, double>()
        .method("norm", &Point::norm)
        .method("moveBy", &Point::move_by)
        .static_method("origin", &Point::origin)
        .method("distance", distance)
        .field("x", &Point::x)
        .field("y", &Point::y);
    globals.set("Point", cls.constructor_function());

    // new + 成员方法（const 成员指针）
    EXPECT_EQ(ctx.eval("new Point(3, 4).norm()").as<double>(), 5.0);
    // 非 const 成员方法 + 字段联动
    EXPECT_EQ(ctx.eval("(() => { const p = new Point(1, 1); p.moveBy(2, 3); return p.norm(); })()")
                  .as<double>(),
        5.0);
    // 静态方法返回 bound class 值（js_convert<T> 值特化：包装成新实例）
    EXPECT_EQ(ctx.eval("Point.origin().norm()").as<double>(), 0.0);
    // 字段读取/写入
    EXPECT_EQ(ctx.eval("new Point(10, 20).x").as<double>(), 10.0);
    EXPECT_EQ(ctx.eval("(() => { const p = new Point(0, 0); p.x = 7; return p.x; })()").as<double>(),
        7.0);
    // 自由函数方法糖：This<Point> + const Point& 引用参数
    EXPECT_EQ(ctx.eval("new Point(0, 0).distance(new Point(3, 4))").as<double>(), 5.0);
}

TEST_F(M2Fixture, ReferenceParams)
{
    qjs::class_<Point> cls(ctx, "Point");
    cls.constructor<double, double>().field("x", &Point::x).field("y", &Point::y);
    globals.set("Point", cls.constructor_function());
    globals.set("pointX", point_x);
    globals.set("setX", set_x);

    EXPECT_EQ(ctx.eval("pointX(new Point(3, 4))").as<double>(), 3.0);
    // T& 可变引用：改值反映到 JS 对象
    EXPECT_EQ(ctx.eval("(() => { const p = new Point(0, 0); setX(p, 99); return p.x; })()")
                  .as<double>(),
        99.0);
}

TEST_F(M2Fixture, ReadonlyField)
{
    qjs::class_<Point> cls(ctx, "Point");
    cls.constructor<>().field_readonly("tag", &Point::tag);
    globals.set("Point", cls.constructor_function());
    // 只读字段可读
    EXPECT_EQ(ctx.eval("new Point().tag").as<double>(), -1.0);
    // 严格模式对无 setter 属性赋值抛 TypeError
    Value r = ctx.eval("'use strict'; try { const p = new Point(); p.tag = 1; 'no' } catch (e) { e.name }");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(M2Fixture, CustomGetterSetter)
{
    qjs::class_<Box> cls(ctx, "Box");
    cls.constructor<>()
        .getter("value", [](This<Box> self) { return self->v * 2; })
        .setter("value", [](This<Box> self, double x) { self->v = x / 2; });
    globals.set("Box", cls.constructor_function());
    EXPECT_EQ(ctx.eval("(() => { const b = new Box(); b.value = 8; return b.value; })()").as<double>(),
        8.0);
}

TEST_F(M2Fixture, ConstructorMissingArg)
{
    qjs::class_<Point> cls(ctx, "Point");
    cls.constructor<double, double>();
    globals.set("Point", cls.constructor_function());
    Value r = ctx.eval("try { new Point(1); 'no' } catch (e) { e.name }");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(M2Fixture, WrongThisType)
{
    qjs::class_<Point> cls(ctx, "Point");
    cls.constructor<double, double>().method("norm", &Point::norm);
    globals.set("Point", cls.constructor_function());
    // 普通对象调用 Point 方法 → GetOpaque2 抛 TypeError
    Value r = ctx.eval(
        "(() => { const p = new Point(1, 1); try { p.norm.call({}); return 'no'; } catch (e) { return e.name; } })()");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(M2Fixture, FinalizerReclaims)
{
    qjs::class_<Tracked> cls(ctx, "Tracked");
    cls.constructor<int>().field("v", &Tracked::v);
    globals.set("Tracked", cls.constructor_function());
    int base = Tracked::alive;
    // 数组持有引用（避免循环块作用域被自动 GC 回收）
    Value r = ctx.eval(
        "const arr = []; for (let i = 0; i < 1000; ++i) arr.push(new Tracked(i)); arr.length;");
    ASSERT_FALSE(r.is_exception()) << "eval failed";
    EXPECT_EQ(Tracked::alive, base + 1000); // 1000 个对象存活（数组持有）
    ctx.eval("arr.length = 0;");
    JS_RunGC(rt.raw());
    JS_RunGC(rt.raw()); // 双 GC 保险
    EXPECT_EQ(Tracked::alive, base); // finalizer 全部回收，无泄漏
}

} // namespace
