#!/bin/sh

if [ ! -p /dev/stdin ]; then
  echo "Nothing was piped."
  exit 1
fi

unset $src

# スクリプト終了イベントとシグナルを捕捉して確実に一時ファイルを削除
trap "rm -f $src" EXIT
trap "rm -f $src; trap - EXIT; exit $?" INT TERM PIPE

src=$(mktemp)
cat - > $src

output=`psyche $src`

if [ $? -gt 0 ]; then
  echo "$output"
  exit 0
fi

wasm-interp --run-all-exports out.wasm
rm -f out.wasm
