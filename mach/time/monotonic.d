module mach.time.monotonic;

private:

import mach.time.duration : Duration;

version(OSX) {
    import core.sys.darwin.mach.kern_return;
    extern(C) nothrow @nogc {
        struct mach_timebase_info_data_t {
            uint numer;
            uint denom;
        }
        alias mach_timebase_info_data_t* mach_timebase_info_t;
        kern_return_t mach_timebase_info(mach_timebase_info_t);
        ulong mach_absolute_time();
    }
}
else version(Posix) {
    import mach.time.posixclock : PosixClock, posixtime;
}
else version(Windows) {
    import core.sys.windows.winbase : QueryPerformanceCounter;
    import core.sys.windows.winbase : QueryPerformanceFrequency;
}

/// Helper to convert a number of ticks to a number of nanoseconds.
/// Used by the Windows implementation of `monotonicns`.
long tickstons(in long ticks, in long tickspersecond) pure nothrow @safe @nogc {
    assert(tickspersecond > 0);
    enum NanosecondsPerSecond = 1_000_000_000L;
    const nspertick = NanosecondsPerSecond / tickspersecond;
    assert(nspertick > 0);
    return ticks * nspertick;
}

/++ Docs

This module implements the `monotonic` and `monotonicns` functions,
which can be used to retrieve the system's monotonic time.
The `monotonic` function returns a `Duration` object whereas the
`monotonicns` function returns an integral number of nanoseconds.

+/

unittest { /// Example
    import mach.time.sleep : sleep;
    // Get initial monotonic time in nanoseconds
    const long begin = monotonicns();
    // Sleep for 5 milliseconds
    sleep(0.005);
    // Get monotonic time after sleeping
    const long end = monotonicns();
    // Elapsed time will roughly equal 5,000,000 nanoseconds (5 milliseconds).
    const long elapsed = end - begin;
}

unittest { /// Example
    import mach.time.duration : Duration;
    // Get monotonic time as a duration
    Duration!long monotime = monotonic();
    const monominutes = monotime.minutes;
}



public:

/// Get monotonic time as a Duration object.
Duration!T monotonic(T = long)(){
    return Duration!T.Nanoseconds(monotonicns());
}

/// Get monotonic time as a number of nanoseconds on OSX.
/// The OSX monotonic clock should be accurate to the nanosecond.
/// The clock counts up from the last reboot time. The clock
/// does not count up while the system is asleep or hibernating.
version(OSX) long monotonicns(){
    const ulong ns = mach_absolute_time();
    return cast(long) ns;
}

/// Get monotonic time as a number of nanoseconds on Posix platforms
/// other than OSX. This encompasses a number of different operating systems,
/// and clock basis and precision can be expected to vary between them.
/// Check the documentation for clock_gettime(CLOCK_MONOTONIC_PRECISE, &t)
/// where available - clock_gettime(CLOCK_MONOTONIC, &t) where not - for a
/// particular platform; the behavior of monotonicns will be the same.
else version(Posix) long monotonicns(){
    const timespec time = posixtime!(PosixClock.PreciseMonotonic)();
    return cast(long) time.tv_sec * 1_000_000_000L + cast(long) time.tv_nsec;
}

/// Get monotonic time as a number of nanoseconds on Windows.
/// The OSX monotonic clock should be accurate to the nanosecond.
/// The clock counts up from the last reboot time. The clock
/// does not count up while the system is asleep or hibernating.
else version(Windows) long monotonicns(){
    // https://msdn.microsoft.com/en-us/library/ms644904(v=VS.85).aspx
    // https://msdn.microsoft.com/en-us/library/ms644905(v=VS.85).aspx
    static long tickspersecond = 0;
    // Initialize tickspersecond if it hasn't been initialized already
    if(tickspersecond == 0){
        const freqstatus = QueryPerformanceFrequency(&tickspersecond);
        if(freqstatus == 0 || tickspersecond <= 0){
            assert(false, "Monotonic clock not available for this platform.");
        }
    }
    // Get the number of ticks
    long ticks;
    const status = QueryPerformanceCounter(&ticks);
    // Note that if this check would fail, then the one just above should
    // have failed already.
    assert(status != 0, "Monotonic clock not available for this platform.");
    // Convert the number of ticks to a number of nanoseconds
    return ticksperns(ticks, tickspersecond);
}



private version(unittest) {
    import mach.time.sleep : sleep;
}

unittest {
    const before = monotonic();
    sleep(Duration!long.Milliseconds(2));
    const after = monotonic();
    assert(before < after);
}
