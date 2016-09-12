module mach.math.box;

private:

import std.traits : isNumeric;
import std.algorithm : min, max;

import mach.traits : isTemplateOf;
import mach.math.vector2 : Vector2;

public:



enum isBox(T) = isTemplateOf!(T, Box);



struct Box(T) if(isNumeric!T){
    
    T minx, miny, maxx, maxy;
    
    alias x = minx;
    alias y = miny;
    
    this(N)(in N maxx, in N maxy) if(isNumeric!N){
        this(0, 0, maxx, maxy);
    }
    this(in T minx, in T miny, in T maxx, in T maxy){
        this.minx = minx; this.miny = miny;
        this.maxx = maxx; this.maxy = maxy;
    }
    this(N)(in N minx, in N miny, in N maxx, in N maxy) if(isNumeric!N && !is(N == T)){
        this(cast(T) minx, cast(T) miny, cast(T) maxx, cast(T) maxy);
    }
    this(N)(in Vector2!N bottomright){
        this(bottomright.x, bottomright.y);
    }
    this(N)(in Vector2!N topleft, in Vector2!N bottomright){
        this(topleft.x, topleft.y, bottomright.x, bottomright.y);
    }
    this(N)(in Box!N box) if(isNumeric!N){
        this(box.minx, box.miny, box.maxx, box.maxy);
    }
    
    @property T width() const{
        return this.maxx - minx;
    }
    @property void width(N)(N value) if(isNumeric!N){
        this.maxx = cast(T)(this.minx + value);
    }
    
    @property T height() const{
        return this.maxy - miny;
    }
    @property void height(N)(N value) if(isNumeric!N){
        this.maxy = cast(T)(this.miny + value);
    }
    
    @property Vector2!T size() const{
        return Vector2!T(this.width, this.height);
    }
    @property void size(N)(in Vector2!N vector){
        this.size(vector.x, vector.y);
    }
    void size(N)(in N width, in N height) if(isNumeric!N){
        this.width = width;
        this.height = height;
    }
    
    @property Box!T cleaned(){
        Box!T box = Box!T(this);
        box.clean();
        return box;
    }
    void clean(){
        if(this.minx > this.maxx){
            T temp = this.minx;
            this.minx = this.maxx;
            this.maxx = temp;
        }
        if(this.miny > this.maxy){
            T temp = this.miny;
            this.miny = this.maxy;
            this.maxy = temp;
        }
    }
    
    /// Get the box's area.
    @property T area() const{
        return this.width() * this.height();
    }
    
    /// Get the horizontal center of the box.
    @property T centerx() const{
        return (this.minx + this.maxx) / 2;
    }
    /// Get the vertical center of the box.
    @property T centery() const{
        return (this.miny + this.maxy) / 2;
    }
    
    /// Get the center of the box.
    @property Vector2!T center() const{
        return Vector2!T(this.centerx(), this.centery());
    }
    
    @property Vector2!T topleft() const{
        return Vector2!T(this.minx, this.miny);
    }
    @property Vector2!T topcenter() const{
        return Vector2!T(this.centerx(), this.miny);
    }
    @property Vector2!T topright() const{
        return Vector2!T(this.maxx, this.miny);
    }
    @property Vector2!T centerleft() const{
        return Vector2!T(this.minx, this.centery());
    }
    @property Vector2!T centerright() const{
        return Vector2!T(this.maxx, this.centery());
    }
    @property Vector2!T bottomleft() const{
        return Vector2!T(this.minx, this.maxy);
    }
    @property Vector2!T bottomcenter() const{
        return Vector2!T(this.centerx(), this.maxy);
    }
    @property Vector2!T bottomright() const{
        return Vector2!T(this.maxx, this.maxy);
    }
    
    /// Get as an array the four vectors of the box
    /// Returns an array in the form of [NW, NE, SE, SW].
    @property Vector2!T[4] corners() const{
        return [this.topleft, this.topright, this.bottomright, this.bottomleft];
    }
    
    @property bool nonzero() const{
        return (this.minx != this.maxx) & (this.miny != this.maxy);
    }
    @property bool exists() const{
        return (this.minx < this.maxx) & (this.miny < this.maxy);
    }
    
