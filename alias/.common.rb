SCRIPT = File.basename($PROGRAM_NAME)
BIN = `which #{SCRIPT}`.strip

def call(*args)
	exec(BIN, *args)
end
