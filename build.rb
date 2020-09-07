#!/usr/bin/env ruby

require File.join(__dir__, "rb", "runtime.rb")

require 'sys/cpu'
require 'pp'
include Sys

CONFIG_NAME = "mc"

BUILD_PLATFORM = System::build_platform
TARGET_PLATFORM = BUILD_PLATFORM

DEFAULT_GNU_CFLAGS = [
	"-O3",
	"-fmerge-all-constants"
]

DEFAULT_GNU_CXXFLAGS = DEFAULT_GNU_CFLAGS + [
	"-fno-threadsafe-statics"
]

DEFAULT_GNU_LDFLAGS = [
	"-Wl,--relax",
	"-Wl,-O1"
]

DEFAULT_LLVM_CFLAGS = [
	"-O3",
	"-fmerge-all-constants"
]

DEFAULT_LLVM_CXXFLAGS = DEFAULT_LLVM_CFLAGS + [
]

DEFAULT_LLVM_LDFLAGS = [
]

DEFAULT_MSVC_CFLAGS = [
	"/O2",
	"/Ob3",
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
	"/Zc:throwingNew"
]

DEFAULT_MSVC_CXXFLAGS = DEFAULT_MSVC_CFLAGS + [
	"/std:c++17"
]

DEFAULT_MSVC_LDFLAGS = [
	"/OPT:REF",
	"/OPT:ICF"
]

# Include the global configuration file if there is one
GLOBAL_BUILD_CFG_PATH = File.join(Dir.pwd, ".build.rb")
if File.exist?(GLOBAL_BUILD_CFG_PATH)
	require GLOBAL_BUILD_CFG_PATH
	INCLUDED_GLOBAL_BUILD_CFG = true
else
	INCLUDED_GLOBAL_BUILD_CFG = false
end

module Architecture
	NATIVE = "Native".upcase
	HASWELL = "Haswell".upcase
	SKYLAKE = "Skylake".upcase
	SKYLAKE_X = "Skylake-X".upcase
	INTEL = "Intel".upcase
	ZEN_1 = "Zen 1".upcase
	ZEN_2 = "Zen 2".upcase
	K10 = "K10".upcase
	AMD = "AMD".upcase
	DEFAULT = "Default".upcase

	include AutoInstance(self)
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
		case toolchain
		when MSVC
			bias = "Intel"
			isa = "AVX" # AVX2 AVX512
			case architecture
			when Architecture::NATIVE
				bias = CPU.model.downcase.include?("intel") ? "Intel" : "AMD"
				# TODO fixme
				# We don't set AVX512 or AVX2 because, well, that's generally a not good idea due to downclocking.
				isa = "AVX"
			when Architecture::ZEN_1, Architecture::ZEN_2
				bias = "AMD"
				isa = "AVX"
			when Architecture::K10, Architecture::AMD
				bias = "AMD"
				isa = nil
			when Architecture::DEFAULT
				isa = nil
			end
			extras = []
			if bias == "Intel"
				extras = ["/QIntel-jcc-erratum"]
			end
			if isa.nil?
				return ["/favor:#{(bias == "Intel") ? "INTEL64" : "AMD64"}"] + extras
			else
				return ["/arch:#{isa}", "/favor:#{(bias == "Intel") ? "INTEL64" : "AMD64"}"] + extras
			end
		when GNU, LLVM
			return {
				Architecture::NATIVE => ["--march=native"],
				Architecture::HASWELL => ["--march=haswell"],
				Architecture::SKYLAKE => ["--march=skylake"],
				Architecture::SKYLAKE_X => ["--march=skylake-avx512"],
				Architecture::INTEL => ["--mtune=nehalem"],
				Architecture::ZEN_1 => ["--march=znver1"],
				Architecture::ZEN_2 => ["--march=znver2"],
				Architecture::K10 => ["--march=amdfam10"],
				Architecture::AMD => ["--mtune=amdfam10"],
				Architecture::DEFAULT => ["--mtune=core2"],
			}[architecture]
		end
	end

	include AutoInstance(self)
