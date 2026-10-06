#!/usr/bin/env bash

FENGYU_SOURCE_PATH="RimeWithFengyu FengyuDeployer FengyuIME FengyuIPC FengyuIPCServer FengyuServer FengyuSetup FengyuTSF FengyuUI include test"

# clang format options
method="-i"

while getopts "in" option; do
	case "${option}" in
	n) # format code
		find ${FENGYU_SOURCE_PATH} -name '*.cpp' -o -name '*.h' ! -path "include/wtl/*" | grep -wiv -f .exclude_pattern.txt | xargs clang-format --verbose -i
		;;
	i) # dry run and changes formatting warnings to errors
		find ${FENGYU_SOURCE_PATH} -name '*.cpp' -o -name '*.h' ! -path "include/wtl/*" | grep -wiv -f .exclude_pattern.txt | xargs clang-format --verbose -Werror --dry-run || { echo Please lint your code by '"'"./clang-format.sh -n"'"'.; false; }
		;;
	\?) # invalid option
		echo "invalid option, please use -i or -n."
		exit 1
		;;
	esac
done
