module mach.range.stripends;

private:

import mach.traits : ElementType, isRange, isSavingRange;
import mach.range.asrange : asrange, validAsRange, validAsBidirectionalRange;

/++ Docs

The `striphead` and `striptail` functions can be used to get a range from
an input which, if it begins or ends with a subject, enumerates only those
elements following or preceding that subject.

`striphead` accepts two inputs valid as a range. If the first input begins
with the second, as determined by a given comparison function, then the
range that `striphead` returns enumerates the elements following those of
the subject. Otherwise, the range it returns enumerates the entire input.

`striptail` also accepts two inputs valid as a range. If the first input ends
with the second, as determined by a given comparison function, then the
range that `striptail` returns enumerates the elements preceding those of
the subject. Otherwise, the range it returns enumerates the entire input.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert("hello".striphead("he").equals("llo"));
    assert("world".striptail("ld").equals("wor"));
}

unittest{ /// Example
    // When the input doesn't begin with the subject,
    // the returned range enumerates the entire input.
    import mach.range.compare : equals;
    assert("hello".striphead("xyz").equals("hello"));
    assert("hello".striphead("hey").equals("hello"));
    assert("world".striptail("xld").equals("world"));
}

public:



template canStripHead(alias pred, Iter, Subject){
    static if(
        validAsRange!Subject && validAsRange!Iter &&
        (!isRange!Iter || isSavingRange!Iter)
    ){
        enum bool canStripHead = is(typeof({
            if(pred(ElementType!Iter.init, ElementType!Subject.init)){}
        }));
    }else{
        enum bool canStripHead = false;
    }
}

template canStripTail(alias pred, Iter, Subject){
    static if(
        validAsBidirectionalRange!Subject && validAsBidirectionalRange!Iter &&
        (!isRange!Iter || isSavingRange!Iter)
    ){
        enum bool canStripTail = is(typeof({
            if(pred(ElementType!Iter.init, ElementType!Subject.init)){}
        }));
    }else{
        enum bool canStripTail = false;
    }
}



/// If `iter` starts with `subject`, return a range representing what remains
/// of `iter` after consuming `subject`.
/// Otherwise, return a range representing the entire input.
auto striphead(alias pred = (a, b) => (a == b), Iter, Subject)(
    auto ref Iter iter, auto ref Subject subject
) if(
    canStripHead!(pred, Iter, Subject)
){
    static if(isRange!Iter){
        auto iterrange = iter.save;
    }else{
        auto iterrange = iter.asrange;
    }
    auto subjectrange = subject.asrange;
    while(!iterrange.empty && !subjectrange.empty){
        if(!pred(iterrange.front, subjectrange.front)) return iter.asrange;
        iterrange.popFront();
        subjectrange.popFront();
    }
    return iterrange;
}

/// If `iter` ends with `subject`, return a range representing what remains
/// of `iter` after consuming `subject`.
/// Otherwise, return a range representing the entire input.
auto striptail(alias pred = (a, b) => (a == b), Iter, Subject)(
    auto ref Iter iter, auto ref Subject subject
) if(
    canStripTail!(pred, Iter, Subject)
){
    static if(isRange!Iter){
        auto iterrange = iter.save;
    }else{
        auto iterrange = iter.asrange;
    }
    auto subjectrange = subject.asrange;
    auto savediter = iterrange.save();
    while(!iterrange.empty && !subjectrange.empty){
        if(!pred(iterrange.back, subjectrange.back)) return iter.asrange;
        iterrange.popBack();
        subjectrange.popBack();
    }
    return iterrange;
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.rangeof : rangeof;
    import mach.text.ascii : tolower;
}
unittest{
    tests("Skip head", {
        tests("Empty inputs", {
            test("".striphead("").empty);
            test("".striphead("ok").empty);
            test!equals("ok".striphead(""), "ok");
        });
        tests("Not empty", {
            test!equals("hello world".striphead("hello "), "world");
            test!equals([1, 2, 3].striphead([4, 5]), [1, 2, 3]);
            // If the whole subject doesn't match, don't strip any of it.
            test!equals("hello".striphead("hey"), "hello");
        });
        tests("Subject larger than input", {
            test("hello".striphead("hello world").empty);
        });
        tests("Explicit predicate", {
            alias compare = (a, b) => (a.tolower == b.tolower);
            test!equals("Hello World".striphead!compare("HELLO "), "World");
            test!equals("Hello World".striphead!compare("Okay"), "Hello World");
        });
        tests("Range input", {
            test!equals(rangeof(0, 1, 2, 3).striphead([0, 1]), [2, 3]);
            test!equals(rangeof(0, 1, 2, 3).striphead([4, 5]), [0, 1, 2, 3]);
        });
    });
    tests("Skip tail", {
        tests("Empty inputs", {
            test("".striptail("").empty);
            test("".striptail("ok").empty);
            test!equals("ok".striptail(""), "ok");
        });
        tests("Not empty", {
            test!equals("hello world".striptail(" world"), "hello");
            test!equals([1, 2, 3].striptail([4, 5]), [1, 2, 3]);
            // If the whole subject doesn't match, don't strip any of it.
            test!equals("hello".striptail("glo"), "hello");
        });
        tests("Subject larger than input", {
            test("world".striptail("hello world").empty);
        });
        tests("Explicit predicate", {
            alias compare = (a, b) => (a.tolower == b.tolower);
            test!equals("Hello World".striptail!compare(" WORLD"), "Hello");
            test!equals("Hello World".striptail!compare("Okay"), "Hello World");
        });
        tests("Range input", {
            test!equals(rangeof(0, 1, 2, 3).striptail([2, 3]), [0, 1]);
            test!equals(rangeof(0, 1, 2, 3).striptail([4, 5]), [0, 1, 2, 3]);
        });
    });
}
