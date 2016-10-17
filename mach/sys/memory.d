module mach.sys.memory;

private:

import core.exception : OutOfMemoryError;
import core.stdc.stdlib : cmalloc = malloc;
import core.stdc.stdlib : cfree = free;
import core.stdc.string : cmemcpy = memcpy;
import core.stdc.string : cmemmove = memmove;

static immutable OOMError = new OutOfMemoryError();

@nogc nothrow public:



T* malloc(T)(){
    auto ptr = cmalloc(T.sizeof);
    if(ptr is null) throw OOMError;
    return cast(T*) ptr;
}

void free(T)(T* ptr) in{
    assert(ptr !is null, "Cannot free null pointer.");
}body{
    cfree(ptr);
}

auto memcpy(A, B)(A* dest, in B* src, in size_t count) in{
    assert(src !is null, "Cannot memcpy from null pointer.");
    assert(dest !is null, "Cannot memcpy to null pointer.");
}body{
    return cast(A*) cmemcpy(dest, src, count);
}

auto memmove(A, B)(A* dest, in B* src, in size_t count) in{
    assert(src !is null, "Cannot memmove from null pointer.");
    assert(dest !is null, "Cannot memmove to null pointer.");
}body{
    return cast(A*) cmemmove(dest, src, count);
}
