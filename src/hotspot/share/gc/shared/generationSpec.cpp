/*
 * Copyright (c) 2001, 2019, Oracle and/or its affiliates. All rights reserved.
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

#include "precompiled.hpp"
#include "gc/shared/cardTableRS.hpp"
#include "gc/shared/generationSpec.hpp"
#include "memory/binaryTreeDictionary.hpp"
#include "memory/filemap.hpp"
#include "runtime/java.hpp"
#include "utilities/macros.hpp"
#if INCLUDE_SERIALGC
#include "gc/serial/defNewGeneration.hpp"
#include "gc/serial/tenuredGeneration.hpp"
#endif

Generation* GenerationSpec::init(ReservedSpace rs, CardTableRS* remset) {
#if INCLUDE_SERIALGC
  switch (name()) {
    case Generation::DefNew:
      return new DefNewGeneration(rs, _init_size, _min_size, _max_size);

    case Generation::MarkSweepCompact:
      return new TenuredGeneration(rs, _init_size, _min_size, _max_size, remset);
			
    default:
#endif
      guarantee(false, "unrecognized GenerationName");
      return NULL;
#if INCLUDE_SERIALGC
  }
#endif
}
