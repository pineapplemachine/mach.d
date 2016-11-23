module mach.range.sort.selectionsort;

private:

import mach.traits : ElementType, isSavingRange, isFiniteIterable;
import mach.range.asrange : asrange, validAsSavingRange;
import mach.range.sort.common;

public:



alias selectionsort = eagerselectionsort;



/// Determine whether a type is able to be eagerly selection sorted.
alias canEagerSelectionSort = canBoundedRandomAccessSort;



template canLazySelectionSort(T){
    enum bool canLazySelectionSort = isFiniteIterable!T && validAsSavingRange!T;
}

template canLazySelectionSort(alias compare, T){
    static if(canLazySelectionSort!T){
        enum bool canLazySelectionSort = is(typeof({
            if(compare(ElementType!T.init, ElementType!T.init)){}
        }));
    }else{
        enum bool canLazySelectionSort = false;
    }
}



template canLazySelectionSortRange(T){
    enum bool canLazySelectionSortRange = isFiniteIterable!T && isSavingRange!T;
}

template canLazySelectionSortRange(alias compare, T){
    static if(canLazySelectionSortRange!T){
        enum bool canLazySelectionSortRange = is(typeof({
            if(compare(ElementType!T.init, ElementType!T.init)){}
        }));
    }else{
        enum bool canLazySelectionSortRange = false;
    }
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
    size_t o = 0;
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
    import mach.io.log;
    return input;
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
auto lazyselectionsort(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canLazySelectionSort!(compare, T)
){
    auto range = input.asrange;
    return SelectionSortRange!(compare, typeof(range))(range);
}



/// Type for lazily computing a range's values sorted according to a given
/// comparison function.
struct SelectionSortRange(alias compare, Range) if(
    canLazySelectionSortRange!(compare, Range)
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
    
    @property bool empty() const{
        return this.currentvalues.length == 0;
    }
    @property auto length(){
        return this.source.length;
    }
    alias opDollar = length;
    
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
            this.search();
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
    void search(){
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
            testsort!lazyselectionsort;
            teststablesort!lazyselectionsort;
        });
    });
}
