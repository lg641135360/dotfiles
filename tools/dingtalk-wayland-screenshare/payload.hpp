#pragma once

#include <atomic>
#include <cstdio>
#include <chrono>
#include <vector>
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/dma-buf.h>

#include <glib-2.0/glib.h>
#include <glib-2.0/gio/gio.h>
#include <libportal/portal.h>

#include <memory>
#include <pipewire-0.3/pipewire/pipewire.h>
#include <spa/buffer/buffer.h>
#include <spa/param/buffers.h>
#include <spa/param/video/format-utils.h>
#include <spa/debug/pod.h>
#include <spa/utils/dict.h>
#include <drm/drm_fourcc.h>

#include "format.hpp"
#include "interface.hpp"

#include "helpers.hpp"

enum class DEType {
  GNOME,
  KDE,
  Hyprland, // Hyprland does not support XDP_CURSOR_MODE_HIDDEN, dang it... 
  Unknown // possibly wlr or some other magical DE
};

inline DEType get_current_de_type(){
  // get the DE type using envvar "XDG_SESSION_DESKTOP"
  char* xdg_session_desktop = std::getenv("XDG_SESSION_DESKTOP");
  if (xdg_session_desktop == nullptr) {
    return DEType::Unknown;
  }
  std::string xdg_session_desktop_str = xdg_session_desktop;
  std::string xdg_session_desktop_lower = toLowerString(xdg_session_desktop_str);
  if (std::string(xdg_session_desktop) == "KDE") {
    return DEType::KDE;
  } else if (std::string(xdg_session_desktop) == "gnome") {
    return DEType::GNOME;
  } else if (xdg_session_desktop_lower == "hyprland") {
    return DEType::Hyprland;
  }
  return DEType::Unknown;
}

enum class SessionType {
  Wayland,
  X11,
  Unknown // heck, unless you did not set the envar properly...
};

inline SessionType get_current_session_type(){
  // get the current session type using envvar "XDG_SESSION_TYPE"
  char* xdg_session_type = std::getenv("XDG_SESSION_TYPE");
  if (xdg_session_type == nullptr) {
    return SessionType::Unknown;
  }
  if (std::string(xdg_session_type) == "wayland") {
    return SessionType::Wayland;
  } else if (std::string(xdg_session_type) == "x11") {
    return SessionType::X11;
  }
  return SessionType::Unknown;
}

enum class XdpScreencastPortalStatus {
  kInit,
  kRunning,
  kCancelled,
};

struct XdpScreencastPortal {

  using THIS_CLASS = XdpScreencastPortal;

  XdpScreencastPortal() {
    portal = xdp_portal_new();
    XdpOutputType output_type = (XdpOutputType)(XdpOutputType::XDP_OUTPUT_MONITOR | XdpOutputType::XDP_OUTPUT_WINDOW);
    XdpScreencastFlags cast_flags = XdpScreencastFlags::XDP_SCREENCAST_FLAG_NONE;
    XdpCursorMode cursor_mode = get_current_session_type() == SessionType::Wayland ? 
                                XDP_CURSOR_MODE_EMBEDDED :
                                XDP_CURSOR_MODE_HIDDEN;
    
    // hyprland cursor mode workaround.
    // as hyprland does not support XDP_CURSOR_MODE_HIDDEN, we simply use XDP_CURSOR_MODE_EMBEDDED for it
    if (get_current_de_type() == DEType::Hyprland) {
      cursor_mode = XDP_CURSOR_MODE_EMBEDDED;
    }
    XdpPersistMode persist_mode = XdpPersistMode::XDP_PERSIST_MODE_NONE;
    xdp_portal_create_screencast_session(
      portal,
      output_type,
      cast_flags,
      cursor_mode,
      persist_mode,
      NULL,
      NULL,
      THIS_CLASS::screencast_session_create_cb,
      this
    );
    gio_mainloop = g_main_loop_new(NULL, FALSE);
  }


  ~XdpScreencastPortal() {
    if (session) xdp_session_close(session);
    if (session) g_object_unref(session);
    if (portal) g_object_unref(portal);
    if (gio_mainloop) g_main_loop_unref(gio_mainloop);
  }


