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
  (cd BUILD && ./autogen.sh && CCLD="$CXX $CXXFLAGS" ./configure && make -j $JOBS)
}

get_git_tag https://gitlab.gnome.org/GNOME/libxml2.git v2.9.2 SRC
get_git_revision https://github.com/mcarpenter/afl be3e88d639da5350603f6c0fee06970128504342 afl
cp $(dirname $0)/cur_diff.patch .
build_lib

cp afl/dictionaries/xml.dict .

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS -std=c++11  $SCRIPT_DIR/target.cc -I BUILD/include BUILD/.libs/libxml2.a $LIB_FUZZING_ENGINE -lz -o $EXECUTABLE_NAME_BASE
