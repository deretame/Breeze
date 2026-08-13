// opencc_test.cpp —— opencc::convert 纯 C++ 单测（六种配置 + 边界）
//
// 期望值对应官方 OpenCC ver.1.1.9 的行为（数据同源、链式 MaxMatch 同语义）：
//   s2t.json  = [STPhrases + STCharacters]
//   t2s.json  = [TSPhrases + TSCharacters]
//   s2tw.json = [STPhrases + STCharacters] → [TWVariants]
//   tw2s.json = [TWVariantsRevPhrases + TWVariantsRev] → [TSPhrases + TSCharacters]
//   s2hk.json = [STPhrases + STCharacters] → [HKVariants]
//   hk2s.json = [HKVariantsRevPhrases + HKVariantsRev] → [TSPhrases + TSCharacters]
#include <gtest/gtest.h>

#include <opencc/opencc.hpp>

#include <stdexcept>
#include <string>

TEST(OpenccTest, S2T)
{
    // 单字 + 词组（STPhrases）
    EXPECT_EQ(opencc::convert("鼠标", "s2t.json"), "鼠標");
    EXPECT_EQ(opencc::convert("里面", "s2t.json"), "裏面");
    EXPECT_EQ(opencc::convert("头发", "s2t.json"), "頭髮");
    EXPECT_EQ(opencc::convert("一丝不挂", "s2t.json"), "一絲不掛");
    // 多候选取第一个：发 → 發（"头发"由词组表处理）
    EXPECT_EQ(opencc::convert("发生", "s2t.json"), "發生");
}

TEST(OpenccTest, T2S)
{
    EXPECT_EQ(opencc::convert("鼠標", "t2s.json"), "鼠标");
    EXPECT_EQ(opencc::convert("裏面", "t2s.json"), "里面");
    EXPECT_EQ(opencc::convert("頭髮", "t2s.json"), "头发");
    // 用词（軟體）不在 TSPhrases，走单字转换
    EXPECT_EQ(opencc::convert("軟體", "t2s.json"), "软体");
}

TEST(OpenccTest, S2TW)
{
    // TWVariants：裏 → 裡（区别于 s2t 的 裏面）
    EXPECT_EQ(opencc::convert("里面", "s2tw.json"), "裡面");
    EXPECT_EQ(opencc::convert("为", "s2tw.json"), "為"); // 爲 → 為（区别于 s2t 的 爲）
    EXPECT_EQ(opencc::convert("着", "s2tw.json"), "著");
}

TEST(OpenccTest, TW2S)
{
    EXPECT_EQ(opencc::convert("裡面", "tw2s.json"), "里面");
    EXPECT_EQ(opencc::convert("為", "tw2s.json"), "为");
    // TWVariantsRev：著 → 着（区别于 t2s 对"著"的处理）
    EXPECT_EQ(opencc::convert("著", "tw2s.json"), "着");
}

TEST(OpenccTest, S2HK)
{
    // HKVariants 保留 裏（区别于 s2tw 的 裡）
    EXPECT_EQ(opencc::convert("里面", "s2hk.json"), "裏面");
    EXPECT_EQ(opencc::convert("为", "s2hk.json"), "為");
}

TEST(OpenccTest, HK2S)
{
    EXPECT_EQ(opencc::convert("裏面", "hk2s.json"), "里面");
    EXPECT_EQ(opencc::convert("為", "hk2s.json"), "为");
}

TEST(OpenccTest, AsciiAndEmpty)
{
    EXPECT_EQ(opencc::convert("", "s2t.json"), "");
    // ASCII 与混合文本：非中文原样保留
    EXPECT_EQ(opencc::convert("abc 123 !@#", "s2t.json"), "abc 123 !@#");
    EXPECT_EQ(opencc::convert("hello 鼠标 world", "s2t.json"), "hello 鼠標 world");
    // 数字/标点夹在中文中间
    EXPECT_EQ(opencc::convert("第1集 头发", "s2t.json"), "第1集 頭髮");
}

TEST(OpenccTest, JP2T)
{
    // 日文新字体 → 旧字体/繁体：JPShinjitaiCharacters（両→兩）
    EXPECT_EQ(opencc::convert("両", "jp2t.json"), "兩");
    // JPVariantsRev（新→旧）：国→國
    EXPECT_EQ(opencc::convert("両国", "jp2t.json"), "兩國");
    // JPShinjitaiPhrases 词组：一獲千金 → 一攫千金
    EXPECT_EQ(opencc::convert("一獲千金", "jp2t.json"), "一攫千金");
    // 多候选取第一个：両 → 兩（候选 兩 輛）
    EXPECT_EQ(opencc::convert("両", "jp2t.json"), "兩");
}

TEST(OpenccTest, T2JP)
{
    // 旧字体/繁体 → 日文新字体（JPVariants：兩→両、國→国）
    EXPECT_EQ(opencc::convert("兩國", "t2jp.json"), "両国");
    EXPECT_EQ(opencc::convert("學", "t2jp.json"), "学");
    EXPECT_EQ(opencc::convert("亂", "t2jp.json"), "乱");
}

TEST(OpenccTest, JapaneseKanaUntouched)
{
    // 假名/平假名不参与转换（词典无假名条目）
    EXPECT_EQ(opencc::convert("あいうえお", "jp2t.json"), "あいうえお");
    EXPECT_EQ(opencc::convert("カタカナ", "t2jp.json"), "カタカナ");
    // 混合文本：汉字转、假名保留
    EXPECT_EQ(opencc::convert("日本語を学ぶ", "jp2t.json"), "日本語を學ぶ");
    EXPECT_EQ(opencc::convert("日本語を學ぶ", "t2jp.json"), "日本語を学ぶ");
}

TEST(OpenccTest, UnknownConfig)
{
    EXPECT_FALSE(opencc::is_valid_config("s2x.json"));
    EXPECT_TRUE(opencc::is_valid_config("s2t.json"));
    EXPECT_THROW(opencc::convert("鼠标", "s2x.json"), std::invalid_argument);
}

TEST(OpenccTest, RoundTrip)
{
    // 简→繁→简 往返保持（常用词）
    EXPECT_EQ(opencc::convert(opencc::convert("软件开发", "s2t.json"), "t2s.json"),
              "软件开发");
    EXPECT_EQ(opencc::convert(opencc::convert("中国大陆", "s2t.json"), "t2s.json"),
              "中国大陆");
    // 台湾变体往返
    EXPECT_EQ(opencc::convert(opencc::convert("里面", "s2tw.json"), "tw2s.json"),
              "里面");
}

TEST(OpenccTest, LongText)
{
    // 长文本冒烟（含词组 + 单字混合），验证 MaxMatch 逐位置推进
    const std::string in =
        "中华人民共和国成立于1949年，软件开发行业蓬勃发展。"
        "头发与皮肤护理都很重要，鼠标和键盘是电脑外设。";
    const std::string out = opencc::convert(in, "s2t.json");
    EXPECT_NE(out, in);
    EXPECT_NE(out.find("中華人民共和國"), std::string::npos); // 词组已转繁
    EXPECT_NE(out.find("頭髮"), std::string::npos);
    EXPECT_NE(out.find("鼠標"), std::string::npos);
    EXPECT_NE(out.find("1949"), std::string::npos); // ASCII 保留
}
