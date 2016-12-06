module mach.math.matrix4;

private:

static import std.math;
import mach.traits : isNumeric;
import mach.math.vector2 : Vector2;
import mach.math.vector3 : Vector3;
import mach.math.box : Box;
import mach.math.cube : Cube;

public:



struct Matrix4(T = real) if(isNumeric!T){
    
    enum size_t Width = 4;
    enum size_t Height = 4;
    enum size_t ValuesLength = 16;
    alias Values = T[ValuesLength];
    
    static immutable identity = typeof(this)(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    );
    
    Values values;
    
    this(in T value){
        this.fill(value);
    }
    this(Values values){
        this.values = values;
    }
    this(in Matrix4!T matrix){
        this.values[] = matrix.values[];
    }
    this(N)(in Matrix4!N matrix) if(!is(N == T)){
        for(size_t i = 0; i < ValuesLength; i++){
            this.values[i] = cast(T) matrix.values[i];
        }
    }
    this(
        in T a, in T b, in T c, in T d,
        in T e, in T f, in T g, in T h,
        in T i, in T j, in T k, in T l,
        in T m, in T n, in T o, in T p
    ){
        this.values = [
            a, b, c, d, e, f, g, h,
            i, j, k, l, m, n, o, p
            //a, e, i, m,
            //b, f, j, n,
            //c, g, k, o,
            //d, h, l, p
        ];
    }
    
    typeof(this) copy() const{
        return typeof(this)(this);
    }
    
    void fill(in T value){
        for(size_t i = 0; i < this.values.length; i++){
            this.values[i] = value;
        }
    }
    
    /// Multiply two matrixes
    Matrix4!T product(N)(in Matrix4!N rhs) const{
        Matrix4!T product;
        alias lhs = this;
        for(size_t i = 0; i < 16; i += 4){
            for(size_t j = 0; j < 4; j++){
                product[i + j] = (
                    lhs[i + 0] * rhs[j + 0] +
                    lhs[i + 1] * rhs[j + 4] +
                    lhs[i + 2] * rhs[j + 8] +
                    lhs[i + 3] * rhs[j + 12]
                );
            }
        }
        return product;
    }
    /// In-place multiplication
    void multiply(N)(in Matrix4!N rhs){
        for(size_t i = 0; i < 16; i += 4){
            T[4] lhsvalues = [this[i + 0], this[i + 1], this[i + 2], this[i + 3]];
            for(size_t j = 0; j < 4; j++){
                this[i + j] = (
                    lhsvalues[0] * rhs[j + 0] +
                    lhsvalues[1] * rhs[j + 4] +
                    lhsvalues[2] * rhs[j + 8] +
                    lhsvalues[3] * rhs[j + 12]
                );
            }
        }
    }
    
    void scale(N)(in Vector2!N vector){
        this.scale(vector.x, vector.y);
    }
    void scale(N)(in Vector3!N vector){
        this.scale(vector.x, vector.y, vector.z);
    }
    void scale(N)(in N x, in N y, in N z = 1) if(isNumeric!N){
        for(size_t i = 0; i < 3; i++){
            N mult;
            final switch(i){
                case 0: mult = x; break;
                case 1: mult = y; break;
                case 2: mult = z; break;
            }
            this[i, 0] *= mult; this[i, 1] *= mult;
            this[i, 2] *= mult; this[i, 3] *= mult;
        }
    }
    
    void translate(N)(in Vector2!N vector){
        this.translate(vector.x, vector.y);
    }
    void translate(N)(in Vector3!N vector){
        this.translate(vector.x, vector.y, vector.z);
    }
    void translate(N)(in N x, in N y, in N z = 1) if(isNumeric!N){
        for(size_t i = 0; i < 4; i++){
            this[3, i] += (
                this[0, i] * x +
                this[1, i] * y +
                this[2, i] * z
            );
        }
    }
    
    typeof(this) frustum(N)(in Cube!N cube) const{
        return frustum!N(
            cube.minx, cube.maxx,
            cube.miny, cube.maxy,
            cube.minz, cube.maxz
        );
    }
    typeof(this) frustum(N)(in N minx, in N maxx, in N miny, in N maxy, in N nearz, in N farz) const{
        if(
            (maxx > minx) & (maxy > miny) &
            (farz > nearz) & (nearz > 0) & (farz > 0)
        ){
            N dx = maxx - minx, dy = maxy - miny, dz = farz - nearz;
            return this * Matrix4!T(
                2 * nearz / dx, 0, 0, 0,
                0, 2 * nearz / dy, 0, 0,
                (minx + maxx) / dx,
                (miny + maxy) / dy,
                -(nearz + farz) / dz,
                -1,
                0, 0, -2 * nearz * farz / dz, 0
            );
        }else{
            return Matrix4!T(this);
        }
    }
    
    Matrix4!T orthographic(N)(in Cube!N cube) const{
        return orthographic!N(
            cube.minx, cube.maxx,
            cube.miny, cube.maxy,
            cube.minz, cube.maxz
        );
    }
    Matrix4!T orthographic(N)(in Box!N box, in N nearz = 1, in N farz = -1) const{
        return orthographic!N(
            box.minx, box.maxx,
            box.miny, box.maxy,
            nearz, farz
        );
    }
    Matrix4!T orthographic(N)(in N minx, in N maxx, in N miny, in N maxy, in N nearz, in N farz) const{
        T dx = maxx - minx, dy = miny - maxy, dz = farz - nearz;
        return this * Matrix4!T(
            2 / dx, 0, 0, -(minx + maxx) / dx,
            0, 2 / dy, 0, -(miny + maxy) / dy,
            0, 0, -2 / dz, -(nearz + farz) / dz,
            0, 0, 0, 1
        );
    }
    
