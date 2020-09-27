#pragma once

#include <cstdint>

#include <type_traits>

// TODO :
// HashCode
// 		Make a better hash algorithm for Java. CityHash for sizes >= 32B on 64-bit would be ideal, with something like FNV-1a for smaller.
// RNG
//    Switch to a faster RNG. Xorshift is quite fast.

// This generates either a value- or reference-type for something that is effectively
// meant to be passed by value, depending upon what is considered faster.
namespace carbide {
	namespace detail {
		using uint = unsigned int;
		using uint_ptr = std::uintptr_t;

		static constexpr const uint pointer_size = sizeof(void *);
		static constexpr const uint system_bits = pointer_size * 8;

		// TODO : handle ARM/AArch
		enum class ABI : uint {
			CDecl,
			FastCall,
			Win64,
			VectorCall,
			SysV
		};

		static constexpr const ABI system_abi =
		#if defined(_MSC_VER)
			(system_bits == 64) ? ABI::Win64 : ABI::CDecl;
		#else
			(system_bits == 64) ? ABI::SysV : ABI::CDecl;
		#endif

		namespace passing {
			// This depends heavily on the ABI of the system.
			static constexpr const uint value_reference_crossover = pointer_size * [] () constexpr -> uint {
				switch (system_abi) {
					case ABI::CDecl:
						return 1u;
					case ABI::FastCall:
						return 2u;
					case ABI::Win64:
						return 2u;
					case ABI::VectorCall:
						return 2u;
					case ABI::SysV:
						return 2u;
					default:
						return 1u;
				}
			}();
			template <typename T> static constexpr const bool by_value = (sizeof(T) <= value_reference_crossover) && std::is_trivially_copyable_v<T>;
			template <typename T> static constexpr const bool by_reference = !by_value<T>;
		}
	}

	// Chooses the best type (by reference or by value) for the given type based upon its size and the system ABI.
	template <typename T> using arg_t = std::conditional_t<detail::passing::by_value<T>, T, const T & __restrict>;
}

#if _HAS_INT128
namespace carbide {
	using int128_t = __int128;
	using uint128_t = unsigned __int128;

	template <typename T>
	static constexpr T make_int128(std::uint64_t high, std::uint64_t low) {
		return T((uint128_t(high) << 64) | uint128_t(low));
	}
}
#endif

#include "spec_helpers.hpp"
#include "c_ext.hpp"
#include "utility.hpp"
#include "hashing.hpp"
#include "dump/dump.hpp"
#include "string_switch.hpp"
#include "method_overrides.hpp"
#include "debug.hpp"

#include "Locks.hpp"
#include "Sizes.hpp"

using namespace carbide;
using namespace carbide::sizes;
