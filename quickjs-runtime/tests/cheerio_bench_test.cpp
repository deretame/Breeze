// cheerio_bench_test.cpp —— BreezeHtml 解析/查询/序列化性能基准
//
// 运行：--gtest_filter="BreezeHtmlBench.*" 输出 [bench] 行。
// 数据：3000 行表格（6000 个 td）+ 3 个 li 的 HTML，
//       分别计时 BreezeHtml.load（解析）、$('td.cell')（查询）、
//       $('tbody').html()（序列化）、$('tr').filter（回调遍历）。
#include <gtest/gtest.h>
#include <qjsbind/cheerio/cheerio.hpp>
#include <qjsbind/qjsbind.hpp>

#include <cstdio>
#include <sstream>
#include <string>
#include <vector>

using namespace qjs;

class BreezeHtmlBench : public ::testing::Test {
protected:
    Runtime rt;
    Context ctx = rt.main_context();

    BreezeHtmlBench() { qjsbind::cheerio::install_cheerio(ctx); }
};

TEST_F(BreezeHtmlBench, ParseQuerySerialize)
{
    Value r = ctx.eval(R"JS(
        const rows = [];
        for (let i = 0; i < 3000; i++)
            rows.push('<tr id="r' + i + '"><td class="cell">cell ' + i + '</td><td class="num">' + i + '</td></tr>');
        const html = '<table><tbody>' + rows.join('') + '</tbody></table>'
            + '<ul><li class="item">a</li><li class="item">b</li><li class="item">c</li></ul>';
        const t0 = Date.now();
        const $ = BreezeHtml.load(html);
        const t1 = Date.now();
        const n = $('td.cell').length;
        const t2 = Date.now();
        const s = $('tbody').html().length;
        const t3 = Date.now();
        const n2 = $('tr').filter(function () { return this.attr('id') === 'r1500'; }).length;
        const t4 = Date.now();
        (t1 - t0) + '|' + (t2 - t1) + '|' + (t3 - t2) + '|' + (t4 - t3) + '|' + n + '|' + s + '|' + n2;
    )JS");
    ASSERT_FALSE(r.is_exception()) << r.as<std::string>();
    std::string out = r.as<std::string>();
    std::vector<std::string> parts;
    std::stringstream ss(out);
    std::string item;
    while (std::getline(ss, item, '|'))
        parts.push_back(item);
    ASSERT_EQ(parts.size(), 7u);
    std::printf("[bench] load=%sms query=%sms serialize=%sms filter=%sms | tds=%s htmlLen=%s filterHits=%s\n",
                parts[0].c_str(), parts[1].c_str(), parts[2].c_str(),
                parts[3].c_str(), parts[4].c_str(), parts[5].c_str(),
                parts[6].c_str());
    std::fflush(stdout);
    // 结果正确性断言（基准也必须是正确性回归）
    EXPECT_EQ(parts[4], "3000");   // td.cell 数量（每 tr 一个）
    EXPECT_EQ(parts[6], "1");      // filter 命中 r1500
}
