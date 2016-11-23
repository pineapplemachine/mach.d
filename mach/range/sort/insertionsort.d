module mach.range.sort.insertionsort;

private:

import mach.range.sort.common;

public:



/// Determine whether a type is able to be insertion sorted.
alias canInsertionSort = canBoundedRandomAccessSort;



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
    });
}
