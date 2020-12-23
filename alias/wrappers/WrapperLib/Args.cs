using System.Collections.Generic;

namespace WrapperLib {
	public static class Args {
		public class Options {
			public bool Logo = true;
			public bool DumpArgs = false;
			public List<string> PassArgs = new();
			public List<string> UnrecognizedArgs = new();
			public string Executable = "";
		}

		public static string Normalize(string argument, bool downcase = false) {
			argument = downcase ? argument.ToLowerInvariant() : argument;
			if (argument[0] == '/') {
				argument = '-' + argument.Substring(1);
			}
			return argument;
		}

		public static Options Parse(string[] args) {
			var result = new Options();

			// Always pass nologo because we don't want the actual tool to print it when we are doing so.
			result.PassArgs.Add("-nologo");

			foreach (var arg in args) {
				var down_arg = Normalize(arg, true);
				switch (down_arg) {
					case "-nologo":
						result.Logo = false;
						break;
					case "-dumpargs":
						result.DumpArgs = true;
						break;
					case "--version":
					case "-version":
					case "-v":
						result.UnrecognizedArgs.Add(arg);
						break;
					default:
						result.PassArgs.Add(arg);
						break;
				}
			}

			return result;
		}
	}
}
