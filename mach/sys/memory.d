module mach.sys.memory;

private:

import core.stdc.stdlib : cmalloc = malloc;
import core.stdc.stdlib : crealloc = realloc;
import core.stdc.stdlib : cfree = free;
import core.stdc.string : cmemcpy = memcpy;
import core.stdc.string : cmemmove = memmove;

/++ Docs

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

+/

public:



class MemoryError: Error{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}

class MemoryAllocationError: MemoryError{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Failed to allocate memory.", null, line, file);
    }
}

class MemoryInvalidPointerError: MemoryError{
    this(string message, size_t line = __LINE__, string file = __FILE__){
        super(message, null, line, file);
    }
    this(size_t line = __LINE__, string file = __FILE__){
        this("Memory management function received invalid arguments.", line, file);
    }
}



@system @nogc nothrow T* malloc(T)(){
    static const error = new MemoryAllocationError();
    auto ptr = cmalloc(T.sizeof);
    if(ptr is null) throw error;
    return cast(T*) ptr;
}

@system @nogc nothrow T* malloc(T)(in size_t count){
    static const error = new MemoryAllocationError();
    if(count <= 0) return null;
    auto ptr = cmalloc(T.sizeof * count);
    if(ptr is null) throw error;
    return cast(T*) ptr;
}

@system @nogc nothrow T* realloc(T)(T* ptr, in size_t count){
    static const error = new MemoryAllocationError();
    auto newPtr = crealloc(ptr, T.sizeof * count);
    if(newPtr is null) throw error;
    return cast(T*) newPtr;
}

@system @nogc nothrow void memfree(T)(T* ptr) in{
    static const error = new MemoryInvalidPointerError("Cannot free a null pointer.");
    if(ptr is null) throw error;
}body{
    cfree(ptr);
}

@system @nogc nothrow auto memcopy(A, B)(A* dest, in B* src, in size_t count) in{
    static const nullerror = new MemoryInvalidPointerError("Cannot copy memory to or from a null pointer.");
    if(src is null || dest is null) throw nullerror;
}body{
    return cast(A*) cmemcpy(dest, src, T.sizeof * count);
}

@system @nogc nothrow auto memmove(A, B)(A* dest, in B* src, in size_t count) in{
    static const error = new MemoryInvalidPointerError("Cannot copy memory to or from a null pointer.");
    if(src is null || dest is null) throw error;
}body{
    return cast(A*) cmemmove(dest, src, T.sizeof * count);
}



unittest{
    int* i = malloc!int;
    memfree(i);
    long* j = malloc!long(100);
    memfree(j);
}

unittest{
    int[] a = [1, 2, 3];
    int[] b = [0, 0, 0];
    memcopy(b.ptr, a.ptr, int.sizeof * a.length);
    assert(b == a);
    memmove(a.ptr + 1, a.ptr, int.sizeof * 2);
    assert(a == [1, 1, 2]);
}
