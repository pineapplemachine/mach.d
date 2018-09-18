module mach.time.sleep;

private:

import core.stdc.errno : errno, EINTR;

version(Windows) import core.sys.windows.winbase : Sleep;
version(Posix) import core.sys.posix.time : timespec, nanosleep;

import mach.math.floats.properties : fisnan, fisinf;
import mach.time.duration : Duration;

/++ Docs

This module implements the `sleep` function.
The function suspends the calling thread for approximately the amount of
time specified.
Sleep time may be given either as a number of seconds or as a `Duration`
object, from the `mach.time.duration` module.

+/

unittest { /// Example
    sleep(0.001); // Sleep for 1 millisecond
}

unittest { /// Example
    import mach.time.duration : Duration;
    sleep(Duration!long.Milliseconds(2)); // Sleep for 2 milliseconds
}

public:

/// Error type thrown when a call to `sleep` fails for any reason.
class SleepError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Sleep failed.", file, line, null);
    }
}

/// Sleep the calling thread for the given number of seconds.
/// If the number is zero, negative, NaN, or infinite, then the function
/// returns without doing anything.
/// If sleeping fails, then a SleepError may be thrown.
/// If the number of seconds is very large (greater than long.max, i.e. about
/// 580 million years) then the input time will be truncated.
/// On Posix platforms, sleep terminates if the process received a signal.
void sleep(in double seconds) @trusted @nogc nothrow {
    static const error = new SleepError();
    if(seconds <= 0 || fisnan(seconds) || fisinf(seconds)){
        return;
    }
    const iseconds = seconds >= ulong.max ? ulong.max : cast(ulong) seconds;
    version(Windows){
        enum ulong MaxSleepMillisecs = cast(ulong) (uint.max - 1);
        enum ulong MaxSleepSeconds = (MaxSleepMillisecs / 1000) - 1;
        ulong sleepseconds = iseconds;
        while(sleepseconds > MaxSleepSeconds){
            Sleep(cast(uint) (1000 * MaxSleepSeconds));
            sleepseconds -= MaxSleepSeconds;
        }
        const uint remainingms = cast(uint) ((seconds % 1.0) * 1000);
        // Condition should be guaranteed by the nature of the while loop
        const ulong sleepms = 1000 * sleepseconds + remainingms;
        assert(sleepms <= MaxSleepMillisecs);
        Sleep(cast(uint) sleepms);
    }else version(Posix){
        enum MaxSleepSeconds = typeof(timespec.tv_sec).max;
        timespec requested = void;
        timespec remaining = void;
        ulong sleepseconds = iseconds;
        while(sleepseconds > MaxSleepSeconds){
            requested.tv_sec = MaxSleepSeconds;
            requested.tv_nsec = 0;
            const status = nanosleep(&requested, &remaining);
            if(status != 0){
                if(errno() != EINTR) throw error;
                return;
            }
            sleepseconds -= MaxSleepSeconds;
        }
        const sleepns = (seconds % 1) * double(1_000_000_000);
        requested.tv_sec = cast(typeof(timespec.tv_sec)) sleepseconds;
        requested.tv_nsec = cast(typeof(timespec.tv_nsec)) sleepns;
        const status = nanosleep(&requested, &remaining);
        if(status != 0){
            if(errno() != EINTR) assert(false, "Sleep failed.");
            return;
        }
    }else{
        static assert(false, "Sleep not implemented for this platform.");
    }
}

/// Sleep the calling thread for the amount of time given by a Duration object.
/// If the input Duration is shorter than the shortest possible sleep
/// amount (1 millisecond on Windows and 1 nanosecond on Posix platforms)
/// then the function returns without doing anything.
/// If sleeping fails, then a SleepError may be thrown.
/// On Posix platforms, sleep terminates if the process received a signal.
void sleep(T)(in Duration!T duration) @trusted @nogc nothrow {
    static const error = new SleepError();
    if(!duration){
        return;
    }
    version(Windows){
        enum MaxSleepMillisecs = uint.max - 1;
        ulong sleepms = cast(ulong) duration.milliseconds;
        assert(sleepms == duration.milliseconds);
        while(sleepms > MaxSleepMillisecs){
            Sleep(MaxSleepMillisecs);
            sleepms -= MaxSleepMillisecs;
        }
        Sleep(cast(uint) sleepms);
    }else version(Posix){
        enum MaxSleepSeconds = typeof(timespec.tv_sec).max;
        timespec requested = void;
        timespec remaining = void;
        ulong sleepseconds = cast(ulong) duration.seconds;
        assert(sleepseconds == duration.seconds);
        while(sleepseconds > MaxSleepSeconds){
            requested.tv_sec = MaxSleepSeconds;
            requested.tv_nsec = 0;
            const status = nanosleep(&requested, &remaining);
            if(status != 0){
                if(errno() != EINTR) throw error;
                return;
            }
            sleepseconds -= MaxSleepSeconds;
        }
        const sleepns = duration.nanoseconds % 1_000_000_000L;
        requested.tv_sec = cast(typeof(timespec.tv_sec)) sleepseconds;
        requested.tv_nsec = cast(typeof(timespec.tv_nsec)) sleepns;
        const status = nanosleep(&requested, &remaining);
        if(status != 0){
            if(errno() != EINTR) assert(false, "Sleep failed.");
            return;
        }
    }else{
        static assert(false, "Sleep not implemented for this platform.");
    }
}

// To manually test, first run unit tests with this block still commented
// and take note of the time. Then uncomment this block and run unit tests
// again. The second run should take roughly 10 seconds more than the first.
// TODO: Is there a reasonable way to test handling of durations that
// exceed values possible for a single call to Sleep or nanosleep?
// Maybe special functions that just verify the inputs are correct instead of
// trying to run a program for 50 days (Sleep) or 136 years (nanosleep)...

//unittest {
//    sleep(5);
//    sleep(Duration!long.Seconds(5));
//}

// Manually uncomment these functions to test `sleep` with inputs exceeding
// what Sleep/nanosleep can accept all in one go, and comment out the imports.

//ulong totalsleepns = 0;
//version(Posix) import core.sys.posix.time : timespec;
//private void Sleep(in uint milliseconds) @safe @nogc nothrow {
//    assert(milliseconds > 0); // sleep functions shouldn't do this
//    assert(milliseconds != uint.max); // Special INFINITY value
//    totalsleepns += milliseconds * 1_000_000L;
//}
//version(Posix) private uint nanosleep(
//    in timespec* req, timespec* rem
//) @safe @nogc nothrow {
//    totalsleepns += req.tv_sec * 1_000_000_000L;
//    totalsleepns += req.tv_nsec;
//    rem.tv_sec = 0;
//    rem.tv_nsec = 0;
//    return 0;
//}
//unittest {
//    const toomanyseconds = double(uint.max) * 2;
//    // Seconds
//    totalsleepns = 0;
//    sleep(toomanyseconds);
//    assert(totalsleepns == toomanyseconds * 1_000_000_000L);
//    // Duration
//    totalsleepns = 0;
//    sleep(Duration!long.Seconds(toomanyseconds));
//    assert(totalsleepns == toomanyseconds * 1_000_000_000L);
//}
