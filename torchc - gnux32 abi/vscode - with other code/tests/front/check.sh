#!/bin/bash

red="\033[1;31m"
green="\033[1;32m"
reset="\033[0m"

fail="false"

while read -r file; do
    tok=out/${file%.*}.tok

    if ! test -f $tok; then
        echo -e "  [${red}ERROR${reset}] $tok not found"
        fail="true"
        continue
    fi

    actual=$(cat $tok)
    expected=$(sed -n "/^\/\/: /s/^\/\/: //p" $file)

    diff <(tr -s '[:space:]' '\n' <<< $actual) <(tr -s '[:space:]' '\n' <<< $expected) > /dev/null

    if [ $? -ne 0 ]; then
        echo -e "  [${red}FAIL${reset}] $file - TOK mismatch"
        diff -y <(tr -s '[:space:]' '\n' <<< $actual) <(tr -s '[:space:]' '\n' <<< $expected)
        echo
        fail="true"
        continue
    fi

    echo -e "  [${green}PASS${reset}] $file"
done <<<$(find . -type f -name '*.th' | sort)

if [[ "$fail" == "true" ]]; then
    echo
    echo -e "${red}some tests failed${reset}"
    exit 1
else
    echo
    echo -e "${green}all tests passed${reset}"
    exit 0
fi
