using WrapperLib;
using static LinkerCommon.Common;

namespace wrappers {
	static class LLVMLib {
		public class ExecutableCls : LinkedExecutable, IExecutable {
			string[] IExecutable.Version => new[] {
				$"Microsoft (R) Library Manager Version {VersionNumber}",
				"Copyright (C) Microsoft Corporation.  All rights reserved."
			};
			string IExecutable.Name => "lld-link";
		}
		private static readonly ExecutableCls Executable = new ExecutableCls();

		static void Main(string[] args) {
			var argResults = Wrapper.Common(args, Executable);

			Linker(argResults, Executable);
		}
	}
}
