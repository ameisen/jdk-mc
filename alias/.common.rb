SCRIPT_ = File.basename($0)
REALDIR_ = File.realdirpath(__dir__)

def which?(name)
	paths = ENV["PATH"].split(":")
	paths.uniq!
	paths.each { |path|
		next if !File.directory?(path) || (File.realdirpath(path) == REALDIR_)
		file = File.join(path, name)
		return file if File.executable?(file)
	}
	return nil
end
BIN = which?(SCRIPT_)

def call(*args)
	exec(BIN, *args)
end
