module mach.range.zip;

private:

import mach.types : tuple;
import mach.meta : varmap;
import mach.range.asrange : asrange;
import mach.range.map.plural : mapplural, canMapPlural;

public:



enum canZip(T...) = canMapPlural!(tuple, T);

auto zip(Iters...)(auto ref Iters iters) if(canZip!Iters){
    return mapplural!tuple(varmap!(e => e.asrange)(iters).expand);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Zip", {
        auto inputa = ['h', 'a', 'y'];
        auto inputb = ['o', 'r', 'o'];
        auto inputc = ['w', 'e', 'u'];
        auto range = zip(inputa, inputb, inputc);
        testeq(range[0], tuple('h', 'o', 'w'));
        testeq(range[1], tuple('a', 'r', 'e'));
        testeq(range[2], tuple('y', 'o', 'u'));
    });
}
