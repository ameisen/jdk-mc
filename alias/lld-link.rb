#!/usr/bin/ruby

require_relative '.common.rb'

MSC_NAME = ["Microsoft (R) Incremental Linker 14.28.29515.1", "Copyright (C) Microsoft Corporation.  All rights reserved."]

def unrecognized(name)
	puts ""
	puts "LINK : warning LNK4044: unrecognized option '-#{name[1..-1]}'; ignored"
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
				exit 0
		end
	end
}
puts *MSC_NAME unless nologo

call(*ARGV)
