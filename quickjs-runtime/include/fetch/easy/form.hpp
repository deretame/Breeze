// fetch::easy —— reqwest 风格 multipart（Form/Part）
//
// 参考 rust reqwest::multipart 的链式 API：
//   Form form = Form::new();
//   form.text("username", "sean")
//       .part("files", Part::bytes(data).file_name("foo.txt").mime("text/plain"))
//       .file("avatar", "path/to/avatar.png");
//   co_await client.post(url).multipart(std::move(form)).send();
//
// 底层复用 fetchcore 的 fetch::FormData + encode_multipart（include/fetch/formdata.hpp）；
// .multipart() 自动生成随机 boundary 与 Content-Type: multipart/form-data; boundary=...
//（仅当未手动设置 Content-Type 时）。本头是 fetchcore 之上的便捷层，不改 fetchcore
// 任何接口。
#pragma once

#include <fetch/formdata.hpp>

#include <cctype>
#include <cstdint>
#include <random>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace fetch {
namespace easy {

// ===================== Part（reqwest::multipart::Part 等价物） =====================

class Part {
public:
    // 文本值：序列化为普通字段（无 filename/Content-Type）
    static Part text(std::string value)
    {
        Part p;
        p.bytes_ = std::move(value);
        return p;
    }

    // 字节值：未设 file_name/mime 时作为普通字段；设置后成为文件字段
    static Part bytes(std::string data)
    {
        Part p;
        p.bytes_ = std::move(data);
        return p;
    }

    // 设 filename：该 part 成为文件字段（multipart 输出 filename="..."）
    Part& file_name(std::string name)
    {
        filename_ = std::move(name);
        is_blob_ = true;
        return *this;
    }

    // 设 Content-Type（multipart 输出 Content-Type: ...）
    Part& mime(std::string mime)
    {
        type_ = std::move(mime);
        is_blob_ = true;
        return *this;
    }

    // 转 fetchcore 条目（name 由 Form 填充；语义与 fetch::FormData::Entry 对齐）
    fetch::FormData::Entry to_entry() const
    {
        fetch::FormData::Entry e;
        e.bytes = bytes_;
        e.type = type_;
        e.filename = filename_;
        e.is_blob = is_blob_;
        return e;
    }

private:
    std::string bytes_;
    std::string type_;
    std::string filename_;
    bool is_blob_ = false;
};

// ===================== Form（reqwest::multipart::Form 等价物） =====================

class Form {
public:
    // 流式文件 part（不整读进内存）：mime 空 = 按扩展名猜（guess_mime）
    struct FilePart {
        std::string name;
        std::string path;
        std::string mime;
    };

    Form() = default;

    // 添加文本字段
    Form& text(std::string name, std::string value)
    {
        parts_.emplace_back(std::move(name), Part::text(std::move(value)));
        return *this;
    }

    // 添加 Part 字段（bytes + file_name/mime 组合）
    Form& part(std::string name, Part p)
    {
        parts_.emplace_back(std::move(name), std::move(p));
        return *this;
    }

    // 添加流式文件字段：不读文件进内存（大文件友好）——打开/大小校验延迟到
    // .multipart()（MultipartEncoder::create 失败 → send 抛 easy::Error(decode)）。
    // Content-Type：mime 非空手动指定，否则按扩展名猜（guess_mime）。
    Form& file(std::string name, std::string path, std::string mime = {})
    {
        files_.push_back({std::move(name), std::move(path), std::move(mime)});
        return *this;
    }

    // 内存 part 列表（RequestBuilder::multipart 组装用）
    const std::vector<std::pair<std::string, Part>>& parts() const noexcept { return parts_; }
    // 流式文件 part 列表
    const std::vector<FilePart>& files() const noexcept { return files_; }

    // 转 fetchcore FormData（仅内存 part；含文件 part 时置 error()）
    fetch::FormData to_formdata() const
    {
        if (!files_.empty()) {
            error_ = "Form 含流式文件 part：请用 RequestBuilder::multipart() 流式发送";
            return {};
        }
        fetch::FormData fd;
        for (const auto& [name, part] : parts_) {
            auto e = part.to_entry();
            e.name = name;
            fd.list.push_back(std::move(e));
        }
        return fd;
    }

    // 扩展名 → MIME 猜测（对齐 reqwest mime_guess）：按 path 的最后一个扩展名查表
    //（大小写不敏感）；无扩展名或未知 → application/octet-stream。
    static std::string guess_mime(std::string_view path)
    {
        const size_t dot = path.find_last_of('.');
        std::string key;
        if (dot != std::string_view::npos) {
            key.reserve(path.size() - dot - 1);
            for (size_t i = dot + 1; i < path.size(); ++i)
                key.push_back(static_cast<char>(
                    std::tolower(static_cast<unsigned char>(path[i]))));
        }
        static const std::unordered_map<std::string, std::string> table = {
            {"txt", "text/plain"},
            {"html", "text/html"},
            {"htm", "text/html"},
            {"css", "text/css"},
            {"csv", "text/csv"},
            {"json", "application/json"},
            {"xml", "application/xml"},
            {"js", "text/javascript"},
            {"mjs", "text/javascript"},
            {"pdf", "application/pdf"},
            {"zip", "application/zip"},
            {"gz", "application/gzip"},
            {"tar", "application/x-tar"},
            {"png", "image/png"},
            {"jpg", "image/jpeg"},
            {"jpeg", "image/jpeg"},
            {"gif", "image/gif"},
            {"webp", "image/webp"},
            {"svg", "image/svg+xml"},
            {"ico", "image/x-icon"},
            {"bmp", "image/bmp"},
            {"mp3", "audio/mpeg"},
            {"wav", "audio/wav"},
            {"ogg", "audio/ogg"},
            {"mp4", "video/mp4"},
            {"webm", "video/webm"},
            {"mov", "video/quicktime"},
            {"doc", "application/msword"},
            {"docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
            {"xls", "application/vnd.ms-excel"},
            {"xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
            {"ppt", "application/vnd.ms-powerpoint"},
            {"pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"},
        };
        const auto it = table.find(key);
        return it == table.end() ? "application/octet-stream" : it->second;
    }

    // 取路径的 basename（multipart 组装时作 filename）
    static std::string file_basename(const std::string& path)
    {
        const size_t p = path.find_last_of("/\\");
        return p == std::string::npos ? path : path.substr(p + 1);
    }

    // 随机 boundary（multipart/form-data; boundary=...；与绑定层同风格）
    std::string boundary() const
    {
        static const char* hexd = "0123456789abcdef";
        std::random_device rd;
        std::mt19937_64 gen(rd());
        std::string b = "----qjsformdata";
        for (int i = 0; i < 16; ++i)
            b.push_back(hexd[gen() & 15]);
        return b;
    }

    // Form::file 失败信息（空 = 无错误；to_formdata 遇文件 part 时置位）
    const std::string& error() const noexcept { return error_; }

private:
    std::vector<std::pair<std::string, Part>> parts_;
    std::vector<FilePart> files_; // 流式文件 part（name/path/mime 覆盖）
    mutable std::string error_;
};

} // namespace easy
} // namespace fetch
