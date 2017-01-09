module mach.range.ends;

private:

import mach.traits : isRange, isInfiniteRange, isBidirectionalRange;
import mach.traits : isSavingRange, isMutableRange, isMutableFrontRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRandomRange;
import mach.traits : isInfiniteIterable, hasNumericLength, ElementType;
import mach.traits : isRandomAccessIterable;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;
import mach.range.asrange : asrange, validAsRange, validAsRandomAccessRange;

/++ Docs

This module implements `head` and `tail` functions, which produce ranges for
enumerating the front or back elements of a range, up to a specified limit.
The length of a range returned by `head` or `tail` is either the limit passed
to the function or the length of its input, whichever is shorter.

The `head` function will work for any input iterable valid as a range.
`tail` will work only for inputs with random access and known numeric length.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert("hello world".head(5).equals("hello"));
    assert("hello world".tail(5).equals("world"));
}

unittest{ /// Example
    import mach.range.compare : equals;
    assert([0, 1, 2].head(10).equals([0, 1, 2]));
}

public:



enum canGetEnd(Iter) = (
    hasNumericLength!Iter && isRandomAccessIterable!Iter
);

enum canGetSimpleHead(Iter) = (
    validAsRange!Iter
);

enum canGetSimpleHeadRange(Range) = (
    isRange!Range && canGetSimpleHead!Range
);

enum canGetHead(Iter) = (
    canGetEnd!Iter || canGetSimpleHead!Iter
);
enum canGetTail(Iter) = (
    canGetEnd!Iter
);



/// Get as a range the first count elements of some iterable.
auto head(Iter)(auto ref Iter iter, in size_t count) if(
    canGetSimpleHead!(Iter) && !canGetEnd!(Iter)
){
    auto range = iter.asrange;
    return SimpleHeadRange!(typeof(range))(range, count);
}

/// ditto
auto head(Iter)(auto ref Iter iter, in size_t count) if(canGetEnd!(Iter)){
    auto range = iter.asrange;
    return HeadRange!(typeof(range))(range, count);
}

/// Get as a range the trailing count elements of some iterable.
auto tail(Iter)(auto ref Iter iter, in size_t count) if(canGetEnd!(Iter)){
    auto range = iter.asrange;
    return TailRange!(typeof(range))(range, count);
}



template HeadRange(Range) if(canGetEnd!(Range)){
    alias HeadRange = EndRange!(Range, false);
}

template TailRange(Range) if(canGetEnd!(Range)){
    alias TailRange = EndRange!(Range, true);
}



struct SimpleHeadRange(Range) if(canGetSimpleHeadRange!(Range)){
    alias Element = ElementType!Range;
    
    Range source;
    size_t index;
    size_t limit;
    
    this(typeof(this) range){
        this(range.source, range.index, range.limit);
    }
    this(Range source, size_t limit, size_t index = size_t.init){
        this.source = source;
        this.limit = limit;
        this.index = index;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.source.front;
    }
    void popFront() in{assert(!this.empty);} body{
        this.index++;
        this.source.popFront();
    }
    
    @property bool empty(){
        return (this.index >= this.limit) || this.source.empty;
    }
    
    static if(isInfiniteRange!Range){
        alias length = limit;
        alias opDollar = length;
    }else static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length < this.limit ? this.source.length : this.limit;
        }
        alias opDollar = length;
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.limit, this.index);
        }
    }
    
    enum bool mutable = isMutableRange!Range;
    static if(isMutableFrontRange!Range){
        @property void front(Element value) in{assert(!this.empty);} body{
            this.source.front = value;
        }
    }
    static if(isMutableRemoveFrontRange!Range){
        void removeFront() in{assert(!this.empty);} body{
            this.source.removeFront();
            this.index++;
        }
    }
}



struct EndRange(Source, bool tail) if(canGetEnd!(Source)){
    alias Element = ElementType!Source;
    
