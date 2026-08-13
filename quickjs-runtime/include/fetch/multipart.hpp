// fetchcore —— 流式 multipart/form-data 编码器（header-only）
//
// 大文件上传场景：FormData 不进内存、multipart body 惰性分段产出。
//   MultipartEncoder 实现 BodySource（read() 拉模型），喂给 Request::body_stream；
//   构造时预计算总长（各 part 大小已知：内存 data.size() 或文件 fstat）→
//   Request::body_size → BodyLengthMiddleware 设 Content-Length（服务器端与
//   普通 formdata 请求完全一致，无需 chunked）。
//   数据来源二选一：内存 std::string（data 非空）或文件路径（file_path；
//   分段读 64 KiB）。文件读取是同步阻塞 IO，但切到进程级文件线程池
//   （fetch::file_pool()，见 fetch/pool.hpp）执行——慢存储不卡 io_context
//   事件循环；读完切回 io_context 线程返回（网络写入始终在 io 线程发起）。
//   reset() 重放：seekg(0) 重开文件 + 状态重置（重试/307/308 保 body 重发）。
//
// 依赖方向：本头只依赖 fetch/body.hpp + fetch/scheduler.hpp + fetch/pool.hpp
// + 标准库；禁止 include quickjs/qjsbind 头。
#pragma once

#include <fetch/body.hpp>
#include <fetch/pool.hpp>
#include <fetch/scheduler.hpp>

#include <cstddef>
#include <fstream>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace fetch {

// 流式 multipart 编码器（BodySource；见头注释）
class MultipartEncoder : public BodySource {
public:
    struct Part {
        std::string name;
        std::string filename;   // 非空 = 文件字段（输出 filename="..."）
        std::string type;       // Content-Type（空 = 不输出）
        std::string data;       // 内存数据（非空则用；与 file_path 二选一）
        std::string file_path;  // 文件路径（流式分段读；fstat 拿大小）
        size_t size = 0;        // 数据总长（data.size() 或文件大小）
    };

    // 构造并预计算总长。任一文件 part 无法打开/stat → nullopt（调用方报错）。
    // 调用方须保证构造后文件不被截断（总长与实际发送一致）。
    // io：从当前线程 thread_local 取（文件读取在 pool 线程执行，读毕切回）；
    // pool：文件读取线程池，nullptr → 全局 fetch::file_pool()。
    static std::optional<MultipartEncoder> create(std::string boundary,
                                                  std::vector<Part> parts,
                                                  boost::asio::thread_pool* pool = nullptr)
    {
        MultipartEncoder enc;
        enc.boundary_ = std::move(boundary);
        enc.parts_ = std::move(parts);
        enc.io_sched_.emplace(fetch::thread_io());
        enc.pool_sched_.emplace(pool ? pool->get_executor()
                                     : fetch::file_pool().get_executor());
        enc.total_ = 2 + enc.boundary_.size() + 4; // 结束边界 "--b--\r\n"
        enc.states_.reserve(enc.parts_.size());
        for (auto& p : enc.parts_) {
            if (p.data.empty() && !p.file_path.empty()) {
                std::ifstream f(p.file_path, std::ios::binary);
                if (!f)
                    return std::nullopt;
                f.seekg(0, std::ios::end);
                const std::streamoff sz = f.tellg();
                if (sz < 0)
                    return std::nullopt;
                p.size = static_cast<size_t>(sz);
            }
            enc.total_ += 2 + enc.boundary_.size() + 2; // "--b\r\n"
            enc.total_ += part_head_len(p);
            enc.total_ += p.size + 2;                   // 数据 + "\r\n"
            State st;
            if (p.data.empty() && !p.file_path.empty())
                st.file_.open(p.file_path, std::ios::binary); // 保持打开（read 分段读）
            st.part = std::move(p);
            enc.states_.push_back(std::move(st));
        }
        return enc;
    }

    // 预计算总长（Content-Length 用；与 read() 产出字节数严格一致）
    size_t total_size() const noexcept { return total_; }

