module mach.error.enforce.bounds;

private:

import mach.traits : hasNumericLength, LengthType;
import mach.text : text;

public:



auto enforcelowbound(string lop = `>=`, I, L)(
    I index, L low, size_t line = __LINE__, string file = __FILE__
)if(canLOOB!(lop, I, L)){
    return LOutOfBoundsException!(lop, I, L).enforce(index, low, line, file);
}

auto enforcehighbound(string hop = `<`, I, H)(
    I index, H high, size_t line = __LINE__, string file = __FILE__
)if(canHOOB!(hop, I, H)){
    return HOutOfBoundsException!(hop, I, H).enforce(index, high, line, file);
}

auto enforcebounds(string lop = `>=`, string hop = `<`, I, L, H)(
    I index, L low, H high, size_t line = __LINE__, string file = __FILE__
)if(canLHOOB!(lop, hop, I, L, H)){
    return LHOutOfBoundsException!(lop, hop, I, L, H).enforce(index, low, high, line, file);
}

auto enforcebounds(string lop = `>=`, string hop = `<`, I, Obj)(
    I index, Obj obj, size_t line = __LINE__, string file = __FILE__
)if(is(typeof({
    mixin(`if(!(index ` ~ lop ~ ` 0 && index ` ~ hop ~ ` obj.length)){}`);
}))){
    return enforcebounds!(lop, hop)(index, 0, obj.length, line, file);
}

auto enforceboundsincl(I, L, H)(
    I index, L low, H high, size_t line = __LINE__, string file = __FILE__
)if(canLHOOB!(`>=`, `<=`, I, L, H)){
    return enforcebounds!(`>=`, `<=`)(index, low, high, line, file);
}



private enum canLOOB(string lop, I, L) = is(typeof({
    mixin(`if(!(I.init ` ~ lop ~ ` L.init)){}`);
}));
private enum canHOOB(string hop, I, H) = is(typeof({
    mixin(`if(!(I.init ` ~ hop ~ `H.init)){}`);
}));
private enum canLHOOB(string lop, string hop, I, L, H) = is(typeof({
    mixin(`if(!(I.init ` ~ lop ~ ` L.init && I.init ` ~ hop ~ `H.init)){}`);
}));



abstract class OutOfBoundsException(Index): Exception{
    this(string message, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, null);
    }
    @property Index index() const;
    @property bool toolow() const;
    @property bool toohigh() const;
}

class LOutOfBoundsException(string lop, Index, Low): OutOfBoundsException!Index if(
    canLOOB!(lop, Index, Low)
){
    Index idx;
    Low low;
    
    this(Index index, Low low, size_t line = __LINE__, string file = __FILE__){
        immutable auto message = text(
            "Value ", index, " out of bounds; must be ", lop, " ", low, "."
        );
        this.idx = index;
        this.low = low;
        super(message, line, file);
    }
    
    static auto enforce(Index index, Low low, size_t line = __LINE__, string file = __FILE__){
        mixin(`auto cond = index ` ~ lop ~ ` low;`);
        if(!cond){
            throw new typeof(this)(index, low, line, file);
        }
        return index;
    }
    
    override @property Index index() const{return this.idx;}
    override @property bool toolow() const{mixin(`
        return !(this.idx ` ~ lop ~ ` this.low);
    `);}
    override @property bool toohigh() const{return false;}
}

class HOutOfBoundsException(string hop, Index, High): OutOfBoundsException!Index if(
    canHOOB!(hop, Index, High)
){
    Index idx;
    High high;
    
    this(Index index, High high, size_t line = __LINE__, string file = __FILE__){
        immutable auto message = text(
            "Value ", index, " out of bounds; must be ", hop, " ", high, "."
        );
        this.idx = index;
        this.high = high;
        super(message, line, file);
    }
    
    static auto enforce(Index index, High high, size_t line = __LINE__, string file = __FILE__){
        mixin(`auto cond = index ` ~ hop ~ ` high;`);
        if(!cond){
            throw new typeof(this)(index, high, line, file);
        }
        return index;
    }
    
    override @property Index index() const{return this.idx;}
    override @property bool toolow() const{return false;}
    override @property bool toohigh() const{mixin(`
        return !(this.idx ` ~ hop ~ ` this.high);
    `);}
}

class LHOutOfBoundsException(string lop, string hop, Index, Low, High): OutOfBoundsException!Index if(
    canLHOOB!(lop, hop, Index, Low, High)
){
    Index idx;
    Low low;
    High high;
    
    this(Index index, Low low, High high, size_t line = __LINE__, string file = __FILE__){
        immutable auto message = text(
            "Value ", index, " out of bounds; must be ",
            lop, " ", low, " and ", hop, " ", high, "."
        );
        this.idx = index;
        this.low = low;
        this.high = high;
        super(message, line, file);
    }
    
    static auto enforce(Index index, Low low, High high, size_t line = __LINE__, string file = __FILE__){
        mixin(`auto cond = index ` ~ lop ~ ` low && index ` ~ hop ~ ` high;`);
        if(!cond){
            throw new typeof(this)(index, low, high, line, file);
        }
        return index;
    }
    
    override @property Index index() const{return this.idx;}
    override @property bool toolow() const{mixin(`
        return !(this.idx ` ~ lop ~ ` this.low);
    `);}
    override @property bool toohigh() const{mixin(`
        return !(this.idx ` ~ hop ~ ` this.high);
    `);}
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Index Bounds", {
        tests("Low", {
            testeq(enforcelowbound(0, 0), 0);
            testeq(enforcelowbound(0, -1), 0);
            testeq(enforcelowbound(100, 0), 100);
            testfail({enforcelowbound(0, 1);});
        });
        tests("High", {
            testeq(enforcehighbound(0, 1), 0);
            testeq(enforcehighbound(-1, 1), -1);
            testeq(enforcehighbound(0, 100), 0);
            testfail({enforcehighbound(1, 0);});
        });
        tests("Low And High", {
            testeq(enforcebounds(0, 0, 10), 0);
            testeq(enforcebounds(0, -10, 10), 0);
            testfail({enforcebounds(10, 0, 10);});
            testfail({enforcebounds(-1, 0, 10);});
            testfail({enforcebounds(11, -10, 10);});
            testfail({enforcebounds(0, 1, 10);});
            testeq(enforceboundsincl(0, 0, 10), 0);
            testeq(enforceboundsincl(10, 0, 10), 10);
            testeq(enforceboundsincl(0, -10, 10), 0);
            testfail({enforceboundsincl(-1, 0, 10);});
            testfail({enforceboundsincl(11, -10, 10);});
            testfail({enforceboundsincl(0, 1, 10);});
        });
        tests("Type with length", {
            struct Obj{size_t length;}
            testeq(enforcebounds(10, Obj(20)), 10);
            testfail({enforcebounds(10, Obj(1));});
        });
    });
}
