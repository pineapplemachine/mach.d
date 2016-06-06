module mach.range.map.combined;

private:

import mach.range.map.plural : mapplural;
import mach.range.map.singular : mapsingular;
import mach.range.map.templates : canMap, AdjoinTransformations;

public:



template map(transformations...) if(transformations.length){
    alias transform = AdjoinTransformations!transformations;
    auto map(Iters...)(Iters iters) if(canMap!(transform, Iters)){
        static if(Iters.length == 1){
            return mapsingular!transform(iters[0]);
        }else{
            return mapplural!transform(iters);
        }
    }
}



version(unittest){
    private:
    import mach.traits : isTemplateOf;
    import mach.range.map.plural : MapPluralRange;
    import mach.range.map.singular : MapSingularRange;
}
unittest{
    alias twice = (n) => (n + n);
    alias sum = (a, b) => (a + b);
    auto inputa = [1, 2, 3];
    auto inputb = [4, 5, 6];
    auto singular = map!twice(inputa);
    auto plural = map!sum(inputa, inputb);
    static assert(isTemplateOf!(typeof(singular), MapSingularRange));
    static assert(isTemplateOf!(typeof(plural), MapPluralRange));
}
