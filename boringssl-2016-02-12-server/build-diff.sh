#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

build_fuzzer

if [ -z $DISABLE_TARGET_ARG ]; then
        export CFLAGS="-target_locations=$(dirname $0)/cur_targets.txt $CFLAGS"
        export CXXFLAGS="-target_locations=$(dirname $0)/cur_targets.txt $CXXFLAGS"
fi

build_lib() {
  rm -rf BUILD
  (cd SRC && patch -p1 < ../cur_diff.patch)
  cp -rf SRC BUILD
  (cd BUILD && cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER="$CC" -DCMAKE_C_FLAGS="$CFLAGS -Wno-deprecated-declarations" -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-error=main" && make -j)
}

get_git_revision https://github.com/google/boringssl.git  894a47df2423f0d2b6be57e6d90f2bea88213382 SRC
build_lib

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS -I BUILD/include BUILD/fuzz/server.cc ./BUILD/ssl/libssl.a ./BUILD/crypto/libcrypto.a $LIB_FUZZING_ENGINE -lpthread -o $EXECUTABLE_NAME_BASE
