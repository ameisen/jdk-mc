using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using WrapperLib;

namespace wrappers {
	static class ClangCL {
		private sealed class ExecutableCls : IExecutable {
			public string VersionNumber => "19.28.29617";
			public string[] Version => new[] {
				$"Microsoft (R) C/C++ Optimizing Compiler Version {VersionNumber} for x64",
				"Copyright (C) Microsoft Corporation.  All rights reserved."
			};
			public string Name => "clang-cl";

			public void UnknownOption(string arg) {
				IO.ErrorLn($"cl : Command line warning D9002 : ignoring unknown option '{arg}'");
			}
		}
		private static readonly ExecutableCls Executable = new ExecutableCls();

		static void Main(string[] args) {
			var argResults = Wrapper.Common(args, Executable);

			foreach (var extraArg in new [] {
				"-Wno-unused-command-line-argument",
				"-D_CRT_SECURE_NO_WARNINGS=1",
				"-fms-compatibility",
				$"-fms-compatibility-version={Executable.VersionNumber}"
			}) {
				if (!argResults.PassArgs.Contains(extraArg)) {
					argResults.PassArgs.Add(extraArg);
				}
			}

			argResults.PassArgs = Wrapper.ParseLLVMOptions(argResults.PassArgs);
			Wrapper.HandleDump(argResults, Executable);

			Environment.Exit(
				Wrapper.Exec(
					argResults.Executable,
					argResults.PassArgs
				)
			);
		}
	}
}