    void translate(N)(in Vector2!N vector){
        this.translate(vector.x, vector.y);
    }
    void translate(N)(in N x, in N y) if(isNumeric!N){
        this.minx += x; this.miny += y;
        this.maxx += x; this.maxy += y;
    }
    Box!T translated(N)(in Vector2!N vector) const{
        return this.translated(vector.x, vector.y);
    }
    Box!T translated(N)(in N x, in N y) const if(isNumeric!N){
        return Box!T(this.minx + x, this.miny + y, this.maxx + x, this.maxy + y);
    }
    
    bool intersects(N)(in Box!N box) const{
        return(
            (this.maxy > box.miny) & (this.miny < box.maxy) &
            (this.maxx > box.minx) & (this.minx < box.maxx)
        );
    }
    
    void intersect(N)(in Box!N box){
        this.minx = max(this.minx, box.minx);
        this.miny = max(this.miny, box.miny);
        this.maxx = min(this.maxx, box.maxx);
        this.maxy = min(this.maxy, box.maxy);
    }
    void intersect(N)(in Box!N[] boxes ...){
        foreach(box; boxes){
            this.minx = cast(T) max(this.minx, box.minx);
            this.miny = cast(T) max(this.miny, box.miny);
            this.maxx = cast(T) min(this.maxx, box.maxx);
            this.maxy = cast(T) min(this.maxy, box.maxy);
        }
    }
    
    Box!T intersection(N)(in Box!N box) const{
        return Box!T(
            cast(T) max(minx, box.minx),
            cast(T) max(miny, box.miny),
            cast(T) min(maxx, box.maxx),
            cast(T) min(maxy, box.maxy)
        );
    }
    Box!T intersection(N)(in Box!N[] boxes ...) const{
        T minx = this.minx, miny = this.miny;
        T maxx = this.maxx, maxy = this.maxy;
        foreach(box; boxes){
            minx = cast(T) max(minx, box.minx);
            miny = cast(T) max(miny, box.miny);
            maxx = cast(T) min(maxx, box.maxx);
            maxy = cast(T) min(maxy, box.maxy);
        }
        return Box!T(minx, miny, maxx, maxy);
    }
    
    void merge(N)(in Box!N box){
        this.minx = cast(T) min(this.minx, box.minx);
        this.miny = cast(T) min(this.miny, box.miny);
        this.maxx = cast(T) max(this.maxx, box.maxx);
        this.maxy = cast(T) max(this.maxy, box.maxy);
    }
    Box!T merged(N)(in Box!N box) const{
        return Box(
            cast(T) min(this.minx, box.minx),
            cast(T) min(this.miny, box.miny),
            cast(T) max(this.maxx, box.maxx),
            cast(T) max(this.maxy, box.maxy)
        );
    }
    
    bool contains(N)(in Vector2!N vector) const{
        return this.contains(cast(T) vector.x, cast(T) vector.y);
    }
    bool contains(N)(in N x, in N y) const if(isNumeric!N){
        return(
            (x >= this.minx) &
            (x <  this.maxx) &
            (y >= this.miny) &
            (y <  this.maxy)
        );
    }
    bool contains(N)(in Box!N box) const{
        return(
            (this.minx <= box.minx) &
            (this.maxx >= box.maxx) &
            (this.miny <= box.miny) &
            (this.maxy >= box.maxy)
        );
    }
    
    void to(N)(in Box!N vector){
        this.to(vector.minx, vector.miny);
    }
    void to(N)(in Vector2!N vector){
        this.to(vector.x, vector.y);
    }
    void to(N)(in N x, in N y) if(isNumeric!N){
        T width = this.width, height = this.height;
        this.minx = x; this.miny = y;
        this.maxx = x + width; this.maxy = y + height;
    }
    Box!T at(N)(in Box!N box) const{
        return this.at(box.minx, box.miny);
    }
    Box!T at(N)(in Vector2!N vector) const{
        return this.at(vector.x, vector.y);
    }
    Box!T at(N)(in N x, in N y) const if(isNumeric!N){
        return Box!T(x, y, x + this.width, y + this.height);
    }
    
    Box!T opBinary(string op: "|", N)(in Box!N rhs) const{
        return this.merged(rhs);
    }
    Box!T opBinary(string op: "&", N)(in Box!N rhs) const{
        return this.intersection(rhs);
    }
    bool opBinaryRight(string op: "in", N)(in Box!N rhs) const{
        return this.contains(rhs);
    }
    bool opBinaryRight(string op: "in", N)(in Vector2!N rhs) const{
        return this.contains(rhs);
    }
    
