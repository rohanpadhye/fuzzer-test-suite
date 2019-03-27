#!/bin/bash
. $(dirname $0)/../custom-build.sh $1 $2
. $(dirname $0)/../common.sh


build_lib() {
  rm -rf BUILD
  mkdir -p BUILD
  cmake -G "Unix Makefiles" -HSRC -BBUILD
  (cd BUILD && make -j $JOBS)
}

get_git_revision https://github.com/mdadams/jasper \
  9aef6d91a82a8a6aecb575cbee57f74470603cc2 SRC

build_lib || exit 1
build_fuzzer || exit 1
if [[ $FUZZING_ENGINE == "hooks" ]]; then
  # Link ASan runtime so we can hook memcmp et al.
  LIB_FUZZING_ENGINE="$LIB_FUZZING_ENGINE -fsanitize=address"
fi
set -x

cp BUILD/src/appl/imginfo $EXECUTABLE_NAME_BASE
