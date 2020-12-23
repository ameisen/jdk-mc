using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;

namespace WrapperLib {
	public static class PathExt {
		[return: NotNullIfNotNull("path")]
		public static string? CanonPath(string? path) {
			if (path == null) {
				return null;
			}
			return new Uri(Path.GetFullPath(path)).LocalPath;
		}
	}
}
