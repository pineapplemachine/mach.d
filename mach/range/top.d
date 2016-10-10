module mach.range.top;

private:

import std.functional : not;
import mach.types : Rebindable;
import mach.traits : ElementType, isFiniteIterable, isPredicate;
import mach.collect : SortedList;

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



template top(alias compare = DefaultTopComparison){
    auto top(Iter)(
        auto ref Iter iter
    ) if(canTop!(Iter, compare)){
        alias Element = ElementType!Iter;
        bool first = true;
        Rebindable!Element top;
        foreach(element; iter){
            if(first || compare(element, top)){
                top = element;
                first = false;
            }
        }
        return cast(Element) top;
    }
    auto top(Iter)(
        auto ref Iter iter, size_t count
    ) if(canTop!(Iter, compare)){
        SortedList!(ElementType!Iter, compare) list;
        foreach(element; iter){
            list.insert(element);
            if(list.length > count) list.removeback();
        }
        return list;
    }
}

template bottom(alias compare = DefaultTopComparison){
    auto bottom(Iter)(
        auto ref Iter iter
    ) if(canTop!(Iter, compare)){
        return top!(not!compare)(iter);
    }
    auto bottom(Iter)(
        auto ref Iter iter, size_t count
    ) if(canTop!(Iter, compare)){
        return top!(not!compare)(iter, count);
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Top and bottom", {
        tests("Top", {
            auto input = [3, 2, 4, 1, 5];
            testeq(input.top, 5);
            test!equals(input.top(3), [5, 4, 3]);
        });
        tests("Bottom", {
            auto input = [3, 2, 4, 1, 5];
            testeq(input.bottom, 1);
            test!equals(input.bottom(3), [1, 2, 3]);
        });
        tests("Const input", {
            const(const(int)[]) input = [0, 1, 2, 3];
            testeq(input.top, 3);
            test!equals(input.top(2), [3, 2]);
        }); 
    });
}
