module mach.sort.heapsort;

private:

//import mach.traits : ElementType, hasNumericLength, isFiniteIterable;
import mach.sort.common;

public:



/// Determine whether a type is able to be heap sorted.
alias canHeapSort = canBoundedRandomAccessSort;



/// Used by heapsort methods to heapify an input in-place.
alias heapify = heapifydown;

/// Used by heapsort methods to heapify an input in-place.
/// Heapify by sifting up.
void heapifyup(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canHeapSort!(compare, T)
){
    size_t end = 1;
    while(end < input.length){
        end++;
        heapsiftup(input, 0, end);
    }
}

/// Used by heapsort methods to heapify an input in-place.
/// Heapify by sifting down.
void heapifydown(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canHeapSort!(compare, T)
){
    size_t start = input.length / 2;
    while(start > 0){
        start--;
        heapsiftdown!compare(input, start, input.length);
    }
}



void heapsiftdown(alias compare = DefaultSortCompare, T)(
    auto ref T input, in size_t start, in size_t end
) if(canHeapSort!(compare, T)){
    size_t root = start;
    while(true){
        immutable size_t leftchild = root * 2 + 1;
        immutable size_t rightchild = leftchild + 1;
        if(leftchild >= end) break;
        size_t swap = root;
        if(compare(input[swap], input[leftchild])){
            swap = leftchild;
        }
        if(rightchild < end && compare(input[swap], input[rightchild])){
            swap = rightchild;
        }
        if(swap != root){
            auto t = input[root];
            input[root] = input[swap];
            input[swap] = t;
            root = swap;
        }else{
            break;
        }
    }
}

void heapsiftup(alias compare = DefaultSortCompare, T)(
    auto ref T input, in size_t start, in size_t end
) if(canHeapSort!(compare, T)){
    size_t child = end - 1;
    while(child > start){
        immutable size_t parent = (child - 1) / 2;
        if(compare(input[parent], input[child])){
            auto t = input[parent];
            input[parent] = input[child];
            input[child] = t;
            child = parent;
        }else{
            break;
        }
    }
}



alias heapsort = eagerheapsort;



/// Sorts an input using heap sort.
/// https://en.wikipedia.org/wiki/Heapsort
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: Yes.
/// Sorting is adaptive: No.
/// Sorting is stable: No.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Favorable worst-case runtime of O(n log n).
/// Why not to use it:
///   Slower in practice than quicksort.
auto eagerheapsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canHeapSort!(compare, T)
){
    if(input.length){
        heapifydown!compare(input);
        size_t end = input.length - 1;
        while(end > 0){
            auto t = input[end];
            input[end] = input[0];
            input[0] = t;
            heapsiftdown!compare(input, 0, end);
            end--;
        }
    }
    return input;
}



/// Sorts an input lazily using a modified heap sort.
/// https://en.wikipedia.org/wiki/Heapsort
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: No.
/// Sorting is adaptive: No.
/// Sorting is stable: No.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Sorting is done lazily, and is relatively efficient.
/// Why not to use it:
///   Slower in practice than quicksort.
auto lazyheapsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canHeapSort!(compare, T)
){
    return HeapSortRange!(compare, T)(input);
}

/// Type returned by `lazyheapsort`.
/// Normally, for heapsort, the root of the heap formed for the input
/// is located at the leftmost index. As values are popped from the heap
/// from greatest to least, they are swapped to positions beginning at
/// the end of the input.
/// [heap] => [heap] [sorted largest values] => [sorted values]
/// In order to support lazy evaluation of this sort, the heap formed by
/// this algorithm is essentially reversed: the root is located at the
/// rightmost index of the input, values are popped from least to
/// greatest, and they are swapped to positions starting at the beginning
/// of the input.
/// [reversed heap] => [sorted smallest values] [reversed heap] => [sorted values]
struct HeapSortRange(alias compare, Source) if(canHeapSort!(compare, Source)){
    Source source;
    size_t index = 0;
    
    this(Source source){
        this.source = source;
        if(this.source.length > 1){
            this.heapify();
            auto t = this.source[0];
            this.source[0] = this.source[this.source.length - 1];
            this.source[this.source.length - 1] = t;
            this.heapsiftdown(0, this.source.length - 1);
        }
    }
    this(Source source, size_t index){
        this.source = source;
        this.index = index;
    }
    
    @property bool empty() const{
        return this.index >= this.source.length;
    }
    @property auto length(){
        return this.source.length;
    }
    @property auto remaining() const{
        return this.source.length - this.index;
    }
    alias opDollar = length;
    
    @property auto front(){
        return this.source[this.index];
    }
    void popFront(){
        this.index++;
        if(this.index < this.source.length){
            auto t = this.source[this.index];
            this.source[this.index] = this.source[this.source.length - 1];
            this.source[this.source.length - 1] = t;
            this.heapsiftdown(0, this.source.length - 1 - index);  // ?
        }
    }
    
    static if(is(typeof({
        typeof(this)(this.source.dup, this.sortend);
    }))){
        @property typeof(this) save(){
            return typeof(this)(this.source.dup, this.sortend);
        }
    }
    
    /// Form the input into a reversed heap.
    void heapify(){
        size_t start = this.source.length / 2;
        while(start > 0){
            start--;
            this.heapsiftdown(start, this.source.length);
        }
    }
    void heapsiftdown(in size_t start, in size_t end){
        size_t idx(in size_t i){
            return this.source.length - 1 - i;
        }
        size_t root = start;
        while(true){
            immutable size_t leftchild = root * 2 + 1;
            immutable size_t rightchild = leftchild + 1;
            if(leftchild >= end) break;
            size_t swap = root;
            if(!compare(this.source[idx(swap)], this.source[idx(leftchild)])){
                swap = leftchild;
            }
            if(rightchild < end && !compare(this.source[idx(swap)], this.source[idx(rightchild)])){
                swap = rightchild;
            }
            if(swap != root){
                auto t = this.source[idx(root)];
                this.source[idx(root)] = this.source[idx(swap)];
                this.source[idx(swap)] = t;
                root = swap;
            }else{
                break;
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Heap sort", {
        tests("Eager", {
            testsort!eagerheapsort;
        });
        tests("Lazy", {
            testsort!lazyheapsort;
        });
    });
}
