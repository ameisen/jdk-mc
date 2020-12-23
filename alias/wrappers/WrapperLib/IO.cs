using System;
using System.IO;

namespace WrapperLib {
	public static class IO {
		public static void WriteLines(this TextWriter io, params string[] lines) {
			foreach (var line in lines) {
				if (line == null) {
					io.WriteLine();
				}
				else {
					io.WriteLine(line);
				}
			}
		}

		public static void ErrorLn() {
			Console.Error.WriteLine();
		}
		public static void ErrorLn(string line) {
			Console.Error.WriteLine(line);
		}

		public static void ErrorLn(params string[] lines) {
			Console.Error.WriteLines(lines);
		}

		public static void OutLn() {
			Console.Out.WriteLine();
		}
		public static void OutLn(string line) {
			Console.Out.WriteLine(line);
		}

		public static void OutLn(params string[] lines) {
			Console.Out.WriteLines(lines);
		}
	}
}
