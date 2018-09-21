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


