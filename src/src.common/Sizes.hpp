#pragma once

#include <cstddef>
#include <cstdint>

namespace carbide::sizes {
	using usize = std::size_t;

	static constexpr usize operator "" _z(unsigned long long int value) {
		return usize(value);
	}

	template <usize size>
	static constexpr const usize B = size;

	template <usize size>
	static constexpr const usize KiB = B<size> * 0x400_z;

	template <usize size>
	static constexpr const usize MiB = KiB<size> * 0x400_z;

	template <usize size>
	static constexpr const usize GiB = MiB<size> * 0x400_z;

	template <usize size>
	static constexpr const usize TiB = GiB<size> * 0x400_z;

	template <usize size>
	static constexpr const usize PiB = TiB<size> * 0x400_z;
}
