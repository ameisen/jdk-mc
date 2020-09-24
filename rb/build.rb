require File.join(__dir__, "runtime.rb")

require 'etc'
require 'shellwords'
require 'sys/cpu'
require 'pp'
include Sys

CONFIG_NAME = "mc"

BUILD_PLATFORM = System::build_platform
TARGET_PLATFORM = BUILD_PLATFORM

# /usr/lib/gcc/x86_64-linux-gnu/10/libstdc++.a(eh_throw.o)(.note.stapsdt+0x14): error: relocation refers to local symbol "" [4], which is defined in a discarded section
PREFERRED_GNU_LINKER = "bfd"

module GNU
	def self.prefix_opt(opt, prefix:, enable: true)
		return "-#{prefix}#{enable ? "" : "no-"}#{opt}"
	end

	def self.opt(opt, enable: true)
		return prefix_opt(opt, prefix: "", enable: enable)
	end

	def self.f_opt(opt, enable: true)
		return prefix_opt(opt, prefix: "f", enable: enable)
	end

	def self.m_opt(opt, enable: true)
		return prefix_opt(opt, prefix: "m", enable: enable)
	end

	def self.warn(opt, enable: true)
		return prefix_opt(opt, prefix: "W", enable: enable)
	end

	def self.warns(*opts, enable: true)
		return opts.map { |opt|
			warn(opt, enable: enable)
		}
	end

	def self.linker(*opts)
		return opts.map { |opt|
			"-Wl,#{opt}"
		}
	end
end

DEFAULT_GNU_C_OPTFLAGS = [
	"-O3",
	GNU::f_opt("merge-all-constants"),
	GNU::f_opt("omit-frame-pointer"),
	GNU::f_opt("ipa-pta"),
	GNU::f_opt("tree-loop-im"),
	GNU::f_opt("tree-loop-ivcanon"),
	GNU::f_opt("ivopts"),
	GNU::f_opt("graphite-identity"),
	GNU::f_opt("loop-nest-optimize"),
	GNU::f_opt("tree-vectorize"),
	GNU::f_opt("allow-store-data-races"), # worrying
	GNU::f_opt("web"),
	GNU::f_opt("fast-math"),
	GNU::f_opt("associative-math"),
	GNU::f_opt("reciprocal-math"),
	#GNU::f_opt("single-precision-constant"),
	GNU::f_opt("rename-registers"),
	GNU::f_opt("split-loops"),
	GNU::f_opt("unswitch-loops"),
	GNU::f_opt("function-sections"),
	GNU::f_opt("data-sections"),
	GNU::f_opt("stdarg-opt")
	#function-sections
	#data-sections
	#-fvariable-expansion-in-unroller
]

DEFAULT_GNU_CFLAGS = DEFAULT_GNU_C_OPTFLAGS + [
	#GNU::f_opt("exceptions", enable: false),
	GNU::warn("unused-function", enable: false),
	"-pipe",
	GNU::f_opt("lto"),
	GNU::f_opt("use-linker-plugin"),
	GNU::f_opt("devirtualize-speculatively"),
	GNU::f_opt("devirtualize-at-ltrans"),
]

DEFAULT_GNU_CXXFLAGS = DEFAULT_GNU_CFLAGS + [
	GNU::f_opt("threadsafe-statics", enable: false),
	GNU::f_opt("rtti", enable: false),
	*GNU::warns("volatile", "attributes", enable: false),
]

DEFAULT_GNU_BFD_FLAGS = [
	*GNU::linker(
		"--enable-non-contiguous-regions",
		"--no-omagic",
		"-O1",
		# non-debug only
	)
]

DEFAULT_GNU_GOLD_FLAGS = [
	*GNU::linker(
		"--icf=all", # none,all,safe
		"--icf-iterations=8", # default 3
		"-O,3",
		#"--preread-archive-symbols",
		#"--threads",
		#"-z,text-unlikely-segment",

		# non-debug only
		# debug only
		# --gdb-index
	)
]

DEFAULT_GNU_LDFLAGS = [
	*GNU::linker(
		"--relax",
		"--gc-sections",
		"--allow-multiple-definition",
		"--as-needed",
		"--compress-debug-sections=zlib",
		"--hash-style=gnu",

		# non-debug only
		"--discard-all", # --discard-locals
		"--strip-all", # --strip-debug
	),

	"-pipe",
	GNU::f_opt("lto"),
	GNU::f_opt("use-linker-plugin"),
	GNU::f_opt("ipa-pta"),
]

