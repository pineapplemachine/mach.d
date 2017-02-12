# mach.sys.memory


This module implements lightweight wrappers around memory management functions
such as `malloc` and `free`.

The `malloc` function accepts a single template argument describing the type
of pointer to allocate and return, and an optional integer runtime argument
to specify how many items of the specified type should fit in the allocated
memory. (When no such argument is given, memory for just one value is allocated.)
When `malloc` fails due to insufficient memory a `MemoryAllocationError` is
thrown.

`memfree` is a wrapper of `free`. It releases memory previously allocated with
`malloc`.

`memcopy` wraps `memcpy`. It accepts three arguments: A destination pointer
which data should be copied to, a source pointer which data should be copied
from, and an integer count specifying the number of bytes to be copied
from the source to the destination.
`memmove`, like `memcopy`, accepts a destination pointer, a source pointer,
and a number of bytes to move.
`memcopy` is more efficient, but assumes that the two regions of memory do
not overlap. `memmove` is comparatively more expensive, but is able to
correctly handle such overlapping regions.

Except for in release mode, `memfree`, `memcopy`, and `memmove` will throw
an `MemoryInvalidPointerError` when any of their pointer arguments are null.


# mach.sys.platform


Defines several enum values pertinent to the compile target platform.

`InlineAsm_X86_Any` is true when inline x86 assembly is available,
as determined by the `D_InlineAsm_X86` and `D_InlineAsm_X86_64`
version identifiers.

`X86_Any` is true when compiling to an x86 target, as determined by the `X86`
and `X86_64` version identifiers.

`PPC_Any` is true when compiling to an x86 target, as determined by the `PPC`
and `PPC64` version identifiers.

`Any_32` is true when compiling to a 32-bit target.
`Any_64` is true when compiling to a 64-bit target.


