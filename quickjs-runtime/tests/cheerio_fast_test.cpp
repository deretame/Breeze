// cheerio_fast_test.cpp —— BreezeHtml 只读选择集 API 测试
//
// 覆盖：load/查询/遍历/过滤/读取（attr/text/html/val）/迭代（each/map/toArray）
// /空集语义/无效选择器抛错/GC 生命周期。
#include <gtest/gtest.h>
#include <qjsbind/cheerio/cheerio.hpp>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

struct BreezeHtmlFixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    BreezeHtmlFixture() { qjsbind::cheerio::install_cheerio(ctx); }

    // 求值并断言无异常，返回字符串结果
    std::string eval_str(const char* code)
    {
        Value r = ctx.eval(code);
        EXPECT_FALSE(r.is_exception()) << r.as<std::string>();
        if (r.is_exception())
            return "<exception>";
        return r.as<std::string>();
    }
};

// 查询 + 读取：length/text/attr/html；空集与缺失属性语义
TEST_F(BreezeHtmlFixture, QueryBasics)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load(
            '<ul id="fruits"><li class="apple">Apple</li>' +
            '<li class="orange">Orange</li></ul>');
        [
            $('li').length,                   // 2
            $('li.apple').text(),             // Apple
            $('li').text(),                   // AppleOrange（拼接）
            $('li.orange').attr('class'),     // orange
            typeof $('li').attr('missing'),   // undefined：属性缺失
            typeof $('nosuch').attr('class'), // undefined：空集
            $('ul').html(),                   // innerHTML
            typeof $('nosuch').html(),        // undefined：空集
            $('nosuch').text(),               // ''
            $('nosuch').length,               // 0
        ].join('|');
    )JS"),
              "2|Apple|AppleOrange|orange|undefined|undefined|"
              "<li class=\"apple\">Apple</li><li class=\"orange\">Orange</li>"
              "|undefined||0");
}

// 遍历：find/first/last/eq/parent/children/siblings/next/prev/closest
TEST_F(BreezeHtmlFixture, Traversal)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load(
            '<div id="wrap"><p class="a">A</p><p class="b">B</p>' +
            '<span>S</span><p class="c">C</p></div>');
        const ps = $('p');
        [
            ps.length,                      // 3
            ps.first().attr('class'),       // a
            ps.last().attr('class'),        // c
            ps.eq(1).text(),                // B
            ps.eq(-1).attr('class'),        // c（负数从尾部数）
            ps.eq(9).length,                // 0（越界空集）
            $('p.b').parent().attr('id'),   // wrap
            $('#wrap').children().length,   // 4
            $('#wrap').children('p').length, // 3（选择器过滤）
            $('p.b').siblings().length,     // 3（除自身的元素兄弟）
            $('p.b').siblings('p').length,  // 2
            $('p.b').next().text(),         // S
            $('p.b').next('span').text(),   // S（紧邻兄弟匹配选择器）
            $('p.b').next('p').length,      // 0（紧邻兄弟不是 p → 空集）
            $('p.b').prev().text(),         // A
            $('p.b').closest('div').attr('id'), // wrap（含自身向上）
            $('p.b').closest('p').attr('class'), // b（自身匹配）
            $('#wrap').find('p').length,    // 3
        ].join('|');
    )JS"),
              "3|a|c|B|c|0|wrap|4|3|3|2|S|S|0|A|wrap|b|3");
}

// 相对选择器 / :scope
TEST_F(BreezeHtmlFixture, RelativeSelector)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load('<div id="a"><ul><li>1</li><li>2</li></ul></div>');
        [
            $('div').find('> ul').length,      // 1（组合器开头 → :scope 包装）
            $('ul').find('> li').length,       // 2
            $('ul').find(':scope > li').length, // 2
        ].join('|');
    )JS"),
              "1|2|2");
}

// filter/has/slice/index/is
TEST_F(BreezeHtmlFixture, SetOps)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load(
            '<ul><li class="x">1</li><li>2</li><li class="x">3</li><li>4</li></ul>');
        const lis = $('li');
        [
            lis.filter('.x').text(),          // 13（选择器过滤）
            lis.filter((i, el) => el.text() === '2').length, // 1（回调第二参为选择集）
            lis.filter(function () { return this.text() === '3'; }).length, // 1（this 绑定）
            $('ul').has('li.x').length,       // 1
            $('ul').has('nosuch').length,     // 0
            lis.slice(1, 3).text(),           // 23
            lis.slice(-2).text(),             // 34（负数）
            lis.eq(1).index(),                // 1（元素兄弟序号）
            $('nosuch').index(),              // -1
            lis.eq(0).is('.x'),               // true
            lis.eq(1).is('.x'),               // false
        ].join('|');
    )JS"),
              "13|1|1|1|0|23|34|1|-1|true|false");
}

