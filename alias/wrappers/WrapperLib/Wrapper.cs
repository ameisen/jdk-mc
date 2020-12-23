using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;

namespace WrapperLib {
	public static class Wrapper {
		public static int Exec(string executable, ICollection<string> args) {
			using var process = new Process();
			var info = new ProcessStartInfo(executable);
			foreach (var arg in args) {
				info.ArgumentList.Add(arg);
			}
			info.RedirectStandardInput = false;
			info.RedirectStandardOutput = false;
			info.RedirectStandardError = false;

			process.StartInfo = info;
			if (!process.Start()) {
				return ErrorCode.FileNotFound;
			}

			process.WaitForExit();
			return process.ExitCode;
		}

		[return: NotNull]
		public static Args.Options Common([NotNull] string[] args, [NotNull] IExecutable exec) {
			var argResults = Args.Parse(args);

			if (argResults.Logo) {
				IO.OutLn(exec.Version);
				IO.OutLn();
			}

			foreach (var arg in argResults.UnrecognizedArgs) {
				exec.UnknownOption(arg);
			}

			if (argResults.PassArgs.Count == 0) {
				Environment.Exit(0);
			}

			var executable = Which(exec, exec.Name);
			if (executable == null) {
				throw new FileNotFoundException($"Could not find executable '{exec.Name}' to pass control to");
			}
			argResults.Executable = executable;

			return argResults;
		}

		public static void HandleDump(Args.Options options, IExecutable exec) {
			if (!options.DumpArgs) {
				return;
			}

			var writePath = "D:\\WrapperDump";
			var dumpFilePath = Path.Join(writePath, $"{exec.Name}.log");
			try {
				try {
					Directory.CreateDirectory(writePath);
				}
				catch { }
				using var dumpFile = File.OpenWrite(dumpFilePath);
				using var dumpFileWriter = new StreamWriter(dumpFile);
				foreach (var arg in options.PassArgs) {
					dumpFileWriter.WriteLine(arg);
				}
			}
			catch (Exception ex) {
				IO.ErrorLn($"Could not write to dump file '{dumpFilePath}' as requested: {ex}");
			}
		}

		[return: NotNullIfNotNull("args")]
		public static List<string> ParseLLVMOptions([NotNull] List<string> args) {
			bool next_llvm = false;
			var llvmArgs = new List<string>(args.Count);
			var passArgs = new List<string>(args.Count);
			foreach (var arg in args) {
				if (arg == "-mllvm") {
					next_llvm = true;
				}
				else if (next_llvm) {
					llvmArgs.Add(arg);
					next_llvm = false;
				}
				else {
					passArgs.Add(arg);
				}
			}

			var appendArgs = llvmArgs.Distinct();
			foreach (var arg in appendArgs) {
				passArgs.Add("-mllvm");
				passArgs.Add(arg);
			}

			return passArgs;
		}

		[return: MaybeNull]
		public static string? Which(IExecutable executable, string name) {
			var pathVar = Environment.GetEnvironmentVariable("PATH");
			if (pathVar == null) {
				return null;
			}
			var pathsArray = pathVar.Split(";");
			var paths = pathsArray.Distinct();

			foreach (var path in paths) {
				if (!Directory.Exists(path)) {
					continue;
				}
				var canonPath = PathExt.CanonPath(path);
				if (canonPath == executable.Dir) {
					continue;
				}
				var filePath = Path.Combine(path, name);
				var canonFilePath = PathExt.CanonPath(filePath);
				if (canonFilePath == executable.Path) {
					continue;
				}

				if (File.Exists(filePath)) {
					return filePath;
				}

				if (!filePath.EndsWith(".exe")) {
					filePath += ".exe";
					if (File.Exists(filePath)) {
						return filePath;
					}
				}
			}

			return null;
		}
	}
}