  GMainLoop* gio_mainloop{nullptr};
  XdpPortal* portal{nullptr};
  std::atomic<XdpSession*> session{nullptr};
  std::atomic<int> pipewire_fd{-1};
  std::atomic<XdpScreencastPortalStatus> status{XdpScreencastPortalStatus::kInit};
  std::vector<unsigned> pipewire_node_ids{};

  static void screencast_session_create_cb(
    GObject* source_object,
    GAsyncResult* result,
    gpointer user_data
  ){
    [[maybe_unused]] auto* this_ptr = reinterpret_cast<THIS_CLASS*>(user_data);
    g_autoptr(GError) error = nullptr;
    this_ptr->session = xdp_portal_create_screencast_session_finish(
      XDP_PORTAL(source_object),
      result,
      &error
    );
    if (!this_ptr->session) {
      g_print("Failed to create screencast session: %s\n", error->message);
      return; //TODO: handle error
    }

  }

  static void screencast_session_start_cb(
    GObject* source_object,
    GAsyncResult* result,
    gpointer user_data
  ){
    [[maybe_unused]] auto* this_ptr = reinterpret_cast<THIS_CLASS*>(user_data);
    GError *error = nullptr;
    if (!xdp_session_start_finish(XDP_SESSION(source_object), result, &error)) {
        g_warning("Failed to start screencast session: %s", error->message);
        g_error_free(error);
        this_ptr->status = XdpScreencastPortalStatus::kCancelled;
        return;
    }
    this_ptr->status.store(XdpScreencastPortalStatus::kRunning, std::memory_order_release);
    this_ptr->pipewire_fd = xdp_session_open_pipewire_remote(XDP_SESSION(source_object));

    // get pipewire node ids
    // there is only one id as XDP_SCREENCAST_FLAG_NONE is chosen
    GVariant *streams = xdp_session_get_streams(XDP_SESSION(source_object));
    GVariantIter *iter = g_variant_iter_new(streams);
    unsigned node_id;
    while (g_variant_iter_next(iter, "(ua{sv})", &node_id, NULL)) {
      this_ptr->pipewire_node_ids.push_back(node_id);
      fprintf(stderr, "%s\n", green_text("[hook] stream node_id: " + std::to_string(node_id)).c_str());
      dingtalk_debug_log("portal stream node_id: " + std::to_string(node_id));
    }
    g_variant_iter_free(iter);
  }
  
};



struct PipewireScreenCast {
  using THIS_CLASS = PipewireScreenCast;

  PipewireScreenCast(int pw_fd, int pw_node_id, double target_framerate = 20.0, uint64_t reporting_interval = 20):
    node_id(pw_node_id),
    target_framerate(target_framerate),
    reporting_interval(reporting_interval),
    processed_frame_count(0)
  {
    reset_last_frame_time();
    pw_init(nullptr, nullptr);
    pw_mainloop = pw_main_loop_new(nullptr);
    pw_loop* pw_mainloop_loop = pw_main_loop_get_loop(pw_mainloop);
    context = pw_context_new(pw_mainloop_loop, nullptr, 0);
    core = pw_context_connect_fd(context, pw_fd, nullptr, 0);
    registry = pw_core_get_registry(core, PW_VERSION_REGISTRY, 0);

    spa_zero(registry_listener);
    pw_registry_add_listener(registry, &registry_listener, &registry_events, this);
  }