DEFAULT_LLVM_CFLAGS = [
	"-O3",
	GNU::f_opt("merge-all-constants"),
]

DEFAULT_LLVM_CXXFLAGS = DEFAULT_LLVM_CFLAGS + [
]

DEFAULT_LLVM_LDFLAGS = [
]

DEFAULT_MSVC_C_OPTFLAGS = [
	"/O2",
	"/Ob3",
]

DEFAULT_MSVC_CFLAGS = DEFAULT_MSVC_C_OPTFLAGS + [
	"/fp:fast",
	"/GS-",
	"/Qpar",
	"/volatile:iso",
	"/Gw",
	"/Gy",
	"/MP",
	"/Zc:alignedNew",
	"/Zc:__cplusplus",
	"/Zc:forScope",
	"/Zc:threadSafeInit-",
	"/Zc:throwingNew",
	"/Zc:strictStrings-",
	"/GL"
]

DEFAULT_MSVC_CXXFLAGS = DEFAULT_MSVC_CFLAGS + [
	"/std:c++latest"
]

DEFAULT_MSVC_LDFLAGS = [
	"/LARGEADDRESSAWARE",
	"/OPT:REF",
	"/OPT:ICF=8", # default 1
	"/CGTHREADS:#{[Etc.nprocessors, 8].min}",
]

def debug_ccflags(flags)
	gcc = false

	flags = flags.map { |f|
		if DEFAULT_GNU_C_OPTFLAGS.include?(f)
			gcc = true
			nil
		elsif DEFAULT_MSVC_C_OPTFLAGS.include?(f)
			gcc = false
			nil
		else
			case f
			when "-flto", /\-flto=.*/
				"-fno-lto"
			when "/O2"
				"/O0"
			when "/Ob3"
				nil
			else
				f
			end
		end
	}.filter { |f|
		!(f.nil?)
	}

	if gcc
		flags += [
			"-fno-omit-frame-pointer",
			"-O0",
			"-ggdb",
			"-fno-eliminate-unused-debug-symbols",
			"-fvar-tracking",
			"-gdescribe-dies",
			"-gpubnames",
			"-ggnu-pubnames",
		]
	else
		flags += [
			"/O0"
		]
	end

	return flags
end

def debug_ldflags(flags)
	return flags.map { |f|
		case f
		when "-O3"
			"-O0"
		when "-Wl,-O1"
			nil
		else
			f
		end
	}.filter { |f|
		!(f.nil?)
	}
end

SUPPORT_MAKEPP = false

$makes_makepp = SUPPORT_MAKEPP ? [ "makepp", "make++" ] : []
$makes_remake = [ "remake" ]
$makes_gnumake = [ "make", "gmake" ]
$makes_bsdmake = [ "make", "bmake" ]

$sys_makepp = nil
$sys_remake = nil
$sys_make = nil

($makes_remake + $makes_gnumake + $makes_bsdmake).uniq.compact.each { |mk|
	if Executable::which?(mk)
		# TODO fix this for BSD?
		$sys_makepp = mk if ($sys_makepp.nil? && $makes_makepp.include?(mk))
		$sys_remake = mk if ($sys_remake.nil? && $makes_remake.include?(mk))
		$sys_make = mk if ($sys_make.nil? && $makes_gnumake.include?(mk))
	end
}

def get_best_make
	[$sys_makepp, $sys_remake, $sys_make].each { |mk|
		return mk unless mk.nil?
	}
	return nil
end

# Include the global configuration file if there is one
GLOBAL_BUILD_CFG_PATH = File.join(Dir.pwd, ".build.rb")
if File.exist?(GLOBAL_BUILD_CFG_PATH)
	require GLOBAL_BUILD_CFG_PATH
	INCLUDED_GLOBAL_BUILD_CFG = true
else
	INCLUDED_GLOBAL_BUILD_CFG = false
end

