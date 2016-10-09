module mach.range.select;

private:

import mach.traits : isIterable, isElementPredicate, hasRemaining;
import mach.traits : isRange, isSavingRange;
import mach.range.asrange : asrange, validAsRange;

public:



alias validSelectFromPredicate = isElementPredicate;
alias validSelectUntilPredicate = isElementPredicate;

enum canSelectFrom(Iter, alias from) = (
    isIterable!Iter && validSelectFromPredicate!(from, Iter)
);
enum canSelectUntil(Iter, alias until) = (
    isIterable!Iter && validSelectUntilPredicate!(until, Iter)
);
enum canSelectFromUntil(Iter, alias from, alias until) = (
    canSelectFrom!(Iter, from) && canSelectUntil!(Iter, until)
);

enum canSelectFromRange(Range, alias from) = (
    isRange!Range && validSelectFromPredicate!(from, Range)
);
enum canSelectUntilRange(Range, alias until) = (
    isRange!Range && validSelectUntilPredicate!(until, Range)
);
enum canSelectFromUntilRange(Range, alias from, alias until) = (
    canSelectFromRange!(Range, from) && canSelectUntilRange!(Range, until)
);



/// Iterate over elements in a range starting with the first element matching a
/// predicate.
auto from(alias pred, bool inclusive = true, Iter)(auto ref Iter iter) if(
    canSelectFrom!(Iter, pred)
){
    auto range = iter.asrange;
    return SelectFromRange!(typeof(range), pred, inclusive)(range);
}
/// ditto
auto from(bool inclusive = true, Iter, From)(auto ref Iter iter, auto ref From element) if(
    canSelectFrom!(Iter, (e) => (e == element))
){
    return from!((e) => (e == element), inclusive, Iter)(iter);
}

/// Iterate over elements in a range ending with the first element matching a
/// predicate.
auto until(alias pred, bool inclusive = false, Iter)(auto ref Iter iter) if(
    canSelectUntil!(Iter, pred)
){
    auto range = iter.asrange;
    return SelectUntilRange!(typeof(range), pred, inclusive)(range);
}
/// ditto
auto until(bool inclusive = true, Iter, Until)(auto ref Iter iter, auto ref Until element) if(
    canSelectUntil!(Iter, (e) => (e == element))
){
    return until!((e) => (e == element), inclusive, Iter)(iter);
}

/// Iterate over elements in a range starting with the first element matching a
/// from predicate and ending with the first following element matching an until
/// predicate.
auto select(
    alias from, alias until,
    bool frominclusive = true, bool untilinclusive = false,
    Iter
)(auto ref Iter iter) if(canSelectFromUntil!(Iter, from, until)){
    auto range = iter.asrange;
    return SelectFromUntilRange!(
        typeof(range), from, until,
        frominclusive, untilinclusive
    )(range);
}
/// ditto
auto select(
    bool frominclusive = true, bool untilinclusive = false, Iter, From, Until
)(auto ref Iter iter, auto ref From from, auto ref Until until) if(
    canSelectFromUntil!(Iter, (e) => (e == from), (e) => (e == until))
){
    return select!(
        (e) => (e == from), (e) => (e == until), frominclusive, untilinclusive, Iter
    )(iter);
}



struct SelectFromRange(Range, alias from, bool inclusive = true) if(
    canSelectFromRange!(Range, from)
){
    Range source;
    
    this(bool initialize = true)(Range source) if(initialize){
        this.source = source;
        this.prepareFront();
    }
    this(bool initialize)(Range source) if(!initialize){
        this.source = source;
    }
    
    @property bool empty(){
        return this.source.empty;
    }
    static if(hasRemaining!Range){
        @property auto remaining(){
            return this.source.remaining();
        }
    }
    @property auto ref front() in{assert(!this.empty);} body{
        return this.source.front;
    }
    void popFront() in{assert(!this.empty);} body{
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
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this).__ctor!false(this.source.save);
        }
    }
}

struct SelectUntilRange(Range, alias until, bool inclusive = false) if(
    canSelectUntilRange!(Range, until)
){
    Range source;
    
    @property auto ref front() in{assert(!this.empty);} body{
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
        void popFront() in{assert(!this.empty);} body{
            this.source.popFront();
            if(this.founduntil || this.source.empty){
                this.empty = true;
            }else{
                this.founduntil = until(this.source.front);
            }
        }
        static if(isSavingRange!Range){
            @property typeof(this) save(){
                return typeof(this)(this.source.save, this.founduntil, this.empty);
            }
        }
    }else{
        this(Range source){
            this.source = source;
        }
        void popFront() in{assert(!this.empty);} body{
            this.source.popFront();
        }
        @property bool empty(){
            return this.source.empty || until(this.source.front);
        }
        static if(isSavingRange!Range){
            @property typeof(this) save(){
                return typeof(this)(this.source.save);
            }
        }
    }
}

struct SelectFromUntilRange(
    Range, alias from, alias until,
    bool frominclusive = true, bool untilinclusive = false
) if(canSelectFromUntilRange!(Range, from, until)){
    Range source;
    
    static if(untilinclusive){
        bool founduntil;
        bool empty;
        this(Range source){
            this(source, false, source.empty);
        }
        this(bool initialize = true)(Range source, bool founduntil, bool empty) if(initialize){
            this.__ctor!false(source, founduntil, empty);
            this.prepareFront();
        }
        this(bool initialize)(Range source, bool founduntil, bool empty) if(!initialize){
            this.source = source;
            this.founduntil = founduntil;
            this.empty = empty;
        }
        void popFront() in{assert(!this.empty);} body{
            this.source.popFront();
            if(this.founduntil || this.source.empty){
                this.empty = true;
            }else{
                this.founduntil = until(this.source.front);
            }
        }
        static if(isSavingRange!Range){
            @property typeof(this) save(){
                return typeof(this).__ctor!false(this.source.save, this.founduntil, this.empty);
            }
        }
    }else{
        this(bool initialize = true)(Range source) if(initialize){
            this.source = source;
            this.prepareFront();
        }
        this(bool initialize)(Range source) if(!initialize){
            this.source = source;
        }
        void popFront() in{assert(!this.empty);} body{
            this.source.popFront();
        }
        @property bool empty(){
            return this.source.empty || until(this.source.front);
        }
        static if(isSavingRange!Range){
            @property typeof(this) save(){
                return typeof(this).__ctor!false(this.source.save);
            }
        }
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
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
            test("No beginning",
                input.from!(e => e == 10).equals(empty)
            );
            test("Default predicate", 
                input.from!true(2).equals([2, 3, 4])
            );
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
            test("No end",
                input.until!(e => e == 10).equals(input)
            );
            test("Default predicate", 
                input.until!true(3).equals([1, 2, 3])
            );
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
            test("No beginning",
                input.select!(e => e == 10, odd).equals(empty)
            );
            test("No end",
                input.select!(e => true, e => e == 10).equals(input)
            );
            test("Default predicate",
                input.select!(true, true)(2, 1).equals([2, 2, 1])
            );
        });
    });
}
