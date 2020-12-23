#include "../common.h"

#if !DISABLE_DUMPING && _BUILD_MSVC

#include <mutex>
#include <thread>
#include <utility>
#include <atomic>
#include <string>
#include <unordered_map>
#include <vector>
#include <algorithm>

#include <cstdio>

#ifdef WIN32_LEAN_AND_MEAN
#	undef WIN32_LEAN_AND_MEAN
#endif
#define WIN32_LEAN_AND_MEAN 1
#include <Windows.h>
#undef WIN32_LEAN_AND_MEAN

namespace carbide::dump {
	namespace {
		template <uint64_t invalid_value>
		class handle_base {
		protected:
			static constexpr const HANDLE invalid = HANDLE(invalid_value);

			HANDLE handle_ = invalid;

			handle_base(HANDLE handle) : handle_(handle) {}
			handle_base(const handle_base &) = delete;
			handle_base(handle_base &&hb) : handle_(hb.handle_) {
				hb.handle_ = nullptr;
			}

		public:
			~handle_base() {
				if _likely_if(handle_ != invalid) {
					::CloseHandle(handle_);
				}
			}
		};

		class event final : public handle_base<0> {
			using super = handle_base<0>;
		public:
			event(bool manualReset = false, bool initialState = false) : super(::CreateEvent(nullptr, BOOL(manualReset), BOOL(initialState), nullptr)) {}
			event(event &&e) : super(std::move(e)) {}

			bool set() __restrict {
				return bool(::SetEvent(handle_));
			}

			bool reset() __restrict {
				return bool(::ResetEvent(handle_));
			}

			bool wait(uint32_t duration_ms = uint32_t(INFINITE)) const __restrict {
				return ::WaitForSingleObject(handle_, duration_ms);
			}
		};

		static constexpr const bool dump = true;
		static constexpr const char dump_path[] = "D:/java_dump.txt";
		static constexpr const char dump_path2[] = "D:/java_dump.txt.bak";
		static FILE *dump_stream;

		static constexpr bool dump_valid() {
			if constexpr (!dump) {
				return false;
			}
			return dump_stream != nullptr;
		}

		static void dump_loop();
		static std::thread dump_thread(dump_loop);
		static std::atomic<bool> run(true);

		static event dirty_event;

		template <typename data_type>
		struct locked_data final {
			std::mutex lock;
			data_type data;
		};

		using counted_string_map = std::unordered_map<std::string, uint64_t>;

		static locked_data<counted_string_map> compiled_method_checks;

		static void dump_loop() {
			if constexpr (!dump) {
				return;
			}

			auto clear_stream = []() {
				if _likely_if(dump_stream) {
					fclose(dump_stream);
				}

				::DeleteFileA(dump_path2);
				::MoveFileA(dump_path, dump_path2);

				dump_stream = fopen(dump_path, "w");
			};

			dump_thread.detach();

			while _likely(run.load()) [[likely]] {
				Sleep(1000);
				dirty_event.wait();

				clear_stream();
				if _unlikely_if(!dump_stream) {
					continue;
				}

				// Compiled Method Checks
				{
					using pair_type = std::pair<std::string, uint64_t>;
					auto sorted_checks = []() {
						std::lock_guard lock(compiled_method_checks.lock);
						return std::vector<pair_type>(compiled_method_checks.data.begin(), compiled_method_checks.data.end());
					}();

					std::sort(sorted_checks.begin(), sorted_checks.end(), [](const pair_type & __restrict l, const pair_type & __restrict r) {
						return l.second > r.second;
					});

					fprintf(dump_stream, "Compiled Method Checks:\n");
					for (const pair_type &check_pair : sorted_checks) {
						fprintf(dump_stream, "\t%s [%llu]\n", check_pair.first.c_str(), check_pair.second);
					}
				}
			}

			fclose(dump_stream);
			dump_stream = nullptr;
		}
	}

	void compiled_method_check(const char * __restrict method) {
		if constexpr (!dump) {
			return;
		}

		if _unlikely_if(!method) {
			return;
		}

		{
			std::lock_guard lock(compiled_method_checks.lock);
			++compiled_method_checks.data[method];
		}
		dirty_event.set();
	}
}

#endif
