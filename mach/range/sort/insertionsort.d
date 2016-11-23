module mach.range.sort.insertionsort;

private:

import mach.traits : ElementType, hasNumericLength, isFiniteIterable;
import mach.range.sort.common;

public:



/// Determine whether a type is able to be insertion sorted.
alias canInsertionSort = canBoundedRandomAccessSort;



template canCopyInsertionSort(T){
    enum bool canCopyInsertionSort = isFiniteIterable!T;
}

template canCopyInsertionSort(alias compare, T){
    enum bool canCopyInsertionSort = (
        canCopyInsertionSort!T && isSortComparison!(compare, T)
    );
}



alias insertionsort = linearinsertionsort;



/// Sorts an input using insertion sort.
/// https://en.wikipedia.org/wiki/Insertion_sort
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: Yes.
/// Sorting is adaptive: Yes.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Relatively efficient for small data sets, by virtue of its simplicity.
/// Why not to use it:
///   Makes many writes, especially compared to the similar selection sort.
auto linearinsertionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canInsertionSort!(compare, T)
){
    for(size_t i = 1; i < input.length; i++){
        auto x = input[i];
        size_t j = i;
        while(j > 0 && compare(x, input[j - 1])){
            input[j] = input[j - 1];
            j--;
        }
        input[j] = x;
    }
    return input;
}



/// Sorts an input using binary insertion sort.
/// https://en.wikipedia.org/wiki/Insertion_sort
/// http://jeffreystedfast.blogspot.com/2007/02/binary-insertion-sort.html
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: Yes.
/// Sorting is adaptive: Yes.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Performs fewer comparisons than a linear insertion sort.
/// Why not to use it:
///   Demands some additional overhead relative to linear insertion sort.
auto binaryinsertionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canInsertionSort!(compare, T)
){
    for(size_t i = 1; i < input.length; i++){
        size_t low = 0;
        size_t high = i;
        size_t mid = i / 2;
        while(true){
            if(!compare(input[i], input[mid])){
                low = mid + 1;
            }else{
                high = mid;
            }
            mid = low + ((high - low) / 2);
            if(low >= high) break;
        }
        if(mid < i){
            auto x = input[i];
            size_t j = i;
            while(j > mid){
                input[j] = input[j - 1];
                j--;
            }
            input[j] = x;
        }
    }
    return input;
}



/// Sorts an input using a modified insertion sort.
/// https://en.wikipedia.org/wiki/Insertion_sort
/// 
/// Input requirements: Finite (more performant when length is known)
/// Input is mutated: No.
/// Sorting is eager: Yes.
/// Sorting is adaptive: Yes.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   The only restriction upon input is that it is a finite iterable.
///   The input is not modified.
/// Why not to use it:
///   Allocates additional memory.
///   Not especially efficient.
auto copyinsertionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canCopyInsertionSort!(compare, T)
){
    ElementType!T[] array;
    static if(hasNumericLength!T){
        array.reserve(input.length);
    }
    foreach(item; input){
        if(array.length == 0 || !compare(item, array[$ - 1])){
            array ~= item;
        }else{
            // Find the last element not less than the new one
            size_t i = array.length - 1;
            while(i > 0){
                if(!compare(item, array[i - 1])) break;
                i--;
            }
            // Shift elements that should follow the new insertion
            immutable jlimit = array.length;
            array.length += 1;
            for(size_t j = jlimit; j > i; j--){
                array[j] = array[j - 1];
            }
            // Place the new element where it belongs
            array[i] = item;
        }
    }
    return array;
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Insertion sort", {
        tests("Linear", {
            testsort!linearinsertionsort;
            teststablesort!linearinsertionsort;
        });
        tests("Binary", {
            testsort!binaryinsertionsort;
            teststablesort!binaryinsertionsort;
        });
        tests("Copy", {
            testsort!copyinsertionsort;
            teststablesort!copyinsertionsort;
            testcopysort!copyinsertionsort;
        });
    });
}
