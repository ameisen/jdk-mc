namespace WrapperLib {
	public static class Extensions {
		public static string? Blank(this string? str) {
			if (str == null || str.Length == 0) {
				return null;
			}
			return str;
		}
	}
}
