module mach.math.vector;

private:

import std.traits : isNumeric;
import mach.traits : PropertyType, hasProperty, isTemplateOf;
import mach.meta : Repeat;
import mach.math.vector2;
import mach.math.vector3;

public:



enum VectorPositionAxes = VectorAxes!4(`x`, `y`, `z`, `w`);
enum VectorSizeAxes = VectorAxes!3(`width`, `height`, `depth`);
struct VectorAxes(size_t dimensions){
    string[dimensions] names;
    this(Repeat!(dimensions, string) names){
        foreach(i, name; names) this.names[i] = name;
    }
}



template isVector2Like(T, alias axes = VectorPositionAxes){
    static if(
        hasProperty!(isNumeric, T, axes.names[0]) &&
        hasProperty!(isNumeric, T, axes.names[1])
    ){
        enum bool isVector2Like = (
            is(PropertyType!(T, axes.names[0]) == PropertyType!(T, axes.names[1]))
        );
    }else{
        enum bool isVector2Like = false;
    }
}

template isVector3Like(T, alias axes = VectorPositionAxes){
    static if(
        hasProperty!(isNumeric, T, axes.names[0]) &&
        hasProperty!(isNumeric, T, axes.names[1]) &&
        hasProperty!(isNumeric, T, axes.names[2])
    ){
        enum bool isVector3Like = (
            is(PropertyType!(T, axes.names[0]) == PropertyType!(T, axes.names[1])) &&
            is(PropertyType!(T, axes.names[1]) == PropertyType!(T, axes.names[2]))
        );
    }else{
        enum bool isVector3Like = false;
    }
}

//enum isVector4(T) = isTemplateOf!(T, Vector4); // TODO
template isVector4Like(T, alias axes = VectorPositionAxes){
    static if(
        hasProperty!(isNumeric, T, axes.names[0]) &&
        hasProperty!(isNumeric, T, axes.names[1]) &&
        hasProperty!(isNumeric, T, axes.names[2]) &&
        hasProperty!(isNumeric, T, axes.names[3])
    ){
        enum bool isVector4Like = (
            is(PropertyType!(T, axes.names[0]) == PropertyType!(T, axes.names[1])) &&
            is(PropertyType!(T, axes.names[1]) == PropertyType!(T, axes.names[2])) &&
            is(PropertyType!(T, axes.names[2]) == PropertyType!(T, axes.names[3]))
        );
    }else{
        enum bool isVector4Like = false;
    }
}



enum bool canGetVectorPosition(T) = (
    isVector2Like!(T, VectorPositionAxes) ||
    isVector3Like!(T, VectorPositionAxes) ||
    isVector4Like!(T, VectorPositionAxes)
);
enum bool canGetVectorSize(T) = (
    isVector2Like!(T, VectorSizeAxes) ||
    isVector3Like!(T, VectorSizeAxes)
);



@property auto position(T)(auto ref T thing) if(canGetVectorPosition!T){
    static if(isVector4Like!(T, VectorPositionAxes)){
        static assert(false, "TODO"); // TODO
    }else static if(isVector3Like!(T, VectorPositionAxes)){
        return Vector3!(typeof(thing.x))(thing.x, thing.y, thing.z);
    }else static if(isVector2Like!(T, VectorPositionAxes)){
        return Vector2!(typeof(thing.x))(thing.x, thing.y);
    }else{
        assert(false);
    }
}

@property auto size(T)(auto ref T thing) if(canGetVectorSize!T){
    static if(isVector3Like!(T, VectorSizeAxes)){
        return Vector3!(typeof(thing.width))(thing.width, thing.height, thing.depth);
    }else static if(isVector2Like!(T, VectorSizeAxes)){
        return Vector2!(typeof(thing.width))(thing.width, thing.height);
    }else{
        assert(false);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    struct pos2{int x, y;}
    struct pos3{int x, y, z;}
    struct nopos1{int x; real y;}
    struct nopos2{string x; string y;}
    struct size2{int width, height;}
    struct size3{int width, height, depth;}
    struct nosize1{int width; real height;}
    struct nosize2{string width; string height;}
}
unittest{
    static assert(canGetVectorPosition!pos2);
    static assert(canGetVectorPosition!pos3);
    static assert(!canGetVectorPosition!size2);
    static assert(!canGetVectorPosition!size3);
    static assert(!canGetVectorPosition!nopos1);
    static assert(!canGetVectorPosition!nopos2);
    static assert(canGetVectorSize!size2);
    static assert(canGetVectorSize!size3);
    static assert(!canGetVectorSize!pos2);
    static assert(!canGetVectorSize!pos3);
    static assert(!canGetVectorSize!nosize1);
    static assert(!canGetVectorSize!nosize2);
}
unittest{
    tests("Vectors", {
        testeq(pos2(1, 2).position, Vector2!int(1, 2));
        testeq(pos3(1, 2, 3).position, Vector3!int(1, 2, 3));
        testeq(size2(1, 2).size, Vector2!int(1, 2));
        testeq(size3(1, 2, 3).size, Vector3!int(1, 2, 3));
    });
}
