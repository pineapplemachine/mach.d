module mach.range.recur;

private:

import std.traits : ReturnType;

public:



enum validRecurFunction(alias func) = (
    validRecurFunction!(ReturnType!func, func)
);

enum validRecurFunction(alias func, alias until) = (
    validRecurFunction!(ReturnType!func, func, until)
);

template validRecurFunction(Element, alias func){
    enum bool validRecurFunction = is(typeof((inout int = 0){
        Element element = func(Element.init);
    }));
}

template validRecurFunction(Element, alias func, alias until){
    enum bool validRecurFunction = is(typeof((inout int = 0){
        Element element = func(Element.init);
        auto empty = until(element);
        if(empty){}
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

/// ditto
auto recur(alias func, alias until)() if(validRecurFunction!(func, until)){
    alias Element = ReturnType!func;
    return RecurUntilRange!(func, until, Element)(Element.init);
}

/// ditto
auto recur(alias func, alias until, Element)(Element initial) if(
    validRecurFunction!(Element, func, until)
){
    return RecurUntilRange!(func, until, Element)(initial);
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

struct RecurUntilRange(alias func, alias until, Element) if(validRecurFunction!(Element, func, until)){
    Element value;
    
    this(Element value){
        this.value = value;
    }
    
    @property bool empty() const{
        return until(this.front);
    }
    @property auto ref front() const{
        return this.value;
    }
    void popFront() in{
        assert(!this.empty);
    }body{
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
    tests("Recur until", {
        alias collatzfunc = (in uint n) => (n % 2 == 0 ? n / 2 : n * 3 + 1);
        alias collatzuntil = (in n) => (n <= 1);
        auto collatz = (uint n) => (recur!(collatzfunc, collatzuntil)(n));
        test(collatz(5).equals([5, 16, 8, 4, 2]));
        test(collatz(6).equals([6, 3, 10, 5, 16, 8, 4, 2]));
    });
}
