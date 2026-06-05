#pragma once

#include <string>
#include <spa/param/video/format-utils.h>
#include <opencv2/imgproc/imgproc_c.h>
#include <X11/Xlib.h>

enum class SpaVideoFormat_e {
  RGBx = SPA_VIDEO_FORMAT_RGBx,
  BGRx = SPA_VIDEO_FORMAT_BGRx,
  RGBA = SPA_VIDEO_FORMAT_RGBA,
  BGRA = SPA_VIDEO_FORMAT_BGRA,
  RGB = SPA_VIDEO_FORMAT_RGB,
  BGR = SPA_VIDEO_FORMAT_BGR,
  INVALID = -1
};

inline std::string spa_to_string(SpaVideoFormat_e const& format){
  switch (format) {
    case SpaVideoFormat_e::RGBx:
      return "RGBx";
    case SpaVideoFormat_e::BGRx:
      return "BGRx";
    case SpaVideoFormat_e::RGBA:
      return "RGBA";
    case SpaVideoFormat_e::BGRA:
      return "BGRA";
    case SpaVideoFormat_e::RGB:
      return "RGB";
    case SpaVideoFormat_e::BGR:
      return "BGR";
    default:
      return "INVALID";
  }
}

// A VERY tedious color convert code getter
// This can be handled more gracefully using something like string matching...
// however let it be it for now
// note: -1 means no conversion is needed
inline int get_opencv_cAPI_color_convert_code(
  SpaVideoFormat_e const& src_format,
  SpaVideoFormat_e const& dst_format
){
  // shortcut1: src and dst match exactly
  if (src_format == dst_format) {
    return -1;
  }
  // shortcut2: RGBA == RGBx
  if (src_format == SpaVideoFormat_e::RGBA && dst_format == SpaVideoFormat_e::RGBx ||
      src_format == SpaVideoFormat_e::RGBx && dst_format == SpaVideoFormat_e::RGBA
  ) {
    return -1;
  }
  // shortcut3: BGRA == BGRx
  if (src_format == SpaVideoFormat_e::BGRA && dst_format == SpaVideoFormat_e::BGRx ||
      src_format == SpaVideoFormat_e::BGRx && dst_format == SpaVideoFormat_e::BGRA
  ) {
    return -1;
  }
  if (src_format == SpaVideoFormat_e::RGB){
    // RGB -> BGR
    if (dst_format == SpaVideoFormat_e::BGR){
      return CV_RGB2BGR;
    }
    // RGB -> BGRA / BGRx
    if (dst_format == SpaVideoFormat_e::BGRA || dst_format == SpaVideoFormat_e::BGRx){
      return CV_RGB2BGRA;
    }
    // RGB -> RGBA / RGBx
    if (dst_format == SpaVideoFormat_e::RGBA || dst_format == SpaVideoFormat_e::RGBx){
      return CV_RGB2RGBA;
    }
  }

  if (src_format == SpaVideoFormat_e::BGR){
    // BGR -> RGB
    if (dst_format == SpaVideoFormat_e::RGB){
      return CV_BGR2RGB;
    }
    // BGR -> BGRA / BGRx
    if (dst_format == SpaVideoFormat_e::BGRA || dst_format == SpaVideoFormat_e::BGRx){
      return CV_BGR2BGRA;
    }
    // BGR -> RGBA / RGBx
    if (dst_format == SpaVideoFormat_e::RGBA || dst_format == SpaVideoFormat_e::RGBx){
      return CV_BGR2RGBA;
    }
  }

  if (src_format == SpaVideoFormat_e::RGBA || src_format == SpaVideoFormat_e::RGBx){
    // RGBA/RGBx -> RGB
    if (dst_format == SpaVideoFormat_e::RGB){
      return CV_RGBA2RGB;
    }
    // RGBA/RGBx -> BGR
    if (dst_format == SpaVideoFormat_e::BGR){
      return CV_RGBA2BGR;
    }
    // RGBA/RGBx -> BGRA/BGRx
    if (dst_format == SpaVideoFormat_e::BGRA || dst_format == SpaVideoFormat_e::BGRx){
      return CV_RGBA2BGRA;
    }
  }

  if (src_format == SpaVideoFormat_e::BGRA || src_format == SpaVideoFormat_e::BGRx){
    // BGRA/BGRx -> RGB
    if (dst_format == SpaVideoFormat_e::RGB){
      return CV_BGRA2RGB;
    }
    // BGRA/BGRx -> BGR
    if (dst_format == SpaVideoFormat_e::BGR){
      return CV_BGRA2BGR;
    }
    // BGRA/BGRx -> RGBA/RGBx
    if (dst_format == SpaVideoFormat_e::RGBA || dst_format == SpaVideoFormat_e::RGBx){
      return CV_BGRA2RGBA;
    }
  }

  // guard
  return -1;
}


inline auto spa_videoformat_bytesize(const SpaVideoFormat_e& format) -> int {
  switch (format) {
    case SpaVideoFormat_e::RGBx:
      return 4;
    case SpaVideoFormat_e::BGRx:
      return 4;
    case SpaVideoFormat_e::RGBA:
      return 4;
    case SpaVideoFormat_e::BGRA:
      return 4;
    case SpaVideoFormat_e::RGB:
      return 3;
    case SpaVideoFormat_e::BGR:
      return 3;
    default:
      return -1;
  }
}

inline auto ximage_to_spa(const XImage& ximage) -> SpaVideoFormat_e {
  if (ximage.format != 2){
    // we only support ZPixmap
    return SpaVideoFormat_e::INVALID;
  }
  if (ximage.bits_per_pixel == 32) {
    // possibly RGBA, BGRA, RGBx or BGRx
    // we just combine RGBx and BGRx to RGBA and BGRA, respectively
    if (ximage.red_mask == 0xff0000 && ximage.green_mask == 0xff00 && ximage.blue_mask == 0xff) {
      return SpaVideoFormat_e::BGRA;
    } else if (ximage.red_mask == 0xff && ximage.green_mask == 0xff00 && ximage.blue_mask == 0xff0000) {
      return SpaVideoFormat_e::RGBA;
    } else {
      return SpaVideoFormat_e::INVALID;
    }
  } else {
    // possibly RGB or BGR
    if (ximage.red_mask == 0xff0000 && ximage.green_mask == 0xff00 && ximage.blue_mask == 0xff) {
      return SpaVideoFormat_e::BGR;
    } else if (ximage.red_mask == 0xff && ximage.green_mask == 0xff00 && ximage.blue_mask == 0xff0000) {
      return SpaVideoFormat_e::RGB;
    } else {
      return SpaVideoFormat_e::INVALID;
    }
  }
    
}
