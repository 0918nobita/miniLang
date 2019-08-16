#!/bin/sh

if [ ! -p /dev/stdin ]; then
  echo 'Nothing was piped.'
  exit 1
fi

output=`cat - | sh interp.sh`

if [ "$output" != "$1" ]; then
  printf "\e[31mexpected:\n%s\nactual:\n%s\e[m\n" "$1" "$output"
  exit 1
fi
