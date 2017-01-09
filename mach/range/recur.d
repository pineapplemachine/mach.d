module mach.range.recur;

private:

import mach.types : Rebindable;

/++ Docs

The `recur` function can be used to generate a range from repeatedly applying
a function to its input, either infinitely or until the output satisfies a
predicate. When such a predicate is provided, `recur` allows specifying whether
that final, matching element should be included in the outputted range via
a template argument. Alternately, the `recuri` function can be used when the
matching element should be included in the output.

+/

unittest{ /// Example
    import mach.range.compareends : headis;
    auto range = 0.recur!(n => n + 1); // Repeatedly increment, starting at 0.
    assert(range.headis([0, 1, 2, 3, 4, 5]));
}

unittest{ /// Example
    import mach.range.compare : equals;
    // Repeat until 4.
    auto exclusive = 0.recur!(n => n + 1, n => n >= 4);
    assert(exclusive.equals([0, 1, 2, 3]));
    // Repeat until and including 4.
    auto inclusive = 0.recuri!(n => n + 1, n => n >= 4);
    assert(inclusive.equals([0, 1, 2, 3, 4]));
}

unittest{
    // Pass exclusivity as a template arugment.
    import mach.range.compare : equals;
    auto range = 0.recur!(n => n + 1, n => n >= 4, true);
    assert(range.equals([0, 1, 2, 3, 4]));
}

public:



private enum bool DefaultRecurUntilInclusive = false;



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
auto recur(alias func, Element)(Element initial) if(validRecurFunction!(Element, func)){
    return RecurRange!(func, Element)(initial);
}

/// ditto
auto recur(alias func, alias until, bool inclusive = DefaultRecurUntilInclusive, Element)(
    Element initial
) if(validRecurFunction!(Element, func, until)){
    return RecurUntilRange!(func, until, inclusive, Element)(initial);
}

/// ditto
auto recuri(alias func, alias until, Element)(
    Element initial
) if(validRecurFunction!(Element, func, until)){
    return recur!(func, until, true, Element)(initial);
}



struct RecurRange(alias func, Element) if(validRecurFunction!(Element, func)){
    Rebindable!Element value;
    
    this(Element value){
        this.value = value;
    }
    
    enum bool empty = false;
    @property auto ref front() const{
        return cast(Element) this.value;
    }
    void popFront(){
        this.value = func(cast(Element) this.value);
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.value);
    }
}



struct RecurUntilRange(
    alias func, alias until, bool inclusive = DefaultRecurUntilInclusive, Element
) if(
    validRecurFunction!(Element, func, until)
){
    Rebindable!Element value;
    bool isempty;
    
    this(Element value){
        static if(inclusive) this(value, false);
        else this(value, until(value));
    }
    this(Element value, bool isempty){
        this.value = value;
        this.isempty = isempty;
    }
    
    @property bool empty() const{
        return this.isempty;
    }
    
    @property auto ref front() const in{assert(!this.empty);} body{
        return cast(Element) this.value;
    }
    void popFront() in{assert(!this.empty);}body{
        static if(inclusive){
            this.isempty = until(cast(Element) this.value);
            if(!this.isempty) this.value = func(cast(Element) this.value);
        }else{
            this.value = func(cast(Element) this.value);
            this.isempty = until(cast(Element) this.value);
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.value, this.isempty);
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.ends : head;
}
unittest{
    tests("Recur", {
        alias increment = (int n) => (n + 1);
        test(recur!increment(0).head(4).equals([0, 1, 2, 3]));
        test(recur!increment(10).head(4).equals([10, 11, 12, 13]));
        tests("Saving", {
            auto a = 0.recur!increment;
            auto b = a.save;
            a.popFront();
            testeq(a.front, 1);
            testeq(b.front, 0);
        });
    });
    tests("Recur until", {
        auto collatz(bool inclusive, N)(N n){
            return n.recur!(
                (in N n) => (n % 2 == 0 ? n / 2 : n * 3 + 1),
                (in N n) => (n <= 1), inclusive
            );
        }
        tests("Inclusive", {
            test(collatz!true(5).equals([5, 16, 8, 4, 2, 1]));
            test(collatz!true(6).equals([6, 3, 10, 5, 16, 8, 4, 2, 1]));
        });
        tests("Exclusive", {
            test(collatz!false(5).equals([5, 16, 8, 4, 2]));
            test(collatz!false(6).equals([6, 3, 10, 5, 16, 8, 4, 2]));
        });
        tests("Saving", {
            auto a = 0.recur!((n) => (n+1), (n) => (n > 10));
            auto b = a.save;
            a.popFront();
            testeq(a.front, 1);
            testeq(b.front, 0);
        });
    });
}
