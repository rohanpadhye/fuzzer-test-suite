#!/bin/bash
# Copyright 2017 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh

build_fuzzer

export CFLAGS="-target_locations=$(dirname $0)/cur_targets.txt $CFLAGS"
export CXXFLAGS="-target_locations=$(dirname $0)/cur_targets.txt $CXXFLAGS"

build_lib() {
  rm -rf BUILD
  cp -rf SRC BUILD
  (cd BUILD && patch -p1 < ../cur_diff.patch)
  (cd BUILD && cmake . && make -j $JOBS)
}

get_git_revision https://github.com/libjpeg-turbo/libjpeg-turbo.git b0971e47d76fdb81270e93bbf11ff5558073350d SRC
build_lib

if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x
$CXX $CXXFLAGS -std=c++11 $SCRIPT_DIR/libjpeg_turbo_fuzzer.cc -I BUILD BUILD/libturbojpeg.a $LIB_FUZZING_ENGINE -o $EXECUTABLE_NAME_BASE