    // BodySource
    std_exec::task<std::optional<std::string>> read() override
    {
        if (finished_)
            co_return std::nullopt;
        // 数据后的 "\r\n"（part 完成）
        if (crlf_pending_) {
            crlf_pending_ = false;
            ++idx_;
            co_return "\r\n";
        }
        if (idx_ == states_.size()) {
            finished_ = true;
            co_return "--" + boundary_ + "--\r\n";
        }
        auto& st = states_[idx_];
        // 1. part 头（含 "--b\r\n" 前缀；一次产出）
        if (!st.head_emitted_) {
            st.head_emitted_ = true;
            co_return "--" + boundary_ + "\r\n" + part_head(st.part);
        }
        // 2. 数据：内存整块一次；文件分段 64 KiB——切到文件线程池做阻塞读
        //（慢存储不卡 io_context 事件循环），读完切回 io_context 线程再返回
        //（调用方紧接着 async_write(socket)，必须回到 io 线程）。read()/reset()
        // 由 transport 顺序 co_await 串行调用，文件句柄无跨线程并发访问。
        if (st.part.data.empty()) {
            co_await (*pool_sched_).schedule(); // → 文件线程
            std::string buf(64 * 1024, '\0');
            st.file_.read(buf.data(), static_cast<std::streamsize>(buf.size()));
            const std::streamsize got = st.file_.gcount();
            co_await (*io_sched_).schedule(); // → 切回 io_context 线程
            if (got > 0) {
                buf.resize(static_cast<size_t>(got));
                co_return buf;
            }
            // 文件读完：置 part 完成标记，返回空串（≠ EOF——状态机还有
            // "\r\n" 与结束边界要产出；调用方跳过空串继续）
            crlf_pending_ = true;
            co_return "";
        }
        crlf_pending_ = true;
        co_return st.part.data;
    }

    void cancel() override {}

    // 重放：文件 clear+seekg(0) + 状态重置（重试/重发前调用）
    void reset() override
    {
        for (auto& st : states_) {
            st.head_emitted_ = false;
            if (st.file_.is_open()) {
                st.file_.clear(); // 清 eofbit/failbit（read 读满文件会置位）
                st.file_.seekg(0, std::ios::beg); // 回到文件头
            }
        }
        idx_ = 0;
        crlf_pending_ = false;
        finished_ = false;
    }

private:
    static std::string escape(const std::string& s)
    {
        std::string r;
        for (const char c : s) {
            if (c == '"' || c == '\\')
                r.push_back('\\');
            r.push_back(c);
        }
        return r;
    }

    // part 头长度（不含 "--b\r\n" 前缀）。单源：直接量 part_head 输出长度，
    // 保证与 read() 实际产出严格一致（name/filename 含 \" 或 \\ 时未转义长度会偏小
    // → Content-Length 偏小 → 服务器挂起/截断；review should-fix）。
    static size_t part_head_len(const Part& p) { return part_head(p).size(); }

    static std::string part_head(const Part& p)
    {
        std::string out;
        out += "Content-Disposition: form-data; name=\"" + escape(p.name) + "\"";
        if (!p.filename.empty())
            out += "; filename=\"" + escape(p.filename) + "\"";
        out += "\r\n";
        if (!p.type.empty())
            out += "Content-Type: " + p.type + "\r\n";
        out += "\r\n";
        return out;
    }

    struct State {
        Part part;
        std::ifstream file_; // 文件 part 的流（read 惰性打开）
        bool head_emitted_ = false;
        size_t emitted_ = 0; // 预留：文件 part 已产出字节（校验用）
    };

    std::string boundary_;
    std::vector<Part> parts_;
    std::vector<State> states_;
    // 线程切换用（create 赋值；read() 仅在 create 成功后调用，必非空）：
    // 文件读取切到 pool_sched_ 线程，读毕切回 io_sched_ 线程再返回
    std::optional<io_scheduler> io_sched_;
    std::optional<pool_scheduler> pool_sched_;
    size_t total_ = 0;
    size_t idx_ = 0;
    bool crlf_pending_ = false;
    bool finished_ = false;
};

} // namespace fetch
