#include "jm_decode.h"

#include "jm_md5.h"

#include <png.h>
#include <webp/decode.h>
#include <webp/encode.h>

#include <csetjmp>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <utility>
#include <vector>

namespace jm_decode {
namespace {

constexpr std::int32_t kScrambleId = 220980;

enum class ImageFormat { kPng, kWebP, kGif, kJpeg, kUnknown };

ImageFormat guess_format(const std::uint8_t* data, std::int32_t len) {
  if (len >= 6 && (std::memcmp(data, "GIF87a", 6) == 0 ||
                   std::memcmp(data, "GIF89a", 6) == 0)) {
    return ImageFormat::kGif;
  }
  if (len >= 12 && std::memcmp(data, "RIFF", 4) == 0 &&
      std::memcmp(data + 8, "WEBP", 4) == 0) {
    return ImageFormat::kWebP;
  }
  static constexpr std::uint8_t kPngMagic[8] = {0x89, 0x50, 0x4e, 0x47,
                                                0x0d, 0x0a, 0x1a, 0x0a};
  if (len >= 8 && std::memcmp(data, kPngMagic, 8) == 0) {
    return ImageFormat::kPng;
  }
  if (len >= 3 && data[0] == 0xff && data[1] == 0xd8 && data[2] == 0xff) {
    return ImageFormat::kJpeg;
  }
  return ImageFormat::kUnknown;
}

/// 从 url 中取图片名（最后一段去掉扩展名），对应 Rust 的 picture_name。
std::string picture_name_from_url(const std::string& url) {
  const auto slash = url.rfind('/');
  const std::string name =
      slash == std::string::npos ? url : url.substr(slash + 1);
  const auto dot = name.find('.');
  return dot == std::string::npos ? name : name.substr(0, dot);
}

/// 与 Rust get_segmentation_num 完全一致。
/// 注意：Rust 里 `hash_str.chars().last().unwrap() as u8` 取的是最后一个
/// 十六进制字符的 ASCII 码值，不是它的数值。
std::int32_t get_segmentation_num(std::int32_t eps_id,
                                  std::int32_t scramble_id,
                                  const std::string& picture_name) {
  if (eps_id < scramble_id) {
    return 0;
  }
  if (eps_id < 268850) {
    return 10;
  }
  const std::string s = std::to_string(eps_id) + picture_name;
  const std::string hash_str = jm_md5::hex(s);
  const auto last_char = static_cast<std::uint8_t>(hash_str.back());
  if (eps_id > 421926) {
    return static_cast<std::int32_t>(last_char % 8) * 2 + 2;
  }
  return static_cast<std::int32_t>(last_char % 10) * 2 + 2;
}

// ────────────────────────── PNG 解码 ──────────────────────────

struct PngMemReader {
  const std::uint8_t* data;
  std::size_t len;
  std::size_t pos;
};

void png_mem_read(png_structp png, png_bytep out, png_size_t count) {
  auto* reader = static_cast<PngMemReader*>(png_get_io_ptr(png));
  if (reader->pos + count > reader->len) {
    png_error(png, "read past end of buffer");
  }
  std::memcpy(out, reader->data + reader->pos, count);
  reader->pos += count;
}

/// 解码 PNG 为 RGB24。失败抛 std::runtime_error。
std::vector<std::uint8_t> decode_png_rgb(const std::uint8_t* data,
                                         std::size_t len,
                                         std::uint32_t& out_width,
                                         std::uint32_t& out_height) {
  png_structp png =
      png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
  if (!png) {
    throw std::runtime_error("png_create_read_struct failed");
  }
  png_infop info = png_create_info_struct(png);
  if (!info) {
    png_destroy_read_struct(&png, nullptr, nullptr);
    throw std::runtime_error("png_create_info_struct failed");
  }

  PngMemReader reader{data, len, 0};
  std::vector<std::uint8_t> pixels;

  // libpng 的错误处理基于 setjmp/longjmp，出错时会跳回这里
  if (setjmp(png_jmpbuf(png))) {
    png_destroy_read_struct(&png, &info, nullptr);
    throw std::runtime_error("failed to decode png");
  }

  png_set_read_fn(png, &reader, png_mem_read);
  png_read_info(png, info);

  png_uint_32 width = png_get_image_width(png, info);
  png_uint_32 height = png_get_image_height(png, info);
  const int bit_depth = png_get_bit_depth(png, info);
  const int color_type = png_get_color_type(png, info);

  // 统一转换为 RGB24，对齐 Rust image 的 to_rgb8()
  if (color_type == PNG_COLOR_TYPE_PALETTE) {
    png_set_palette_to_rgb(png);
  }
  if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
    png_set_expand_gray_1_2_4_to_8(png);
  }
  if (png_get_valid(png, info, PNG_INFO_tRNS)) {
    png_set_tRNS_to_alpha(png);
  }
  if (bit_depth == 16) {
    png_set_strip_16(png);
  }
  // to_rgb8() 直接丢弃 alpha
  png_set_strip_alpha(png);
  if (color_type == PNG_COLOR_TYPE_GRAY ||
      color_type == PNG_COLOR_TYPE_GRAY_ALPHA) {
    png_set_gray_to_rgb(png);
  }

  png_read_update_info(png, info);

  const std::size_t row_bytes = static_cast<std::size_t>(width) * 3;
  if (png_get_rowbytes(png, info) != row_bytes) {
    png_destroy_read_struct(&png, &info, nullptr);
    throw std::runtime_error("unexpected png row size after transforms");
  }

