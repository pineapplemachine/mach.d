module mach.collect.heap;

private:

import mach.traits : isIterableOf, isFiniteIterable, isPredicate, ElementType;

public:



/// Determine whether a heap can be created given some element and comparison
/// function.
enum canHeap(T, alias compare) = isPredicate!(compare, T, T);

/// Put the least element at the root of the heap by default.
alias DefaultHeapCompare = (a, b) => (a < b);
static assert(canHeap!(int, DefaultHeapCompare));

/// Determine whether a heap can be constructed from some iterable given its
/// type and a comparison function.
template canHeapify(Iter, alias compare){
    static if(isFiniteIterable!Iter){
        enum bool canHeapify = canHeap!(ElementType!Iter, compare);
    }else{
        enum bool canHeapify = false;
    }
}



/// Eagerly construct a binary heap from the elements of some iterable and 
/// a comparison function.
auto heapify(alias compare = DefaultHeapCompare, Iter)(auto ref Iter iter) if(
    canHeapify!(Iter, compare)
){
    return Heap!(ElementType!Iter, compare)(iter);
}



/// Binary heap implementation.
struct Heap(T, alias compare = DefaultHeapCompare) if(canHeap!(T, compare)){
    T[] elements;
    
    this(in size_t size){
        this.reserve(size);
    }
    this(Values)(Values values) if(isIterableOf!(Values, T)){
        this.clear();
        this.push(values);
    }
    
    void reserve(in size_t size){
        this.elements.reserve(size);
    }
    
    /// Get the number of values in the heap.
    @property auto length(){
        if(this.elements.length){
            return this.elements.length - 1;
        }else{
            return 0;
        }
    }
    /// Determine whether the heap is empty.
    @property bool empty(){
        return this.elements.length <= 1;
    }
    
    /// Clear all elements from the heap.
    void clear(){
        this.elements.length = 1;
    }
    
    /// Create a copy of the heap.
    @property typeof(this) dup(){
        typeof(this) heap;
        heap.elements = this.elements.dup;
        return heap;
    }
    
    /// Push a new value or values onto the heap.
    auto push(ref T value){
        if(!this.elements.length) this.clear();
        this.elements ~= value;
        auto index = this.siftup(this.length);
        if(index > 0) index = this.siftdown(index);
        return index;
    }
    /// ditto
    auto push(T[] values...){
        foreach(value; values) this.push(value);
    }
    /// ditto
    auto push(Iter)(Iter values...) if(isIterableOf!(Iter, T)){
        foreach(value; values) this.push(value);
    }
    
    /// Get the topmost value of the heap.
    @property auto top() in{assert(!this.empty);} body{
        return this.elements[1];
    }
    /// Pop and return the topmost value of the heap.
    @property auto pop() in{assert(!this.empty);} body{
        auto element = this.elements[1];
        this.elements[1] = this.elements[this.length];
        this.elements.length = this.elements.length - 1;
        this.siftdown(1);
        return element;
    }
    
    auto siftup(in size_t startindex){
        size_t index = startindex;
        while(index / 2 > 0){
            auto temp = this.elements[index / 2];
            this.elements[index / 2] = this.elements[index];
            this.elements[index] = temp;
            index /= 2;
        }
        return index;
    }
    auto siftdown(in size_t startindex){
        size_t index = startindex;
        while(index * 2 <= this.length){
            auto min = this.child(index);
            if(compare(this.elements[min], this.elements[index])){
                auto temp = this.elements[index];
                this.elements[index] = this.elements[min];
                this.elements[min] = temp;
            }
            index = min;
        }
        return index;
    }
    auto child(in size_t index){
        if(index * 2 + 1 > this.length){
            return index * 2;
        }else if(compare(this.elements[index * 2], this.elements[index * 2 + 1])){
            return index * 2;
        }else{
            return index * 2 + 1;
        }
    }
    
    /// Make it a range.
    alias front = top;
    /// ditto
    alias popFront = pop;
    /// ditto
    alias save = dup;
}



version(unittest){
    private:
    import mach.test;
    import mach.traits : isRange;
    import mach.range.compare : equals;
}
unittest{
    tests("Heap", {
        static assert(isRange!(Heap!int));
        tests("Iteration", {
            test!equals(Heap!int([2, -1, -2, 1, 0]), [-2, -1, 0, 1, 2]);
            test!equals(Heap!int([2, 1, 1, 2, 1]), [1, 1, 1, 2, 2]);
        });
        tests("Length", {
            Heap!int heap;
            test(heap.empty);
            testeq(heap.length, 0);
            heap.push(1, 2);
            testeq(heap.length, 2);
            heap.push(3);
            testeq(heap.length, 3);
            heap.pop();
            testeq(heap.length, 2);
            heap.clear();
            testeq(heap.length, 0);
        });
        tests("Heapify", {
            auto heap = heapify([4, 1, 3, 2]);
            test!equals(heap, [1, 2, 3, 4]);
        });
    });
}