module Toolchains
	MSVC = "MSVC"
	GNU = "GNU"
	LLVM = "LLVM"

	def self.get_default
		if (TARGET_PLATFORM.is?(System::Platforms::WINDOWS))
			return Toolchains::MSVC
		elsif (TARGET_PLATFORM.is?(System::Platforms::LINUX))
			return Toolchains::GNU
		else
			return Toolchains::LLVM
		end
	end

	def self.get_arch(toolchain, architecture)
		flags = []

		case toolchain
		when MSVC
			if architecture.manufacturer == Architectures::Manufacturers::INTEL
				flags << "/QIntel-jcc-erratum"
			end
			flags += architecture.cc_flags(gcc: false)
		when GNU, LLVM
			flags += architecture.cc_flags(gcc: true)
		end

		return flags
	end

	include AutoInstance(self)
end

$DEFAULT_MAKE = get_best_make()

module Options
	@toolchain = Toolchains::get_default
	@linker = nil
	@project = false
	@native = false
	@cflags = nil
	@cxxflags = nil
	@ldflags = nil
	@arch = Architectures::Intel::HASWELL
	@debug = false
	@jobs = Etc.nprocessors
	@make = $DEFAULT_MAKE

	def self.all_flags; return [@cflags, @cxxflags, @ldflags]; end
	def self.compile_flags; return [@cflags, @cxxflags]; end

	module Pass
		@cleared = false
		@fetch = false
		@clean = true
		@configure = true
		@build = true
		@package = true
		@install = true
		@clear_term = false

		def self.clear(force = false, inverse = false)
			return if (@cleared && !force)
			@cleared = true

			@fetch = inverse
			@clean = inverse
			@configure = inverse
			@build = inverse
			@package = inverse
			@install = inverse
		end

		include AutoInstance(self)
	end

	include AutoInstance(self)
end

cmd_arguments = {
	"config" => [ Argument::FUNCTION, proc { |cmd, arg|
		puts "Loading Configuration File '#{arg}'..."
		load(arg)
	} ],
	"project" => [ Argument::FLAG, proc { |name, flag|
		Options::project = flag
	} ],
	"fetch" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::fetch = flag
	} ],
	"clean" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::clean = flag
	} ],
	"configure" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::configure = flag
	} ],
	"reconfigure" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::clean = true if flag
		Options::Pass::configure = true if flag
	} ],
	"build" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::build = flag
	} ],
	"install" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::install = flag
	} ],
	"package" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear if flag
		Options::Pass::package = flag
	} ],
	"debug" => [ Argument::FLAG, proc { |name, flag|
		Options::debug = flag
	} ],
	"clear" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear_term = flag
	} ],
	"all" => [ Argument::FLAG, proc { |name, flag|
		Options::Pass::clear(force: true, inverse: flag)
	} ],
	"llvm" => [ Argument::FLAG, proc { |name, flag|
		Options::toolchain = flag ? Toolchains::LLVM : Toolchains::get_default
	} ],
	"native" => [ Argument::FLAG, proc { |name, flag|
		Options::native = flag ? Toolchains::LLVM : Toolchains::get_default
	} ],
	"arch" => [ Argument::FUNCTION, proc { |cmd, arg|
		Options::arch = arg.upcase
	} ],
	"jobs" => [ Argument::FUNCTION, proc { |cmd, arg|
		arg = arg.downcase
		if arg == "auto"
			Options::jobs = Etc.nprocessors
		elsif arg == "none"
			Options::jobs = 1
		else
			jobs = arg.to_i
			if jobs == 0
				Options::jobs = 1
			elsif jobs < 0
				jobs = -jobs
				jobs = [Etc.nprocessors - jobs, 1].max
				Options::jobs = jobs
			else
				Options::jobs = jobs
			end
		end
	} ],
	"with-linker" => [ Argument::FUNCTION, proc { |cmd, arg|
		Options::linker = arg.downcase
	} ],
	"with-make" => [ Argument::FUNCTION, proc { |cmd, arg|
		Options::make = arg.downcase
	} ],
	"with-remake" => [ Argument::FLAG, proc { |name, flag|
		Options::make = $sys_remake if flag
	} ],
	"with-makepp" => [ Argument::FLAG, proc { |name, flag|
		Options::make = $sys_makepp if flag
	} ],
}

Argument.process(ARGV, cmd_arguments)

Options::linker = {
	Toolchains::GNU => PREFERRED_GNU_LINKER,
	Toolchains::LLVM => PREFERRED_GNU_LINKER,
	Toolchains::MSVC => "link"
}[Options::toolchain] if Options::linker.nil?

ADDITIONAL_LD_FLAGS = {
	"gold" => DEFAULT_GNU_GOLD_FLAGS,
	"bfd" => DEFAULT_GNU_BFD_FLAGS
}.fetch(Options::linker, [])

