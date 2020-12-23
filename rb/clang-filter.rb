#!/usr/bin/env ruby

require 'open3'
require 'fileutils'

TAB = "  "
CLANG_EXEC = "clang"
CLANG_CL_EXEC = "clang-cl"
CLANG_TEST_FILE = File.join(__dir__, "dummy.cpp")
unless File.exist?(CLANG_TEST_FILE)
	STDERR.puts "Clang Test File '#{CLANG_TEST_FILE}' doesn't exist, cannot filter arguments"
	exit -1
end

$exec = CLANG_EXEC
$no_error = false
$filter = false

$args = []

ARGV.each { |arg|
	case arg
		when '--clang'
			$exec = CLANG_EXEC
		when '--clang-cl'
			$exec = CLANG_CL_EXEC
		when '--no-error'
			$no_error = true
		when '--error'
			$no_error = false
		when '--no-filter'
			$filter = false
		when '--filter'
			$filter = true
		else
			$args << arg
	end
}

if $args.size == 0
	STDERR.puts "No arguments provided to test"
	exit 0
end

$success_args = []
$fail_args = []

$args.each { |arg|
	out, stat = Open3.capture2e($exec, *arg.split(" ").map(&:strip), CLANG_TEST_FILE, "-o", "test.e")
	FileUtils.rm_f("test.e")
	if stat.success?
		$success_args << arg
	else
		$fail_args << arg
	end
}

if $filter
	$success_args.each { |arg|
		puts arg
	}
else
	unless $fail_args.empty?
		puts "Failed Arguments (#{$fail_args.size}):"
		$fail_args.each { |arg|
			puts "#{TAB}#{arg}"
		}
		puts "" unless $success_args.empty?
	end

	unless $success_args.empty?
		puts "Passed Arguments (#{$success_args.size}):"
		$success_args.each { |arg|
			puts "#{TAB}#{arg}"
		}
	end
end

exit $no_error ? 0 : $fail_args.size
