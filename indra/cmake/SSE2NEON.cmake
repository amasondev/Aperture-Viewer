# -*- cmake -*-

include(Prebuilt)

include_guard()
add_library(ll::sse2neon INTERFACE IMPORTED)

if (DARWIN)
    use_prebuilt_binary(sse2neon)

    target_include_directories(ll::sse2neon SYSTEM INTERFACE ${LIBS_PREBUILT_DIR}/include/sse2neon)
endif()
