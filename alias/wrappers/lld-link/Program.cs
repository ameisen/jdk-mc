using WrapperLib;
using static LinkerCommon.Common;

namespace wrappers {
	public static class LLDLink {
		public class ExecutableCls : LinkedExecutable, IExecutable {
			string[] IExecutable.Version => new[] {
				$"Microsoft (R) Incremental Linker {VersionNumber}",
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
