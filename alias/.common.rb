_SCRIPT = File.basename(SCRIPT)
BIN = `which #{_SCRIPT}`.strip

def call(*args)
	exec(BIN, *args)
end
