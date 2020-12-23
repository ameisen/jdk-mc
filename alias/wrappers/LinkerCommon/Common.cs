using System;
using System.Collections.Generic;
using WrapperLib;

namespace LinkerCommon {
	public static class Common {
		public abstract class LinkedExecutable : IExecutable {
			string IExecutable.VersionNumber => "14.28.29617.0";
			public string VersionNumber => ((IExecutable)this).VersionNumber;

			string[] IExecutable.Version => throw new System.NotImplementedException();
			public string[] Version => ((IExecutable)this).Version;

			string IExecutable.Name => throw new System.NotImplementedException();
			public string Name => ((IExecutable)this).Name;

			void IExecutable.UnknownOption(string arg) {
				IO.ErrorLn($"LINK : warning LNK4044: unrecognized option '{arg}'; ignored");
			}
			public void UnknownOption(string arg) => ((IExecutable)this).UnknownOption(arg);
		}

		// This exists because llvm-lib is technically a wrapper for lld-link and I want to share the logic
		public static void Linker(Args.Options options, IExecutable exec) {
			options.PassArgs = Wrapper.ParseLLVMOptions(options.PassArgs);

			// further processing of argument data
			{
				bool inLLVM = false;
				var passArgs = new List<string>(options.PassArgs.Count);
				foreach (var arg in options.PassArgs) {
					if (arg == "-mllvm") {
						inLLVM = true;
						passArgs.Add(arg);
					}
					else if (inLLVM) {
						inLLVM = false;
						passArgs.Add(arg);
					}
					else {
						var canonArg = Args.Normalize(arg, true);
						if (canonArg.StartsWith("-flto=") || canonArg == "-flto") {
							// Ignore LTO arguments in linker
						}
						// lld-link doesn't understand arguments for -opt:icf, so we should strip them.
						else if (canonArg.StartsWith("-opt:icf,")) {
							passArgs.Add(arg.Split(',', 2)[0]);
						}
						// lld-link doesn't understand 'ltcg'
						else if (canonArg == "-ltcg") {
							// Ignore argument
						}
						else {
							passArgs.Add(arg);
						}
					}
				}
				options.PassArgs = passArgs;
			}

			Wrapper.HandleDump(options, exec);

			Environment.Exit(
				Wrapper.Exec(
					options.Executable,
					options.PassArgs
				)
			);
		}
	}
}
