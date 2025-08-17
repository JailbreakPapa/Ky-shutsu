# NOTE(Mikael A.): Chaos3P Should be included by now... debug if not.
set(CHAOS_3RDPARTY_DIR "${CMAKE_SOURCE_DIR}/Code/ThirdParty/.PulledLibs")


function(ns_setup_heavylibs)
    ns_vcpkg_init()

    ns_vcpkg_install(libvorbis OFF)
    ns_vcpkg_install(opus OFF)
    # Configuration for Opus
    set(OPUS_BUILD_SHARED_LIBRARY OFF)
    set(OPUS_BUILD_TESTING OFF)
    set(OPUS_STATIC_RUNTIME ON)
    set(OPUS_BUILD_PROGRAMS OFF)

    # Configuration for Vorbis
    set(BUILD_SHARED_LIBS OFF)

    #ns_integrate_vcpkg(3rdParty::vorbis libogg OFF)
    #ns_integrate_vcpkg(3rdParty::vorbisenc libogg OFF)
    #ns_integrate_vcpkg(3rdParty::vorbisfile libogg OFF)
endfunction()
