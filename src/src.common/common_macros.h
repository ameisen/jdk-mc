#pragma once

#define TOOLCHAIN_GCC 0
#define TOOLCHAIN_LLVM 1
#define TOOLCHAIN_MSVC_CLANG 2
#define TOOLCHAIN_MSVC 3

#if defined(__cplusplus)
#	define _has_cpp_attribute(attr) __has_cpp_attribute(attr)
#else
#	define _has_cpp_attribute(attr) 0
#endif

#if defined(__GNUC__)
#	define _BUILD_GCC true
#	define _COMPAT_GCC true
#	define _BUILD_MSVC false
#	if defined(__clang__)
#		define _BUILD_CLANG true
#		define _BUILD_TOOLCHAIN TOOLCHAIN_LLVM
#	else
#		define _BUILD_CLANG false
#		define _BUILD_TOOLCHAIN TOOLCHAIN_GCC
#	endif
#elif defined(_MSC_VER)
#	define _BUILD_GCC false
#	define _BUILD_MSVC true
#	if defined(__clang__)
#		define _BUILD_CLANG true
#		define _COMPAT_GCC true
#		define _BUILD_TOOLCHAIN TOOLCHAIN_MSVC_CLANG
#	else
#		define _BUILD_CLANG false
#		define _COMPAT_GCC false
#		define _BUILD_TOOLCHAIN TOOLCHAIN_MSVC
#	endif
#elif defined(__clang__)
// not sure what this means - how can clang work without pretending to be gcc or msvc...
#	define _BUILD_GCC false
#	define _BUILD_MSVC true
#	define _BUILD_CLANG true
#	define _COMPAT_GCC true
#	define _BUILD_TOOLCHAIN TOOLCHAIN_MSVC_CLANG
#else
#	error "Unknown Toolchain"
#endif

#if _COMPAT_GCC || _BUILD_GCC
#	define _HAS_INT128 true
#	define _expect(expr, value) (__builtin_expect((expr), (value)))
#	define _likely(expr) _expect(!!(expr), true)
#	define _unlikely(expr) _expect(!!(expr), false)
#	define _unreachable __builtin_unreachable()
#	if defined(__cplusplus)
#		define _constant_p(expr) __builtin_constant_p(expr)
#	else
#		define _constant_p(expr) (__builtin_constant_p(expr) || std::is_constant_evaluated())
#	endif
# define _forceinline __attribute__((always_inline)) inline
#	define _nothrow __attribute__((nothrow))
# define _noalias _nothrow
# define _pure _noalias __attribute__((pure))
#	define _constf _noalias __attribute__((const))
// __attribute__((returns_nonnull))
#	define _allocf __attribute__((malloc))
#	define _alloc_alignargf(align_arg) _allocf __attribute__((alloc_align(align_arg)))
#	define _alloc_alignf(alignment) _allocf __attribute__((assume_aligned(alignment)))
#	define _noreturn
#	define _pure_interface
#	define _cold __attribute__((cold))
#	define _hot __attribute__((hot))
#	define _flatten __attribute__((flatten))
#	define _internal_linkage __attribute__((internal_linkage))
#	if _BUILD_CLANG
#		define _expect_with_probability(expr, value, prob) (expr)
#		define _unpredictable(expr) (__builtin_unpredictable((expr)))
#		define _unpredictable_count(expr, num) _unpredictable(expr)
#		define _assume(expr) __builtin_assume(expr)
#		define _nonstring
#	else
#		define _expect_with_probability(expr, value, prob) (__builtin_expect_with_probability((expr), (value), (prob)))
#		define _unpredictable(expr) _expect_with_probability(!!(expr), true, 0.5)
#		define _unpredictable_count(expr, num) _expect_with_probability(!!(expr), true, 1.0 / ((double)(num)))
#		define _assume(expr) do { if (!(expr)) _unreachable; } while (false)
#		define _nonstring __attribute__((nonstring))
#	endif
#endif

#if _BUILD_MSVC
# if defined(__INTELLISENSE__)
#		define __assume(expr) // I've found that this can cause issues with Intellisense for some reason
#		if defined(_COMPAT_GCC)
#			define __builtin_assume(expr)
#		endif
#	endif
#	undef _pure_interface
#	define _pure_interface __declspec(novtable)
#	if _COMPAT_GCC
#		undef _noalias
#		define _noalias __declspec(nothrow) __declspec(noalias) __attribute__((nothrow))
#		undef _pure
#		define _pure _noalias __attribute__((pure))
#		undef _constf
# 	define _constf _pure __attribute__((const))
#	else
#		define _HAS_INT128 false
#		define _expect(expr, value) (expr)
#		define _expect_with_probability(expr, value, prob) (expr)
// TODO : we can probably encode these in lambdas of some kind, or inline functions, that apply the C++ attribute?
#		define _likely(expr) (expr)
#		define _unlikely(expr) (expr)
#		define _unpredictable(expr) (expr)
#		define _unpredictable_count(expr, num) _unpredictable(expr)
#		define _unreachable __assume(0)
#		define _assume(expr) __assume(expr)
#		if defined(__cplusplus)
#			define _constant_p(expr) (std::is_constant_evaluated())
#		else
#			define _constant_p(expr) (false)
#		endif
#		define _nothrow __attribute__((nothrow))
#		define _noalias _nothrow __declspec(noalias)
#		define _pure _noalias
# 	define _constf _pure
#		define _allocf __declspec(restrict)
#		define _alloc_alignargf(align_arg) _allocf
#		define _alloc_alignf(alignment) _allocf
#		define _noreturn __declspec(noreturn)
#		define _cold
#		define _hot
#		define _flatten
#		define _nonstring
#		define _internal_linkage
#	endif
#endif

#if	_has_cpp_attribute(no_unique_address)
#	define _elidable [[no_unique_address]]
#else
#	define _elidable
#endif

// Because MSVC doesn't have built-ins for this but uses C++ attributes, but GCC and Clang don't support the attributes fully yet.
// More recent versions parse them but don't necessarily use them.
#if _has_cpp_attribute(likely)
	#define _likely_if(expr) _likely(expr) [[likely]]
#else
	#define _likely_if(expr) _likely(expr)
#endif

#if _has_cpp_attribute(unlikely)
	#define _unlikely_if(expr) _unlikely(expr) [[unlikely]]
#else
	#define _unlikely_if(expr) _unlikely(expr)
#endif

#define _SUPERSCALAR true

// TODO
// alloca, __builtin_alloca, __builtin_alloca_with_align, __builtin_alloca_with_align_and_max
// __builtin_clear_padding
// __builtin_assume_aligned
// __builtin___clear_cache
// __builtin_prefetch
// __builtin_inf __builtin_inff
// __builtin_isinf_sign
// __builtin_nan __builtin_nanf
// __builtin_ffs find first set
// __builtin_clz count leading zeros
// __builtin_ctz count trailing zeros
// __builtin_clrsb count leading redundant sign bits
// __builtin_popcount population count (return number of bits set)
// __builtin_parity (number of set bits modulo 2)
// __builtin_powi __builtin_powif
// __builtin_bswap16 __builtin_bswap32 __builtin_bswap64 __builtin_bswap128
// https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html#Integer-Overflow-Builtins
// __float128
// https://gcc.gnu.org/onlinedocs/gcc/x86-Built-in-Functions.html#x86-Built-in-Functions
// __builtin_ia32_pause
// __builtin_cpu_init
// __builtin_cpu_is
// __builtin_cpu_supports
// clang enable_if
// clang::reinitializes

// OpenMP?
