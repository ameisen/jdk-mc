require 'sys/cpu'
require 'pp'

module Architectures
	# Intel chips, in particular, downclock when encountering >= 256-bit instructions.
	# AMD chips _might_, but they work off of a temperature heuristic rather than an instruction heuristic.
	# I'll let the compiler decide in that case.
	ALLOW_AVX = true
	ALLOW_AVX2 = true
	ALLOW_AVX512 = true

	class InstructionSet
		@name = nil
		@parents = []

		def initialize(name:, parents: nil)
			parents = [] if parents.nil?

			raise if name.nil?

			(@name = name).freeze
			(@parents = parents.dup).freeze
			self.freeze
		end

		def to_s; return @name; end
		alias_method :to_str, :to_s

		def include?(set, searched = [])
			# to prevent circular loops. They shouldn't happen, but they could.
			return false if searched.include?(self)
			searched.push(self)

			return true if self == set
			@parents.each { |parentset|
				return true if parentset.include?(set, searched)
			}
			return false
		end
	end

	module InstructionSets
		X86 = InstructionSet.new(name: "x86")
		SSE2 = InstructionSet.new(name: "SSE2", parents: [InstructionSets::X86])
		X86_64 = InstructionSet.new(name: "x86-64", parents: [InstructionSets::SSE2])
		SSE3 = InstructionSet.new(name: "SSE3", parents: [InstructionSets::X86_64])
		SSSE3 = InstructionSet.new(name: "SSSE3", parents: [InstructionSets::SSE3])

		SSE4_1 = InstructionSet.new(name: "SSE4.1", parents: [InstructionSets::X86_64])
		SSE4_2 = InstructionSet.new(name: "SSE4.2", parents: [InstructionSets::X86_64])
		SSE4 = InstructionSet.new(name: "SSE4", parents: [InstructionSets::SSE4_1, InstructionSets::SSE4_2])
		# TODO add predicate searches on architectures
		SSE4_ANY = InstructionSet.new(name: "SSE4 (any)", parents: [InstructionSets::X86_64])
		SSE4A = InstructionSet.new(name: "SSE4a", parents: [InstructionSets::X86_64])
		ABM = InstructionSet.new(name: "ABM", parents: [InstructionSets::X86_64])

		AVX = InstructionSet.new(name: "AVX", parents: [InstructionSets::X86_64])
		AVX2 = InstructionSet.new(name: "AVX2", parents: [InstructionSets::AVX])

		# AVX-512 is weird. It's being rolled out in bits.
		module AVX512_SUB
			AVX512F = InstructionSet.new(name: "AVX-512F", parents: [InstructionSets::AVX2])
			AVX512CD = InstructionSet.new(name: "AVX-512CD", parents: [InstructionSets::AVX2])
			AVX512ER = InstructionSet.new(name: "AVX-512ER", parents: [InstructionSets::AVX2])
			AVX5124F = InstructionSet.new(name: "AVX-5124F", parents: [InstructionSets::AVX2])
			AVX512VL = InstructionSet.new(name: "AVX-512VL", parents: [InstructionSets::AVX2])
			AVX512IFMA = InstructionSet.new(name: "AVX-512IFMA", parents: [InstructionSets::AVX2])
			AVX512VP = InstructionSet.new(name: "AVX-512VP", parents: [InstructionSets::AVX2])
			AVX512VNNI = InstructionSet.new(name: "AVX-512VNNI", parents: [InstructionSets::AVX2])

			AutoInstance(self)
		end
		AVX512 = InstructionSet.new(name: "AVX-512", parents: [
			InstructionSets::AVX512_SUB.instance_variables.filter { |var|
				return var.is_a?(InstructionSet)
			}
		])
		# TODO add predicate searches on architectures
		AVX512_ANY = InstructionSet.new(name: "AVX-512 (any)", parents: [InstructionSets::AVX2])

		AutoInstance(self)
	end

	class Manufacturer
		@name = nil
		@search = nil

		def initialize(name:, search: nil)
			search = name.downcase if search.nil?

			raise if name.nil?
			raise if search.nil?

			(@name = name).freeze
			(@search = search).freeze
			self.freeze
		end

		def to_s; return @name; end
		alias_method :to_str, :to_s

		def is?(model)
			return model.downcase.include?(@search)
		end
	end

	class Architecture
		@name = nil
		attr_reader :manufacturer
		@sets = nil
		@gcc_flags = nil
		@msvc_flags

		attr_reader :slow_avx
		attr_reader :fast_avx
		attr_reader :fast_avx2
		attr_reader :fast_avx512

		def initialize(name:, manufacturer:, sets:, slow_avx: false, fast_avx: false, fast_avx2: false, fast_avx512: false, gcc_flags: nil, msvc_flags: nil)
			raise if name.nil?
			raise if manufacturer.nil?
			raise if sets.nil?

			(@name = name).freeze
			@manufacturer = manufacturer
			(@sets = sets.dup).freeze
			@slow_avx = slow_avx
			@fast_avx512 = fast_avx512
			@fast_avx2 = fast_avx2 || @fast_avx512
			@fast_avx = fast_avx || @fast_avx2
			@gcc_flags = gcc_flags
			@msvc_flags = msvc_flags
			self.freeze
		end

		def to_s; return @name; end
		alias_method :to_str, :to_s

		def include?(set)
			@sets.each { |subset|
				return true if subset.include?(set)
			}

			return false
		end

		def cc_flags(gcc:)
			out_flags = []

			prefer_avx512 = include?(InstructionSets::AVX512_ANY) && (@fast_avx512) && ALLOW_AVX512
			prefer_avx2 = include?(InstructionSets::AVX2) && (@fast_avx || !@slow_avx) && ALLOW_AVX
			prefer_avx = include?(InstructionSets::AVX) && (@fast_avx || !@slow_avx) && ALLOW_AVX

			prohibit_avx512 = !ALLOW_AVX512 || @slow_avx512
			prohibit_avx2 = (!ALLOW_AVX2 || @slow_avx) && !@fast_avx
			prohibit_avx = (!ALLOW_AVX || @slow_avx) && !@fast_avx

			if gcc
				width = 64
				if prefer_avx512
					width = 512
				elsif prefer_avx
					width = 256
				elsif include?(InstructionSets::SSE2) # this should be the default for x64
					width = 128
				end

				out_flags += [
					"-mno-avx512f",
					"-mno-avx512bitalg",
					"-mno-avx512bw",
					"-mno-avx512cd",
					"-mno-avx512dq",
					"-mno-avx512er",
					"-mno-avx512ifma",
					"-mno-avx512pf",
					"-mno-avx512vbmi",
					"-mno-avx512vbmi2",
					"-mno-avx512vl",
					"-mno-avx512vnni",
					"-mno-avx512vpopcntdq",
				] if prohibit_avx512
				out_flags << "-mno-avx2" if prohibit_avx2
				out_flags << "-mno-avx" if prohibit_avx

				#out_flags << "-mprefer-vector-width=#{width}"

				out_flags += @gcc_flags unless @gcc_flags.nil?

				case @manufacturer
				when Manufacturers::INTEL
					out_flags << "-mtune=intel" unless out_flags.any? { |flag| flag.start_with?("-march=")}
				end
			else
				arch = nil

				msvc_allow_highest = false

				if prefer_avx512 || (msvc_allow_highest && include?(InstructionSets::AVX512_ANY) && ALLOW_AVX512)
					arch = "AVX512"
				elsif prefer_avx2 || (msvc_allow_highest && include?(InstructionSets::AVX2) && ALLOW_AVX512)
					arch = "AVX2"
				elsif prefer_avx || (msvc_allow_highest && include?(InstructionSets::AVX) && ALLOW_AVX512)
					arch = "AVX"
				end

				out_flags << "/arch:#{arch}" unless arch.nil?

				case @manufacturer
				when Manufacturers::AMD
					out_flags << "/favor:AMD64"
				when Manufacturers::INTEL
					out_flags << "/favor:INTEL64"
				end

				out_flags += @msvc_flags unless @msvc_flags.nil?
			end

			return out_flags
		end
	end

	module Manufacturers
		AMD = Manufacturer.new(name: 'AMD')
		INTEL = Manufacturer.new(name: 'Intel')
		GENERIC = Manufacturer.new(name: 'Generic')

		def self.get(model)
			Manufacturers.instance_variables.each { |var|
				return var if var.is?(model)
			}

			return Manufacturers::GENERIC
		end

		AutoInstance(self)
	end

	@@list = []
	def self.list
    @@list
  end

	# TODO improve me regarding sets and flags
	list << NATIVE = Architecture.new(
		name: "Native",
		manufacturer: Manufacturers::get(Sys::CPU.model),
		sets: [InstructionSets::X86_64, InstructionSets::SSE3],
		gcc_flags: ["-march=native"]
	)

	# Intel
	module Intel
		def self.arch(name:, sets:, slow_avx: false, fast_avx: false, fast_avx2: false, fast_avx512: false, gcc_flags: nil, msvc_flags: nil)
			Architecture.new(
				name: name,
				manufacturer: Manufacturers::INTEL,
				sets: sets,
				slow_avx: slow_avx,
				fast_avx: fast_avx,
				fast_avx2: fast_avx2,
				fast_avx512: fast_avx512,
				gcc_flags: gcc_flags,
				msvc_flags: msvc_flags
			)
		end

		Architectures.list << SKYLAKE_X = arch(
			name: "Skylake-X",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::AVX512_ANY,
				InstructionSets::AVX512_SUB::AVX512F,
				InstructionSets::AVX512_SUB::AVX512VL,
				InstructionSets::ABM,
			],
			gcc_flags: ["-march=skylake-avx512"]
		)
		Architectures::list << SKYLAKE = arch(
			name: "Skylake",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			gcc_flags: ["-march=skylake"]
		)
		Architectures::list << BROADWELL = arch(
			name: "Broadwell",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			gcc_flags: ["-march=broadwell"]
		)
		Architectures::list << HASWELL = arch(
			name: "Haswell",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			slow_avx: true, # Haswell downclocks _all_ cores
			gcc_flags: ["-march=haswell"]
		)
		Architectures::list << GENERIC = arch(
			name: "Intel",
			sets: [
				InstructionSets::X86_64,
				InstructionSets::SSE3,
			],
			gcc_flags: ["-mtune=nehalem"]
		)

		AutoInstance(self)
	end

	# TODO handle things like -mprefer-vector-width=256

	# AMD
	module AMD
		def self.arch(name:, sets:, slow_avx: false, fast_avx: false, fast_avx2: false, fast_avx512: false, gcc_flags: nil, msvc_flags: nil)
			return Architecture.new(
				name: name,
				manufacturer: Manufacturers::AMD,
				sets: sets,
				slow_avx: slow_avx,
				fast_avx: fast_avx,
				fast_avx2: fast_avx2,
				fast_avx512: fast_avx512,
				gcc_flags: gcc_flags,
				msvc_flags: msvc_flags
			)
		end

		Architectures::list << ZEN_3 = arch(
			name: "Zen3",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			fast_avx: true,
			fast_avx2: true,
			gcc_flags: ["-march=znver3"]
		)

		Architectures::list << ZEN_2 = arch(
			name: "Zen2",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			fast_avx: true,
			fast_avx2: true,
			gcc_flags: ["-march=znver2"]
		)

		Architectures::list << ZEN_1 = arch(
			name: "Zen",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSSE3,
				InstructionSets::SSE4,
				InstructionSets::SSE4A,
				InstructionSets::AVX,
				InstructionSets::AVX2,
				InstructionSets::ABM,
			],
			fast_avx: true,
			fast_avx2: true,
			gcc_flags: ["-march=znver1"]
		)

		Architectures::list << K10 = arch(
			name: "K10",
			sets: [
				InstructionSets::SSE3,
				InstructionSets::SSE4A,
				InstructionSets::ABM,
			],
			gcc_flags: ["-march=amdfam10"]
		)

		Architectures::list << GENERIC = arch(
			name: "AMD",
			sets: [
				InstructionSets::X86_64,
				InstructionSets::SSE3,
			],
			gcc_flags: ["-mtune=amdfam10"]
		)

		AutoInstance(self)
	end

	# Generic
	Architectures::list << DEFAULT = Architecture.new(
		name: "Generic",
		manufacturer: Manufacturers::GENERIC,
		sets: [InstructionSets::X86_64, InstructionSets::SSE3],
		gcc_flags: ["-mtune=core2"]
	)

	def self.get(name)
		name = name.downcase
		Architectures::list.each { |arch|
			return arch if arch.to_s.downcase == name
		}
		return nil
	end

	AutoInstance(self)
end
