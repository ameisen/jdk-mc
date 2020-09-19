#pragma once

namespace carbide {
	static constexpr bool streq (
			const char * __restrict a,
			const char * __restrict b
	) {
			char ac = {};
			char bc = {};

			while (
					((ac = *(a++)) != '\0') &
					((bc = *(b++)) == ac)
			) {}

			return ac == bc;
	}
}
