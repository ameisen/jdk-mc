#pragma once

#if 0

#include <cstddef>
#include <cstdint>
#include <memory>

namespace carbide {
	namespace unique_ptr {
		template <typename T>
		static std::unique_ptr<T> make(std::size_t size) {
			return std::make_unique<T>(size);
		}

#ifdef __cpp_lib_smart_ptr_for_overwrite
		template <typename T>
		static std::unique_ptr<T> make_uninitialized(std::size_t size) {
			return std::make_unique_for_overwrite<T>(size);
		}
#else
		template <typename T>
		static std::unique_ptr<T> make_uninitialized(std::size_t size) {
			return make<T>(size);
		}
#endif
	}
}

#endif
