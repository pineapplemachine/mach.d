module mach.traits.enums;

private:

import mach.meta : Filter;

public:



/// Determine whether a given type is an enum, or a value of an enum type.
template isEnum(T){
    enum bool isEnum = is(T == enum);
}

/// ditto
template isEnum(alias T){
    static if(is(typeof(T))){
        enum bool isEnum = is(typeof(T) == enum);
    }else{
        enum bool isEnum = is(T == enum);
    }
}



/// Determine whether a given type is an enum.
template isEnumType(T){
    enum bool isEnumType = is(T == enum);
}

/// ditto
template isEnumType(alias T){
    static if(!is(typeof(T))){
        enum bool isEnumType = is(T == enum);
    }else{
        enum bool isEnumType = false;
    }
}



/// Determine whether a given value is an enum member.
template isEnumValue(T){
    enum bool isEnumValue = false;
}

/// ditto
template isEnumValue(alias T){
    static if(is(typeof(T))){
        enum bool isEnumValue = is(typeof(T) == enum);
    }else{
        enum bool isEnumValue = false;
    }
}



/// Thrown by `enummember` when passed a nonexistent member name.
class NoSuchEnumMemberException(T): Exception{
    alias Enum = T; /// The enum type for which the exception was thrown.
    string name; /// The nonexistent member name for which the exception was thrown.
    this(string name, size_t line = __LINE__, string file = __FILE__){
        this.name = name;
        super("No enum member with name \"" ~ name ~ "\".", file, line, null);
    }
}



/// Get the member of an enum by name.
/// Causes a static assertion error when no such member exists.
template getEnumMember(Enum, string name){
    template namefilter(string member){
        enum bool namefilter = member == name;
    }
    alias Member = Filter!(namefilter, __traits(allMembers, Enum));
    static if(Member.length == 1){
        mixin(`enum getEnumMember = Enum.` ~ Member[0] ~ `;`);
    }else{
        static assert(false, "No enum member with name \"" ~ name ~ "\".");
    }
}

/// Get the member of an enum by name.
/// Throws NoSuchEnumMemberException when no such member exists.
Enum getenummember(Enum)(in string name){
    foreach(member; __traits(allMembers, Enum)){
        if(member == name){
            mixin(`return Enum.` ~ member ~ `;`);
        }
    }
    throw new NoSuchEnumMemberException!Enum(name);
}



/// Get the name of an enum member.
template EnumMemberName(alias value) if(isEnumValue!value){
    alias Enum = typeof(value);
    template memberfilter(string member){
        mixin(`enum bool memberfilter = value is Enum.` ~ member ~ `;`);
    }
    alias Member = Filter!(memberfilter, __traits(allMembers, Enum));
    static if(Member.length == 1){
        enum string EnumMemberName = Member[0];
    }else{
        static assert(false, "Failed to get enum member name."); // Shouldn't happen
    }
}

/// ditto
string enummembername(T)(in T value) if(isEnum!T){
    foreach(member; __traits(allMembers, T)){
        mixin(`if(value is T.` ~ member ~ `) return member;`);
    }
    assert(false, "Failed to get enum member name."); // Shouldn't happen
}



version(unittest){
    private:
    enum int X = 0;
    enum Ints: int{A = 1, B = 2}
    enum Enum{A, B, C}
}

unittest{
    static assert(isEnum!Enum);
    static assert(isEnum!(Enum.A));
    static assert(isEnum!(Enum.B));
    static assert(isEnum!(Enum.C));
    static assert(!isEnum!X);
    static assert(!isEnum!void);
    static assert(!isEnum!null);
    static assert(!isEnum!int);
    static assert(!isEnum!0);
    static assert(isEnumType!Ints);
    static assert(isEnumType!Enum);
    static assert(!isEnumType!(Enum.A));
    static assert(!isEnumType!X);
    static assert(!isEnumType!void);
    static assert(!isEnumType!null);
    static assert(!isEnumType!int);
    static assert(!isEnumType!0);
    static assert(isEnumValue!(Enum.A));
    static assert(isEnumValue!(Enum.B));
    static assert(isEnumValue!(Enum.C));
    static assert(!isEnumValue!Ints);
    static assert(!isEnumValue!Enum);
    static assert(!isEnumValue!X);
    static assert(!isEnumValue!void);
    static assert(!isEnumValue!null);
    static assert(!isEnumValue!int);
    static assert(!isEnumValue!0);
}

unittest{
    static assert(getEnumMember!(Ints, "A") is Ints.A);
    static assert(getEnumMember!(Ints, "B") is Ints.B);
    static assert(getEnumMember!(Enum, "A") is Enum.A);
    static assert(getEnumMember!(Enum, "B") is Enum.B);
    static assert(getEnumMember!(Enum, "C") is Enum.C);
    static assert(!is(getEnumMember!(Enum, "D")));
}
unittest{
    assert(getenummember!(Ints)("A") is Ints.A);
    assert(getenummember!(Ints)("B") is Ints.B);
    assert(getenummember!(Enum)("A") is Enum.A);
    assert(getenummember!(Enum)("B") is Enum.B);
    assert(getenummember!(Enum)("C") is Enum.C);
    bool nomember = false;
    try{
        getenummember!(Enum)("D");
    }catch(NoSuchEnumMemberException!Enum){
        nomember = true;
    }
    assert(nomember);
}

unittest{
    static assert(EnumMemberName!(Ints.A) == "A");
    static assert(EnumMemberName!(Ints.B) == "B");
    static assert(EnumMemberName!(Enum.A) == "A");
    static assert(EnumMemberName!(Enum.B) == "B");
    static assert(EnumMemberName!(Enum.C) == "C");
}
unittest{
    assert(enummembername(Ints.A) == "A");
    assert(enummembername(Ints.B) == "B");
    assert(enummembername(Enum.A) == "A");
    assert(enummembername(Enum.B) == "B");
    assert(enummembername(Enum.C) == "C");
}
