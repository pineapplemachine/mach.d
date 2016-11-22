module mach.range.sort.insertionsort;

private:

import mach.range.sort.common;

public:



alias insertionsort = linearinsertionsort;



/// Sorts an input using insertion sort.
/// The input is mutated.
/// The input must be finite, of known length, and allow random access
/// reading and writing.
/// The sorting is stable; i.e. equivalent elements retain their original order.
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// https://en.wikipedia.org/wiki/Insertion_sort
auto linearinsertionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canBoundedRandomAccessSort!(compare, T)
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
/// Differs from linear insertion sort in that it requires fewer comparisons,
/// at the cost of slightly increased overhead.
/// The input is mutated.
/// The input must be finite, of known length, and allow random access
/// reading and writing.
/// The sorting is stable; i.e. equivalent elements retain their original order.
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// https://en.wikipedia.org/wiki/Insertion_sort
/// http://jeffreystedfast.blogspot.com/2007/02/binary-insertion-sort.html
auto binaryinsertionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canBoundedRandomAccessSort!(compare, T)
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
