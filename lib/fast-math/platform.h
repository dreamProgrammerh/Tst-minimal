#ifndef __PLATFORM_H__
#define __PLATFORM_H__

#include "types.h"

#if defined(_WIN32) || defined(_WIN64)
    #include <Windows.h>
    #include <process.h>    // for _getpid()
    #include <intrin.h>     // for __rdtsc()
#else
    #include <unistd.h>     // for getpid()
    #if defined(__APPLE__) || defined(__MACH__)
        #include <pthread.h>
        #include <mach/mach.h>
    #elif defined(__linux__)
        #include <sys/syscall.h>
        #include <sys/types.h>
    #endif
#endif

/**
 * @brief Get current process ID (cross-platform)
 * @return Process ID as 64-bit unsigned integer
 */
static inline u64 getPid(void) {
#ifdef _WIN32
    return (u64)_getpid();  // Windows
#else
    return (u64)getpid();   // Unix (Linux, macOS, BSD)
#endif
}

/**
 * @brief Get current thread ID (cross-platform)
 * @return Thread ID as 64-bit unsigned integer
 * 
 * Note: Thread IDs are not guaranteed to be unique across reboots.
 */
static inline u64 getTid(void) {
#if defined(_WIN32) || defined(_WIN64)
    // Windows: GetCurrentThreadId() returns DWORD (32-bit)
    return (u64)GetCurrentThreadId();
    
#elif defined(__APPLE__) || defined(__MACH__)
    // macOS: pthread_threadid_np() gets 64-bit thread ID
    u64 tid = 0;
    pthread_threadid_np(NULL, &tid);
    return tid;
    
#elif defined(__linux__)
    // Linux: syscall(SYS_gettid) gets kernel thread ID
    return (u64)syscall(SYS_gettid);
    
#else
    // Unknown platform: fallback to process ID
    return getPid();
#endif
}

/**
 * @brief Get a high-resolution CPU timestamp (if available)
 * @return CPU timestamp counter or 0 if not available
 */
static inline u64 getCpuTimestamp(void) {
#ifdef _WIN32
    // Windows: Read Time Stamp Counter
    return (u64)__rdtsc();
    
#elif defined(__x86_64__) || defined(__i386__)
    // x86/x64: RDTSC instruction
    unsigned int lo, hi;
    __asm__ __volatile__ ("rdtsc" : "=a" (lo), "=d" (hi));
    return ((u64)hi << 32) | lo;
    
#elif defined(__aarch64__)
    // ARM64: Read CNTVCT_EL0 (Virtual Count Register)
    u64 tsc;
    __asm__ __volatile__ ("mrs %0, cntvct_el0" : "=r" (tsc));
    return tsc;
    
#elif defined(__APPLE__) && defined(__aarch64__)
    // Apple Silicon: system register
    u64 tsc;
    __asm__ __volatile__ ("mrs %0, cntpct_el0" : "=r" (tsc));
    return tsc;
    
#else
    // Unsupported architecture
    return 0ULL;
#endif
}

/**
 * @brief Get a memory address that varies
 * @return A stack or heap address that changes per call/process
 */
static inline u64 getVaryingAddress(void) {
    // Stack variable - address changes with call stack depth
    volatile int stack_var = 0;
    u64 stack_addr = (u64)&stack_var;
    
    // Heap allocation (tiny) - varies with ASLR
    static char* heap_ptr = NULL;
    if (heap_ptr == NULL) {
        heap_ptr = (char*)malloc(1);
    }
    u64 heap_addr = (u64)heap_ptr;
    
    // Function pointer - varies with ASLR
    u64 func_addr = (u64)&getVaryingAddress;
    
    // Mix them together
    return stack_addr ^ heap_addr ^ func_addr;
}

/**
 * @brief 64-bit bit mixing function (finalizer from MurmurHash3)
 * @param h 64-bit value to mix
 * @return Well-mixed 64-bit value
 */
static inline u64 mix64(u64 h) {
    h ^= h >> 33;
    h *= 0xff51afd7ed558ccdULL;
    h ^= h >> 33;
    h *= 0xc4ceb9fe1a85ec53ULL;
    h ^= h >> 33;
    return h;
}

/**
 * @brief Simple 64-bit mix (faster, less thorough)
 * @param h 64-bit value to mix
 * @return Mixed 64-bit value
 */
static inline u64 simpleMix64(u64 h) {
    h = (h ^ (h >> 30)) * 0xbf58476d1ce4e5b9ULL;
    h = (h ^ (h >> 27)) * 0x94d049bb133111ebULL;
    h = h ^ (h >> 31);
    return h;
}

#endif // __PLATFORM_H__