Options::cflags, Options::cxxflags, Options::ldflags = *{
	Toolchains::GNU  => [DEFAULT_GNU_CFLAGS, DEFAULT_GNU_CXXFLAGS, DEFAULT_GNU_LDFLAGS + ADDITIONAL_LD_FLAGS],
	Toolchains::LLVM => [DEFAULT_LLVM_CFLAGS, DEFAULT_LLVM_CXXFLAGS, DEFAULT_LLVM_LDFLAGS + ADDITIONAL_LD_FLAGS],
	Toolchains::MSVC => [DEFAULT_MSVC_CFLAGS, DEFAULT_MSVC_CXXFLAGS, DEFAULT_MSVC_LDFLAGS + ADDITIONAL_LD_FLAGS]
}[Options::toolchain]

Options::all_flags.each {|flags|
	flags.map!{ |flag|
		case flag
		when "-flto"
			(Options::toolchain == Toolchains::GNU) ? "-flto=#{Options::jobs}" : "-flto=thin"
			#(Options::toolchain == Toolchains::GNU) ? "-flto=1" : "-flto=thin"
		else
			flag
		end
	}
}

if Options::debug
	Options::cflags = debug_ccflags(Options::cflags)
	Options::cxxflags = debug_ccflags(Options::cxxflags)
	Options::ldflags = debug_ldflags(Options::ldflags)
end

case Options::toolchain
when Toolchains::GNU, Toolchains::LLVM
	Options::all_flags.each { |flags|
		flags << GNU::f_opt("use-ld=#{PREFERRED_GNU_LINKER}")
	}
end

if Options::arch.is_a?(String)
	arch_name = Options::arch
	Options::arch = Architectures::get(arch_name)
	raise "Unknown Architecture: #{arch_name}" if Options::arch.nil?
end

architecture_flags = Toolchains::get_arch(Options::toolchain, Options::arch)
Options::cflags += architecture_flags
Options::cxxflags += architecture_flags

def WriteEchoFile(path, str)
	File.open(path, 'w') { |file|
		file.write(str);
	}
	# TODO use FileUtils.chmod
	`chmod +x #{path}`
end

FileUtils.mkdir_p(Directory::build_root)
WriteEchoFile(File.join(Directory::build_root, "cflags"), Options::cflags.join(" "))
WriteEchoFile(File.join(Directory::build_root, "cxxflags"), Options::cxxflags.join(" "))
WriteEchoFile(File.join(Directory::build_root, "ldflags"), Options::ldflags.join(" "))

if (Options::Pass::clear_term)
	puts "\e[H\e[2J"
	system("clear") or system("cls")
end

unless INCLUDED_GLOBAL_BUILD_CFG
	warning "Global Build Configuration File '#{GLOBAL_BUILD_CFG_PATH}' not accessible"
end

Directory::finalize

puts "Build System Information:\n#{System::dump(1)}"

TARGET_NAME = {
	"Linux" => "linux",
	"Windows" => "windows",
	"Cygwin" => "windows",
	"MSys" => "windows"
}[TARGET_PLATFORM.name]

def parse_jdk_version_file(path)
	lines = []
	File.open(path).each { |line|
		quote = nil
		escape = false
		comment = false

		lines << ""

		line.each_char { |c|
			break if comment

			escaped = escape

			out_char = nil

			case c
			when quote
				if escape
					out_char = c
				else
					quote = nil
				end
			when '\"', '\''
				if quote.nil?
					out_char = c
				else
					quote = c
				end
			when '\\'
				if escape || quote.nil?
					out_char = '\\'
				else
					escape = true
				end
			when '#'
					if !(quote.nil?) || escape
						out_char = '#'
					else
						comment = true
					end
			else
				out_char = c
			end

			break if comment

			escape = false if escaped

			next if c.nil?
			lines[-1] += c
		}

		lines[-1].strip!

		raise "unterminated quote in '#{line}'" unless quote.nil?
		raise "escape without determiner in '#{line}'" if escape
	}

	result = Hash.new

	lines.each { |line|
		next if line.empty?

		line = line.split("=", 2)

		raise "invalid config line: '#{line}'" if (line.size != 2)

		key = line[0].strip
		value = line[1].strip

		result[key] = value
	}

	return result
end

