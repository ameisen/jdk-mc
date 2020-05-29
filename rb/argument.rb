module Argument
	def self.flag(name, callback, cmd, arg)
		m = /([\+\-]?)#{name}/.match(cmd)
		return nil if !m
		f = (m[1].strip != '-')
		callback.call(name, f)
		return true
	end
	FLAG = self.method(:flag)

	def self.function(name, callback, cmd, arg)
		return nil if (cmd != name)
		callback.call(cmd, arg)
		return true
	end
	FUNCTION = self.method(:function)

	def self.process(args = ARGV, config)
		args.each { |arg|
			(cmd, carg) = arg.split("=", 2)
			name = cmd.strip

			handler = nil
			# test handlers
			config.each { |k, v|
				handler = v[0].call(name, v[1], k, carg)
				break unless handler.nil?
			}

			if handler.nil?
				error "Unknown Argument '#{name}'"
				exit 1
			end
		}
	end
end
