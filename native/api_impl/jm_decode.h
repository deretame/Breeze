#pragma once

// 禁漫图片反混淆（移植自 rust/src/decode/segmentation.rs）。
//
// 流程：
//   1. 按 magic bytes 探测图片格式；GIF 或不需切割的图片直接原样落盘。
//   2. 用 MD5(章节 id + 图片名) 计算切割块数。
//   3. 解码为 RGB（PNG 走 libpng，WebP 走 libwebp），按块逆序重组。
//   4. 以 quality=75 重新编码为 WebP 并写入磁盘。

#include <cstdint>
#include <string>
#include <vector>

namespace jm_decode {

/// 反混淆并保存图片。
///
/// @param img_data   原始图片字节（PNG / WebP / GIF）
/// @param img_len    字节数
/// @param chapter_id 章节 id
/// @param url        图片完整 url（用于取图片名计算切割数）
/// @param file_name  输出文件完整路径（父目录会自动创建）
///
/// 失败时抛出 std::runtime_error。
void anti_obfuscation_picture(const std::uint8_t* img_data,
                              std::int32_t img_len,
                              std::int32_t chapter_id,
                              const std::string& url,
                              const std::string& file_name);

}  // namespace jm_decode
