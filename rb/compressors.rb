require 'etc'

class Compressor
	@parallel
	@serial
	attr_reader :flags
	attr_reader :extension
	attr_reader :proc

	def initialize(parallel: nil, serial: nil, flags:, extension:, cmd: nil)
		raise "Compressor :parallel and :serial must not both be nil" if (parallel.nil? && serial.nil?)
		raise "Compressor :flags must not be nil" if flags.nil?
		raise "Compressor :extension must not be nil and must not be empty" if (extension.nil? || extension.empty?)
		(@parallel = parallel).safe_freeze
		(@serial = serial).safe_freeze
		(@flags = flags.to_a).freeze rescue raise "Compressor :flags must be an array type"
		(@extension = extension).freeze
		if cmd.nil?
			@proc = nil
		else
			(@proc = cmd).freeze
		end
		self.freeze
	end

	def get
		[@parallel, @serial].compact.each { |comp|
			return comp if Executable::which?(comp)
		}
		return nil
	end

	def exist?
		[@parallel, @serial].compact.each { |comp|
			return true if Executable::which?(comp)
		}
		return false
	end

	def full_command(source:, archive:)
		return nil if @proc.nil?
		return @proc.call(self.get, source, archive)
	end

	def command
		return [self.get, *@flags]
	end
end

module Compressors
	ALL = []
	# These are ordered by best to worst compression ratio
	ALL << XZ = Compressor.new(parallel: 'xz', flags: ["-zk", "-c", "-9e", "--threads=0", "--lzma2=preset=9e,dict=1536m", "--memory=32g"], extension: 'txz')
	ALL << SEVENZ = Compressor.new(serial: '7z', flags: [], extension: '7z', cmd: Proc.new { |executable, source, archive|
		[
			executable,
			"a", "-r", "-slp", "-snl", "-y", "-mx=9", "-myx=9", "-ms=on", "-mmt=#{Etc.nprocessors}",
			"-m0=LZMA2:d=1536m:fb=273:mc=10000000",
#			"-m1=PPMd:mem=2g",
#			"-m2=BZip2:x=9:pass=10:d=900000b:mt=#{Etc.nprocessors}",
			"--", archive, source
		]
	})
	ALL << LZMA2 = Compressor.new(parallel: 'pxz', serial: 'xz', flags: ['-zk', '--threads=0', '-9e', '-c'], extension: 'txz')
	ALL << LZIP = Compressor.new(parallel: 'plzip', serial: 'lzip', flags: ['-F', '-9', '-c'], extension: 'tlz')
	ALL << ZSTD = Compressor.new(parallel: 'pzstd', serial: 'zstd', flags: ['--ultra', '-22', '-k', '-T0', '-c'], extension: 'tzstd')
	ALL << BZIP2 = Compressor.new(serial: 'bzip2', flags: ['-c', '-k', '-c', '--best'], extension: 'tbz')
	ALL << GZIP = Compressor.new(parallel: 'pigz', serial: 'gzip', flags: ['-c', '-k', '-r', '--best'], extension: 'tgz')
	ALL << LZ4 = Compressor.new(serial: 'lz4', flags: ['--best', '-z', '-k', '-r', '-BD', '--content-size', '--sparse'], extension: 'tlz4')
	ALL.freeze

	def self.best
		ALL.each { |comp|
			return comp if comp.exist?
		}
		return nil
	end
end
