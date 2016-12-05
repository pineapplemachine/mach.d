# mach.text.str

The `str` function is able to compose an intelligible string representation of anything you throw at it.

The function accepts a template argument of the type `StrSettings` which defines how `str` behaves. The presets are `StrSettings.Concise`, `StrSettings.Medium`, and `StrSettings.Verbose`, in ascending order of how much information is included in the outputted string.

``` D
assert(str(100) == "100");
assert(str(123.456) == "123.456");
assert(str("hello") == "hello");
assert(str(["a", "b", "c"]) == `["a", "b", "c"]`);
```

``` D
struct Test{int x, y;}
assert(str(Test(1, 2)) == "{x: 1, y: 2}");
assert(str!(StrSettings.Verbose)(Test(1, 2)) == "struct:Test:{x: int(1), y: int(2)}");
```
