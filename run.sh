#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

./build.sh
./lib/bin/i18n_bin.js test/i18n test/js test/bin
