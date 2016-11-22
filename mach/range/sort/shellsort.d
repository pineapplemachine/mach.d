module mach.range.sort.shellsort;

private:

import mach.range.sort.common;

public:



/// Sorts an input using shellsort.
/// The input is mutated.
/// The input must be finite, of known length, and allow random access
/// reading and writing.
/// The sorting is stable; i.e. equivalent elements retain their original order.
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// https://en.wikipedia.org/wiki/Shellsort
/// https://www.tutorialspoint.com/data_structures_algorithms/shell_sort_algorithm.htm
auto shellsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canBoundedRandomAccessSort!(compare, T)
){
    immutable l3 = input.length / 3;
    size_t interval = 1;
    while(interval < l3){
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
        teststablesort!shellsort;
    });
}