def get_revision_count(source_root)
	Dir.chdir(source_root) {
		output, result = Executable::capture2e!("git", "rev-list", "--count", "HEAD")
		output.strip!
		begin
			output = output.to_i
		rescue
			output = nil
		end
		return output.nil? ? "?????" : output
	}
end

JDK_BUILD = get_revision_count(Directory::build_root)

JDK_VERSION_HASH = parse_jdk_version_file(File.join(Directory::build_root, "make", "autoconf", "version-numbers"))

JDK_VERSION_HASH.each { |key, value|
	puts "\t'#{key}'' = '#{value}''"
}

puts "\tRevision Count: #{JDK_BUILD}"

puts "\tArchitecture: #{Options::arch.to_s}"
puts "\tManufacturer: #{Options::arch.manufacturer.to_s}"
puts "\tcflags: #{Options::cflags.to_s}"
puts "\tcxxflags: #{Options::cxxflags.to_s}"
puts "\tldflags: #{Options::ldflags.to_s}"
puts "\tdebug: #{Options::debug}"

TARGET_ARCH = "x86_64"

CONFIG_TYPE = Options::debug ? "slowdebug" : "release"

FULL_CONFIG_NAME = "#{TARGET_NAME}-#{TARGET_ARCH}-#{CONFIG_NAME}-#{CONFIG_TYPE}"
FULL_CONFIG_NAME_WITH_ARCH = "#{FULL_CONFIG_NAME}-#{Options::arch.to_s.downcase}"

puts "Building: '#{FULL_CONFIG_NAME}'"

def ExecutePass(name, flag)
	puts "Executing Pass #{name}"
	Error::push_flag(flag)
	yield
	Error::pop_flag
	puts "Completed Pass #{name}"
end

puts "Toolchain: #{Options::toolchain}"
puts "Passes:"
tputs(1, "Clean") if Options::Pass::clean
tputs(1, "Fetch") if Options::Pass::fetch
tputs(1, "Configure") if Options::Pass::configure
tputs(1, "Build") if Options::Pass::build
tputs(1, "Package") if Options::Pass::package
tputs(1, "Install") if Options::Pass::install

IN_BUILD_ROOT = Directory.same?(Directory::build, Directory::build_root)

ExecutePass("Cleaning Pass", Error::Flag::CLEAN) {
	Directory.delete(File.join(Directory::build, FULL_CONFIG_NAME), recursive: true)
	Directory.delete(File.join(Directory::build, ".configure-support"), recursive: true)
	Directory.make(Directory::build) if IN_BUILD_ROOT
	File.delete(File.join(Directory::build, "#{FULL_CONFIG_NAME}.config.cache"))
	File.delete(File.join(Directory::build_root, "#{FULL_CONFIG_NAME}.config.cache"))
} if Options::Pass::clean

ExecutePass("Fetch Pass", Error::Flag::FETCH) {
	Directory.enter(Directory::source, must: true) {
		`git fetch --unshallow --recursive`
		`git pull --unshallow --recursive`
		`git gc --aggressive --prune=now`
	}
} if Options::Pass::fetch