  void init(const char *serial) {
    pw_properties *props = pw_properties_new(PW_KEY_TARGET_OBJECT, serial, NULL);
    stream = pw_stream_new(core, "pipewire-portal-screencast", props);

    stream_events = {
      .version = PW_VERSION_STREAM_EVENTS,
      .state_changed = THIS_CLASS::on_stream_state_changed,
      .param_changed = THIS_CLASS::on_param_changed,
      .process = THIS_CLASS::on_process,
    };
    pw_stream_add_listener(stream, &listener, &stream_events, this);

    // set up stream params
    this->param_buffer.reset(new uint8_t[param_buffer_size]);
    b = SPA_POD_BUILDER_INIT(param_buffer.get(), param_buffer_size);
    
    auto vidsize_default = SPA_RECTANGLE(320, 240);
    auto vidsize_min = SPA_RECTANGLE(1, 1);
    auto vidsize_max = SPA_RECTANGLE(DEFAULT_FB_ALLOC_WIDTH, DEFAULT_FB_ALLOC_HEIGHT);
    
    auto vidframerate_default = SPA_FRACTION(20, 1);
    auto vidframerate_min = SPA_FRACTION(0, 1);
    auto vidframerate_max = SPA_FRACTION(1000, 1);
    spa_pod_frame format_frame;
    spa_pod_builder_push_object(&b, &format_frame, SPA_TYPE_OBJECT_Format, SPA_PARAM_EnumFormat);
    spa_pod_builder_add(&b,
          SPA_FORMAT_mediaType,       SPA_POD_Id(SPA_MEDIA_TYPE_video),
          SPA_FORMAT_mediaSubtype,    SPA_POD_Id(SPA_MEDIA_SUBTYPE_raw),
          SPA_FORMAT_VIDEO_format,    SPA_POD_CHOICE_ENUM_Id(6,
                          SPA_VIDEO_FORMAT_RGB,
                          SPA_VIDEO_FORMAT_BGR,
                          SPA_VIDEO_FORMAT_RGBA,
                          SPA_VIDEO_FORMAT_BGRA,
                          SPA_VIDEO_FORMAT_RGBx,
                          SPA_VIDEO_FORMAT_BGRx
                          ),
          0);
    spa_pod_builder_prop(&b, SPA_FORMAT_VIDEO_modifier, SPA_POD_PROP_FLAG_MANDATORY);
    spa_pod_builder_long(&b, DRM_FORMAT_MOD_LINEAR);
    spa_pod_builder_add(&b,
          SPA_FORMAT_VIDEO_size,      SPA_POD_CHOICE_RANGE_Rectangle(
                          &vidsize_default,
                          &vidsize_min,
                          &vidsize_max),
          SPA_FORMAT_VIDEO_framerate, SPA_POD_CHOICE_RANGE_Fraction(
                          &vidframerate_default,
                          &vidframerate_min,
                          &vidframerate_max),
          0);
    params[0] = reinterpret_cast<spa_pod*>(spa_pod_builder_pop(&b, &format_frame));
    
        pw_stream_connect(stream, PW_DIRECTION_INPUT, PW_ID_ANY, pw_stream_flags(PW_STREAM_FLAG_AUTOCONNECT |  PW_STREAM_FLAG_MAP_BUFFERS), params, 1);
  }

  static void registry_global(void *data, uint32_t id, uint32_t permissions, const char *type, uint32_t version, const struct spa_dict *props) {
    THIS_CLASS *this_ptr = reinterpret_cast<THIS_CLASS *>(data);

    if (id != this_ptr->node_id)
      return;

    const spa_dict_item *serial = spa_dict_lookup_item(props, PW_KEY_OBJECT_SERIAL);
    if (!serial || !serial->value) {
      fprintf(stderr, "%s stream %u has no serial\n", red_text("[hook]").c_str(), id);
      return;
    }

    this_ptr->init(serial->value);
  }

  static constexpr pw_registry_events registry_events{ PW_VERSION_REGISTRY_EVENTS, THIS_CLASS::registry_global };

  ~PipewireScreenCast() {
    if (stream) pw_stream_disconnect(stream);
    if (stream) pw_stream_destroy(stream);
    if (core) pw_core_disconnect(core);
    if (context) pw_context_destroy(context);
    if (pw_mainloop) pw_main_loop_destroy(pw_mainloop);
    pw_deinit();
  }

  void reset_last_frame_time() {
    // reset the last frame time to a very old time
    last_frame_time = std::chrono::high_resolution_clock::time_point(
      std::chrono::seconds(1)
    );
  }