    Matrix4!T perspective(N)(in N fovdegrees, in real aspectratio, in N nearz, in N farz) const if(isNumeric!N){
        N height = std.math.tan(fovy * std.math.PI / 360) * nearz;
        N width = height * aspectratio;
        return this.frustum(-width, width, -height, height, nearz, farz);
    }
    
    void rotate(N)(in real degrees, in Vector3!N vector){
        this.rotate(degrees, vector.x, vector.y, vector.z);
    }
    void rotate(N)(in real degrees, in N x, in N y, in N z) if(isNumeric!N){
        real magnitude = std.math.sqrt(cast(real)(x * x + y * y + z * z));
        if(mag > 0){
            real sin = std.math.sin(degrees * std.math.pi / 180.0);
            real cos = std.math.cos(degrees * std.math.pi / 180.0);
            N xx = x * x, yy = y * y, zz = z * z;
            N xy = x * y, yz = y * z; zx = z * x;
            real xs = x * sin, ys = y * sin, zs = z * sin;
            real icos = 1 - cos;
            this.multiply(
                (icos * xx) + cos, (icos * xy) - zs, (icos * zx) + ys, 0,
                (icos * xy) + zs, (icos * yy) + cos, (icos * yz) - xs, 0,
                (icos * zx) - ys, (icos * yz) + xs, (icos * zz) - cos, 0,
                0, 0, 0, 1
            );
        }
    }
    
    size_t index(in size_t x, in size_t y) const{
        assert(
            (x >= 0) & (y >= 0) & (x < Width) & (y < Height),
            "Coordinates are out of bounds.",
        );
        return x + (y << 2);
        //return y + (x << 2);
    }
    
    Matrix4!T opBinary(string op : "*", N)(in Matrix4!N rhs) const{
        return this.product(rhs);
    }
    Matrix4!T opBinary(string op : "*", N)(in N[16] rhs) const{
        return this.product(rhs);
    }
    void opOpAssign(string op : "*", N)(in Matrix4!N rhs){
        this.multiply(rhs);
    }
    
    T opIndex(in size_t index) const{
        return this.values[index];
    }
    T opIndex(in size_t x, in size_t y) const{
        return this.values[this.index(x, y)];
    }
    void opIndexAssign(in T value, in size_t index){
        this.values[index] = value;
    }
    void opIndexAssign(N)(in N value, in size_t x, in size_t y) if(isNumeric!N){
        this.values[this.index(x, y)] = value;
    }
    
    bool opEquals(in Matrix4!T rhs) const{
        return this.values == rhs.values;
    }
    bool opEquals(N)(in Matrix4!N rhs) const if(!is(N == T)){
        for(int i = 0; i < 16; i++){
            if(this.values[i] != cast(T) rhs.values[i]) return false;
        }
        return true;
    }
    
    string toString() const{
        import std.format : format;
        return (
            "%s %s %s %s\n" ~
            "%s %s %s %s\n" ~
            "%s %s %s %s\n" ~
            "%s %s %s %s"
        ).format(
            this[0x0], this[0x1], this[0x2], this[0x3],
            this[0x4], this[0x5], this[0x6], this[0x7],
            this[0x8], this[0x9], this[0xa], this[0xb],
            this[0xc], this[0xd], this[0xe], this[0xf]
            //this[0x0], this[0x4], this[0x8], this[0xc],
            //this[0x1], this[0x5], this[0x9], this[0xd],
            //this[0x2], this[0x6], this[0xa], this[0xe],
            //this[0x3], this[0x7], this[0xb], this[0xf]
        );
    }
    
    auto aligned() const{ // TODO: Just make it aligned this way by default
        return [
            this[0x0], this[0x4], this[0x8], this[0xc],
            this[0x1], this[0x5], this[0x9], this[0xd],
            this[0x2], this[0x6], this[0xa], this[0xe],
            this[0x3], this[0x7], this[0xb], this[0xf]
        ];
    }
    
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    // TODO: Make this better
    
    auto m0 = Matrix4!real(
        1, 2, 3, 4,
        5, 6, 7, 8,
        1, 2, 3, 4,
        5, 6, 7, 8
    );
    auto m1 = Matrix4!real(
        2, 4, 6, 8,
        1, 3, 5, 7,
        0, 5, 0, 5,
        6, 5, 4, 3
    );
    // Test multiplication
    tests("Matrix multiplication", {
        auto m0m1 = Matrix4!real(
            28,  45, 32,  49,
            64, 113, 92, 141,
            28,  45, 32,  49,
            64, 113, 92, 141
        );
        // By the identity matrix
        testeq(m0 * Matrix4!real.identity, m0);
        // By an arbitrary matrix
        testeq(m0 * m1, m0m1);
        // In-place
        auto inplace = m0.copy(); inplace *= m1;
        testeq(inplace, m0m1);
    });
    
    // TODO: More unit tests
    
    
    /+
    import Dgame.Math.Matrix4x4;
    import Dgame.Math.Rect;
    Matrix4x4 Dmat;
    auto rect = Rect(0, 0, 800, 600);
    auto cube = Cube!int(0, 0, 1, 800, 600, -1);
    
    Dmat.ortho(rect);
    
    auto Mmat = Matrix4!real.identity.orthographic(Box!int(800, 600));
    
    import std.stdio;
    writeln(Mmat);
    writeln(Dmat);
    
    writeln(Mmat[0], " ", Mmat[1], " ", Mmat[3]);
    writeln(Dmat[0], " ", Dmat[1], " ", Dmat[3]);
    +/
    
    
}
