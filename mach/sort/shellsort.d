module mach.sort.shellsort;

private:

import mach.sort.common;

public:



/// Determine whether a type is able to be shell sorted.
alias canShellSort = canBoundedRandomAccessSort;



/// Sorts an input using shell sort.
/// https://en.wikipedia.org/wiki/Shellsort
/// https://www.tutorialspoint.com/data_structures_algorithms/shell_sort_algorithm.htm
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: Yes.
/// Sorting is adaptive: Yes.
/// Sorting is stable: No.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Does not require recursive calls.
/// Why not to use it:
///   Comparatively less efficient than quicksort.
auto shellsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canShellSort!(compare, T)
){
    immutable l3 = input.length / 3;
    size_t interval = 1;
    while(interval < l3){ // TODO: There are probably more optimal intervals than this
        interval = interval * 3 + 1;
    }
    while(interval > 0){
        for(size_t outer = interval; outer < input.length; outer++){
            auto x = input[outer];
            size_t inner = outer;
            while(inner > interval - 1 && compare(x, input[inner - interval])){
                input[inner] = input[inner - interval];
                inner -= interval;
            }
            input[inner] = x;
        }
        interval = (interval - 1) / 3;
    }
    return input;
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Shell sort", {
        testsort!shellsort;
        //teststablesort!shellsort;
    });
}
