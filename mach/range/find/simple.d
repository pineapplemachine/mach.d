module mach.range.find.simple;

private:

import mach.range.find.findeager;
import mach.range.find.findelement;
import mach.range.find.findlazy;
import mach.range.find.templates;

public:



enum canFindAllIterable(alias pred, Index, Iter, Subject) = (
    canFindAllEager!(pred, Index, Iter, Subject) ||
    canFindAllLazy!(pred, Index, Iter, Subject)
);

enum canFindAll(alias pred, Index, Iter, Subject) = (
    canFindAllIterable!(pred, Index, Iter, Subject)
);
enum canFindAll(alias pred, Index, Iter) = (
    canFindAllElements!(pred, Index, Iter)
);
enum canFindAll(Index, Iter, Subject) = (
    canFindAllElements!((e => e == Subject.init), Index, Iter) ||
    canFindAllIterable!(DefaultFindPredicate, Index, Iter, Subject)
);



auto findalliter(
    alias pred = DefaultFindPredicate, Index = DefaultFindIndex, Iter, Subject
)(Iter iter, Subject subject) if(
    canFindAllIterable!(pred, Index, Iter, Subject)
){
    static if(canFindAllLazy!(DefaultFindPredicate, Index, Iter, Subject)){
        return findalliterlazy!(DefaultFindPredicate, Index, Iter, Subject)(
            iter, subject
        );
    }else{
        return findallitereager!(DefaultFindPredicate, Index, Iter, Subject)(
            iter, subject
        );
    }
}



auto findfirst(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    return findfirstelement!(pred, Index, Iter)(iter);
}

auto findlast(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, false)){
    return findlastelement!(pred, Index, Iter)(iter);
}

auto findall(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindAllElements!(pred, Index, Iter)){
    static if(canFindAllElementsLazy!(pred, Index, Iter)){
        return findallelementslazy!(pred, Index, Iter)(iter);
    }else{
        return findallelementseager!(pred, Index, Iter)(iter);
    }
}



auto findfirst(Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(
    canFindElementEager!(e => e == subject, Index, Iter, true) ||
    canFindIterable!(DefaultFindPredicate, Index, Iter, Subject, true)
){
    static if(canFindElementEager!(e => e == subject, Index, Iter, true)){
        return findfirstelement!(e => e == subject, Index, Iter)(iter);
    }else{
        return findfirstiter!(DefaultFindPredicate, Index, Iter, Subject)(iter, subject);
    }
}

auto findlast(Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(
    canFindElementEager!(e => e == subject, Index, Iter, false) ||
    canFindIterable!(DefaultFindPredicate, Index, Iter, Subject, false)
){
    static if(canFindElementEager!(e => e == subject, Index, Iter, false)){
        return findlastelement!(e => e == subject, Index, Iter)(iter);
    }else{
        return findlastiter!(DefaultFindPredicate, Index, Iter, Subject)(iter, subject);
    }
}

auto findall(Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(
    canFindAllElements!(e => e == subject, Index, Iter) ||
    canFindAllIterable!(DefaultFindPredicate, Index, Iter, Subject)
){
    static if(canFindAllElements!(e => e == subject, Index, Iter)){
        return findallelements!(e => e == subject, Index, Iter)(iter);
    }else{
        return findalliter!(DefaultFindPredicate, Index, Iter, Subject)(iter, subject);
    }
}



auto findfirst(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindIterable!(DefaultFindPredicate, Index, Iter, Subject, true)){
    return findfirstiter!(pred, Index, Iter)(iter, subject);
}

auto findlast(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindIterable!(DefaultFindPredicate, Index, Iter, Subject, false)){
    return findlastiter!(pred, Index, Iter)(iter, subject);
}

auto findall(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindAllIterable!(pred, Index, Iter, Subject)){
    return findalliter!(pred, Index, Iter)(iter, subject);
}



alias find = findfirst;



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.asarray : asarray;
}
unittest{
    tests("Find", {
        tests("Element", {
            tests("With predicate", {
                alias isL = (e) => (e == 'l');
                testeq("First", "hello".findfirst!isL.index, 2);
                testeq("Last", "hello".findlast!isL.index, 3);
                tests("All", {
                    auto result = "hello".findall!isL.asarray(2);
                    testeq(result[0].index, 2);
                    testeq(result[1].index, 3);
                });
            });
            tests("Default predicate", {
                testeq("First", "hello".findfirst('l').index, 2);
                testeq("Last", "hello".findlast('l').index, 3);
                tests("All", {
                    auto result = "hello".findall('l').asarray(2);
                    testeq(result[0].index, 2);
                    testeq(result[1].index, 3);
                });
            });
        });
        tests("Iterable", {
            tests("With predicate", {
                alias eq = (a, b) => (a == b);
                testeq("First", "hihi".findfirst!eq("hi").index, 0);
                testeq("Last", "hihi".findlast!eq("hi").index, 2);
                tests("All", {
                    auto result = "hihi".findall!eq("hi").asarray(2);
                    testeq(result[0].index, 0);
                    testeq(result[1].index, 2);
                });
            });
            tests("Default predicate", {
                testeq("First", "hihi".findfirst("hi").index, 0);
                testeq("Last", "hihi".findlast("hi").index, 2);
                tests("All", {
                    auto result = "hihi".findall("hi").asarray(2);
                    testeq(result[0].index, 0);
                    testeq(result[1].index, 2);
                });
            });
        });
    });
}
