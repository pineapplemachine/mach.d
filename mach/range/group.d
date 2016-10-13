module mach.range.group;

private:

import mach.types : Tuple, tuple;
import mach.traits : ElementType, isElementPredicate, isFiniteIterable;
import mach.meta : All, Repeat;

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
    static if(isFiniteIterable!Iter){
        enum bool canGroup = AllElementPredicates!(Iter, predicates);
    }else{
        enum bool canGroup = false;
    }
}



/// Given some predicates and an iterable, return a tuple with each item
/// containing an array of all elements matching the corresponding predicate.
template group(predicates...){
    auto group(Iter)(auto ref Iter iter) if(canGroup!(Iter, predicates)){
        static if(predicates.length){
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
        }else{
            return tuple();
        }
    }
}

/// Given some predicates and an iterable, return a tuple with each item
/// containing a numeric count of elements matching the corresponding predicate.
template distribution(predicates...){
    auto distribution(Iter)(auto ref Iter iter) if(canGroup!(Iter, predicates)){
        static if(predicates.length){
            alias Groups = Tuple!(Repeat!(predicates.length, size_t));
            Groups groups;
            foreach(element; iter){
                foreach(index, predicate; predicates){
                    if(predicate(element)) groups[index]++;
                }
            }
            return groups;
        }else{
            return tuple();
        }
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Group", {
        auto input = [0, 1, 2, 3, 4, 5];
        // No predicates
        testeq(
            input.group!(), tuple()
        );
        // A predicate that matches nothing
        testeq(
            input.group!(e => e == 10), tuple(new int[0])
        );
        // One predicate matching one element
        testeq(
            input.group!(e => e == 0), tuple([0])
        );
        // A predicate matching multiple elements
        testeq(
            input.group!(e => e < 3), tuple([0, 1, 2])
        );
        // Multiple predicates
        testeq(
            input.group!(e => e % 2 == 0, e => e % 2 == 1),
            tuple([0, 2, 4], [1, 3, 5])
        );
    });
    tests("Distribution", {
        auto input = [0, 1, 2, 3, 4, 5];
        // No predicates
        testeq(
            input.distribution!(), tuple()
        );
        // A predicate that matches nothing
        testeq(
            input.distribution!(e => e == 10), tuple(0)
        );
        // One predicate matching one element
        testeq(
            input.distribution!(e => e == 0), tuple(1)
        );
        // A predicate matching multiple elements
        testeq(
            input.distribution!(e => e < 3), tuple(3)
        );
        // Multiple predicates
        testeq(
            input.distribution!(e => e % 2 == 0, e => e % 2 == 1),
            tuple(3, 3)
        );
    });
}
