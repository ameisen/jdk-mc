#pragma once

namespace carbide {
	template <typename LockType>
	class ScopedLock final {
		LockType & __restrict lock_;

	public:
		_forceinline ScopedLock(LockType & __restrict lock) : lock_(lock) {
			lock_.lock();
		}
		_forceinline ScopedLock(LockType * __restrict lock) : ScopedLock(*lock) {}

		_forceinline ~ScopedLock() {
			lock_.unlock();
		}
	};

	template <typename LockType>
	class ScopedTryLock final {
		LockType & __restrict lock_;
		const bool locked_;

	public:
		_forceinline ScopedTryLock(LockType & __restrict lock) : lock_(lock), locked_(lock.try_lock()) {}
		_forceinline ScopedTryLock(LockType * __restrict lock) : ScopedTryLock(*lock) {}

		_forceinline ~ScopedTryLock() {
			if _likely_if(locked_) {
				lock_.unlock();
			}
		}

		_forceinline operator bool () const __restrict {
			return _likely(locked_);
		}
	};

	template <typename LockType>
	class ScopedUnlocker final {
		LockType & __restrict lock_;

	public:
		_forceinline ScopedUnlocker(LockType & __restrict lock) : lock_(lock) {
			lock_.unlock();
		}
		_forceinline ScopedUnlocker(LockType * __restrict lock) : ScopedUnlocker(*lock) {}

		_forceinline ~ScopedUnlocker() {
			lock_.lock();
		}
	};
}
