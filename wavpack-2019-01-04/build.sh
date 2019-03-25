#!/bin/bash
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh


build_lib() {
  rm -rf BUILD
  cp -rf SRC BUILD
  (cd BUILD && ./autogen.sh --disable-shared && make -j $JOBS)
}

get_git_revision https://github.com/dbry/WavPack \
  8948be9fd118cd3646eb83c9bc10afca478b0e32 SRC

build_lib || exit 1
build_fuzzer || exit 1
if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x

ln -f -s /dev/stdin stdin.wav
cp BUILD/cli/wavpack $EXECUTABLE_NAME_BASE
