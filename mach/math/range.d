module mach.math.range;

private:

import std.range.primitives : ElementType;
import std.traits : isIterable;

public:

auto range(T)(T min, T max){
    return Range!T(min, max);
}
auto range(Iter)(Iter iter) if(isIterable!Iter){
    return Range!(ElementType!Iter)(iter);
}

struct Range(T){
    T min, max;
    
    this(N)(N min, N max){
        this.min = cast(N) min;
        this.max = cast(N) max;
    }
    this(Iter)(Iter iter) if(isIterable!Iter){
        bool first = true;
        foreach(item; iter){
            if(first){
                this.min = cast(T) item;
                this.max = cast(T) item;
                first = false;
            }else{
                this.min = item < this.min ? cast(T) item : this.min;
                this.max = item > this.max ? cast(T) item : this.max;
            }
        }
    }
    
    @property T delta() const{
        return this.max - this.min;
    }
    alias length = delta;
    
    T opIndex(in size_t index) const in{
        assert(index == 0 || index == 1);
    }body{
        return index == 0 ? this.min : this.max;
    }
    
    bool opEquals(N)(in Range!N rhs) const{
        return(
            (this.min == cast(T) rhs.min) &
            (this.max == cast(T) rhs.max)
        );
    }
    bool opEquals(N)(in N[] rhs) const in{
        assert(rhs !is null && rhs.length == 2);
    }body{
        return(
            (this[0] == cast(T) rhs[0]) &
            (this[1] == cast(T) rhs[1])
        );
    }
    bool opEquals(in T rhs) const{
        return this.delta == rhs;
    }
    
    auto opCast(Type: Range!N, N)() const{
        return Range!N(cast(N) this.min, cast(N) this.max);
    }
    T opCast(Type: T)() const{
        return this.delta;
    }
}

version(unittest) import mach.error.unit;
unittest{
    tests("Ranges", {
        tests("Basic equality", {
            testeq([0, 10].range, 10);
            testeq([0, 10].range, [0, 10]);
            testeq([0, 10].range, Range!int(0, 10));
        });
        tests("Numeric ranges", {
            testeq([-2, 0, 2].range, [-2, 2]);
            testeq([2, 0, -2].range, [-2, 2]);
        });
    });
}
