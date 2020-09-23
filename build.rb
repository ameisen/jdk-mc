#!/usr/bin/env ruby

RUBY_BIN = "ruby"

RUBY_PATH = `which #{RUBY_BIN}`.strip

DEFAULT_ARCHITECTURES = [
	"haswell",
	"k10",
	"generic",
	"zen",
	"skylake"
]

build_arches = ["haswell"]

args = []
ARGV.each { |arg|
	case arg
	when "multi"
		build_arches = DEFAULT_ARCHITECTURES.dup
	when /multi\=.*/
		build_arches = arg.split("=", 2)[1].strip.split(",")
	else
		args.push(arg)
	end
}

build_arches.map! {|arch|
	arch.strip.downcase
}

build_arches.map! {|arch|
	arch.empty? ? nil : arch
}

build_arches.filter!

failures = []

case build_arches.size
when 0
	STDERR.puts "No architectures provided to build"
	exit 1
else
	build_arches.each { |arch|
		command = [
			RUBY_PATH,
			"--",
			File.join(__dir__, "rb", "build.rb"),
			"arch=#{arch}",
			*args
		]
		result = system(*command)
		failures << arch unless result
	}
end

exit 0 if failures.empty?

STDERR.puts "The following architectures failed to build:"
failures.each { |failure|
	STDERR.puts "\t#{failure}"
}
exit -1
