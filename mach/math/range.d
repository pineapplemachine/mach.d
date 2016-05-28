module mach.math.range;

private:

import mach.range.traits : ElementType, isFiniteIterable, hasBinaryOp, hasComparison;

public:



enum isValidRangeElement(Element) = (
    hasComparison!(Element, ">") &&
    hasComparison!(Element, "<") &&
    hasBinaryOp!(Element, "-")
);
enum hasRange(Iter) = (
    isFiniteIterable!Iter &&
    isValidRangeElement!(ElementType!Iter)
);



auto range(Element)(Element min, Element max) if(isValidRangeElement!Element){
    return Range!Element(min, max);
}
auto range(Iter)(Iter iter) if(hasRange!Iter){
    return Range!(ElementType!Iter)(iter);
}



struct Range(Element) if(isValidRangeElement!Element){
    Element min, max;
    
    this(N)(N min, N max){
        this.min = cast(N) min;
        this.max = cast(N) max;
    }
    this(Iter)(Iter iter) if(hasRange!Iter){
        bool first = true;
        foreach(item; iter){
            if(first){
                this.min = cast(Element) item;
                this.max = cast(Element) item;
                first = false;
            }else{
                this.min = item < this.min ? cast(Element) item : this.min;
                this.max = item > this.max ? cast(Element) item : this.max;
            }
        }
    }
    
    @property Element delta() const{
        return this.max - this.min;
    }
    alias length = delta;
    
    Element opIndex(in size_t index) const in{
        assert(index == 0 || index == 1);
    }body{
        return index == 0 ? this.min : this.max;
    }
    
    bool opEquals(N)(in Range!N rhs) const{
        return(
            (this.min == cast(Element) rhs.min) &
            (this.max == cast(Element) rhs.max)
        );
    }
    bool opEquals(N)(in N[] rhs) const in{
        assert(rhs !is null && rhs.length == 2);
    }body{
        return(
            (this[0] == cast(Element) rhs[0]) &
            (this[1] == cast(Element) rhs[1])
        );
    }
    bool opEquals(in Element rhs) const{
        return this.delta == rhs;
    }
    
    auto opCast(Type: Range!N, N)() const{
        return Range!N(cast(N) this.min, cast(N) this.max);
    }
    Element opCast(Type: Element)() const{
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
