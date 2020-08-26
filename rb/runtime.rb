def _runtime_require(name)
	require File.join(__dir__, name)
end

_runtime_require 'io.rb'
_runtime_require 'common.rb'
_runtime_require 'system.rb'
_runtime_require 'error.rb'
_runtime_require 'extensions.rb'
_runtime_require 'argument.rb'

require 'etc'
require 'fileutils'
require 'open3'
require 'date'
