// fetchcore —— 中性 C++ 异常类型
//
// 核心库只抛中性异常：URL/协议/策略错误抛 fetch::Error（SRI 校验失败、
// redirect mode 冲突、data: URL 解析失败等）；网络/TLS/SOCKS5 抛
// boost::system::system_error；body 阶段由 BodySource::read() 抛
// std::exception。绑定层捕获后统一映射 JS TypeError。
//
// 注意：fetch::Error 必须可拷贝（MSVC 协程异常传播对 move-only 异常类型
// 损坏，见 docs/known_issues.md KI-051）。
#pragma once

#include <stdexcept>
#include <string>

namespace fetch {

class Error : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

} // namespace fetch
