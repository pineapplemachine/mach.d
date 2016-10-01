module mach.math.cube;

private:

import mach.meta : min = varmin, max = varmax;
import mach.traits : isNumeric;

public:

// TODO: More methods

struct Cube(T) if(isNumeric!T){
    
    T minx, miny, minz, maxx, maxy, maxz;
    
    this(N)(in Cube!N cube){
        this(
            cube.minx, cube.miny, cube.minz,
            cube.maxx, cube.maxy, cube.maxz
        );
    }
    this(
        in T minx, in T miny, in T minz,
        in T maxx, in T maxy, in T maxz
    ){
        this.minx = minx; this.maxx = maxx;
        this.miny = miny; this.maxy = maxy;
        this.minz = minz; this.maxz = maxz;
    }
    this(in T width, in T height, in T depth){
        this(0, 0, 0, width, height, depth);
    }
    
    @property T width() const{
        return this.maxx - this.minx;
    }
    @property void width(N)(N value) if(isNumeric!N){
        this.maxx = cast(T)(this.minx + value);
    }
    
    @property T height() const{
        return this.maxy - this.miny;
    }
    @property void height(N)(N value) if(isNumeric!N){
        this.maxy = cast(T)(this.miny + value);
    }
    
    @property T depth() const{
        return this.maxz - this.minz;
    }
    @property void depth(N)(N value) if(isNumeric!N){
        this.maxz = cast(T)(this.minz + value);
    }
    
    bool nonzero() const{
        return (this.minx != this.maxx) & (this.miny != this.maxy) & (this.minz != this.maxz);
    }
    
    T volume() const{
        return this.width * this.width * this.height;
    }
    
    bool opCast(Type : bool)(){
        return this.nonzero();
    }
    Cube!N opCast(Type : Cube!N, N)() if(!is(N == T)){
        return Type(this);
    }
    
    string toString() const{
        import std.format : format;
        return format(
            "(%s, %s, %s), (%s, %s, %s)",
            this.minx, this.miny, this.minz,
            this.maxx, this.maxy, this.maxz
        );
    }
    
}

unittest{
    // TODO: Unit tests
}
