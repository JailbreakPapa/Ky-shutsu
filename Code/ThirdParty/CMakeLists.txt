set(NS_SLANG_VERSION latest)
set(NS_SLANG_ENABLE ON)
set(NS_SLANG_FORCE_DOWNLOAD OFF)

ns_add_all_subdirs()

# init vcpkg so we can install needed 3rdParty 
ns_vcpkg_init()

# initialize slang (shader-slang) integration (downloads latest release by default)
ns_slang_init()

