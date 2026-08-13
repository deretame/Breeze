// fetchcore —— 响应体字节源（拉模型）
//
// read()：返回一块字节（可任意大小）；nullopt = EOF。失败抛 std::exception
// （网络/协议/解压错误，读取路径统一由绑定层转 TypeError）。
// cancel()：尽力取消（关闭 socket、释放资源），幂等，可能在其他线程触发。
#pragma once

#include <fetch/types.hpp>

#include <memory>
#include <optional>
#include <string>
#include <utility>

namespace fetch {

struct BodySource {
    virtual ~BodySource() = default;
    virtual std_exec::task<std::optional<std::string>> read() = 0;
    virtual void cancel() = 0;
    // 重放：回到初始状态（重试/重发前调用；默认 no-op）
    virtual void reset() {}
};

// 内存字节源（data: URL、测试直连等整收字节场景）
class BytesBodySource : public BodySource {
public:
    explicit BytesBodySource(std::string bytes) : bytes_(std::move(bytes)) {}

    std_exec::task<std::optional<std::string>> read() override
    {
        if (pos_ >= bytes_.size())
            co_return std::nullopt;
        std::string out = bytes_.substr(pos_);
        pos_ = bytes_.size();
        co_return out;
    }

    void cancel() override {}

private:
    std::string bytes_;
    size_t pos_ = 0;
};

// 便捷整读（C++ 侧没有 .text()，给一个等效物）。无 body → 空串。
inline std_exec::task<std::string> read_all(const Response& resp)
{
    std::string out;
    if (!resp.body)
        co_return out;
    for (;;) {
        auto block = co_await resp.body->read();
        if (!block)
            break;
        out += *block;
    }
    co_return out;
}

} // namespace fetch
