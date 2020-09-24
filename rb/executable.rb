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

	def self.execute!(name, *args)
		puts([name, *args].join(" "))

		Open3.popen3(name, *args) { |stdin, stdout, stderr, wait_thr|
			io_lock = Mutex.new

			thread_stdout = stream_stream(stream_in: stdout, stream_out: STDOUT, lock: io_lock)
			thread_stderr = stream_stream(stream_in: stderr, stream_out: STDERR, lock: io_lock)

			stdin.close

			thread_stdout.join
			thread_stderr.join
			return wait_thr.value
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

		return [captured_stdout.string, captured_stderr.string, result]
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

		return [captured_stdout.string, result]
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
