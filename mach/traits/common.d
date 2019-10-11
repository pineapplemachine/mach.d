module mach.traits.common;

private:

import mach.meta.ctint : ctint;

/++ Docs

This module provides the `CommonType` and `hasCommonType` templates.
These can be used to find the common implicit type among multiple
potentially different types, and whether such a common type exists.

When the input types do not have any common type, the `CommonType`
template will produce the `void` type as output.

+/

unittest { /// Example
    static assert(hasCommonType!(ubyte, uint, ulong));
    static assert(is(CommonType!(ubyte, uint, ulong) == ulong));
}

unittest { /// Example
    static assert(!hasCommonType!(int, int[]));
    static assert(is(CommonType!(int, int[]) == void));
}

public:



string CommonTypeMixin(in size_t args) {
    assert(args >= 2);
    string codegen = `T[0].init`;
    foreach(i; 1 .. args) {
        codegen = `(0 ? T[` ~ ctint(i) ~ `].init : ` ~ codegen ~ `)`;
    }
    return `typeof(` ~ codegen ~ `)`;
}

template hasCommonType(T...) {
    static if(T.length == 0) {
        enum bool hasCommonType = true;
    }
    else static if(T.length == 1) {
        enum bool hasCommonType = is(typeof(T[0].init));
    }
    else {
        mixin(`enum bool hasCommonType = is(` ~ CommonTypeMixin(T.length) ~ `);`);
    }
}

template CommonType(T...) {
    static if(T.length == 1) {
        alias CommonType = T[0];
    }
    else static if(T.length > 1 && hasCommonType!T) {
        mixin(`alias CommonType = ` ~ CommonTypeMixin(T.length) ~ `;`);
    }
    else {
        alias CommonType = void;
    }
}



private version(unittest) {
    class BaseClass{}
    class SubClassA : BaseClass {}
    class SubClassB : BaseClass {}
}

unittest { /// hasCommonType
    static assert(hasCommonType!(int));
    static assert(hasCommonType!(int, int));
    static assert(hasCommonType!(byte, ubyte, short, ushort, int, uint, long, ulong, real, double, float));
    static assert(hasCommonType!(BaseClass, SubClassA));
    static assert(hasCommonType!(BaseClass, SubClassB));
    static assert(hasCommonType!(SubClassA, SubClassB));
    static assert(hasCommonType!(BaseClass, SubClassA, SubClassB));
    static assert(!hasCommonType!(BaseClass, double));
}

unittest { /// CommonType with no common type
    static assert(is(CommonType!() == void));
    static assert(is(CommonType!(BaseClass, size_t) == void));
}

unittest { /// CommonType with a common type
    static assert(is(CommonType!(void) == void));
    static assert(is(CommonType!(real, byte) == real));
    static assert(is(CommonType!(BaseClass, SubClassA) == BaseClass));
    static assert(is(CommonType!(BaseClass, SubClassB) == BaseClass));
    static assert(is(CommonType!(SubClassA, SubClassB) == BaseClass));
    static assert(is(CommonType!(BaseClass, SubClassA, SubClassB) == BaseClass));
}
