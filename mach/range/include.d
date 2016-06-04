module mach.range.include;

private:

import mach.range.filter : filter;
import mach.range.contains : contains;

public:



auto include(Iter, Element)(Iter iter, Element[] inclusions...){
    return iter.filter!((element) => (inclusions.contains(element)));
}

auto exclude(Iter, Element)(Iter iter, Element[] exclusions...){
    return iter.filter!((element) => (!exclusions.contains(element)));
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

