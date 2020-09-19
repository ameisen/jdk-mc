#pragma once

#if defined(__INTELLISENSE__)
#	include "../common.h"
#endif

#define DISABLE_DUMPING 1

#if DISABLE_DUMPING
#	define _IMPL_METHOD(...) static __VA_ARGS__ {}
#else
#	define _IMPL_METHOD(...) extern __VA_ARGS__;
#endif

namespace carbide::dump {
	_IMPL_METHOD(void compiled_method_check(const char * __restrict method));
}

#undef _IMPL_METHOD
