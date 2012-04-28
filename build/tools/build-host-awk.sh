#!/bin/sh
#
# Copyright (C) 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Build the host version of the awk executable and place it
# at the right location

PROGDIR=$(dirname $0)
. $PROGDIR/prebuilt-common.sh

PROGRAM_PARAMETERS=""
PROGRAM_DESCRIPTION=\
"Rebuild the host awk tool used by the NDK."

register_try64_option
register_mingw_option
register_jobs_option

NDK_DIR=$ANDROID_NDK_ROOT
register_var_option "--ndk-dir=<path>" NDK_DIR "Specify NDK install directory"

PACKAGE_DIR=
register_var_option "--package-dir=<path>" PACKAGE_DIR "Archive to package directory"

GNUMAKE=make
register_var_option "--make=<path>" GNUMAKE "Specify GNU Make program"

extract_parameters "$@"

SUBDIR=$(get_prebuilt_host_exec awk)
OUT=$NDK_DIR/$SUBDIR

AWK_VERSION=20071023
AWK_SRCDIR=$ANDROID_NDK_ROOT/sources/host-tools/nawk-$AWK_VERSION
if [ ! -d "$AWK_SRCDIR" ]; then
    echo "ERROR: Can't find sed-$AWK_VERSION source tree: $AWK_SRCDIR"
    exit 1
fi

log "Using sources from: $AWK_SRCDIR"

prepare_host_build

BUILD_DIR=$NDK_TMPDIR
BUILD_MINGW=
if [ "$MINGW" = "yes" ]; then
  BUILD_MINGW=yes
fi

log "Configuring the build"
mkdir -p $BUILD_DIR && rm -rf $BUILD_DIR/*
log "Building $HOST_TAG awk"
run $GNUMAKE \
    -C "$AWK_SRCDIR" \
    -j $NUM_JOBS \
    BUILD_DIR="$BUILD_DIR" \
    MINGW="$BUILD_MINGW"
fail_panic "Failed to build the sed-$AWK_VERSION executable!"

log "Copying executable to prebuilt location"
run mkdir -p $(dirname "$OUT") && cp "$BUILD_DIR/$(get_host_exec_name ndk-awk)" "$OUT"
fail_panic "Could not copy executable to: $OUT"

if [ "$PACKAGE_DIR" ]; then
    ARCHIVE=ndk-awk-$HOST_TAG.tar.bz2
    dump "Packaging: $ARCHIVE"
    mkdir -p "$PACKAGE_DIR" &&
    pack_archive "$PACKAGE_DIR/$ARCHIVE" "$NDK_DIR" "$SUBDIR"
    fail_panic "Could not package archive: $PACKAGE_DIR/$ARCHIVE"
fi

log "Cleaning up"
rm -rf $BUILD_DIR

log "Done."

