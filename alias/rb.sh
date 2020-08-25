#!/usr/bin/zsh

_RUBY=truffleruby
command -v "$_RUBY" > /dev/null || _RUBY=ruby

script="$1"
shift

_exec_script="SCRIPT='${script}'; require '${0:a:h}/.common.rb'; load '${script}'"

if [ "$_RUBY" = "truffleruby" ]; then
	exec "${_RUBY}" -e "$_exec_script" -- "$@"
else
	exec "${_RUBY}" -e "$_exec_script" "-W0" "--disable=gems" "--disable=did_you_mean" "--disable=rubyopt" -- "$@"
fi
