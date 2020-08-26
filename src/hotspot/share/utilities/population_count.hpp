/*
 * Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 *
 */

#ifndef SHARE_UTILITIES_POPULATION_COUNT_HPP
#define SHARE_UTILITIES_POPULATION_COUNT_HPP

#include "metaprogramming/conditional.hpp"
#include "metaprogramming/enableIf.hpp"
#include "metaprogramming/isIntegral.hpp"
#include "metaprogramming/isSigned.hpp"
#include "utilities/debug.hpp"
#include "utilities/globalDefinitions.hpp"

#include <limits>
#include <type_traits>

#if defined(TARGET_COMPILER_visCPP)
# include <intrin.h>
#endif

// Returns the population count of x, i.e., the number of bits set in x.
//
// Adapted from Hacker's Delight, 2nd Edition, Figure 5-2 and the text that
// follows.
//
// Ideally this should be dispatched per platform to use optimized
// instructions when available, such as POPCNT on modern x86/AMD. Our builds
// still target and support older architectures that might lack support for
// these. For example, with current build configurations, __builtin_popcount(x)
// generate a call to a similar but slower 64-bit version when calling with
// a 32-bit integer type.
template <typename ST>
ALWAYSINLINE CONSTF unsigned population_count(ST _x) {
  STATIC_ASSERT(BitsPerWord <= 128);
  STATIC_ASSERT(BitsPerByte == 8);
  STATIC_ASSERT(IsIntegral<ST>::value);

  using T = std::make_unsigned_t<ST>;
  const T x = T(_x);

  using ushort = unsigned short;
  using uint = unsigned int;
  using ulong = unsigned long;
  using ullong = unsigned long long;

  static constexpr const T t_max = std::numeric_limits<T>::max();
#if defined(TARGET_COMPILER_gcc)
  if constexpr (t_max <= std::numeric_limits<uint>::max()) {
    auto vx = uint(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__builtin_popcount(vx));
  }
  else if constexpr (t_max <= std::numeric_limits<ulong>::max()) {
    auto vx = ulong(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__builtin_popcountl(vx));
  }
  else if constexpr (t_max <= std::numeric_limits<ullong>::max()) {
    auto vx = ullong(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__builtin_popcountll(vx));
  }
#elif defined(TARGET_COMPILER_visCPP)
  if constexpr (t_max <= std::numeric_limits<ushort>::max()) {
    auto vx = ushort(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__popcnt16(vx));
  }
  else if constexpr (t_max <= std::numeric_limits<uint>::max()) {
    auto vx = uint(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__popcnt(vx));
  }
  else if constexpr (t_max <= std::numeric_limits<ullong>::max()) {
    auto vx = ullong(x);
    ASSUME(vx <= std::numeric_limits<decltype(vx)>::max());
    return unsigned(__popcnt64(vx));
  }
#endif

  // We need to take care with implicit integer promotion when dealing with
  // integers < 32-bit. We chose to do this by explicitly widening constants
  // to unsigned

  using P = typename Conditional<std::numeric_limits<T>::max() <= std::numeric_limits<unsigned>::max(), unsigned, T>::type;
  ASSUME(x <= std::numeric_limits<P>::max());
  static constexpr const T all = ~T(0);           // 0xFF..FF
  static constexpr const P fives = all/3;         // 0x55..55
  static constexpr const P threes = (all/15) * 3; // 0x33..33
  static constexpr const P z_ones = all/255;      // 0x0101..01
  static constexpr const P z_effs = z_ones * 15;  // 0x0F0F..0F
  P r = x;
  r -= ((r >> 1) & fives);
  r = (r & threes) + ((r >> 2) & threes);
  r = ((r + (r >> 4)) & z_effs) * z_ones;
  // The preceeding multiply by z_ones is the only place where the intermediate
  // calculations can exceed the range of T. We need to discard any such excess
  // before the right-shift, hence the conversion back to T.
  const auto result = unsigned(static_cast<T>(r) >> (((sizeof(T) - 1) * BitsPerByte)));
  // This might not be ideal if the type is larger than what it represents, but I don't want to write a constexpr
  // function to calculate relevant bits at the moment.
  ASSUME(result <= unsigned(sizeof(result) * BitsPerByte));
  return result;
}

#endif // SHARE_UTILITIES_POPULATION_COUNT_HPP
