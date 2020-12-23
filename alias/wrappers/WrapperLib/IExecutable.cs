using System;
using System.Reflection;

namespace WrapperLib {
	public interface IExecutable {
		public string VersionNumber { get; }
		public string[] Version { get; }
		public string Name { get; }
		public Assembly Assembly => Assembly.GetEntryAssembly() ?? Assembly.GetExecutingAssembly();
		public string Path => PathExt.CanonPath(Assembly.Location.Blank() ?? AppContext.BaseDirectory);
		public string? Dir => PathExt.CanonPath(System.IO.Path.GetDirectoryName(Path));

		public abstract void UnknownOption(string arg);
	}
}
