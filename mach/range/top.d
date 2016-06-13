module mach.range.top;

private:

import mach.traits : ElementType, isFiniteIterable, isPredicate;
import mach.collect : LinkedList;

public:



template canTop(Iter, alias compare){
    static if(isFiniteIterable!Iter){
        enum bool canTop = isPredicate!(
            compare, ElementType!Iter, ElementType!Iter
        );
    }else{
        enum bool canTop = false;
    }
}

alias DefaultTopComparison = (a, b) => (a > b);



/// Get the top-most element given a comparison function.
auto top(alias compare = DefaultTopComparison, Iter)(
    auto ref Iter iter
) if(canTop!(Iter, compare)){
    alias Element = ElementType!Iter;
    bool first = true;
    Element top;
    foreach(element; iter){
        if(first || compare(element, top)){
            top = element;
            first = false;
        }
    }
    return top;
}

/// Get the n top-most elements given a comparison function.
auto top(alias compare = DefaultTopComparison, Iter)(
    auto ref Iter iter, size_t count
) if(canTop!(Iter, compare)){
    alias Element = ElementType!Iter;
    auto list = new LinkedList!Element;
    foreach(element; iter){
        list.insertsorted((a, b) => (compare(a, b)), element);
        if(list.length > count) list.removelast();
    }
    return list;
}



/// Get the bottom-most element given a comparison function.
auto bottom(alias compare = (a, b) => (a > b), Iter)(
    auto ref Iter iter
) if(canTop!(Iter, compare)){
    return top!((a, b) => (compare(b, a)))(iter);
}

/// Get the n bottom-most elements given a comparison function.
auto bottom(alias compare = (a, b) => (a > b), Iter)(
    auto ref Iter iter, size_t count
) if(canTop!(Iter, compare)){
    return top!((a, b) => (compare(b, a)))(iter, count);
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Top and bottom", {
        auto input = [3, 2, 4, 1, 5];
        tests("Top", {
            testeq(input.top, 5);
            test(input.top(3).equals([5, 4, 3]));
        });
        tests("Bottom", {
            testeq(input.bottom, 1);
            test(input.bottom(3).equals([1, 2, 3]));
        });
    });
}
