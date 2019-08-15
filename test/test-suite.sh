#!/bin/bash -u

success=0
failed=0

for src in `ls -1 *.psy`; do
  echo "----- $src -----"
  name=`basename "$src" .psy`
  snapshot="$name.snapshot"
  if [ ! -e "$snapshot" ]; then
    printf "\e[31mThe corresponding snapshot file \`$snapshot\` was not found.\e[m\n"
    exit 1
  fi
  expected=`cat "$snapshot"`
  cat "$src" | sh run-test.sh "$expected"
  if [ $? -gt 0 ]; then
    (( failed++ ))
  else
    (( success++ ))
  fi
done

printf "\e[32mSuccess: $success\e[m, \e[31mFailed: $failed\e[m\n"

if [ $failed -ne 0 ]; then
  exit 1
fi
