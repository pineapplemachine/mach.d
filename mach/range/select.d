module mach.range.select;

private:

import mach.traits : isRange, isIterable, isElementPredicate;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



alias validSelectFromPredicate = isElementPredicate;
alias validSelectUntilPredicate = isElementPredicate;

enum canSelectFrom(Iter, alias from) = (
    isIterable!Iter && validSelectFromPredicate!(Iter, from)
);
enum canSelectUntil(Iter, alias until) = (
    isIterable!Iter && validSelectUntilPredicate!(Iter, until)
);
enum canSelectFromUntil(Iter, alias from, alias until) = (
    canSelectFrom!(Iter, from) && canSelectUntil!(Iter, until)
);

enum canSelectFromRange(Range, alias from) = (
    isRange!Range && validSelectFromPredicate!(Range, from)
);
enum canSelectUntilRange(Range, alias until) = (
    isRange!Range && validSelectUntilPredicate!(Range, until)
);
enum canSelectFromUntilRange(Range, alias from, alias until) = (
    canSelectFromRange!(Range, from) && canSelectUntilRange!(Range, until)
);



/// Iterate over elements in a range starting with the first element matching a
/// predicate.
auto from(alias pred, bool inclusive = true, Iter)(Iter iter) if(
    canSelectFrom!(Iter, pred)
){
    auto range = iter.asrange;
    return SelectFromRange!(typeof(range), pred, inclusive)(range);
}

/// Iterate over elements in a range ending with the first element matching a
/// predicate.
auto until(alias pred, bool inclusive = false, Iter)(Iter iter) if(
    canSelectUntil!(Iter, pred)
){
    auto range = iter.asrange;
    return SelectUntilRange!(typeof(range), pred, inclusive)(range);
}

/// Iterate over elements in a range starting with the first element matching a
/// from predicate and ending with the first following element matching an until
/// predicate.
auto select(
    alias from, alias until,
    bool frominclusive = true, bool untilinclusive = false, Iter
)(Iter iter) if(canSelectFromUntil!(Iter, from, until)){
    auto range = iter.asrange;
    return SelectFromUntilRange!(
        typeof(range), from, until,
        frominclusive, untilinclusive
    )(range);
}



struct SelectFromRange(Range, alias from, bool inclusive = true) if(
    canSelectFromRange!(Range, from)
){
    mixin MetaRangeMixin!(Range, `source`, `Empty Save`);
    
    Range source;
    
    this(Range source){
        this.source = source;
        this.prepareFront();
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.source.popFront();
    }
    void prepareFront(){
        while(!this.source.empty && !from(this.source.front)){
            this.source.popFront();
        }
        static if(!inclusive){
            if(!this.source.empty) this.source.popFront();
        }
    }
}

struct SelectUntilRange(Range, alias until, bool inclusive = false) if(
    canSelectUntilRange!(Range, until)
){
    mixin MetaRangeMixin!(Range, `source`, `Save`);
    
    Range source;
    
    @property auto ref front(){
        return this.source.front;
    }
    
    static if(inclusive){
        bool founduntil;
        bool empty;
        this(Range source){
            this(source, false, source.empty);
        }
        this(Range source, bool founduntil, bool empty){
            this.source = source;
            this.founduntil = founduntil;
            this.empty = empty;
        }
        void popFront() in{assert(!this.empty);}body{
            this.source.popFront();
            if(this.founduntil){
                this.empty = true;
            }else{
                this.founduntil = !this.source.empty && until(this.source.front);
            }
        }
    }else{
        this(Range source){
            this.source = source;
        }
        void popFront() in{assert(!this.empty);}body{
            this.source.popFront();
        }
        @property bool empty(){
            return this.source.empty || until(this.source.front);
        }
    }
}

struct SelectFromUntilRange(
    Range, alias from, alias until,
    bool frominclusive = true, bool untilinclusive = false
) if(canSelectFromUntilRange!(Range, from, until)){
    mixin MetaRangeMixin!(Range, `source`, `Empty`);
    
    Range source;
    
    static if(untilinclusive){
        bool founduntil;
        bool empty;
        this(Range source){
            this(source, false, source.empty);
        }
        this(Range source, bool founduntil, bool empty){
            this.source = source;
            this.founduntil = founduntil;
            this.empty = empty;
            this.prepareFront();
        }
        void popFront() in{assert(!this.empty);}body{
            this.source.popFront();
            if(this.founduntil){
                this.empty = true;
            }else{
                this.founduntil = !this.source.empty && until(this.source.front);
            }
        }
    }else{
        this(Range source){
            this.source = source;
            this.prepareFront();
        }
        void popFront() in{assert(!this.empty);}body{
            this.source.popFront();
        }
        @property bool empty(){
            return this.source.empty || until(this.source.front);
        }
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void prepareFront(){
        while(!this.source.empty && !from(this.source.front)){
            this.source.popFront();
        }
        static if(!frominclusive){
            if(!this.source.empty) this.source.popFront();
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Select", {
        
        alias even = (n) => (n % 2 == 0);
        alias odd = (n) => (n % 2 == 1);
        int[] empty = new int[0];
        
        tests("From", {
            auto input = [1, 2, 3, 4];
            tests("Inclusive", {
                test("Iteration", input.from!(even, true).equals([2, 3, 4]));
                test("Empty source", empty.from!(even, true).equals(empty));
            });
            tests("Exclusive", {
                test("Iteration", input.from!(even, false).equals([3, 4]));
                test("Empty source", empty.from!(even, false).equals(empty));
            });
        });
        tests("Until", {
            auto input = [1, 2, 3, 4];
            tests("Inclusive", {
                test("Iteration", input.until!(even, true).equals([1, 2]));
                test("Empty source", empty.until!(even, true).equals(empty));
            });
            tests("Exclusive", {
                test("Iteration", input.until!(even, false).equals([1]));
                test("Empty source", empty.until!(even, false).equals(empty));
            });
        });
        tests("From and until", {
            auto input = [1, 1, 2, 2, 1, 1, 2, 2];
            tests("Inclusive from, inclusive until", {
                test("Iteration",
                    input.select!(even, odd, true, true).equals([2, 2, 1])
                );
                test("Empty source",
                    empty.select!(even, odd, true, true).equals(empty)
                );
            });
            tests("Inclusive from, exclusive until", {
                test("Iteration",
                    input.select!(even, odd, true, false).equals([2, 2])
                );
                test("Empty source",
                    empty.select!(even, odd, true, false).equals(empty)
                );
            });
            tests("Exclusive from, inclusive until", {
                test("Iteration",
                    input.select!(even, odd, false, true).equals([2, 1])
                );
                test("Empty source",
                    empty.select!(even, odd, false, true).equals(empty)
                );
            });
            tests("Exclusive from, exclusive until", {
                test("Iteration",
                    input.select!(even, odd, false, false).equals([2])
                );
                test("Empty source",
                    empty.select!(even, odd, false, false).equals(empty)
                );
            });
        });
    });
}
