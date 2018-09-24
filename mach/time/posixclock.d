module mach.time.posixclock;

private:

version(Posix) import core.sys.posix.time : timespec;

// These imports define constants such as CLOCK_MONOTONIC
// for use with clock_gettime and related functions.
version(Posix) import core.sys.posix.time;
version(linux) import core.sys.linux.time;
version(FreeBSD) import core.sys.freebsd.time;
version(Solaris) import core.sys.solaris.time;

/++ Docs

This module implements the `posixclock` function. It can be used to read
the time on different clocks on Posix systems, such as the real-time clock
or the monotonic clock.

+/

unittest { /// Example
    version(linux) {
        import core.sys.posix.time : timespec;
        timespec monotime = posixtime!(PosixClock.Monotonic)();
    }
}

public:

/// clockid_t type.
alias clockid_t = int;

/// True when clock_gettime is defined and false when it is not.
/// clock_gettime should be defined for most (though not all) Posix platforms.
enum bool PosixClockPlatform = is(typeof(clock_gettime));

/// Enumerations of various clock types supported by various platforms.
enum PosixClock {
    /// Get the value of the real-time clock
    Realtime,
    /// Use a faster and less precise real-time clock when available.
    /// Uses the normal real-time clock when there is no fast version.
    FastRealtime,
    /// Use a slower and more precise real-time clock when available.
    /// Uses the normal real-time clock when there is no precise version.
    PreciseRealtime,
    
    /// Get the value of the monotonic clock
    Monotonic,
    /// Use a faster and less precise monotonic clock when available.
    /// Uses the normal monotonic clock when there is no fast version.
    FastMonotonic,
    /// Use a slower and more precise monotonic clock when available.
    /// Uses the normal monotonic clock when there is no precise version.
    PreciseMonotonic,
    /// Get monotonic time, not subject to NTP adjustments or adjtime.
    /// Linux only. Uses CLOCK_MONOTONIC_RAW.
    RawMonotonic,
    
    /// Get time since the system was booted.
    /// Does not include time elapsed while the system was suspended.
    /// FreeBSD only. Uses CLOCK_UPTIME.
    Uptime,
    /// Use a faster and less precise uptime clock when available.
    /// Uses the normal real-time clock when there is no fast version.
    /// Does not include time elapsed while the system was suspended.
    /// FreeBSD only. Uses CLOCK_UPTIME_FAST.
    FastUptime,
    /// Use a slower and more precise uptime clock when available.
    /// Uses the normal real-time clock when there is no precise version.
    /// Does not include time elapsed while the system was suspended.
    /// FreeBSD only. Uses CLOCK_UPTIME_PRECISE.
    PreciseUptime,
    
    /// Get time since the system was booted.
    /// Includes time elapsed while the system was suspended.
    /// Linux only. Uses CLOCK_BOOTTIME.
    BootTime,
    
    /// Get how much CPU time has been used by the process.
    /// Linux and Solaris only. Uses CLOCK_PROCESS_CPUTIME_ID.
    ProcessCPUTime,
    /// Get how much CPU time has been used by the thread.
    /// Linux and Solaris only. Uses CLOCK_THREAD_CPUTIME_ID.
    ThreadCPUTime,
    
    /// Increments  only when the CPU is running in user mode on behalf of
    /// the calling process.
    /// FreeBSD and Solaris only.
    Virtual,
}