ExecutePass("Configure Pass", Error::Flag::CONFIGURE) {
	Directory.make(Directory::build)

	Directory.enter(Directory::build_root, must: true) {
		# figure out configuration flags

		def jvm_enable(flag)
			return "--enable-jvm-feature-#{flag}"
		end

		def jvm_disable(flag)
			return "--disable-jvm-feature-#{flag}"
		end

		all_features = [
			"aot",
			"cds",
			"compiler1",
			"compiler2",
			"graal",
			"jvmci",
			"jvmti",
			"management",
			"nmt",
			"services",
			"shenandoahgc",
			"static-build",
			"vm-structs",
			"zgc",
			"dtrace",
			"epsilongc",
			"g1gc",
			"jfr",
			"jni-check",
			"minimal",
			"opt-size",
			"parallelgc",
			"serialgc",
			"zero"
		]

		disabled_features = [
			"dtrace",
			"jfr",
			"minimal",
			"opt-size",
			"zero",
			"static-build",
			#"g1gc",
			"parallelgc",
			"serialgc",
			"epsilongc",
			"jni-check",
			"management",
			"nmt",
			"compiler2",
			"link-time-opt",
		].sort

		enabled_features = all_features.filter_map { |f| f unless disabled_features.include?(f) }.sort

		enable_flags = [
			"linktime-gc",
			"generate-classlist",
			"cds-archive",
			"javac-server",
			"precompiled-headers",
			#"aot=yes",
			"dtrace=no",
			"unlimited-crypto",
			"sjavac",
		]

		disable_flags = [
			"option_checking",
			"full-docs",
			"jtreg-failure-handler",
			"manpages",
			"reproducible-build",
			"icecc"
		]

		build_date = DateTime.now.strftime("%y.%m.%d.%H.%M")

		with_flags = [
			"target-bits=64",
			"debug-level=#{CONFIG_TYPE}",
			"jvm-variants=#{CONFIG_NAME}",
			"vendor-name=Digital Carbide",
			"vendor-url=https://www.digitalcarbide.com/",
			"version-build=#{JDK_VERSION_HASH["DEFAULT_VERSION_REVISION"]}",
			"version-opt=mc-#{JDK_BUILD}",
			"version-pre=#{(Options::debug ? "debug" : "release")}",
			"native-debug-symbols=#{(Options::debug ? "internal" : "none")}"
		]

		if (TARGET_PLATFORM.is?(System::Platforms::WINDOWS))
			with_flags << "tools-dir=#{Directory::vc_bin}"
		else
			with_flags << "toolchain_type=#{(Options::toolchain == Toolchains::GNU) ? "gcc" : "clang"}"
			with_flags << "ccache"
			enable_flags << "ccache"
		end

		with_flags << "boot-jdk=#{Directory::java}" unless Directory::java.blank?
		with_flags << "jmh=#{Directory::jmh}" unless Directory::jmh.blank?

		without_flags = [
			"devkit",
		]

		configure_flags = [
			"--cache-file=#{FULL_CONFIG_NAME}.config.cache",
			"--prefix=#{Directory::install}",
		] +
		enable_flags.filter_map { |f| "--enable-#{f}" unless f.blank? } +
		disable_flags.filter_map { |f| "--disable-#{f}" unless f.blank? } +
		with_flags.filter_map { |f| "--with-#{f}" unless f.blank? } +
		without_flags.filter_map { |f| "--without-#{f}" unless f.blank? }
		#enabled_features.filter_map { |f| jvm_enable(f) unless f.blank? } +
		#disabled_features.filter_map { |f| jvm_disable(f) unless f.blank? }

		configure_add_env = lambda { |name|
			return if ENV[name].nil?
			configure_flags << "#{name}=#{ENV[name]}"
			configure_flags << "BUILD_#{name}=#{ENV[name]}"
		}

		llvm = (Options::toolchain == Toolchains::LLVM)

		ENV["PATH"] = File.join(Directory::build_root, "alias", "interpreter") + ":" + ENV["PATH"]

		extra_cflags = []

		if BUILD_PLATFORM.is?(System::Platforms::WINDOWS)
			# At the present, we only have to redirect if we're using an LLVM toolchain
			if llvm
				# Add the toolchain to the PATH so that the scripts know where to find it
				#ENV["CC"] = File.join(__dir__, "alias", "clang-cl")
				#ENV["CXX"] = File.join(__dir__, "alias", "clang-cl")
				#ENV["CPP"] = File.join(__dir__, "alias", "clang-cl")
				#ENV["LD"] = File.join(__dir__, "alias", "lld-link")
				ENV["CC"] = File.join(Directory::llvm_root, "bin", "clang-cl")
				ENV["CXX"] = File.join(Directory::llvm_root, "bin", "clang-cl")
				extra_cflags += ['-m64', '-Wno-narrowing', '-fms-compatibility', '-fms-extensions', '-fms-compatibility-version=19.26.28806']
				ENV["LD"] = File.join(Directory::llvm_root, "bin", "lld-link")

				ENV["AS"] = "llvm-as"
				#ENV["RC"] = "llvm-rc"
				#ENV["NM"] = "llvm-nm"
				#ENV["AR"] = "llvm-ar"
				#ENV["RANLIB"] = "llvm-ranlib"
				ENV["OBJDUMP"] = "llvm-objdump"
				ENV["OBJCOPY"] = "llvm-objcopy"
				ENV["PROFDATA"] = "llvm-profdata"
				ENV["LIB"] = "llvm-lib"
				ENV["SYMBOLIZER"] = "llvm-symbolizer"
			end
		else
			ENV["CC"] = File.join(Directory::build_root, "alias", llvm ? "clang" : "gcc")
			ENV["CXX"] = File.join(Directory::build_root, "alias", llvm ? "clang++" : "g++")
			ENV["CPP"] = File.join(Directory::build_root, "alias", llvm ? "clang-cpp" : "cpp")
			ENV["NM"] = File.join(Directory::build_root, "alias", llvm ? "llvm-nm" : "nm")
			ENV["AR"] = File.join(Directory::build_root, "alias", llvm ? "llvm-ar" : "ar")
			ENV["RANLIB"] = File.join(Directory::build_root, "alias", llvm ? "llvm-ranlib" : "ranlib")

			configure_add_env.call("NM")
			configure_add_env.call("AR")
			configure_add_env.call("RANLIB")
			configure_add_env.call("CPP")
			configure_add_env.call("CC")
			configure_add_env.call("CXX")
			configure_add_env.call("LD")
			configure_add_env.call("STRIP")

			if Options::native
				extra_cflags += [
					'-march=native'
				]
			end
		end

		configure_flags << "--with-extra-cflags=#{extra_cflags.join(" ")}" unless extra_cflags.empty?

		puts "Configure Flags:"
		configure_flags.each { |f|
			tputs(1, f)
		}

		Directory.make(Directory::install)

		if IN_BUILD_ROOT
			Executable::execute!(
				"rsync",
				"-avrLkHA",
				"--preallocate",
				"--sparse",
				"--exclude='.git/*'",
				Directory.canonical(Directory::source),
				"./"
			)
		end

		Executable::execute!("bash", "configure", "MAKE=#{Options::make}",*configure_flags)
	}
} if Options::Pass::configure

