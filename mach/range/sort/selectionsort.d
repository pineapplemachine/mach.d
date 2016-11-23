module mach.range.sort.selectionsort;

private:

import mach.traits : ElementType, isSavingRange, isFiniteIterable, hasNumericLength;
import mach.range.asrange : asrange, validAsSavingRange;
import mach.range.sort.common;

public:



alias selectionsort = eagerselectionsort;



/// Determine whether a type is able to be eagerly selection sorted.
alias canEagerSelectionSort = canBoundedRandomAccessSort;

alias canLazySelectionSort = canBoundedRandomAccessSort;



template canLazyCopySelectionSort(T){
    enum bool canLazyCopySelectionSort = isFiniteIterable!T && validAsSavingRange!T;
}

template canLazyCopySelectionSort(alias compare, T){
    enum bool canLazyCopySelectionSort = (
        canLazyCopySelectionSort!T && isSortComparison!(compare, T)
    );
}



template canLazyCopySelectionSortRange(T){
    enum bool canLazyCopySelectionSortRange = isFiniteIterable!T && isSavingRange!T;
}

template canLazyCopySelectionSortRange(alias compare, T){
    enum bool canLazyCopySelectionSortRange = (
        canLazyCopySelectionSortRange!T && isSortComparison!(compare, T)
    );
}



/// Sorts an input using selection sort.
/// https://en.wikipedia.org/wiki/Selection_sort
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: Yes.
/// Sorting is adaptive: No.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Requires relatively few write operations.
/// Why not to use it:
///   Inefficient: O(n^2) complexity.
auto eagerselectionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canEagerSelectionSort!(compare, T)
){
    immutable size_t ilimit = cast(size_t) input.length;
    immutable size_t jlimit = ilimit - 1;
    for(size_t j = 0; j < jlimit; j++){
        size_t min = j;
        for(size_t i = j + 1; i < ilimit; i++){
            if(compare(input[i], input[min])){
                min = i;
            }
        }
        if(min != j){
            auto t = input[j];
            input[j] = input[min];
            input[min] = t;
        }
    }
    return input;
}



/// Sorts an input lazily using a modified selection sort.
/// https://en.wikipedia.org/wiki/Selection_sort
/// 
/// Input requirements: Finite, known length, random access reads & writes.
/// Input is mutated: Yes.
/// Sorting is eager: No.
/// Sorting is adaptive: No.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Lazily evaluated.
/// Why not to use it:
///   Inefficient: O(n^2) complexity.
auto lazyselectionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canLazySelectionSort!(compare, T)
){
    auto range = input.asrange;
    return SelectionSortRange!(compare, typeof(range))(range);
}

/// Type returned by `lazyselectionsort`.
struct SelectionSortRange(alias compare, Source) if(
    canLazySelectionSort!(compare, Source)
){
    Source source;
    size_t index = 0;
    
    this(Source source){
        this.source = source;
        this.select(0);
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
    alias opDollar = length;
    
    static if(is(typeof({
        typeof(this)(this.source.dup, this.index);
    }))){
        @property typeof(this) save(){
            return typeof(this)(this.source.dup, this.index);
        }
    }
    
    @property auto front(){
        return this.source[this.index];
    }
    void popFront(){
        this.index++;
        this.select(this.index);
    }
    
    void select(in size_t start){
        size_t min = start;
        for(size_t i = start + 1; i < this.source.length; i++){
            if(compare(this.source[i], this.source[min])){
                min = i;
            }
        }
        if(min != start){
            auto t = this.source[start];
            this.source[start] = this.source[min];
            this.source[min] = t;
        }
    }
}



/// Sorts an input lazily using a modified selection sort.
/// https://en.wikipedia.org/wiki/Selection_sort
/// 
/// Input requirements: Finite, valid as saving range.
/// Input is mutated: No.
/// Sorting is eager: No.
/// Sorting is adaptive: No.
/// Sorting is stable: Yes.
/// 
/// The inputted comparison function should return true when the first input
/// must precede the second in the sorted output and false otherwise.
/// 
/// Why to use it:
///   Lazily evaluated.
///   Does not modify the input.
/// Why not to use it:
///   Inefficient: O(n^2) complexity.
auto lazycopyselectionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canLazyCopySelectionSort!(compare, T)
){
    auto range = input.asrange;
    return CopySelectionSortRange!(compare, typeof(range))(range);
}

/// Type returned by `lazycopyselectionsort`.
struct CopySelectionSortRange(alias compare, Range) if(
    canLazyCopySelectionSortRange!(compare, Range)
){
    alias Element = ElementType!Range;
    
    Range source;
    Element[] currentvalues;
    size_t valuesindex = 0;
    
    this(Range source){
        this.source = source;
        this.initialize();
    }
    this(Range source, Element[] currentvalues, size_t valuesindex){
        this.source = source;
        this.currentvalues = currentvalues;
        this.valuesindex = valuesindex;
    }
    
    static if(isFiniteIterable!Range){
        @property bool empty() const{
            return this.currentvalues.length == 0;
        }
    }else{
        enum bool empty = false;
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length;
        }
        alias opDollar = length;
    }
    
    @property typeof(this) save(){
        return typeof(this)(
            this.source.save(),
            this.currentvalues.dup,
            this.valuesindex
        );
    }
    
    @property auto front(){
        return this.currentvalues[this.valuesindex];
    }
    void popFront(){
        this.valuesindex++;
        if(this.valuesindex >= this.currentvalues.length){
            this.select();
        }
    }
    
    void initialize(){
        foreach(item; this.source.save()){
            if(this.currentvalues.length == 0 || compare(item, this.currentvalues[0])){
                this.currentvalues = [item];
            }else if(!compare(this.currentvalues[0], item)){
                this.currentvalues ~= item;
            }
        }
    }
    void select(){
        // Find all items that follow this and do not follow each other
        auto lowerbound = this.currentvalues[0];
        // Reset the list of current values
        this.currentvalues.length = 0;
        this.valuesindex = 0;
        // Search for the new values
        foreach(item; this.source.save()){
            if(compare(lowerbound, item)){
                if(this.currentvalues.length == 0 || compare(item, this.currentvalues[0])){
                    this.currentvalues = [item];
                }else if(!compare(this.currentvalues[0], item)){
                    this.currentvalues ~= item;
                }
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Selection sort", {
        tests("Eager", {
            testsort!eagerselectionsort;
            teststablesort!eagerselectionsort; // TODO: This IS stable, right?
        });
        tests("Lazy", {
            tests("Mutating", {
                testsort!lazyselectionsort;
                teststablesort!lazyselectionsort;
            });
            tests("Copy", {
                testsort!lazycopyselectionsort;
                teststablesort!lazycopyselectionsort;
                testcopysort!lazycopyselectionsort;
            });
        });
    });
}