/// Get clock ID as a clockid_t corresponding to a PosixClock type.
template ClockId(PosixClock clock){
    static if(clock is PosixClock.Realtime){
        static if(is(typeof(CLOCK_REALTIME))){
            enum ClockId = CLOCK_REALTIME;
        }else{
            static assert(false, "Real-time clock not available.");
        }
    }else static if(clock is PosixClock.FastRealtime){
        static if(is(typeof(CLOCK_REALTIME_FAST))){
            enum ClockId = CLOCK_REALTIME_FAST;
        }else static if(is(typeof(CLOCK_REALTIME_COARSE))){
            enum ClockId = CLOCK_REALTIME_COARSE;
        }else static if(is(typeof(CLOCK_REALTIME))){
            enum ClockId = CLOCK_REALTIME;
        }else{
            static assert(false, "Real-time clock not available.");
        }
    }else static if(clock is PosixClock.PreciseRealtime){
        static if(is(typeof(CLOCK_REALTIME_PRECISE))){
            enum ClockId = CLOCK_REALTIME_PRECISE;
        }else static if(is(typeof(CLOCK_REALTIME))){
            enum ClockId = CLOCK_REALTIME;
        }else{
            static assert(false, "Real-time clock not available.");
        }
    }else static if(clock is PosixClock.Monotonic){
        static if(is(typeof(CLOCK_MONOTONIC))){
            enum ClockId = CLOCK_MONOTONIC;
        }else{
            static assert(false, "Monotonic clock not available.");
        }
    }else static if(clock is PosixClock.FastMonotonic){
        static if(is(typeof(CLOCK_MONOTONIC_FAST))){
            enum ClockId = CLOCK_MONOTONIC_FAST;
        }else static if(is(typeof(CLOCK_MONOTONIC_COARSE))){
            enum ClockId = CLOCK_MONOTONIC_COARSE;
        }else static if(is(typeof(CLOCK_MONOTONIC))){
            enum ClockId = CLOCK_MONOTONIC;
        }else{
            static assert(false, "Monotonic clock not available.");
        }
    }else static if(clock is PosixClock.PreciseMonotonic){
        static if(is(typeof(CLOCK_MONOTONIC_PRECISE))){
            enum ClockId = CLOCK_MONOTONIC_PRECISE;
        }else static if(is(typeof(CLOCK_MONOTONIC))){
            enum ClockId = CLOCK_MONOTONIC;
        }else{
            static assert(false, "Monotonic clock not available.");
        }
    }else static if(clock is PosixClock.Uptime){
        static if(is(typeof(CLOCK_UPTIME))){
            enum ClockId = CLOCK_UPTIME;
        }else{
            static assert(false, "Uptime clock not available.");
        }
    }else static if(clock is PosixClock.FastUptime){
        static if(is(typeof(CLOCK_UPTIME_FAST))){
            enum ClockId = CLOCK_UPTIME_FAST;
        }else static if(is(typeof(CLOCK_UPTIME_COARSE))){
            enum ClockId = CLOCK_UPTIME_COARSE;
        }else static if(is(typeof(CLOCK_UPTIME))){
            enum ClockId = CLOCK_UPTIME;
        }else{
            static assert(false, "Uptime clock not available.");
        }
    }else static if(clock is PosixClock.PreciseUptime){
        static if(is(typeof(CLOCK_UPTIME_PRECISE))){
            enum ClockId = CLOCK_UPTIME_PRECISE;
        }else static if(is(typeof(CLOCK_UPTIME))){
            enum ClockId = CLOCK_UPTIME;
        }else{
            static assert(false, "Uptime clock not available.");
        }
    }else static if(clock is PosixClock.BootTime){
        static if(is(typeof(CLOCK_BOOTTIME))){
            enum ClockId = CLOCK_BOOTTIME;
        }else{
            static assert(false, "Boot-time clock not available.");
        }
    }else static if(clock is PosixClock.ProcessCPUTime){
        static if(is(typeof(CLOCK_PROCESS_CPUTIME_ID))){
            enum ClockId = CLOCK_PROCESS_CPUTIME_ID;
        }else{
            static assert(false, "Process CPU time clock not available.");
        }
    }else static if(clock is PosixClock.ThreadCPUTime){
        static if(is(typeof(CLOCK_THREAD_CPUTIME_ID))){
            enum ClockId = CLOCK_THREAD_CPUTIME_ID;
        }else{
            static assert(false, "Thread CPU time clock not available.");
        }
    }else static if(clock is PosixClock.Virtual){
        static if(is(typeof(CLOCK_THREAD_VIRTUAL))){
            enum ClockId = CLOCK_THREAD_VIRTUAL;
        }else{
            static assert(false, "Virtual clock not available.");
        }
    }else{
        static assert(false, "Unknown clock type.");
    }
}

static if(PosixClockPlatform){
    /// Helpful wrapper for clock_gettime.
    timespec posixtime(in clockid_t clock) @trusted @nogc nothrow {
        timespec time;
        const status = clock_gettime(clock, &time);
        if(status) assert(false, "Failed to get clock time.");
        return time;
    }
    /// Ditto
    timespec posixtime(PosixClock clock)() @trusted @nogc nothrow {
        return posixtime(ClockId!clock);
    }
}

// TODO: More thorough unit tests (how?)
static if(PosixClockPlatform) unittest {
    auto monotime = posixtime!(PosixClock.Monotonic)();
}
