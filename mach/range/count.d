module mach.range.count;

private:

import mach.traits : isFiniteIterable, ElementType;

/++ Docs

The `count` function can be used to determine the number of elements in an
iterable which satisfy a predicate function.
Alternatively, it can be passed a value instead of a predicate and the function
counts the number of elements in the input which are equal to that value.

+/

unittest{ /// Example
    // Count the number of even numbers.
    assert([0, 1, 2, 3, 4].count!(n => n % 2 == 0) == 3);
    // Count the number of occurrences of the character 'l'.
    assert("hello".count('l') == 2);
}

/++ Docs

Though the return value of `count` may be treated like a number, it in fact
is not. The produced type supports `exactly`, `atleast`, `atmost`,
`morethan`, and `lessthan` methods for performing optimized comparisons upon
the number of elements. They are more efficient than acquiring the total count
and then comparing because they are able to short-circuit when the condition
has been met, or has ceased to be met.

Due to a limitation of the language at the time of writing, the comparison
operator overloads implemented by this type are not able to use the optimized
methods. So while `input.count > n` may be supported, `input.count.morethan(n)`
will perform more efficiently.
Note that the equality `==` and inequality `!=` operators suffer no such
disadvantage.

+/

unittest{ /// Example
    assert("greetings".count('e').atleast(2));
    assert("how are you?".count('?').lessthan(5));
    assert("I'm well thank you".count('k').atmost(1));
    assert("ok".count('o').morethan(0));
}

unittest{ /// Example
    // Comparison operators are supported, but are not efficiently implemented.
    assert([0, 1, 2, 3, 4].count!(n => n > 0) > 2);
    assert([5, 6, 7].count!(n => n == 5) <= 1);
}

/++ Docs

When necessary, the actual number of matching elements may be accessed using
the `total` property of a value returned by `count`.

+/

unittest{
    int n = "hello".count('l').total;
    assert(n == 2);
}

public:



template canCount(alias pred, Source){
    static if(isFiniteIterable!Source){
        enum bool canCount = is(typeof({
            if(pred(ElementType!Source.init)){}
        }));
    }else{
        enum bool canCount = false;
    }
}



/// Count the number of elements satisfying a predicate.
auto count(alias pred, Iter)(auto ref Iter iter) if(canCount!(pred, Iter)){
    return CountResult!(pred, Iter)(iter);
}

/// Count the number of elements equal to the provided value.
auto count(Iter, Element)(auto ref Iter iter, auto ref Element element) if(
    canCount!((e) => (e == element), Iter)
){
    return CountResult!((e) => (e == element), Iter)(iter);
}



struct CountResult(alias pred, Source) if(canCount!(pred, Source)){
    Source source;
    
    alias total this;
    
    @property size_t total(){
        size_t count = 0;
        foreach(element; source) count += cast(bool) pred(element);
        return count;
    }
    
    bool exactly(in size_t target){
        size_t count = 0;
        foreach(element; source){
            if(pred(element)){
                count++;
                if(count > target) return false;
            }
        }
        return true;
    }
    
    bool lessthan(in size_t target){
        if(target == 0) return false;
        size_t count = 0;
        foreach(element; source){
            if(pred(element)){
                count++;
                if(count >= target) return false;
            }
        }
        return true;
    }
    
    bool morethan(in size_t target){
        size_t count = 0;
        foreach(element; source){
            if(pred(element)){
                count++;
                if(count > target) return true;
            }
        }
        return false;
    }
    
    bool atleast(in size_t target){
        if(target == 0) return true;
        size_t count = 0;
        foreach(element; source){
            if(pred(element)){
                count++;
                if(count >= target) return true;
            }
        }
        return false;
    }
    
    bool atmost(in size_t target){
        size_t count = 0;
        foreach(element; source){
            if(pred(element)){
                count++;
                if(count > target) return false;
            }
        }
        return true;
    }
    
    /// Support for equality and inequality operators.
    bool opEquals(in size_t target){
        return this.exactly(target);
    }
    
    /// Note that this is less efficient than calling `lessthan`, `morethan`,
    /// `atleast`, `atmost`, etc. because of limitations of D's operator
    /// overloading.
    int opCmp(in size_t target){
        auto count = this.total();
        if(count > target) return 1;
        else if(count < target) return -1;
        else return 0;
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Count", {
        tests("Predicate", {
            auto result = [0, 1, 2, 3, 4].count!(n => n % 2 == 0);
            testeq(result.total, 3);
            test(result.exactly(3));
            test(result == 3);
            testf(result.exactly(0));
            test(result != 0);
            test(result.morethan(0));
            test(result > 0);
            test(result.lessthan(4));
            test(result < 4);
            test(result.atleast(3));
            test(result >= 3);
            test(result.atmost(3));
            test(result <= 3);
        });
        tests("Element", {
            auto result = "hello".count('l');
            testeq(result.total, 2);
            test(result.exactly(2));
            test(result == 2);
        });
        tests("Empty input", {
            auto result = "".count!(e => true);
            testeq(result.total, 0);
            test(result.exactly(0));
            test(result.atleast(0));
            testf(result.lessthan(0));
            test(result.atmost(0));
            testf(result.morethan(0));
        });
        tests("Alias this", {
            void func(int x){}
            func("hi".count('i'));
        });
    });
}
