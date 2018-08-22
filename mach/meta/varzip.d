module mach.meta.varzip;

private:

import mach.meta.ctint : ctint;
import mach.meta.logical : All;
import mach.meta.reduce : Reduce;
import mach.types.tuple : tuple, isTuple;

/++ Docs

The `varzip` function accepts any number of tuples as arguments and outputs
a new tuple of tuples where each successive tuple contains the values of the
inputted tuples at the same indexes.
This is known as the [convolution, or "zip"]
(https://en.wikipedia.org/wiki/Convolution_(computer_science)) function.

The length of the outputted tuple is equal to the least length of the inputted
tuples. (If the function was called with no inputs, then the length of the
output is zero.)
The length of each element of the outputted tuple, if it has any elements,
is equal to the number of inputs.

+/

unittest{ /// Example
    import mach.types.tuple : tuple;
    assert(varzip(tuple('a', 'b', 'c'), tuple('x', 'y', 'z')) == tuple(
        tuple('a', 'x'), tuple('b', 'y'), tuple('c', 'z')
    ));
}

public:



/// Used to generate `varzip` code.
private string ZipMixin(in size_t outputlength, in size_t argslength){
    string codegen = ``;
    foreach(i; 0 .. outputlength){
        if(codegen.length) codegen ~= `, `;
        string term = ``;
        foreach(j; 0 .. argslength){
            if(term.length) term ~= `, `;
            term ~= `args[` ~ ctint(j) ~ `][` ~ ctint(i) ~ `]`;
        }
        codegen ~= `tuple(` ~ term ~ `)`;
    }
    return `return tuple(` ~ codegen~ `);`;
}

/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
auto varzip(T...)(auto ref T args) if(All!(isTuple, T)){
    static if(T.length == 0){
        return tuple();
    }else{
        // Get the length of the shortest input
        template MinLength(Acc, Next){
            static if(Next.length < Acc.length) alias MinLength = Next;
            else alias MinLength = Acc;
        }
        mixin(ZipMixin(Reduce!(MinLength, T).length, args.length));
    }
}



unittest{
    // Empty inputs
    assert(varzip() is tuple());
    assert(varzip(tuple()) is tuple());
    assert(varzip(tuple(), tuple()) is tuple());
    assert(varzip(tuple(), tuple(), tuple()) is tuple());
    // Same-length inputs
    assert(varzip(tuple(1)) is tuple(tuple(1)));
    assert(varzip(tuple(1, 2)) is tuple(tuple(1), tuple(2)));
    assert(varzip(tuple(1), tuple(10)) is tuple(tuple(1, 10)));
    assert(varzip(tuple(1, 2), tuple(10, 20)) is tuple(tuple(1, 10), tuple(2, 20)));
    assert(varzip(tuple(1, 2, 3), tuple(4, 5, 6), tuple(7, 8, 9)) is tuple(
        tuple(1, 4, 7), tuple(2, 5, 8), tuple(3, 6, 9)
    ));
    // Differing-length inputs
    assert(varzip(tuple(1, 2, 3), tuple(4, 5)) is tuple(tuple(1, 4), tuple(2, 5)));
    assert(varzip(tuple(1, 2, 3), tuple()) is tuple());
    // Differently-typed elements
    assert(varzip(tuple(1, 2), tuple('a', 'b')) is tuple(tuple(1, 'a'), tuple(2, 'b')));
}
