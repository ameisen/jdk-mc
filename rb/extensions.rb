require 'pathname'

def AutoInstance(mod)
	# https://stackoverflow.com/a/4082937
	def create_method(mod, name, &block)
		mod.class.send(:define_method, name, &block)
	end

	mod.instance_variables.each { |variable|
		name = variable[1..-1]
		create_method(mod, "#{name}=".to_sym) { |value|
			instance_variable_set("@#{name}", value)
		}
		create_method(mod, name.to_sym) {
			instance_variable_get("@#{name}")
		}
	}
end

class File
	def self.canonical(*path)
		Pathname.new(File.join(*path)).cleanpath.to_s
	end

	def self.delete(path, recursive: false, must: false)
		begin
			if recursive
				FileUtils.rm_rf(canonical(path))
			else
				FileUtils.rm_f(canonical(path))
			end
		rescue
			raise if must
		end
	end

	def self.same?(path1, path2)
		return canonical(path1) == canonical(path2)
	end

	AutoInstance(self)
end

module Directory
	def self.canonical(*path)
		return File.canonical(*path)
	end

	@root = canonical(__dir__, "..")
	@up_root = canonical(@root, "..")
	@source = @root
	@build_root = @source
	@build = File.join(@build_root, "build")
	@install = File.join(@up_root, "install")
	@java = nil #ENV["JAVA_HOME"]
	@vc_root = ENV["VC_ROOT"]
	@vc_bin = nil
	@llvm_root = nil
	@jmh = nil
	@jtreg = nil
	@proguard = nil

	def self.working; Dir.pwd; end

	def self.finalize
		if System::build_platform.is?(System::Platforms::WINDOWS)
			if (@vc_root.nil?)
				error "'Directory.vc_root' is not set!"
				exit 1
			end
			@vc_bin = File.join(@vc_root, "VC", "Tools")
		end
		self.freeze
	end

	def self.enter(path, must: false, make: false)
		begin
			self.make(path) if make
			Dir.chdir(canonical(path)) {
				yield
			}
		rescue
			raise if must
		end
	end

	def self.make(*path)
		FileUtils.mkdir_p(canonical(File.join(*path)))
	end

	def self.delete(path, recursive: false, must: false)
		return File.delete(path, recursive: recursive, must: must)
	end

	def self.same?(path1, path2)
		return File.same?(path1, path2)
	end

	AutoInstance(self)
end
