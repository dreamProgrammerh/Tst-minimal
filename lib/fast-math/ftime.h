#ifndef FTIME_H
#define FTIME_H

#include "types.h"

#ifdef _WIN32
#include <Windows.h>
#else
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#endif

#if defined(_WIN32) || defined(_WIN64)
  #include <windows.h>
  static LARGE_INTEGER start_time;

#elif defined(__APPLE__) || defined(__MACH__)
  #include <mach/mach_time.h>
  #include <unistd.h>
  #include <sys/syscall.h>
  static struct timespec start_time;

#elif defined(__linux__)
  #include <unistd.h>
  #include <sys/syscall.h>
  static struct timespec start_time;

#endif

// current time
static inline u64 nowUs() {
#if defined(_WIN32) || defined(_WIN64)
  FILETIME ft;
  GetSystemTimeAsFileTime(&ft);

  ULARGE_INTEGER t;
  t.LowPart = ft.dwLowDateTime;
  t.HighPart = ft.dwHighDateTime;

  return (u64)((t.QuadPart - 116444736000000000ULL/* 100unit Epochs difference in nanoseconds */)
                / 10ULL/* take 10unit from QuadPart to get prefect microseconds */);

#elif defined(__APPLE__) || defined(__MACH__)
#include <sys/time.h>
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (u64)tv.tv_sec * 1e6 + tv.tv_usec;

#elif defined(__linux__)
#include <time.h>
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return (u64)ts.tv_sec * 1e6 + ts.tv_nsec * 1e-3;
  
#endif
}

// passed time of os start
static inline u64 uptimeUs() {
#if defined(_WIN32) || defined(_WIN64)
  LARGE_INTEGER counter;
  QueryPerformanceCounter(&counter);

  return (u64)counter.QuadPart
            / 10ULL/* take 10unit from QuadPart to get prefect microseconds */;

#elif defined(__APPLE__) || defined(__MACH__)
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0)
    mach_timebase_info(&timebase);

  uint64_t time = mach_absolute_time();
  return time * timebase.numer / timebase.denom;

#elif defined(__linux__)
  struct timespec ts;
  syscall(SYS_clock_gettime, CLOCK_MONOTONIC, &ts);
  return (u64)(ts.tv_sec * 1e6 + ts.tv_nsec * 1e-3);
  
#endif
}

// passed time of program start (call once on program start)
static inline u64 clockUs() {
#ifdef _WIN32
  if (start_time.QuadPart == 0)
    QueryPerformanceCounter(&start_time);

  LARGE_INTEGER current_time;
  QueryPerformanceCounter(&current_time);

  return (u64)(current_time.QuadPart - start_time.QuadPart)
            / 10ULL/* take 10unit from QuadPart to get prefect microseconds */;
  
#else
  // use nanosleep for accurate result
  struct timespec current_time;

  if (start_time.tv_sec == 0 && start_time.tv_nsec == 0) {
    if (clock_gettime(CLOCK_MONOTONIC, &start_time) == -1) {
      perror("clock_gettime");
      return -1;
    }
  }

  if (clock_gettime(CLOCK_MONOTONIC, &current_time) == -1) {
    perror("clock_gettime");
    return -1;
  }

  return (u64)((current_time.tv_sec - start_time.tv_sec) * 1e6 +
                (current_time.tv_nsec - start_time.tv_nsec) * 1e-3);
  
#endif
}

#endif // FTIME_H