module mach.range.associate;

private:

import mach.types : tuple;
import mach.traits : Unqual, isIterable, canHash, ElementType;
import mach.range.map : map;
import mach.range.zip : zip;

public:



// TODO: canAssociate, canGroup, canDistribution templates



/// Vaguely like a reduction, but specialized for the construction of
/// associative arrays. Accepts one function to map the initial value
/// encountered for some key to a value to store in the array, and another
/// function to describe how the value in the array is mutated upon successive
/// encounters with the same key. This can be used, for example, to: First set
/// some counter to 1, then increment every time the key is encountered again;
/// to replace the previous value with the new one every time some key is
/// encountered; to construct a list of values associated with some key.
auto associate(alias initial, alias successive, Iter)(Iter iter){
    alias Key = typeof(ElementType!Iter[0]);
    alias Value = typeof(initial(ElementType!Iter[1].init));
    Unqual!Value[Key] array;
    foreach(key, value; iter){
        if(auto current = key in array){
            successive(current, value);
        }else{
            array[key] = initial(value);
        }
    }
    return array;
}

/// ditto
auto associate(alias initial, alias successive, Keys, Values)(
    Keys keys, Values values
){
    return associate!(initial, successive)(zip(keys, values));
}



/// Map keys to values one to one. The first value encountered for a key is the
/// one that is recorded in the associative array.
auto associate(Iter)(Iter iter){
    return associate!((first) => (first), (acc, next){})(iter);
}

/// ditto
auto associate(alias by, Iter)(Iter iter){
    return associate(iter.map!(by, e => e));
}

/// ditto
auto associate(Keys, Values)(Keys keys, Values values){
    return associate(zip(keys, values));
}



/// Map keys to values one to many. A list of values is recorded for every key.
auto aagroup(Iter)(Iter iter){
    return associate!((first) => ([first]), (acc, next){(*acc) ~= next;})(iter);
}

/// ditto
auto aagroup(alias by, Iter)(Iter iter){
    return aagroup(iter.map!(e => tuple(by(e), e)));
}

/// ditto
auto aagroup(Keys, Values)(Keys keys, Values values){
    return aagroup(zip(keys, values));
}



/// Records a count of the number of values encountered with some key, but does
/// not record the values themselves.
auto aadistribution(Iter)(Iter iter){
    return associate!((first) => (1), (acc, next){(*acc)++;})(
        iter.map!(e => e, e => e)
    );
}



version(unittest){
    private:
    import mach.test;
    import mach.range.enumerate : enumerate;
}
unittest{
    // TODO: More thorough unittests
    tests("Associations", {
        auto inputa = [0, 0, 1, 1, 2, 2];
        auto inputb = [0, 1, 2, 3, 4, 5];
        tests("Distribution", {
            testeq(
                inputa.aadistribution, [0:2, 1:2, 2:2]
            );
        });
        tests("Association", {
            testeq(
                associate(inputa, inputb), [0:0, 1:2, 2:4]
            );
            testeq(
                [10, 11, 12].enumerate.associate,
                [cast(size_t) 0:10, cast(size_t) 1:11, cast(size_t) 2:12]
            );
        });
        tests("Group", {
            testeq(
                aagroup(inputa, inputb), [0:[0,1], 1:[2,3], 2:[4,5]]
            );
        });
    });
}
