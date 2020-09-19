#pragma once

#if defined(__INTELLISENSE__)
#	include "common.h"
#	include "hashing.hpp"
#endif

namespace carbide::string_switch {
	using hash_t = std::uint64_t;
	static constexpr hash_t get (const char *str) {
		_assume(str != nullptr);
		return carbide::hashing::get<hash_t>(str);
	}
}

// Entirely macros, unfortunately.
#define string_switch(str) switch (carbide::string_switch::get(str))
#define string_case(str) case carbide::string_switch::get(str)
