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
  cp -rf SRC BUILD
  (cd BUILD && patch -p1 < ../cur_diff.patch)
  (cd BUILD/build && ./autogen.sh && cd .. && ./configure --without-nettle && make -j $JOBS)
}

get_git_revision https://github.com/libarchive/libarchive.git 51d7afd3644fdad725dd8faa7606b864fd125f88 SRC
cp $(dirname $0)/cur_diff.patch .
build_lib

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS -std=c++11 $SCRIPT_DIR/libarchive_fuzzer.cc -I BUILD/libarchive BUILD/.libs/libarchive.a $LIB_FUZZING_ENGINE -lz  -lbz2 -lxml2 -lcrypto -lssl -llzma -llz4 -llzo2 -o $EXECUTABLE_NAME_BASE
