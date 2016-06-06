module mach.range.associate;

private:

import std.traits : Unqual;
import std.typecons : tuple;
import mach.traits : isIterable, canHash, ElementType, isTuple;

public:



template canAssociate(Iter){
    static if(isIterable!Iter){
        alias Element = ElementType!Iter;
        static if(isTuple!Element && Element.length == 2){
            enum bool canAssociate = canHash!(typeof(Element[0]));
        }else{
            enum bool canAssociate = false;
        }
    }else{
        enum bool canAssociate = false;
    }
}

template canAssociate(Iter, Key){
    static if(isIterable!Iter){
        enum bool canAssociate = canHash!Key;
    }else{
        enum bool canAssociate = false;
    }
}

template canAssociateTransformed(alias transform, Iter){
    import mach.range.map : canMap;
    static if(canMap!(transform, Iter)){
        enum bool canAssociateTransformed = canAssociate!(
            Iter, typeof(transform(ElementType!Iter.init))
        );
    }else{
        enum bool canAssociateTransformed = false;
    }
}

template canAssociateIterables(Keys, Values){
    static if(isIterable!Keys && isIterable!Values){
        enum bool canAssociateIterables = canHash!(ElementType!Keys);
    }else{
        enum bool canAssociateIterables = false;
    }
}



/// Create an associative array using keys and values from two separate ranges.
/// When plural is false, every key maps to the first element associated with
/// that key. When plural is true, every key maps to an array of elements
/// associated with that key.
auto associate(bool plural = false, Keys, Values)(Keys keys, Values values) if(
    canAssociateIterables!(Keys, Values)
){
    import mach.range.zip : zip;
    return associate!plural(zip(keys, values));
}

/// Create an associative array, mapping to key, value from an input iterable.
auto associate(alias transform, bool plural = false, Iter)(Iter iter) if(
    canAssociateTransformed!(transform, Iter)
){
    import mach.range.map : map;
    return associate!plural(iter.map!transform);
}

/// Create an associative array from an iterable containing key, value tuples.
auto associate(bool plural = false, Iter)(Iter iter) if(canAssociate!Iter){
    alias Element = ElementType!Iter;
    return associate!(typeof(Element[0]), typeof(Element[1]), plural)(iter);
}

/// ditto
auto associate(Key, Value, bool plural = false, Iter)(Iter iter) if(canAssociate!(Iter, Key)){
    static if(!plural){
        Unqual!Value[Key] array;
        foreach(key, value; iter){
            if(key !in array) array[key] = value;
        }
        return array;
    }else{
        Unqual!Value[][Key] array;
        foreach(key, value; iter){
            if(key in array) array[key] ~= value;
            else array[key] = [value];
        }
        return array;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.enumerate : enumerate;
}
unittest{
    tests("Associate", {
        auto inputa = [0, 0, 1, 1, 2, 2];
        auto inputb = [0, 1, 2, 3, 4, 5];
        tests("Singular", {
            testeq(
                associate!false(inputa, inputb),
                cast(const int[const int]) [0:0, 1:2, 2:4]
            );
            testeq("Enumerate",
                [10, 11, 12].enumerate.associate!false,
                cast(const int[uint]) [0:10, 1:11, 2:12]
            );
        });
        tests("Plural", {
            testeq(
                associate!true(inputa, inputb),
                cast(const int[][const int]) [0:[0,1], 1:[2,3], 2:[4,5]]
            );
        });
    });
}
