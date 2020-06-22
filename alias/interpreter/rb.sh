#!/usr/bin/zsh

_RUBY=truffleruby
command -v "$_RUBY" > /dev/null || _RUBY=ruby

script="$1"
shift

if [ "$_RUBY" = "truffleruby" ]; then
	exec "${_RUBY}" -e "SCRIPT='${script}'; require '${0:a:h}/.common.rb'; load '${script}'" -- "$@"
else
	exec "${_RUBY}" -e "SCRIPT='${script}'; require '${0:a:h}/.common.rb'; load '${script}'" "-T0" "-W0" "--disable=gems" "--disable=did_you_mean" "--disable=rubyopt" -- "$@"
fi
