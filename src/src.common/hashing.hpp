#pragma once

#include <cstdint>

#include <type_traits>

// Compile-time FNV1-a hash methods. Also supports runtime variants.
// https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
namespace carbide::hashing {
	namespace detail {
		template <typename T>
		struct constants final {
			constexpr constants() = delete;

			using raw_type = std::make_unsigned_t<std::remove_cvref_t<T>>;
			template <typename U> static constexpr const bool is_type = std::is_same_v<raw_type, U>;

			static constexpr T offset_basis = []() {
				if constexpr (is_type<std::uint32_t>) {
					return T(0x811C'9DC5);
				}
				else if constexpr (is_type<std::uint64_t>) {
					return T(0xCBF2'9CE4'8422'2325);
				}
#if _HAS_INT128
				else if constexpr (is_type<unsigned __int128>) {
					// 6c62272e07bb0142'62b821756295c58d
					return make_int128<T>(0x6C62'272E'07BB'0142, 0x62B8'2175'6295'C58D);
				}
#endif
				//else {
				//	throw 0; // Unknown type.
				//}
			}();

			static constexpr T prime = []() {
				if constexpr (is_type<std::uint32_t>) {
					return T(0x0100'0193);
				}
				else if constexpr (is_type<std::uint64_t>) {
					return T(0x0000'0100'0000'01B3);
				}
#if _HAS_INT128
				else if constexpr (is_type<unsigned __int128>) {
					// 0000000001000000'000000000000013B
					return make_int128<T>(0x0000'0000'0100'0000, 0x0000'0000'0000'013B);
				}
#endif
				//else {
				//	throw 0; // Unknown type.
				//}
			}();

		};
	}

	template <typename T = std::uint64_t>
	static constexpr T fnv1a (const char *str) {
		T hash = detail::constants<T>::offset_basis;

		char c;
		while ((c = *(str++)) != '\0') {
			hash *= detail::constants<T>::prime;
			hash ^= std::uint8_t(c);
		}

		return hash;
	}

	template <typename T = std::uint64_t>
	static constexpr T get (const char *str) {
		return fnv1a<T>(str);
	}
}
