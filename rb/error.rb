module Error
	module Flag
		UNKNOWN_FLAG = 1
		GENERAL = -1
		FETCH = -2
		CLEAN = -3
		CONFIGURE = -4
		BUILD = -5
	end

	@flag_stack = [ Flag::GENERAL ]

	class << self
		def _error(flag, *str)
			eputs "[FAIL] #{str.join(" ")}"
			exit flag
		end

		def push_flag(flag)
			@flag_stack << flag
		end

		def pop_flag
			@flag_stack[-1] = nil
		end

		def error(*str); _error(@flag_stack[-1], *str); end
		def unknown_flag(*str); _error(Flag::UNKNOWN_FLAG, *str); end
		def general(*str); _error(Flag::GENERAL, *str); end
		def fetch(*str); _error(Flag::FETCH, *str); end
		def clean(*str); _error(Flag::CLEAN, *str); end
		def configure(*str); _error(Flag::CONFIGURE, *str); end
		def build(*str); _error(Flag::BUILD, *str); end
	end
end
