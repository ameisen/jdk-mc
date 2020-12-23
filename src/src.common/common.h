#pragma once

// The macros use true/false, which requires stdbool.h in C.
#if !defined(__cplusplus)
//#	if defined(__STDC__) // This isn't C++, it's C
#		include <stdbool.h>
//#	endif
#endif

#include "common_macros.h"

// C++-specific headers.
#if defined(__cplusplus)
#	include "common.hpp"
#endif
