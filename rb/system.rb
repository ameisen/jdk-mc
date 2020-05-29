module System
	class Platform
		attr_reader :parent
		attr_reader :name
		attr_reader :uname
		attr_reader :version

		def initialize(parent: nil, name: nil, uname: nil, version: nil)
			if parent.nil?
				parent = self
			else
				name = parent.name if name.nil?
				uname = parent.uname if uname.nil?
				version = parent.version if version.nil?
			end
			(@name = name).freeze
			(@uname = uname).freeze
			(@version = version).freeze
			@parent = parent
			self.freeze
		end

		def to_s; @name; end

		alias_method :to_string, :to_s

		def match?(uname: nil)
			return uname[0].include?(@uname) unless (@uname.nil? || uname.nil?)
			return false
		end

		def parent?
			last_parent = self
			parent = self.parent
			while (parent != last_parent)
				last_parent = parent
				parent = parent.parent
			end
			return parent
		end

		def is?(platform)
			return parent?.eql?(platform.parent?)
		end

		def instance(version:)
			return Platform.new(
				parent: self,
				version: version
			)
		end
	end

	module Platforms
		ALL = []
		ALL << LINUX = Platform.new(name: "Linux", uname: "Linux")
		ALL << WINDOWS = Platform.new(name: "Windows")
		ALL << CYGWIN = Platform.new(parent: WINDOWS, name: "Cygwin", uname: "CYGWIN")
		ALL << MSYS = Platform.new(parent: WINDOWS, name: "MSys", uname: "MINGW64")
		ALL.freeze
	end

	class << self
		attr_reader :build_platform
	end

	def self.init
		raise "System already initialized" unless @uname.nil?
		@uname = `uname -a`.strip.split(" ")
		raise "Could not get system version" unless $?.success?
		@uname = (@uname.map { |e| e.strip.freeze }).freeze
		version = @uname[2].strip.freeze

		platform = nil
		Platforms::ALL.each { |p|
			platform = p if p.match?(uname: @uname)
		}
		raise "Unknown Build Platform: #{@uname}" if platform.nil?

		@build_platform = platform.instance(
			version: version
		)
		self.freeze
	end

	def self.dump(tab = 0)
		tab = $TAB * tab
		result = ""
		result += "#{tab}uname   : #{@uname}\n" unless @uname.nil?
		result += "#{tab}platform: #{@build_platform}\n"
		result += "#{tab}version : #{@build_platform.version}\n"
	end
end
System::init
