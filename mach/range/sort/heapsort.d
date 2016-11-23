module mach.range.sort.heapsort;

private:

//import mach.traits : ElementType, hasNumericLength, isFiniteIterable;
import mach.range.sort.common;

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
        size_t leftchild = root * 2 + 1;
        size_t rightchild = leftchild + 1;
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
auto heapsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
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



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Heap sort", {
        testsort!heapsort;
    });
}
