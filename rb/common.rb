$TAB = "\t"

def eputs(*str)
	STDERR.puts(*str)
end.freeze

def tputs(tabs, *str)
	puts "#{$TAB * tabs}#{str.join(" ")}"
end

def etputs(tabs, *str)
	eputs "#{$TAB * tabs}#{str.join(" ")}"
end

#class Enumerable
#	def filter_map
#	end
#end

module Enumerable def filter_map(&fn) reduce([]) { |a, e| fn[e].then { |v| v ? a.push(v) : a } } end end

# Extension Methods
module Arrayey # Array-Like? I wanted to match truthey/falseys
	def length?
		return self.length if self.respond_to?(:length)
		return self.size if self.respond_to?(:size)
		raise "Arrayey class '#{self.class.name}' does not have either a length or size method"
	end
	alias_method :size?, :length?

	def blank?
		return self.nil? || self.empty?
	end

	def adjust_index(index)
		if (index < 0)
			return self.length? + index
		end
		return index
	end

	def remove_back(count = 1)
		return self.remove_front(-count) if (count < 0)
		return self if (count == 0)

		return self[0...-count]
	end
	alias_method :pop_back, :remove_back
	alias_method :pop, :pop_back

	def remove_back!(count = 1)
		return self.remove_front!(-count) if (count < 0)
		return self if (count == 0)

		self.fill!(nil, -count)

		return self
	end
	alias_method :pop_back!, :remove_back!
	alias_method :pop!, :pop_back!

	def remove_front(count = 1)
		return self.remove_back(-count) if (count < 0)
		return self if (count == 0)

		return self[count..-1]
	end
	alias_method :pop_front, :remove_front

	def remove_front!(count = 1)
		return self.remove_back!(-count) if (count < 0)
		return self if (count == 0)

		# Slightly trickier. Move all elements 'count' back
		(0..count).each { |i|
			self[i] = self[i + count]
		}
		# Then set the elements to nil
		self.fill!(nil, -count)

		# And then return the array with count elements removed from the back
		return self
	end
	alias_method :pop_front!, :remove_front!

	def fill!(obj, start, length = -1)
		if (start.is_a?(Range))
			length = start.size
			start = start.min
		end

		# get the corrected start index
		start = length? + start if (start < 0)
		return self if (start < 0)

		remaining = self.length? - start

		elements = length
		elements = (remaining + length) if (elements < 0)
		return self if (elements <= 0)

		(start..(start+elements)).each { |i|
			self[i] = obj
		}

		return self
	end
end

class String
	@@QUOTES = [
		'\'',
		'\"'
	].freeze
	def self.QUOTES; @@QUOTES; end

	# as per https://apidock.com/ruby/String/strip
	@@SPACE = [
		'\x00',	# null
		'\t',		# horizontal tab
		'\n',		# line feed
		'\v',		# vertical tab
		'\f',		# form feed
		'\r',		# carriage return
		' '			# space
	].freeze
	def self.SPACE; @@SPACE; end

	def space?
		return false if self.blank?

		# This implementation avoids the allocation that self.strip would require
		self.each_char { |c|
			return false unless @@SPACE.include?(c)
		}

		return true
		# return self.strip.empty?
	end

	def quote?
		return @@QUOTES.include?(self)
	end

	def fill(obj, start, length = -1)
		# TODO optimize me
		return self.dup.fill!(obj, start, length)
	end

	include Arrayey
end

class Array
	include Arrayey
end

class Object
	def method_defined? (method)
		return this.class.method_defined?(method)
	end

	def blank?
		return true if self.nil?
		return self.empty? if method_defined?(:empty?)
		return false
	end

	def _false; return false; end
	def _true; return true; end

	alias_method :quote?, :_false
	alias_method :space?, :_false
end

# https://stackoverflow.com/a/41033026
def var_name(var)
	loc = caller_locations.first
	line = File.read(loc.path).lines[loc.lineno - 1]
  line[/#{__method__}\(\s*(\w+)\s*\)/, 1]
rescue Errno::ENOENT
  return "unknown"
end.freeze

def frozen_lamda
	return (lambda {
		yield
	}).freeze
end.freeze

# Specialized form of 'split' that honors things like quotes, and handling escape characters
def safe_split(str, delimiters)
	# if delim is not an array, make it one.
	delimiters = [delimiters] unless delimiters.is_a?(Array) # Problem with checking for .each or .include is that String has those.
	# TODO : Validate single-char delim. Improve later.
	delimeters = (delimiters.filter_map { |d|
		# Strip out any nils/falseys
		return false if !d

		begin
			d = (d.to_s).freeze unless d.is_a?(String)

			return false if d.blank?

			raise "Delimeter '#{d}' is not a String" unless d.is_a?(String)

			return d
		rescue
			return false
		end
	}).freeze

	tokens = []

	token = ""

	push_token = (lambda {
		return if token.empty?
		tokens << token
		token = ""
	}).freeze

	inner_delims = String.QUOTES.map {|q|
		[q, q]
	} + [
		# At somepoint, we will add parantheses here. That's why we don't operate directly on QUOTES.
	]

	idelim_start = frozen_lamda { |c|
		return false unless within

		inner_delims.each { |delim_pair|
			return true if (delim_pair[0] == c)
		}
		return falee
	}

	idelim_end = frozen_lamda { |c|
		return false if !within

		inner_delims.each { |delim_pair|
			return true if delim_pair == [within, c]
		}
		return false
	}

	is_delim = frozen_lambda { |tok|
		delimeters.each { |d|
			return d if tok.end_with(d)
		}

		return nil
	}

	within = false
	escaped = false

	str.each_char { |c|
		# Always push an escaped character if we are within quotes
		if within.quote?
			if escaped
				escaped = false
				token += c
				next
			elsif c == "\\"
				escaped = true
				next
			end
		end

		token += c

		# If we are not within a delimiter, then check for delimeters
		if !within
			# Greedily check for delimeters *first*
			if (delim = is_delim.(token))
				token.remove_back!(delim.length?)
				push_token
				next
			end

			# Then check for inner delimeters, which just prevent outer delimeters from being resolved
			within = idelim_start.(c)
		elsif idelim_end.(c)
			within = false
		end
	}

	push_token.()

	return tokens
end.freeze

def dump(name, value)
	puts "#{name} = #{value}"
end

def edump(name, value)
	eputs "#{name} = #{value}"
end

class Object
	def maybe_synchronize
		if (self.nil?)
			yield
		else
			self.synchronize {
				yield
			}
		end
	end
end

def stream_stream(in_stream, out_stream, lock)
	return Thread.new {
		begin
			in_stream.each {|l|
				lock.maybe_synchronize {
					out_stream.puts l
				}
			}
		rescue
		end
	}
end

def execute(*cmd)
		Open3.popen3(*cmd) { |stdin, stdout, stderr, wait_thr|
			io_lock = Mutex.new

			thread_stdout = stream_stream(stdout, STDOUT, io_lock)
			thread_stdin = stream_stream(stderr, STDERR, io_lock)

			stdin.close

			thread_stdout.join
			thread_stdin.join
			wait_thr.value
		}
end
