module mach.range.lexorder;

private:

import mach.range.asrange : asrange, validAsRange;

/++ Docs

The `lexorder` function implements a generalized
[lexicographical ordering](https://en.wikipedia.org/wiki/Lexicographical_order)
algorithm that, given any two input iterables, will return a value indicating
the correct ordering.

+/

unittest{ /// Example
    assert(lexorder("hello", "hello") == 0); // Both inputs are equal
    assert(lexorder("apple", "zed") == -1); // "apple" precedes "zed"
    assert(lexorder("watch", "bear") == +1); // "watch" follows "bear"
}

unittest{ /// Example
    assert(lexorder([3, 2, 1], [3, 2, 1]) == 0);
    assert(lexorder([3, 2, 1], [3, 2, 2]) == -1);
    assert(lexorder([3, 2, 1], [3, 2, 0]) == +1);
    assert(lexorder([3, 2, 1, 0], [3, 2, 1]) == +1);
}

/++ Docs

`lexorder` optionally accepts an ordering function that is applied to each
pair of correlating elements. It should return 0 when the elements are equal,
-1 when the first element precedes the second, and +1 when the first element
follows the second.

+/

unittest{ /// Example
    import mach.text.ascii;
    alias order = (a, b){ // Case-insensitive ASCII character comparison
        if(a.tolower() > b.tolower()) return 1;
        else if(a.tolower() < b.tolower()) return -1;
        return 0;
    };
    assert(lexorder!order("HELLO", "hello") == 0);
    assert(lexorder!order("apple", "Zed") == -1);
}

public:



/// Default ordering function for `lexorder`.
alias DefaultLexOrder = (a, b){
    if(a > b) return +1;
    else if(a < b) return -1;
    return 0;
};



/// Lexicographical ordering implementation.
/// Returns +1 when A follows B.
/// Returns -1 when A precedes B.
/// Returns 0 when A and B are equivalent.
int lexorder(alias order = DefaultLexOrder, A, B)(auto ref A a, auto ref B b) if(
    validAsRange!A && validAsRange!B && is(typeof({
        int n = order(a.asrange.front, b.asrange.front);
    }))
){
    auto arange = a.asrange;
    auto brange = b.asrange;
    while(!arange.empty && !brange.empty){
        immutable cmp = order(arange.front, brange.front);
        if(cmp != 0) return cmp;
        arange.popFront();
        brange.popFront();
    }
    if(arange.empty){
        return brange.empty ? 0 : -1;
    }else{ // implies brange.empty
        return 1;
    }
}



private version(unittest){
    import mach.test;
    void testorder(A, B)(int expected, A a, B b){
        testeq(lexorder(a, b), expected);
        testeq(lexorder(b, a), -expected);
    }
}
unittest{
    tests("OLexicographical ordering", {
        testorder(0, "", "");
        testorder(0, new int[0], new int[0]);
        testorder(0, new int[0], new long[0]);
        testorder(1, "a", "");
        testorder(1, "x", "");
        testorder(1, "abc", "");
        testorder(1, "abc", "a");
        testorder(1, "x", "a");
    });
}
