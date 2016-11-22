module mach.range.sort.mergesort;

private:

import mach.traits : ElementType;
import mach.range.sort.common;

public:



/// Determine whether a type is able to be merge-sorted.
alias canMergeSort = canBoundedRandomAccessSort;



/// Sorts an input using mergesort.
/// The input is mutated.
/// The input must be finite, of known length, and allow random access
/// reading and writing.
/// The sorting is stable; i.e. equivalent elements retain their original order.
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// https://en.wikipedia.org/wiki/Merge_sort
/// https://www.tutorialspoint.com/data_structures_algorithms/merge_sort_program_in_c.htm
auto mergesort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canMergeSort!(compare, T)
){
    alias E = ElementType!T;
    E[] buffer = new E[input.length];
    
    void sort(in size_t begin, in size_t end){
        if(end - begin >= 2){
            immutable middle = (end + begin) / 2;
            sort(begin, middle);
            sort(middle, end);
            size_t i = begin;
            size_t j = middle;
            size_t k = begin;
            while(i < middle && j < end){
                buffer[k++] = compare(input[j], input[i]) ? input[j++] : input[i++];
            }
            while(i < middle){
                buffer[k++] = input[i++];
            }
            while(j < end){
                buffer[k++] = input[j++];
            }
            for(size_t l = begin; l < end; l++){
                input[l] = buffer[l];
            }
        }
    }
    
    sort(0, input.length);
    return input;
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Merge sort", {
        testsort!mergesort;
        teststablesort!mergesort;
    });
}
