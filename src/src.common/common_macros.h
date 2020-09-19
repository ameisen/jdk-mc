#pragma once

#define TOOLCHAIN_GCC 0
#define TOOLCHAIN_LLVM 1
#define TOOLCHAIN_MSVC_CLANG 2
#define TOOLCHAIN_MSVC 3

#if defined(__GNUC__)
#	define _BUILD_GCC true
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
#		define _BUILD_TOOLCHAIN TOOLCHAIN_MSVC_CLANG
#	else
#		define _BUILD_CLANG false
#		define _BUILD_TOOLCHAIN TOOLCHAIN_MSVC
#	endif
#else
#	error "Unknown Toolchain"
#endif

#if _BUILD_GCC
#	define _HAS_INT128 true
#	define _expect(expr, value) (__builtin_expect((expr), (value)))
#	define _likely(expr) _expect(!!(expr), true)
#	define _unlikely(expr) _expect(!!(expr), false)
#	define _unreachable __builtin_unreachable()
#	define _constant_p(expr) __builtin_constant_p(expr)
#	if _BUILD_CLANG
#	define _expect_with_probability(expr, value, prob) (expr)
#	define _unpredictable (__builtin_unpredictable((expr)))
#	define _assume(expr) __builtin_assume(expr)
#	else
#	define _expect_with_probability(expr, value, prob) (__builtin_expect_with_probability((expr), (value), (prob)))
#	define _unpredictable(expr) _expect_with_probability(!!(expr), true, 0.5)
#	define _unpredictable_count(expr, num) _expect_with_probability(!!(expr), true, 1.0 / ((double)(num)))
#	define _assume(expr) do { if (!(expr)) _unreachable; } while (false)
# define _forceinline __attribute__((always_inline)) inline
# define _noalias __attribute__((nothrow))
# define _pure _noalias __attribute__((pure))
#	define _constf _noalias __attribute__((const))
#	endif
#elif _BUILD_MSVC
# if defined(__INTELLISENSE__)
#		define __assume(expr)
#	endif

#	define _HAS_INT128 false
#	define _expect(expr, value) (expr)
#	define _likely(expr) (expr)
#	define _unlikely(expr) (expr)
#	define _expect_with_probability(expr, value, prob) (expr)
#	define _unpredictable(expr) (expr)
#	define _unreachable __assume(0)
#	define _assume(expr) __assume(expr)
#	if defined(__cplusplus)
#		define _constant_p(expr) (std::is_constant_evaluated())
#	else
#		define _constant_p(expr) (false)
#	endif
# define _forceinline __forceinline inline
#	define _noalias __declspec(nothrow) __declspec(noalias)
#	define _pure _noalias
# define _constf _pure
#else
#	error "Unknown Toolchain"
#endif

#if __has_cpp_attribute(no_unique_address)
#	define _elidable [[no_unique_address]]
#else
#	define _elidable
#endif

// Because MSVC doesn't have built-ins for this but uses C++ attributes, but GCC and Clang don't support the attributes fully yet.
// More recent versions parse them but don't necessarily use them.
#define _likely_if(expr) _likely(expr) [[likely]]
#define _unlikely_if(expr) _unlikely(expr) [[unlikely]]

#define _SUPERSCALAR true
