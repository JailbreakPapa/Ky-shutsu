function(ns_setup_iwyu)
    message(NOTICE "Downloading fix_includes.py to ${CMAKE_BINARY_DIR}")
    file(DOWNLOAD
        https://raw.githubusercontent.com/include-what-you-use/include-what-you-use/refs/heads/master/fix_includes.py
        ${CMAKE_BINARY_DIR}/fix_includes.py
        SHOW_PROGRESS
    )
endfunction()
