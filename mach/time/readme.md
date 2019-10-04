# mach.time


This package provides utilities for dealing with dates and times.


## mach.time.duration


This module implements the `Duration` type. It can be used to represent
some length of time.

It provides various properties for getting the amount of time as various
units. Note that each unit supported by `Duration` has an integral and
a fractional method, for example `duration.seconds` returns the number of
seconds as an integer, rounded down, and `duration.fseconds` returns the
number of seconds as a floating point number, including fractional seconds.

``` D
alias LongDuration = Duration!long;
auto duration = LongDuration.Seconds(15);
assert(duration.seconds == 15);
assert(duration.milliseconds == 15_000);
```

``` D
auto duration = Duration!long.Seconds(15);
// Integer minutes, rounded down
assert(duration.minutes == 0);
// Floating point minutes, exact
assert(duration.fminutes == 0.25);
```


The module also provides convenience functions for tersely constructing
a Duration object.
These functions are named `weeks`, `days`, `hours`, `minutes`, `seconds`,
`milliseconds`, `microseconds`, and `nanoseconds`.

``` D
const dur = 5.seconds;
assert(dur.milliseconds == 5_000);
```

``` D
const intdur = 500.microseconds!int;
assert(intdur.fmilliseconds == 0.5);
```


## mach.time.monotonic


This module implements the `monotonic` and `monotonicns` functions,
which can be used to retrieve the system's monotonic time.
The `monotonic` function returns a `Duration` object whereas the
`monotonicns` function returns an integral number of nanoseconds.

``` D
import mach.time.sleep : sleep;
// Get initial monotonic time in nanoseconds
const long begin = monotonicns();
// Sleep for 5 milliseconds
sleep(0.005);
// Get monotonic time after sleeping
const long end = monotonicns();
// Elapsed time will roughly equal 5,000,000 nanoseconds (5 milliseconds).
const long elapsed = end - begin;
```

``` D
import mach.time.duration : Duration;
// Get monotonic time as a duration
Duration!long monotime = monotonic();
const monominutes = monotime.minutes;
```


## mach.time.posixclock


This module implements the `posixclock` function. It can be used to read
the time on different clocks on Posix systems, such as the real-time clock
or the monotonic clock.

``` D
version(linux) {
    import core.sys.posix.time : timespec;
    timespec monotime = posixtime!(PosixClock.Monotonic)();
}
```


## mach.time.sleep


This module implements the `sleep` function.
The function suspends the calling thread for approximately the amount of
time specified.
Sleep time may be given either as a number of seconds or as a `Duration`
object, from the `mach.time.duration` module.

``` D
sleep(0.001); // Sleep for 1 millisecond
```

``` D
import mach.time.duration : Duration;
sleep(Duration!long.Milliseconds(2)); // Sleep for 2 milliseconds
```


## mach.time.systime


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

``` D
// Assertion succeeds because you most certainly aren't
// running this program in or before 1970
const currentTime = systime();
assert(currentTime.seconds > 0);
```


The module also provides a `systimens` function, which returns the
approximate number of nanoseconds since local Unix epoch as an integer,
rather than as `Duration` object.

``` D
const Duration!long currentTime = systime();
const long currentNanoseconds = systimens();
const long delta = currentTime.nanoseconds - currentNanoseconds;
assert(delta >= -1_000 && delta <= +1_000);
```


