#!/usr/bin/ruby

require_relative '.common.rb'

MSC_VER = "19.28.29515.1"
MSC_NAME = ["Microsoft (R) C/C++ Optimizing Compiler Version #{MSC_VER} for x64", "Copyright (C) Microsoft Corporation.  All rights reserved."]

def unrecognized(name)
	puts ""
	puts "cl : Command line warning D9002 : ignoring unknown option '#{name}'"
	puts "cl : Command line error D8003 : missing source filename"
end

if ARGV.empty?
	puts *MSC_NAME
	exit 0
end

nologo = false
ARGV.each { |arg|
	darg = arg.downcase
	if darg[1..-1] == "nologo"
		nologo = true
		break
	else
		case arg[1..-1]
			when '-version', 'version', 'v', 'V'
				unrecognized(arg)
				exit 2
		end
	end
}
puts *MSC_NAME unless nologo

call(*ARGV, "-Wno-unused-command-line-argument", "-D_CRT_SECURE_NO_WARNINGS=1", "-fms-compatibility", "-fms-compatibility-version=#{MSC_VER}")