end

module Options
	@toolchain = Toolchains::get_default
	@project = false
	@native = false
	@cflags = nil
	@cxxflags = nil
	@ldflags = nil
	@arch = Architecture::HASWELL

	module Pass
		@cleared = false
		@fetch = false
		@clean = false
		@configure = true
		@build = true
		@install = true
		@clear_term = false

		def self.clear(force = false, inverse = false)
			return if (@cleared && !force)
			@cleared = true

			@fetch = inverse
			@clean = inverse
			@configure = inverse
			@build = inverse
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
}

Argument.process(ARGV, cmd_arguments)

Options::cflags, Options::cxxflags, Options::ldflags = *{
	Toolchains::GNU  => [DEFAULT_GNU_CFLAGS, DEFAULT_GNU_CXXFLAGS, DEFAULT_GNU_LDFLAGS],
	Toolchains::LLVM => [DEFAULT_LLVM_CFLAGS, DEFAULT_LLVM_CXXFLAGS, DEFAULT_LLVM_LDFLAGS],
	Toolchains::MSVC => [DEFAULT_MSVC_CFLAGS, DEFAULT_MSVC_CXXFLAGS, DEFAULT_MSVC_LDFLAGS]
}[Options::toolchain]

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

TARGET_ARCH = "x86_64"

FULL_CONFIG_NAME = "#{TARGET_NAME}-#{TARGET_ARCH}-#{CONFIG_NAME}-release"

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
tputs(1, "Install") if Options::Pass::install

IN_BUILD_ROOT = Directory.same?(Directory::build, Directory::build_root)

ExecutePass("Cleaning Pass", Error::Flag::CLEAN) {
	Directory.delete(File.join(Directory::build, FULL_CONFIG_NAME), recursive: true)
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
			"unlimited-crypto"
		]

		disable_flags = [
			"option_checking",
			"full-docs",
			"hotspot-gtest",
			"jtreg-failure-handler",
			"manpages",
			"reproducible-build",
			"icecc"
		]

		with_flags = [
			"target-bits=64",
			"debug-level=release",
			"jvm-variants=#{CONFIG_NAME}",
			"vendor-name=Digital Carbide",
			"vendor-url=https://www.digitalcarbide.com/",
			"version-pre=Minecraft",
			"version-opt=#{DateTime.now.strftime("%y.%m.%d.%H.%M")}",
			"native-debug-symbols=none"
		]

		if (TARGET_PLATFORM.is?(System::Platforms::WINDOWS))
			with_flags << "tools-dir=#{Directory::vc_bin}"
		else
			with_flags << "toolchain_type=#{(Options::toolchain == Toolchains::GNU) ? "gcc" : "clang"}"
			with_flags << "ccache"
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

		ENV["PATH"] = File.join(__dir__, "alias", "interpreter") + ":" + ENV["PATH"]

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
			ENV["CC"] = File.join(__dir__, "alias", llvm ? "clang" : "gcc")
			ENV["CXX"] = File.join(__dir__, "alias", llvm ? "clang++" : "g++")
			ENV["CPP"] = File.join(__dir__, "alias", llvm ? "clang-cpp" : "cpp")

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
					'-O3', '-march=native'
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
			execute(
				"rsync",
				"-avrLkHA",
				"--preallocate",
				"--sparse",
				"--exclude='.git/*'",
				Directory.canonical(Directory::source),
				"./"
			)
		end

		execute("bash", "configure", *configure_flags)
	}
} if Options::Pass::configure

ExecutePass("Build Pass", Error::Flag::BUILD) {
	Directory.make(Directory::build)

	Directory.enter(Directory::build_root, must: true) {
		jobs = Etc.nprocessors

		execute("make", "JOBS=#{jobs}", "CONF=#{FULL_CONFIG_NAME}", Options::project ? "hotspot-ide-project" : "images")
	}
} if Options::Pass::build

puts "done"