ExecutePass("Build Pass", Error::Flag::BUILD) {
	Directory.make(Directory::build)

	Directory.enter(Directory::build_root, must: true) {
		if Options::Pass::clean
			execute(
				Options::make,
				"CONF_NAME=#{FULL_CONFIG_NAME}",
				"clean"
			)
		end

		success = execute(
			Options::make,
#			"--no-print-directory",
			"JOBS=#{Options::jobs}",
			"CONF_NAME=#{FULL_CONFIG_NAME}",
			Options::project ? "hotspot-ide-project" : "images"
		)

		if (!success)
			STDERR.puts("Build Failed")
			exit 1
		end

		#if (success)
			#build_root = File.join(Directory::build_root, "build")
			#source = File.join(build_root, FULL_CONFIG_NAME)
			#dest = File.join(build_root, FULL_CONFIG_NAME_WITH_ARCH)
			#FileUtils.rm_rf(dest)
			#FileUtils.mv(source, dest)
		#end
	}
} if Options::Pass::build

ExecutePass("Package Pass", Error::Flag::PACKAGE) {
	builds_root = File.join(Directory::up_root, "builds")
	Directory.make(builds_root)

	build_root = File.join(Directory::build_root, "build")
	source = File.join(build_root, FULL_CONFIG_NAME, "images", "jdk")
	Error::error("Package source '#{source}' does not exist or is not accessible") unless File.directory?(source)
	dest = File.join(builds_root, FULL_CONFIG_NAME_WITH_ARCH)

	puts("Copying '#{source}' to '#{dest}'")
	FileUtils.rm_rf(dest)
	Error::error("Package destination '#{dest}' was not able to be cleaned") if File.directory?(dest)
	FileUtils.cp_r(source, dest)

	best_compressor = Compressors::best

	package_name = "#{FULL_CONFIG_NAME_WITH_ARCH}.#{best_compressor.nil? ? "tar" : best_compressor.extension}"
	puts("Compressing package '#{package_name}'")
	package_path = File.join(builds_root, package_name)

	FileUtils.rm_rf(package_path)
	Error::error("Failed to remove existing package '#{package_path}'") if File.exist?(package_path)

	command = nil
	if best_compressor.nil?
		command = [
			"tar", "-cvf", "-", dest,
			">", package_path
		]
	else
		command = best_compressor.full_command(source: dest, archive: package_path)
		if command.nil?
			command = [
				"tar", "-cvf", "-", dest, "|",
				*best_compressor.command, "-",
				">", package_path
			]
		end
	end

	#command.map! { |element|
	#	["|", ">", ">>", "||", "&&", "-", "--"].include?(element) ? element : Shellwords.escape(element)
	#}

	execute(*command) or Error::error("Failed to compress package")
} if Options::Pass::package

puts "done"