  pixels.resize(row_bytes * height);
  std::vector<png_bytep> rows(height);
  for (png_uint_32 y = 0; y < height; ++y) {
    rows[y] = pixels.data() + y * row_bytes;
  }
  png_read_image(png, rows.data());
  png_read_end(png, nullptr);

  png_destroy_read_struct(&png, &info, nullptr);
  out_width = width;
  out_height = height;
  return pixels;
}

// ────────────────────────── WebP 解码 ──────────────────────────

std::vector<std::uint8_t> decode_webp_rgb(const std::uint8_t* data,
                                          std::size_t len,
                                          std::uint32_t& out_width,
                                          std::uint32_t& out_height) {
  int width = 0;
  int height = 0;
  std::uint8_t* decoded = WebPDecodeRGB(data, len, &width, &height);
  if (!decoded) {
    throw std::runtime_error("failed to decode webp");
  }
  const std::size_t size =
      static_cast<std::size_t>(width) * static_cast<std::size_t>(height) * 3;
  std::vector<std::uint8_t> pixels(decoded, decoded + size);
  WebPFree(decoded);
  out_width = static_cast<std::uint32_t>(width);
  out_height = static_cast<std::uint32_t>(height);
  return pixels;
}

// ────────────────────── 块逆序重组 + WebP 编码 ──────────────────────

/// 对应 Rust rearrange_blocks_by_block：把高度均分为 num 块后逆序拼接。
void rearrange_blocks_reverse(const std::vector<std::uint8_t>& src,
                              std::uint32_t width,
                              std::uint32_t height,
                              std::int32_t num,
                              std::vector<std::uint8_t>& dst) {
  const std::size_t row_bytes = static_cast<std::size_t>(width) * 3;
  const std::uint32_t block_size = height / static_cast<std::uint32_t>(num);
  const std::uint32_t remainder = height % static_cast<std::uint32_t>(num);

  dst.resize(src.size());
  std::uint32_t y_pos = 0;
  for (std::int32_t i = num - 1; i >= 0; --i) {
    const std::uint32_t start = static_cast<std::uint32_t>(i) * block_size;
    const std::uint32_t end =
        i == num - 1 ? start + block_size + remainder : start + block_size;
    const std::size_t block_bytes = (end - start) * row_bytes;
    std::memcpy(dst.data() + y_pos * row_bytes,
                src.data() + start * row_bytes,
                block_bytes);
    y_pos += end - start;
  }
}

/// 对应 Rust Encoder::from_rgb(...).encode(75.0)（libwebp 简单 API）。
std::vector<std::uint8_t> encode_webp(const std::vector<std::uint8_t>& rgb,
                                      std::uint32_t width,
                                      std::uint32_t height) {
  std::uint8_t* output = nullptr;
  const std::size_t size =
      WebPEncodeRGB(rgb.data(), static_cast<int>(width),
                    static_cast<int>(height), static_cast<int>(width) * 3,
                    75.0f, &output);
  if (size == 0 || output == nullptr) {
    throw std::runtime_error("failed to encode webp");
  }
  std::vector<std::uint8_t> encoded(output, output + size);
  WebPFree(output);
  return encoded;
}

// ────────────────────────── 文件写入 ──────────────────────────

void save_image(const std::uint8_t* data, std::size_t len,
                const std::string& file_path) {
  const std::filesystem::path path(file_path);
  const auto parent = path.parent_path();
  if (!parent.empty()) {
    std::error_code ec;
    std::filesystem::create_directories(parent, ec);
    if (ec) {
      throw std::runtime_error("failed to create directory: " +
                               parent.string());
    }
  }
  std::ofstream file(path, std::ios::binary | std::ios::trunc);
  if (!file) {
    throw std::runtime_error("failed to open file: " + file_path);
  }
  file.write(reinterpret_cast<const char*>(data),
             static_cast<std::streamsize>(len));
  if (!file) {
    throw std::runtime_error("failed to write file: " + file_path);
  }
}

}  // namespace

void anti_obfuscation_picture(const std::uint8_t* img_data,
                              std::int32_t img_len,
                              std::int32_t chapter_id,
                              const std::string& url,
                              const std::string& file_name) {
  if (img_data == nullptr || img_len <= 0) {
    throw std::runtime_error("empty image data");
  }

  const ImageFormat format = guess_format(img_data, img_len);
  const std::string picture_name = picture_name_from_url(url);
  const std::int32_t num =
      get_segmentation_num(chapter_id, kScrambleId, picture_name);

  // GIF 或无需切割：原样落盘
  if (format == ImageFormat::kGif || num <= 1) {
    save_image(img_data, static_cast<std::size_t>(img_len), file_name);
    return;
  }

  std::uint32_t width = 0;
  std::uint32_t height = 0;
  std::vector<std::uint8_t> rgb;
  switch (format) {
    case ImageFormat::kPng:
      rgb = decode_png_rgb(img_data, static_cast<std::size_t>(img_len), width,
                           height);
      break;
    case ImageFormat::kWebP:
      rgb = decode_webp_rgb(img_data, static_cast<std::size_t>(img_len),
                            width, height);
      break;
    default:
      throw std::runtime_error(
          "unsupported image format for de-scramble (only png/webp)");
  }

  std::vector<std::uint8_t> rearranged;
  rearrange_blocks_reverse(rgb, width, height, num, rearranged);

  const std::vector<std::uint8_t> encoded =
      encode_webp(rearranged, width, height);
  save_image(encoded.data(), encoded.size(), file_name);
}

}  // namespace jm_decode