    Box!T opBinary(string op, N)(in N value) const if(isNumeric!N){
        mixin(`return Box!T(
            this.minx ` ~ op ~ ` value,
            this.miny ` ~ op ~ ` value,
            this.maxx ` ~ op ~ ` value,
            this.maxy ` ~ op ~ ` value
        );`);
    }
    Box!T opBinary(string op, N)(in Vector2!N vector) const{
        mixin(`return Box!T(
            this.minx ` ~ op ~ ` vector.x,
            this.miny ` ~ op ~ ` vector.y,
            this.maxx ` ~ op ~ ` vector.x,
            this.maxy ` ~ op ~ ` vector.y
        );`);
    }
    Box!T opBinaryRight(string op, N)(in N value) const if(isNumeric!N){
        mixin(`return Box!T(
            value ` ~ op ~ ` this.minx,
            value ` ~ op ~ ` this.miny,
            value ` ~ op ~ ` this.maxx,
            value ` ~ op ~ ` this.maxy
        );`);
    }
    Box!T opBinaryRight(string op, N)(in Vector2!N vector) const if(op != "in"){
        mixin(`return Box!T(
            vector.x ` ~ op ~ `this.minx,
            vector.y ` ~ op ~ `this.miny,
            vector.x ` ~ op ~ `this.maxx,
            vector.y ` ~ op ~ `this.maxy 
        );`);
    }
    
    bool opCast(Type: bool)() const{
        return this.exists();
    }
    Box!N opCast(Type: Box!N, N)() const if(!is(N == T)){
        return Box!N(this);
    }
    
    bool opEquals(N)(Box!N box) const{
        return (
            (this.minx == box.minx) &
            (this.miny == box.miny) &
            (this.maxx == box.maxx) &
            (this.maxy == box.maxy)
        );
    }
    
    string toString() const{
        import std.format;
        return format("(%s, %s), (%s, %s)", this.minx, this.miny, this.maxx, this.maxy);
    }
    
}

version(unittest) import mach.error.unit;
unittest{
    // TODO: More tests
    tests("Box", {
        tests("Equality", {
            testeq(Box!int(1, 1), Box!int(1, 1));
            testeq(Box!int(1, 1), Box!real(1, 1));
            testneq(Box!int(1, 1), Box!int(0, 0));
            testneq(Box!int(1, 1), Box!real(1.5, 1.5));
        });
        tests("Scalar math", {
            Box!int box = Box!int(1, 2, 3, 4);
            testeq(box - 1, Box!int(0, 1, 2, 3));
            testeq(box + 1, Box!int(2, 3, 4, 5));
            testeq(box / 2, Box!int(0, 1, 1, 2));
            testeq(box * 2, Box!int(2, 4, 6, 8));
        });
        tests("Intersection", {
            testeq(
                Box!int(0, 0, 2, 4).intersection(Box!int(0, 0, 4, 2)),
                Box!int(0, 0, 2, 2)
            );
            testeq(
                Box!int(-2, -2, 1, 1) & Box!int(-1, -1, 2, 2),
                Box!int(-1, -1, 1, 1)
            );
            testf(
                Box!int(0, 0, 4, 4).intersection(Box!int(-4, -4, 0, 0)).exists
            ); 
        });
        tests("Merge", {
            testeq(
                Box!int(0, 0, 1, 1).merged(Box!int(-1, -1, 0, 0)),
                Box!int(-1, -1, 1, 1)
            );
            testeq(
                Box!int(2, 5) | Box!int(5, 2), Box!int(5, 5)
            );
        });
        tests("Contains", {
            test(Box!int(10, 10).contains(Box!int(2, 2, 5, 5)));
            testf(Box!int(10, 10).contains(Box!int(2, 2, 5, 12)));
            test(Box!int(10, 10).contains(Vector2!int(5, 5)));
            testf(Box!int(10, 10).contains(Vector2!int(5, 12)));
            test(Box!int(2, 2, 5, 5) in Box!int(10, 10));
            test(Vector2!int(2, 2) in Box!int(10, 10));
            test(Vector2!int(-1, -1) !in Box!int(10, 10));
        });
    });
}
