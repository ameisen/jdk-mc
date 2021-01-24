#pragma once

#include <cstddef>
#include <cstdio>

#include <array>
#include <type_traits>

namespace carbide::debug {
	static constexpr const bool enable_print = true;


	template <std::uint64_t filename_hash, size_t N, typename... Args>
	void dumpf_from_hash(const char *filename, const char (&format)[N], Args... args) {
		static FILE *fp = nullptr;
		if (!fp) {
			fp = fopen(filename, "w");
			if (!fp) {
				return;
			}
		}
		fprintf(fp, format, args...);
	}

	template <size_t N, typename... Args>
	void dumpf(const char *filename, const char (&format)[N], Args... args) {
		//dumpf_from_hash<carbide::hashing::get(filename), N, Args...>(filename, format, std::forward<Args>(args)...);
	}

	namespace detail {
		template <typename T>
		concept CharType =
			std::is_same_v<T, char> ||
			std::is_same_v<T, wchar_t> ||
			std::is_same_v<T, char8_t> ||
			std::is_same_v<T, char16_t> ||
			std::is_same_v<T, char32_t>
		;

		template <CharType T, std::size_t prefix_len, std::size_t str_len, std::size_t suffix_len>
		static constexpr auto format_str(const T(&prefix)[prefix_len], const T(&str)[str_len], const T(&suffix)[suffix_len]) {
			constexpr const auto impl = []<
				std::size_t... prefix_i,
				std::size_t... str_i,
				std::size_t... suffix_i
			>(
				const T(&prefix)[prefix_len],
				const T(&str)[str_len],
				const T(&suffix)[suffix_len],
				std::index_sequence<prefix_i...> prefix_seq,
				std::index_sequence<str_i...> str_seq,
				std::index_sequence<suffix_i...> suffix_seq
			) {
				constexpr const std::size_t array_len = prefix_seq.size() + str_seq.size() + suffix_seq.size() + 1;
				return std::array<T, array_len> {
					prefix[prefix_i]...,
					str[str_i]...,
					suffix[suffix_i]...,
					'\0'
				};
			};

			return impl(
				prefix,
				str,
				suffix,
				std::make_index_sequence<prefix_len - 1>{},
				std::make_index_sequence<str_len - 1>{},
				std::make_index_sequence<suffix_len - 1>{}
			);
		}

		static constexpr const char prefix[] = "[JDK-MC] ";
	}

	template <typename... Args>
	static void printf(const char * __restrict format, Args... args) {
		if constexpr (!enable_print) {
			return;
		}

		//static std::FILE * const __restrict err_stream = defaultStream::error_stream();

		std::fprintf(stderr, format, args...);
	}

	template <std::size_t N, typename... Args>
	static void println(const char (& __restrict format)[N], Args... args) {
		if constexpr (!enable_print) {
			return;
		}

		carbide::debug::printf(detail::format_str(detail::prefix, format, "\n").data(), args...);
	}
}
