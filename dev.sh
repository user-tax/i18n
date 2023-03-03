#!/usr/bin/env bash
set -e
DIR=$( dirname $(realpath "$0") )

cd $DIR

exec watchexec --shell=none \
  --project-origin . \
  -w ./src \
  -w ./test.coffee \
  --exts coffee,js,mjs,json,wasm,txt,yaml \
  -r \
  -- ./run.sh $@
