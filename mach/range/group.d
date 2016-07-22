module mach.range.group;

private:

import std.typecons : Tuple;
import mach.traits : ElementType, isElementPredicate, isFiniteIterable;
import mach.meta : All, Partial, Repeat;

public:



// TODO: Move this into mach.traits
private template AllElementPredicates(Iter, predicates...){
    static if(predicates.length == 0){
        enum bool AllElementPredicates = true;
    }else static if(predicates.length == 1){
        enum bool AllElementPredicates = isElementPredicate!(predicates[0], Iter);
    }else{
        enum bool AllElementPredicates = (
            AllElementPredicates!(Iter, predicates[0]) &&
            AllElementPredicates!(Iter, predicates[1 .. $])
        );
    }
}

template canGroup(Iter, predicates...){
    static if(predicates.length && isFiniteIterable!Iter){
        enum bool canGroup = AllElementPredicates!(Iter, predicates);
    }else{
        enum bool canGroup = false;
    }
}



template group(predicates...) if(predicates.length){
    auto group(Iter)(auto ref Iter iter) if(canGroup!(Iter, predicates)){
        alias Element = ElementType!Iter;
        alias Group = Element[];
        alias Groups = Tuple!(Repeat!(predicates.length, Group));
        Groups groups;
        foreach(element; iter){
            foreach(index, predicate; predicates){
                if(predicate(element)) groups[index] ~= element;
            }
        }
        return groups;
    }
}

template distribution(predicates...) if(predicates.length){
    auto distribution(Iter)(auto ref Iter iter) if(canGroup!(Iter, predicates)){
        alias Element = ElementType!Iter;
        alias Group = Element[];
        alias Groups = Tuple!(Repeat!(predicates.length, size_t));
        Groups groups;
        foreach(element; iter){
            foreach(index, predicate; predicates){
                if(predicate(element)) groups[index]++;
            }
        }
        return groups;
    }
}



unittest{
    // TODO
    //import std.stdio;
    //auto input = "hello world";
    //writeln(group!((e) => (e == 'h'), (e) => (e > 'e'))(input));
    //writeln(distribution!((e) => (e == 'h'), (e) => (e > 'e'))(input));
}

