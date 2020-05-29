begin
require 'colorize'
HAS_COLORIZE = true
rescue
HAS_COLORIZE = false
end

class String
	@@_AS_ERROR = !HAS_COLORIZE ? :identity : :light_red
	@@_AS_WARNING = !HAS_COLORIZE ? :identity : :light_yellow
	@@_AS_GOOD = !HAS_COLORIZE ? :identity : :light_green
	@@_AS_DEBUG = !HAS_COLORIZE ? :identity : :light_blue
	@@_AS_INFO = !HAS_COLORIZE ? :identity : :light_white

	alias_method :as_error, @@_AS_ERROR
	alias_method :as_warning, @@_AS_WARNING
	alias_method :as_good, @@_AS_GOOD
	alias_method :as_debug, @@_AS_DEBUG
	alias_method :as_info, @@_AS_INFO
end

class Object
	def identity; return self; end
	def as_error
		self.to_s.as_error
	end
	def as_warning
		self.to_s.as_warning
	end
	def as_good
		self.to_s.as_good
	end
	def as_debug
		self.to_s.as_debug
	end
	def as_info
		self.to_s.as_debug
	end
end

module IOExtensions
	@@io_lock = Mutex.new.freeze

	protected
	def _synchronize
		if self == STDERR || self == STDOUT
			@@io_lock.synchronize {
				yield
			}
		else
			yield
		end
	end

	def _locked_puts(printer, callback, *str)
		_synchronize {
			if callback.nil?
				printer.call(*str)
			else
				str.each { |s|
					printer.call(callback.call(s))
				}
			end
		}
	end

	public
	def puts(*str)
		_locked_puts(lambda { |*s| super(*s) }, nil, *str)
	end
end

class IO
	def _locked_puts(*str)
		puts *str
	end

	prepend IOExtensions
end

def puts(*str)
	STDOUT.puts(*str)
end

def eputs(*str)
	STDERR.puts(*str)
end

ERROR_TOKEN =   "[ERROR]".as_error
WARNING_TOKEN = "[WARN] ".as_warning
GOOD_TOKEN =    "[OK]   ".as_good
DEBUG_TOKEN =   "[DEBUG]".as_debug
INFO_TOKEN =    "[INFO] ".as_info

FAIL_TOKEN =    "[FAIL]".as_error
PASS_TOKEN =    "[PASS]".as_good

def error(str)
	STDERR.puts("#{ERROR_TOKEN} #{str}")
end

def warning(str)
	STDERR.puts("#{WARNING_TOKEN} #{str}")
end

def good(str)
	STDOUT.puts("#{GOOD_TOKEN} #{str}")
end

def debug(str)
	STDOUT.puts("#{DEBUG_TOKEN} #{str}")
end

def info(str)
	STDOUT.puts("#{INFO_TOKEN} #{str}")
end

def fail(str)
	STDERR.puts("#{FAIL_TOKEN} #{str}")
end

def pass(str)
	STDOUT.puts("#{PASS_TOKEN} #{str}")
end

unless HAS_COLORIZE
	warning("Ruby module 'colorize' not found, output colors disabled")
end
