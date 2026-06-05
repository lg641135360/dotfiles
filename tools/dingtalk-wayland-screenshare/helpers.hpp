#pragma once


#include <cstdio>
#include <ctime>
#include <string>
#include <sstream>
#include <unistd.h>

// Inline function to colorize text
inline std::string color_text(const std::string& text, const std::string& color_code) {
    return "\033[" + color_code + "m" + text + "\033[0m";
}

// Helper functions for specific colors
inline std::string red_text(const std::string& text) {
    return color_text(text, "31");
}

inline std::string green_text(const std::string& text) {
    return color_text(text, "32");
}

inline std::string yellow_text(const std::string& text) {
    return color_text(text, "33");
}

inline std::string int_to_hexstr(int value) {
    std::stringstream ss;
    ss << std::hex << value;
    return ss.str();
}

inline std::string toLowerString(const std::string& str) {
    std::string lower_str = str;
    for (char& c : lower_str) {
        c = std::tolower(c);
    }
    return lower_str;
}

inline void dingtalk_debug_log(const std::string& message) {
    FILE* file = fopen("/tmp/dingtalk-wayland-debug.log", "a");
    if (!file) {
        return;
    }
    fprintf(file, "%ld pid=%d %s\n", static_cast<long>(time(nullptr)), getpid(), message.c_str());
    fclose(file);
}