  std::atomic<pw_main_loop*> pw_mainloop{nullptr}; // need to be freed using pw_main_loop_destroy
  std::atomic<pw_context*> context{nullptr}; // need to be freed using pw_context_destroy
  std::atomic<pw_core*> core{nullptr}; // need to be freed using pw_core_disconnect
  std::atomic<pw_stream*> stream{nullptr}; // need to be freed using pw_stream_destroy

private:
  int node_id;
  pw_registry *registry;
  spa_hook registry_listener;
  std::unique_ptr<uint8_t[]> param_buffer{nullptr};
  static constexpr size_t param_buffer_size = 1024;
  spa_pod_builder b;
  spa_hook listener;
  const spa_pod* params[1];
  pw_stream_events stream_events;
  std::chrono::time_point<std::chrono::high_resolution_clock> last_frame_time;
  int counter{0};
  double target_framerate;
  uint64_t reporting_interval;
  uint64_t processed_frame_count;

  struct ActualParams {
    uint32_t width{0};
    uint32_t height{0};
    double framerate{0.0f};
    double max_framerate{0.0f};
    SpaVideoFormat_e format{SpaVideoFormat_e::INVALID};
    bool param_good{false};
    
    void update_from_pod(const spa_pod* pod){
      spa_video_info_raw info;
      auto retval = spa_format_video_raw_parse(pod, &info);
      fprintf(stderr, "%s", yellow_text("[payload pw] spa_format_video_raw_parse retval: " + std::to_string(retval) + "\n").c_str());
      width = info.size.width;
      height = info.size.height;
      framerate = static_cast<double>(info.framerate.num) / static_cast<double>(info.framerate.denom);
      max_framerate = static_cast<double>(info.max_framerate.num) / static_cast<double>(info.max_framerate.denom);
      format = SpaVideoFormat_e{static_cast<SpaVideoFormat_e>(info.format)};
      param_good = (width > 0) && (height > 0) && (format != SpaVideoFormat_e::INVALID);
      
      std::string reporting_str = "width: " + std::to_string(width) + " | " +
                                  "height: " + std::to_string(height) + " | " +
                                  "framerate: " + std::to_string(framerate) + " | " +
                                  "max_framerate: " + std::to_string(max_framerate) + " | " +
                                  "format: " + spa_to_string(format) + " | " +
                                  "param_good: " + std::to_string(param_good);
      
      fprintf(stderr, "%s", yellow_text("[payload pw] actual params: " + reporting_str + "\n").c_str());
      dingtalk_debug_log("actual params: " + reporting_str);
    }

  } actual_params;


  static void on_stream_state_changed(void* data, pw_stream_state old_state, pw_stream_state state, const char* error_message){
    std::string old_state_str = pw_stream_state_as_string(old_state);
    std::string state_str = pw_stream_state_as_string(state);
    fprintf(stderr, "%s", yellow_text("[payload pw] stream state changed from " + old_state_str + " to " + state_str + "\n").c_str());
    dingtalk_debug_log("stream state changed from " + old_state_str + " to " + state_str);
    THIS_CLASS* this_ptr = reinterpret_cast<THIS_CLASS*>(data);
    this_ptr->reset_last_frame_time();
    if (state == PW_STREAM_STATE_ERROR) {
      fprintf(stderr, "%s", red_text("[payload pw] stream error: " + std::string(error_message) + "\n").c_str());
      dingtalk_debug_log("stream error: " + std::string(error_message));
    }
  }
  
  static void on_param_changed(void* data, uint32_t id, const struct spa_pod* param){
    
    THIS_CLASS* this_ptr = reinterpret_cast<THIS_CLASS*>(data);
    this_ptr->reset_last_frame_time();
    std::string param_id_name_str = spa_debug_type_find_name(spa_type_param, id);
    fprintf(stderr, "%s", yellow_text("[payload pw] param changed. received param type: " + param_id_name_str + "\n").c_str());
    dingtalk_debug_log("param changed: " + param_id_name_str);
    if (param == nullptr || id != SPA_PARAM_Format) {
      fprintf(stderr, "%s", yellow_text("[payload pw] ignoring non-format param\n").c_str());
      return;
    }
    // we gather the actual video stream params here
    this_ptr->actual_params.update_from_pod(param);

    uint8_t params_buffer[1024];
    struct spa_pod_builder b = SPA_POD_BUILDER_INIT(params_buffer, sizeof(params_buffer));
    const struct spa_pod *params[1];

    params[0] = (struct spa_pod *)(spa_pod_builder_add_object(&b,
      SPA_TYPE_OBJECT_ParamMeta, SPA_PARAM_Meta,
      SPA_PARAM_META_type, SPA_POD_Id(SPA_META_VideoCrop),
      SPA_PARAM_META_size, SPA_POD_Int(sizeof(struct spa_meta_region))
    ));
    pw_stream_update_params(this_ptr->stream.load(), params, 1);
  }