// each/map/toArray：回调签名 (index, 单元素选择集)；each 中断；map 结果
// {length, get()}
TEST_F(BreezeHtmlFixture, Iteration)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load('<ul><li>a</li><li>b</li><li>c</li></ul>');
        const seen = [];
        $('li').each((i, el) => seen.push(i + ':' + el.text()));
        const early = [];
        $('li').each((i, el) => { early.push(el.text()); return el.text() !== 'b'; });
        const mapped = $('li').map((i, el) => i === 1 ? null : el.text().toUpperCase());
        const arr = $('li').toArray();
        [
            seen.join(','),     // 0:a,1:b,2:c
            early.join(''),     // ab（=== false 中断）
            mapped.length,      // 2（null 跳过）
            mapped.get().join(''), // AC
            arr.length,         // 3
            arr[1].text(),      // b（toArray 元素为单元素选择集）
        ].join('|');
    )JS"),
              "0:a,1:b,2:c|ab|2|AC|3|b");
}

// val()：cheerio 语义（input/textarea/select/option/checkbox）
TEST_F(BreezeHtmlFixture, ValSemantics)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load(
            '<form>' +
            '<input id="i1" value="hello">' +
            '<input id="i2" type="checkbox">' +
            '<input id="i3">' +
            '<textarea id="t1">foobar</textarea>' +
            '<select id="s1"><option value="a">A</option>' +
            '<option value="b" selected>B</option></select>' +
            '<select id="s2"><option>x</option><option value="y">Y</option></select>' +
            '</form>');
        [
            $('#i1').val(),          // hello（value 属性）
            $('#i2').val(),          // on（checkbox 无 value）
            typeof $('#i3').val(),   // undefined（无 value）
            $('#t1').val(),          // foobar（textarea → 文本）
            $('#s1').val(),          // b（selected option）
            $('#s2').val(),          // x（第一个 option，无 value → 文本）
            typeof $('nosuch').val(), // undefined（空集）
            $('option:checked').attr('value'), // b（:checked 匹配 selected 裸属性）
            $('#s1 option').toArray()[1].attr('selected') === '', // true（裸属性 → 空串）
        ].join('|');
    )JS"),
              "hello|on|undefined|foobar|b|x|undefined|b|true");
}

// $ 调用形式：$(selection) 原样返回；$(其他) 空集；无效选择器/参数抛错
TEST_F(BreezeHtmlFixture, ApiCallForms)
{
    EXPECT_EQ(eval_str(R"JS(
        const $ = BreezeHtml.load('<div><p>a</p></div>');
        const p = $('p');
        let err1 = '', err2 = '', err3 = '';
        try { $('ul >'); } catch (e) { err1 = e.message; }
        try { $('li:bah'); } catch (e) { err2 = e.message; }
        try { BreezeHtml.load(); } catch (e) { err3 = e.message; }
        [
            $(p) === p,     // true（选择集原样返回）
            $(p).text(),    // a
            $(null).length, // 0
            $(42).length,   // 0
            err1,           // Invalid selector: ul >
            err2,           // Unknown pseudo-class :bah
            err3,           // BreezeHtml.load() expects a string
        ].join('|');
    )JS"),
              "true|a|0|0|Invalid selector: ul >|Unknown pseudo-class :bah|"
              "BreezeHtml.load() expects a string");
}

// 生命周期：选择集释放后派生集仍持有文档；批量 load + GC 无崩溃
TEST_F(BreezeHtmlFixture, GcLifecycle)
{
    Value r = ctx.eval(R"JS(
        let keep;
        {
            const $ = BreezeHtml.load('<p>keep</p>');
            keep = $('p');
        }
        // 批量 load 制造垃圾文档
        for (let i = 0; i < 50; i++) BreezeHtml.load('<div>g' + i + '</div>');
        globalThis.__keep = keep;
        keep.text();
    )JS");
    ASSERT_FALSE(r.is_exception()) << r.as<std::string>();
    EXPECT_EQ(r.as<std::string>(), "keep");
    // 强制 GC 后再操作：无悬垂、无崩溃
    JS_RunGC(JS_GetRuntime(ctx.raw()));
    EXPECT_EQ(eval_str("__keep.text()"), "keep");
    EXPECT_EQ(eval_str("BreezeHtml.load('<span>after</span>')('span').text()"),
              "after");
}

} // namespace
