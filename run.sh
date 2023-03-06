#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

./build.sh
cd test
../lib/bin/i18n.js
#../lib/bin/i18n_bin.js i18n js bin
