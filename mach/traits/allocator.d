module mach.traits.allocator;

private:

import std.experimental.allocator : CAllocatorImpl;

public:



/// Determine whether some type is an allocator as defined by phobos'
/// std.experimental.allocator.
enum isAllocator(Allocator) = is(CAllocatorImpl!Allocator);



version(unittest){
    private:
    import std.experimental.allocator.mallocator : Mallocator;
    import std.experimental.allocator.gc_allocator : GCAllocator;
}
unittest{
    static assert(isAllocator!Mallocator);
    static assert(isAllocator!GCAllocator);
    static assert(!isAllocator!int);
}
