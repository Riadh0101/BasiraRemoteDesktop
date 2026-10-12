if(EXISTS "${OPENSSL_SRC}/Configurations/15-android.conf")
  file(READ "${OPENSSL_SRC}/Configurations/15-android.conf" CONF)
  if(NOT CONF MATCHES "which_clang")
    string(REPLACE "\$ndk = canonpath(\$ndk);" "\$ndk = canonpath(\$ndk);\n            \$ndk =~ s|\\\\|/|g;" CONF "${CONF}")
    string(REPLACE "if (which(\"clang\") =~ m|^\$ndk/.*/prebuilt/([^/]+)/|) {"
                   "my \$which_clang = which(\"clang\") // which(\"clang.exe\");\n            \$which_clang =~ s|\\\\|/|g if \$which_clang;\n            \$which_clang =~ s|^/([a-zA-Z])/|uc(\$1) . ':/'|e if \$which_clang;\n            if (\$which_clang && \$which_clang =~ m|^\$ndk/.*/prebuilt/([^/]+)/|) {" CONF "${CONF}")
    string(REPLACE "if (which(\"llvm-ar\") =~ m|^\$ndk/.*/prebuilt/([^/]+)/|) {"
                   "my \$which_ar = which(\"llvm-ar\") // which(\"llvm-ar.exe\");\n            \$which_ar =~ s|\\\\|/|g if \$which_ar;\n            \$which_ar =~ s|^/([a-zA-Z])/|uc(\$1) . ':/'|e if \$which_ar;\n            if (\$which_ar && \$which_ar =~ m|^\$ndk/.*/prebuilt/([^/]+)/|) {" CONF "${CONF}")
    file(WRITE "${OPENSSL_SRC}/Configurations/15-android.conf" "${CONF}")
  endif()
endif()
