module Argument
	def self.flag(name, callback, cmd, arg)
		flag = true
		if ['+', '-'].include?(name[0])
			flag = (name[0] == '+')
			name = name[1..-1]
		end
		return nil if (cmd != name)
		callback.call(name, flag)
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
