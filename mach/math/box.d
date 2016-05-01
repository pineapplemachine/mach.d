module mach.math.box;

private:

import std.traits : isNumeric;
import std.algorithm : min, max;

import mach.math.vector2 : Vector2;

public:

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
    
    @property bool nonzero() const{
        return (this.minx != this.maxx) & (this.miny != this.maxy);
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
    //void intersect(in Box[] boxes ...) const{
    //    foreach(arg; boxes) this.intersect(arg);
    //}
    Box!T intersection(N)(in Box!N box) const{
        return Box(
            max(this.minx, box.minx),
            max(this.miny, box.miny),
            min(this.maxx, box.maxx),
            min(this.maxy, box.maxy)
        );
    }
    //Box!T intersection(in Box[] boxes ...) const{
    //    Box!T box = Box!T(this);
    //    box.intersect(boxes);
    //    return box;
    //}
    
    
    Box!T contains(N)(in Vector2!N vector) const{
        return this.contains(cast(T) vector.x, cast(T) vector.y);
    }
    bool contains(N)(in N x, in N y) const if(isNumeric!N){
        return(
            (x >= this.minx) & (x < this.maxx) &
            (y >= this.miny) & (y < this.maxy)
        );
    }
    bool contains(N)(in Box!N box) const{
        return(
            (this.minx <= box.minx) & (this.maxx >= box.maxx) &
            (this.miny <= box.miny) & (this.maxy >= box.maxy)
        );
    }
    
    void merge(N)(in Box!N box){
        this.minx = min(this.minx, box.minx);
        this.miny = min(this.miny, box.miny);
        this.maxx = max(this.maxx, box.maxx);
        this.maxy = max(this.maxy, box.maxy);
    }
    Box!T merged(N)(in Box!N box) const{
        return Box(
            min(this.minx, box.minx),
            min(this.miny, box.miny),
            max(this.maxx, box.maxx),
            max(this.maxy, box.maxy)
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
    
    Box!T opBinary(string op, N)(Box!N rhs) const{
        static if(op == "|"){
            return this.merged(rhs);
        }else static if(op == "&"){
            return this.intersection(rhs);
        }
    }
    bool opBinaryRight(string op, N)(Box!N rhs) const if(op == "in"){
        return this.contains(rhs);
    }
    bool opBinaryRight(string op, N)(Vector2!N rhs) const if(op == "in"){
        return this.contains(rhs);
    }
    
    bool opCast(Type : bool)(){
        return this.nonzero();
    }
    Box!N opCast(Type : Box!N, N)() if(!is(N == T)){
        return Type(this);
    }
    
    string toString() const{
        import std.format;
        return format("(%s, %s), (%s, %s)", this.minx, this.miny, this.maxx, this.maxy);
    }
    
}

unittest{
    // TODO
}
