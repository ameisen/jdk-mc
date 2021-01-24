#pragma once

#if defined(__INTELLISENSE__)
#	include "common.h"
#endif

#include <type_traits>
#include <cstring>

class Symbol;

namespace carbide::utility {
	static _forceinline bool streq (const char *a, const char *b) {
		return std::strcmp(a, b) == 0;
	}

	static _forceinline bool strneq (const char *a, const char *b) {
		return std::strcmp(a, b) != 0;
	}

	namespace detail {
		template <typename T, bool is_enum = std::is_enum_v<T>>
		struct underlying_type_s {
			using type = T;
		};

		template <typename T>
		struct underlying_type_s<T, true> {
			using type = std::underlying_type_t<T>;
		};

		template <typename T>
		using underlying_type = typename underlying_type_s<std::remove_cvref_t<T>>::type;

		template <typename T>
		using if_integral = std::enable_if_t<
			std::is_integral_v<
				underlying_type<T>
			>
		>;

		template <typename From, typename To>
		static constexpr const bool is_convertible =
#ifdef __cpp_lib_is_nothrow_convertible
			std::is_nothrow_convertible_v
#else
			std::is_convertible_v
#endif
		<From, To>;

		template <typename T>
		using if_boolean = std::enable_if_t<
			is_convertible<
				underlying_type<T>,
				bool
			>
		>;

		template <typename T>
		static constexpr const T zero = T(0);

		enum branch_hint : int {
			none = 0,
			unpredictable,
			likely,
			unlikely
		};

		template <branch_hint hint = branch_hint::none, typename T>//, typename = if_boolean<T>>
		static constexpr _forceinline _constf bool branch (T value) {
#if _BUILD_MSVC || (__has_cpp_attribute(likely) && __has_cpp_attribute(unlikely))
			if constexpr (hint == branch_hint::none || hint == branch_hint::unpredictable) {
				return _unpredictable(value);
			}
			else if constexpr (hint == branch_hint::likely) {
				if _likely_if(value) {
					return true;
				}
				return false;
			}
			else if constexpr (hint == branch_hint::unlikely) {
				if _unlikely_if(value) {
					return true;
				}
				return false;
			}
			//else {
			//	throw 0;
			//}
#else
			switch (hint) {
				case branch_hint::none:
				case branch_hint::unpredictable:
					return _unpredictable(value);
				case branch_hint::likely:
					return _likely(value);
				case branch_hint::unlikely:
					return _unlikely(value);
			}
#endif
		}
	}

	namespace flags {
		enum atomicity : bool {
			not_atomic = false,
			atomic = true
		};

		namespace detail {
			using namespace carbide::utility::detail;

			/*
			template <typename T, typename ... Tt, typename = if_integral<T>>
			static constexpr _forceinline _constf T packed_or(Tt ... values) noexcept {
				return T(T(values) | ...);
			}
			*/

			// https://graphics.stanford.edu/~seander/bithacks.html#ConditionalSetOrClearBitsWithoutBranching
			template <typename T, typename U/*, typename = if_integral<T>*/> // TODO : Add enable_if for is_convertible<U, T>
			static constexpr _forceinline _constf T set_conditional(bool condition, T value, U mask) {
				using UT = std::make_unsigned_t<detail::underlying_type<T>>;
				const UT uvalue = UT(value);
				const UT umask = UT(mask);
#if _SUPERSCALAR
				return T(UT(uvalue & ~umask) | UT(UT(-condition) & umask));
#else
				return T(uvalue ^ UT(UT(UT(-condition) ^ uvalue) & umask));
#endif
			}
		}

		template </*atomicity atomic = atomicity::not_atomic, */typename T, typename U/*, typename = detail::if_integral<T>*/> // TODO : Add enable_if for is_convertible<U, T>
		static constexpr _forceinline _constf bool is_set(T value, U flag) noexcept {
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			return (UT(value) & UT(flag)) != detail::zero<UT>;
		}

		/*
		template <typename T, typename ... Tt, typename = detail::if_integral<T>>
		static constexpr _forceinline _constf bool all_set(T value, Tt ... flags) noexcept {
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			const UT mask = packed_or<UT>(flags...);

			return (UT(value) & mask) == mask;
		}

		template <typename T, typename ... Tt, typename = detail::if_integral<T>>
		static constexpr _forceinline _constf bool any_set(T value, Tt ... flags) noexcept {
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			const UT mask = packed_or<UT>(flags...);

			return (UT(value) & mask) != detail::zero<UT>;
		}
		*/

		template <typename T, typename U/*, typename = detail::if_integral<T>*/>
		static constexpr _forceinline _constf T set(T value, U flag) noexcept { // TODO : Add enable_if for is_convertible<U, T>
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			return T(UT(value) | UT(flag));
		}

		template <typename T, typename U/*, typename = detail::if_integral<T>*/>
		static constexpr _forceinline _constf T unset(T value, U flag) noexcept { // TODO : Add enable_if for is_convertible<U, T>
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			return T(UT(value) & ~UT(flag));
		}

		template <typename T, typename U/*, typename = detail::if_integral<T>*/>
		static constexpr _forceinline _constf T set_conditional(bool condition, T value, U flag) noexcept { // TODO : Add enable_if for is_convertible<U, T>
			using UT = std::make_unsigned_t<detail::underlying_type<T>>;

			// if flag is zero, we can just return the value unchanged.
			if (_constant_p(flag) && T(flag) == detail::zero<T>) {
				return value;
			}

			// if value is zero, we either return zero (value) or we return flag.
			if (_constant_p(value) && value == detail::zero<T>) {
				if (_constant_p(condition)) {
					return condition ? T(flag) : value;
				}
				return detail::branch<detail::branch_hint::none>(condition) ? T(flag) : value;
			}

			if (_constant_p(condition)) {
				return condition ?
					set(value, flag) :
					unset(value, flag);
			}
			else {
				// TODO : add the ability to specify branch hints here
				return detail::set_conditional<T, U>(detail::branch<detail::branch_hint::none>(condition), value, flag);
			}
		}
	}
}