  static void on_process(void* data){
    THIS_CLASS* this_ptr = reinterpret_cast<THIS_CLASS*>(data);
    pw_buffer* b = pw_stream_dequeue_buffer(this_ptr->stream);
    if (b == nullptr) {
      fprintf(stderr, "%s", red_text("[payload pw] received a null buffer on processing. ignoring.\n").c_str());
      pw_stream_queue_buffer(this_ptr->stream, b);
      return;
    }

    auto cur_frame_time = std::chrono::high_resolution_clock::now();
    auto last_frame_time = this_ptr->last_frame_time;

    if (cur_frame_time - last_frame_time < std::chrono::milliseconds(int(1000 / this_ptr->target_framerate))) {
      // fprintf(stderr, "%s", yellow_text("[payload pw] frame came too fast. dropped.\n").c_str());
      pw_stream_queue_buffer(this_ptr->stream, b);
      return;
    }
    
    // start processing frame
    this_ptr->processed_frame_count++;
    this_ptr->last_frame_time = cur_frame_time;

    if (this_ptr->processed_frame_count % this_ptr->reporting_interval == 0) {
      fprintf(stderr, "%s", yellow_text("[payload pw] processed frame count: " + std::to_string(this_ptr->processed_frame_count) + "\n").c_str());
      dingtalk_debug_log("processed frame count: " + std::to_string(this_ptr->processed_frame_count));
    }

    if (this_ptr->processed_frame_count <= 5) {
      auto* data0 = &b->buffer->datas[0];
      dingtalk_debug_log("process frame " + std::to_string(this_ptr->processed_frame_count) +
                         " type=" + std::to_string(data0->type) +
                         " fd=" + std::to_string(data0->fd) +
                         " flags=" + std::to_string(data0->flags) +
                         " mapoffset=" + std::to_string(data0->mapoffset) +
                         " data=" + std::to_string(reinterpret_cast<uintptr_t>(data0->data)) +
                         " maxsize=" + std::to_string(data0->maxsize) +
                         " stride=" + std::to_string(data0->chunk ? data0->chunk->stride : 0) +
                         " offset=" + std::to_string(data0->chunk ? data0->chunk->offset : 0) +
                         " size=" + std::to_string(data0->chunk ? data0->chunk->size : 0));
    }


    // try to write to the frame buffer if the param is good
    if (this_ptr->actual_params.param_good){
      auto& interface_singleton = InterfaceSingleton::getSingleton();
      auto& framebuffer = interface_singleton.interface_handle.load()->framebuf;

      struct spa_meta_region *mc;
      int x = 0, y = 0, width = this_ptr->actual_params.width, height = this_ptr->actual_params.height;
      if ((mc = (struct spa_meta_region *)spa_buffer_find_meta_data(b->buffer, SPA_META_VideoCrop, sizeof(*mc))) && spa_meta_region_is_valid(mc)) {
        x = mc->region.position.x;
        y = mc->region.position.y;
        width = mc->region.size.width;
        height = mc->region.size.height;
        if (this_ptr->processed_frame_count % this_ptr->reporting_interval == 0) {
          fprintf(stderr, "videocrop: offset=(%d,%d) size=(%d,%d)\n", x, y, width, height);
        }
      }

      framebuffer.update_param(
        height,
        width,
        this_ptr->actual_params.format
      );

      // copy the data from the pw buffer to the frame buffer
      struct spa_data& pw_data = b->buffer->datas[0];
      if (pw_data.chunk == nullptr) {
        dingtalk_debug_log("drop frame with null chunk");
        goto exit;
      }
      uint32_t pw_chunk_stride = pw_data.chunk->stride;
      size_t mapped_size = 0;
      void* mapped_data = nullptr;
      uint8_t* pw_chunk_ptr = reinterpret_cast<uint8_t*>(pw_data.data);
      uint32_t pw_chunk_offset = pw_data.maxsize > 1 ? pw_data.chunk->offset % pw_data.maxsize : pw_data.chunk->offset;

      if (pw_chunk_ptr == nullptr && pw_data.fd >= 0 && (pw_data.type == SPA_DATA_DmaBuf || pw_data.type == SPA_DATA_MemFd)) {
        mapped_size = std::max<size_t>(pw_data.maxsize, static_cast<size_t>(pw_chunk_stride) * this_ptr->actual_params.height + pw_chunk_offset);
        struct dma_buf_sync sync_start = { DMA_BUF_SYNC_START | DMA_BUF_SYNC_READ };
        ioctl(pw_data.fd, DMA_BUF_IOCTL_SYNC, &sync_start);
        mapped_data = mmap(nullptr, mapped_size, PROT_READ, MAP_SHARED, pw_data.fd, pw_data.mapoffset);
        if (mapped_data != MAP_FAILED) {
          pw_chunk_ptr = reinterpret_cast<uint8_t*>(mapped_data);
          if (this_ptr->processed_frame_count <= 5) {
            dingtalk_debug_log("mmap frame fd=" + std::to_string(pw_data.fd) + " size=" + std::to_string(mapped_size));
          }
        } else {
          dingtalk_debug_log("mmap frame failed fd=" + std::to_string(pw_data.fd) +
                             " size=" + std::to_string(mapped_size) +
                             " errno=" + std::to_string(errno) +
                             " error=" + std::string(strerror(errno)));
          mapped_data = nullptr;
        }
      }

      if (pw_chunk_ptr == nullptr || pw_chunk_stride <= 0) {
        dingtalk_debug_log("drop frame with unreadable buffer type=" + std::to_string(pw_data.type) +
                           " fd=" + std::to_string(pw_data.fd) +
                           " flags=" + std::to_string(pw_data.flags) +
                           " data=" + std::to_string(reinterpret_cast<uintptr_t>(pw_chunk_ptr)) +
                           " maxsize=" + std::to_string(pw_data.maxsize));
        if (mapped_data != nullptr) munmap(mapped_data, mapped_size);
        struct dma_buf_sync sync_end = { DMA_BUF_SYNC_END | DMA_BUF_SYNC_READ };
        if (pw_data.fd >= 0 && pw_data.type == SPA_DATA_DmaBuf) ioctl(pw_data.fd, DMA_BUF_IOCTL_SYNC, &sync_end);
        goto exit;
      }
      pw_chunk_ptr += pw_chunk_offset;

      for (int row_idx = 0; row_idx < height; ++row_idx) {
        uint8_t* framebuffer_row_start = framebuffer.data.get() + row_idx * framebuffer.row_byte_stride;
        uint8_t* pw_chunk_row_start = pw_chunk_ptr + (row_idx + y) * pw_chunk_stride + x * spa_videoformat_bytesize(this_ptr->actual_params.format);
        memcpy(framebuffer_row_start, pw_chunk_row_start, width * spa_videoformat_bytesize(this_ptr->actual_params.format));
      }
      if (mapped_data != nullptr) munmap(mapped_data, mapped_size);
      struct dma_buf_sync sync_end = { DMA_BUF_SYNC_END | DMA_BUF_SYNC_READ };
      if (pw_data.fd >= 0 && pw_data.type == SPA_DATA_DmaBuf) ioctl(pw_data.fd, DMA_BUF_IOCTL_SYNC, &sync_end);
    }

    
    exit:
    pw_stream_queue_buffer(this_ptr->stream, b);
    return;
  }


};


void payload_main();
