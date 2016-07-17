module mach.range.include;

private:

import mach.range.filter : filter;
import mach.range.logical : any, none;

public:



alias DefaultIncludePredicate = (a, b) => (a == b);



auto include(alias pred = DefaultIncludePredicate, Iter, Element)(
    auto ref Iter iter, Element[] inclusions...
){
    return iter.filter!(a => inclusions.any!(b => pred(a, b)));
}

auto exclude(alias pred = DefaultIncludePredicate, Iter, Element)(
    auto ref Iter iter, Element[] exclusions...
){
    return iter.filter!(a => exclusions.none!(b => pred(a, b)));
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Include and exclude", {
        auto input = "hello world";
        tests("Include", {
            test(input.include("eo").equals("eoo"));
            test(input.include('e', 'o').equals("eoo"));
            test(input.include('x').equals(""));
        });
        tests("Exclude", {
            test(input.exclude("eo").equals("hll wrld"));
            test(input.exclude('e', 'o').equals("hll wrld"));
            test(input.exclude('x').equals("hello world"));
        });
    });
}