    Source source;
    size_t frontindex;
    size_t backindex;
    size_t limit;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.source, range.frontindex, range.backindex, range.limit);
    }
    this(Source source, size_t limit, size_t frontindex = size_t.init){
        size_t backindex = source.length < limit ? cast(size_t)(source.length) : limit;
        this(source, limit, frontindex, backindex);
    }
    this(Source source, size_t limit, size_t frontindex, size_t backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.limit = limit;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto back() in{assert(!this.empty);} body{
        return this[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto length(){
        return this.source.length < this.limit ? this.source.length : this.limit;
    }
    @property auto remaining(){
        return this.backindex - this.frontindex;
    }

    alias opDollar = length;
    
    private auto transformindex(in size_t index){
        static if(!tail){
            return index;
        }else{
            return cast(size_t) this.source.length - this.length + index;
        }
    }
    
    auto opIndex(in size_t index) in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        return this.source[this.transformindex(index)];
    }
    
    auto opSlice(in size_t low, in size_t high) in{
        static const error = new InvalidSliceBoundsError();
        error.enforce(low, high, this);
    }body{
        static if(!tail){
            return this.source[low .. high];
        }else{
            immutable startindex = cast(size_t) this.source.length - this.length;
            return this.source[startindex + low .. startindex + high];
        }
    }
    
    static if(isSavingRange!Source){
        @property typeof(this) save(){
            return typeof(this)(
                this.source.save, this.limit, this.frontindex, this.backindex
            );
        }
    }else static if(!isRange!Source){
        @property typeof(this) save(){
            return typeof(this)(
                this.source, this.limit, this.frontindex, this.backindex
            );
        }
    }
    
    enum bool mutable = is(typeof({this.source[0] = this.source[0];}));
    static if(mutable){
        @property void front(Element value){
            this[this.frontindex] = value;
        }
        @property void back(Element value){
            this[this.backindex - 1] = value;
        }
        @property void opIndexAssign(Element value, in size_t index){
            this.source[this.transformindex(index)] = value;
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.rangeof : rangeof;
    import mach.range.repeat : repeat;
    import mach.collect : DoublyLinkedList;
    struct TestRange{
        int low, high;
        int index = 0;
        @property bool empty() const{return this.index >= (this.high - this.low);}
        @property int front() const{return this.low + this.index;}
        void popFront(){this.index++;}
    }
}
unittest{
    tests("Ends", {
        tests("Simple head", {
            tests("Empty", {
                 test(rangeof().head(4).empty);
            });
            tests("Finite", {
                test(TestRange(0, 0).head(0).empty);
                test(TestRange(0, 0).head(4).empty);
                test(TestRange(0, 4).head(0).empty);
                test!equals(TestRange(0, 6).head(4), [0, 1, 2, 3]);
            });
            tests("Infinite", {
                test!equals("ok".repeat.head(0), "");
                test!equals("yes".repeat.head(7), "yesyesy");
                test!equals("very".repeat.head(2), "ve");
            });
            tests("Saving", {
                auto range = "hi".repeat.head(4);
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 'i');
                testeq(saved.front, 'h');
            });
            tests("Mutability", {
                auto source = [0, 1, 2, 3].asrange;
                auto range = SimpleHeadRange!(typeof(source))(source, 3);
                testeq(range.front, 0);
                testeq(source[0], 0);
                range.front = 10;
                testeq(range.front, 10);
                testeq(source[0], 10);
            });
            tests("Removal", {
                auto list = new DoublyLinkedList!int([0, 1, 2, 3, 4]);
                auto range = list.values.head(3);
                testeq(range.front, 0);
                testeq(list.front, 0);
                range.front = 10;
                testeq(range.front, 10);
                testeq(list.front, 10);
                range.removeFront();
                testeq(range.front, 1);
                testeq(list.front, 1);
                range.popFront();
                testeq(range.front, 2);
                range.removeFront();
                test!equals(list.ivalues, [1, 3, 4]);
            });
        });
        tests("Head", {
            tests("Empty", {
                void TestEmpty(T)(auto ref T range){
                    test(range.empty);
                    testeq(range.length, 0);
                    testeq(range.remaining, 0);
                }
                tests("Empty input", {
                     TestEmpty(new int[0].head(4));
                });
                tests("Empty result", {
                     TestEmpty([0, 1, 2].head(0));
                });
                tests("Empty input and result", {
                     TestEmpty(new int[0].head(0));
                });
            });
            tests("Bidirectionality", {
                auto range = [0, 1, 2, 3, 4].head(3);
                testf(range.empty);
                testeq(range.length, 3);
                testeq(range.remaining, 3);
                testeq(range.front, 0);
                testeq(range.back, 2);
                range.popFront();
                testeq(range.length, 3);
                testeq(range.remaining, 2);
                testeq(range.front, 1);
                range.popBack();
                testeq(range.remaining, 1);
                testeq(range.back, 1);
                range.popFront();
                testeq(range.remaining, 0);
                test(range.empty);
                testfail({range.front;});
                testfail({range.popFront();});
                testfail({range.back;});
                testfail({range.popBack();});
            });
            tests("Random access", {
                auto range = [0, 1, 2, 3, 4].head(3);
                testeq(range[0], 0);
                testeq(range[1], 1);
                testeq(range[$-1], 2);
                testfail({range[$];});
            });
            tests("Slicing", {
                auto range = [0, 1, 2, 3, 4, 5, 6].head(4);
                test(range[0 .. 0].empty);
                test(range[$ .. $].empty);
                test!equals(range[0 .. 1], [0]);
                test!equals(range[0 .. 2], [0, 1]);
                test!equals(range[0 .. $], [0, 1, 2, 3]);
                test!equals(range[1 .. $], [1, 2, 3]);
                test!equals(range[3 .. $], [3]);
                testfail({range[0 .. $+1];});
            });
            tests("Saving", {
                auto range = [0, 1, 2, 3].head(2);
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 1);
                testeq(saved.front, 0);
            });
            tests("Mutability", {
                auto array = [0, 1, 2, 3, 4];
                auto range = array.head(3);
                // Front
                testeq(range.front, 0);
                testeq(array[0], 0);
                range.front = 10;
                testeq(range.front, 10);
                testeq(array[0], 10);
                // Back
                testeq(range.back, 2);
                testeq(array[2], 2);
                range.back = 20;
                testeq(range.back, 20);
                testeq(array[2], 20);
                // Random access
                testeq(range[1], 1);
                testeq(array[1], 1);
                range[1] = 30;
                testeq(range[1], 30);
                testeq(array[1], 30);
            });
        });
        tests("Tail", {
            tests("Empty", {
                void TestEmpty(T)(auto ref T range){
                    test(range.empty);
                    testeq(range.length, 0);
                    testeq(range.remaining, 0);
                }
                tests("Empty input", {
                     TestEmpty(new int[0].tail(4));
                });
                tests("Empty result", {
                     TestEmpty([0, 1, 2].tail(0));
                });
                tests("Empty input and result", {
                     TestEmpty(new int[0].tail(0));
                });
            });
            tests("Bidirectionality", {
                auto range = [-2, -1, 0, 1, 2].tail(3);
                testf(range.empty);
                testeq(range.length, 3);
                testeq(range.remaining, 3);
                testeq(range.front, 0);
                testeq(range.back, 2);
                range.popFront();
                testeq(range.length, 3);
                testeq(range.remaining, 2);
                testeq(range.front, 1);
                range.popBack();
                testeq(range.remaining, 1);
                testeq(range.back, 1);
                range.popFront();
                testeq(range.remaining, 0);
                test(range.empty);
                testfail({range.front;});
                testfail({range.popFront();});
                testfail({range.back;});
                testfail({range.popBack();});
            });
            tests("Random access", {
                auto range = [0, 1, 2, 3, 4].tail(3);
                testeq(range[0], 2);
                testeq(range[1], 3);
                testeq(range[$-1], 4);
                testfail({range[$];});
            });
            tests("Slicing", {
                auto range = [-2, -1, 0, 1, 2, 3].tail(4);
                test(range[0 .. 0].empty);
                test(range[$ .. $].empty);
                test!equals(range[0 .. 1], [0]);
                test!equals(range[0 .. 2], [0, 1]);
                test!equals(range[0 .. $], [0, 1, 2, 3]);
                test!equals(range[1 .. $], [1, 2, 3]);
                test!equals(range[3 .. $], [3]);
                testfail({range[0 .. $+1];});
            });
            tests("Saving", {
                auto range = [0, 1, 2, 3].tail(2);
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 3);
                testeq(saved.front, 2);
            });
            tests("Mutability", {
                auto array = [0, 1, 2, 3, 4];
                auto range = array.tail(3);
                // Front
                testeq(range.front, 2);
                testeq(array[2], 2);
                range.front = 10;
                test!equals(array, [0, 1, 10, 3, 4]);
                testeq(range.front, 10);
                testeq(array[2], 10);
                // Back
                testeq(range.back, 4);
                testeq(array[4], 4);
                range.back = 20;
                testeq(range.back, 20);
                testeq(array[4], 20);
                // Random access
                testeq(range[1], 3);
                testeq(array[3], 3);
                range[1] = 30;
                testeq(range[1], 30);
                testeq(array[3], 30);
            });
        });
    });
}
