module mach.range.recur;

private:

import std.traits : ReturnType;

public:



enum validRecurFunction(alias func) = (
    validRecurFunction!(ReturnType!func, func)
);

template validRecurFunction(Element, alias func){
    enum bool validRecurFunction = is(typeof((inout int = 0){
        Element element = func(Element.init);
    }));
}



/// Creates a range by repeatedly calling some function with the output of the
/// previous call as its arugment.
auto recur(alias func)() if(validRecurFunction!(func)){
    alias Element = ReturnType!func;
    return RecurRange!(func, Element)(Element.init);
}

/// ditto
auto recur(alias func, Element)(Element initial) if(validRecurFunction!(Element, func)){
    return RecurRange!(func, Element)(initial);
}



struct RecurRange(alias func, Element) if(validRecurFunction!(Element, func)){
    Element value;
    
    this(Element value){
        this.value = value;
    }
    
    enum bool empty = false;
    @property auto ref front() const{
        return this.value;
    }
    void popFront(){
        this.value = func(this.value);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.ends : head;
}
unittest{
    tests("Recur", {
        alias increment = (int n) => (n + 1);
        test(recur!increment.head(4).equals([0, 1, 2, 3]));
        test(recur!increment(10).head(4).equals([10, 11, 12, 13]));
    });
}
