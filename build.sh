#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

rm -rf lib
bun run cep -- -o lib -c src
rsync -av --include="*/" \
  --include="*.js" \
  --exclude="*" \
  ./src/* lib
