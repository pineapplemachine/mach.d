module mach.time.systime;

private:

import mach.time.duration : Duration;

version(Posix) {
    import core.sys.posix.time : timespec;
    import core.sys.posix.sys.time : timeval, gettimeofday;
    import mach.time.posixclock; // import PosixClock, posixtime when defined
}

version(Windows) {
    import core.sys.windows.winbase : GetSystemTimeAsFileTime, FILETIME;
}

/++ Docs

The `systime` function returns the amount of time since the local
Unix epoch as a `Duration` object.
This system time is distinctly different from monotonic time.
Where monotonic time can be relied on to always increase uniformly
over time, the system time reflects a realtime clock and may jump
forward or backward as the result of timezone changes or user
configuration.

The realtime clock resolution varies across platforms. In the best
case, the clock will have a resolution of one nanosecond.
The Windows clock is likely the lowest resolution among platforms, in
which case the clock has a resolution of roughly ten milliseconds.

+/

unittest { /// Example
    // Assertion succeeds because you most certainly aren't
    // running this program in or before 1970
    const currentTime = systime();
    assert(currentTime.seconds > 0);
}

/++ Docs

The module also provides a `systimens` function, which returns the
approximate number of nanoseconds since local Unix epoch as an integer,
rather than as `Duration` object.

+/

unittest { /// Example
    const Duration!long currentTime = systime();
    const long currentNanoseconds = systimens();
    const long delta = currentTime.nanoseconds - currentNanoseconds;
    assert(delta >= -1_000 && delta <= +1_000);
}

public:

/// Get system time as a Duration object representing an amount of time
/// since Unix epoch.
Duration!T systime(T = long)(){
    return Duration!T.Nanoseconds(systimens());
}

/// Get system time as a number of nanoseconds since Unix epoch on
/// a Posix platform.
/// This encompasses a number of different operating systems, and clock
/// precision may vary between them.
/// Check the documentation for clock_gettime(CLOCK_REALTIME_PRECISE, &t)
/// where available - clock_gettime(CLOCK_REALTIME, &t) where not - for a
/// particular platform; the behavior of systimens will be the same.
version(PosixClockPlatform) long systimens(){
    const timespec time = posixtime!(PosixClock.PreciseRealtime)();
    return cast(long) time.tv_sec * 1_000_000_000L + cast(long) time.tv_nsec;
}

/// Fall back to gettimeofday on Posix platforms which do not
/// support `clock_gettime` - for example OSX before 10.12.
else version(Posix) long systimens(){
    timeval time;
    const status = gettimeofday(&time, null);
    if(status != 0) {
        assert(false, "Failed to get time of day.");
    }
    return (
        cast(long) time.tv_sec * 1_000_000_000L +
        cast(long) time.tv_usec * 1_000L
    );
}

/// Get system time as a number of nanoseconds since Unix epoch on Windows.
/// Note that this timer has low resolution, normally around 10 milliseconds.
version(Windows) long systimens(){
    // https://msdn.microsoft.com/en-us/library/windows/desktop/ms724284(v=vs.85).aspx
    // https://docs.microsoft.com/en-us/windows/desktop/api/sysinfoapi/nf-sysinfoapi-getsystemtimeasfiletime
    FILETIME fileTime;
    GetSystemTimeAsFileTime(&fileTime);
    // Number of 100-nanosecond intervals since 1 January 1601 (UTC), unsigned
    static assert(fileTime.dwLowDateTime.sizeof == 4);
    const ulong time = (
        cast(ulong) fileTime.dwLowDateTime |
        (cast(ulong) fileTime.dwHighDateTime << 32)
    );
    // Convert to nanoseconds since Unix epoch
    // https://stackoverflow.com/a/6161842/3478907
    enum ulong EpochGapSeconds = 11644473600UL;
    enum ulong EpochGapTimeUnits = 10000000UL * EpochGapSeconds;
    return (time - EpochGapTimeUnits) * 100;
}



private version(unittest) {
    import mach.time.sleep : sleep;
    import mach.text.ascii.chars : isdigit;
    import mach.text.numeric.integrals : parseint;
}

/// Sleep and make sure the clock has changed
unittest {
    const before = systime();
    sleep(Duration!long.Milliseconds(100));
    const after = systime();
    assert(before < after);
}

/// Check against the compile-time clock
unittest {
    // Get the current year according to the compiler
    enum string dateString = __DATE__;
    string yearString = "";
    for(int i = dateString.length - 1; i >= 0; i--) {
        if(!dateString[i].isdigit) break;
        yearString = dateString[i] ~ yearString;
    }
    // Compute the middle of the year as seconds since UTC Unix epoch
    enum secondsPerYear = cast(long) (60 * 60 * 24 * 365.25);
    const yearMiddleUnix = cast(long) (
        (parseint(yearString) - 1970) * secondsPerYear + secondsPerYear / 2
    );
    // The middle of the UTC current year in seconds and the
    // number of seconds since local epoch as returned by systime
    // should not differ by more than one year's worth of seconds
    const currentTime = systime();
    const delta = yearMiddleUnix - currentTime.seconds;
    assert(delta >= -secondsPerYear && delta <= +secondsPerYear);
}
