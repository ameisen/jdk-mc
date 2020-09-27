require 'open3'
require 'stringio'

module Executable
	def self.which?(name)
		stdout, stderr, status = Open3.capture3("which", name)
		return status.success? ? stdout.strip : nil
	end

	def self.exists?(name)
		return Executable::which?(name).nil? ? false : true
	end

	class Result
		attr_reader :status

		def initialize(status:, is_super: false)
			(@status = status).freeze
			self.freeze unless is_super
		end

		def valid?; return !(@status.nil?); end
		def exited?; return @status.exited?; end
		def exitstatus?; return @status.exitstatus?; end
		def pid; return @status.pid; end
		def stopped?; return @status.stopped?; end
		def success?; return @status.success?; end
		def failure?; return !@status.success?; end
		def signaled?; return @status.signaled?; end
		def stopsig; return @status.stopsig; end
		def termsig; return @status.termsig; end

		def to_i; return @status.to_i; end
		alias_method :to_int, :to_i

		def to_s; return @status.to_s; end
		alias_method :to_str, :to_s
	end

	class Result2 < Result
		attr_reader :stdout

		def initialize(status:, stdout:)
			super(status: status, is_super: true)

			(@stdout = stdout).freeze

			self.freeze
		end
	end

	class Result3 < Result
		attr_reader :stdout
		attr_reader :stderr

		def initialize(status:, stdout:, stderr:)
			super(status: status, is_super: true)

			(@stdout = stdout).freeze
			(@stderr = stderr).freeze

			self.freeze
		end
	end

	def self.execute!(name, *args)
		puts([name, *args].join(" "))

		Open3.popen3(name, *args) { |stdin, stdout, stderr, wait_thr|
			io_lock = Mutex.new

			thread_stdout = stream_stream(stream_in: stdout, stream_out: STDOUT, lock: io_lock)
			thread_stderr = stream_stream(stream_in: stderr, stream_out: STDERR, lock: io_lock)

			stdin.close

			thread_stdout.join
			thread_stderr.join
			return Result.new(status: wait_thr.value)
		}
	end

	def self.capture!(name, *args, stream: false)
		captured_stdout = StringIO.new
		captured_stderr = StringIO.new

		result = nil

		Open3.popen3(name, *args) { |stdin, stdout, stderr, wait_thr|
			io_lock = Mutex.new

			thread_stdout = stream_capture(stream_in: stdout, stream_out: [stream ? STDOUT : nil, captured_stdout], lock: io_lock)
			thread_stderr = stream_capture(stream_in: stderr, stream_out: [stream ? STDERR : nil, captured_stderr], lock: io_lock)

			stdin.close

			thread_stdout.join
			thread_stderr.join
			result = wait_thr.value
		}

		return Result3.new(
			status: result,
			stdout: captured_stdout.string,
			stderr: captured_stderr.string
		)
	end

	def self.capture2e!(name, *args, stream: false)
		captured_stdout = StringIO.new

		result = nil

		Open3.popen3(name, *args) { |stdin, stdout, stderr, wait_thr|
			io_lock = Mutex.new

			thread_stdout = stream_capture(stream_in: stdout, stream_out: [stream ? STDOUT : nil, captured_stdout], lock: io_lock)
			thread_stderr = stream_capture(stream_in: stderr, stream_out: [stream ? STDERR : nil, captured_stdout], lock: io_lock)

			stdin.close

			thread_stdout.join
			thread_stderr.join
			result = wait_thr.value
		}

		return Result2.new(
			status: result,
			stdout: captured_stdout.string
		)
	end
end

# legacy
def executable_exists?(name)
	return Executable::which?(name)
end

# legacy
def execute(*cmd)
	return Executable::execute!(cmd[0], *cmd[1..-1])
end
