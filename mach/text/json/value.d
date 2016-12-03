module mach.text.json.value;

private:

import mach.text.parse.numeric : writeint, writefloat, WriteFloatSettings;
import mach.traits : isNull, isBoolean, isNumeric, isIntegral, isFloatingPoint;
import mach.traits : isCharacter, isString, isArray, isAssociativeArray;
import mach.traits : ArrayElementType, ArrayKeyType, ArrayValueType;
import mach.range : map, join, sum, all, orderstrings, asrange, asarray;
import mach.range.sort : keysort = mergesort;
import mach.text.utf : utf8encode;

import mach.text.json.escape;
import mach.text.json.exceptions;
import mach.text.json.literals;

public:



static struct JsonValue{
    alias Boolean = bool;
    alias Integer = long;
    alias Float = double;
    alias String = string;
    alias Array = JsonValue[];
    alias Object = JsonValue[string];
    
    /// Enumeration of possible json value types.
    static enum Type{
        Null,
        Boolean,
        Integer,
        Float,
        String,
        Array,
        Object,
    }
    
    union Store{
        Boolean booleanval;
        Integer integerval;
        Float floatval;
        String stringval;
        Array arrayval;
        Object objectval;
    }
    
    Type valuetype = Type.Null;
    Store store;
    
    this(Type type){
        this.type = type;
    }
    this(T)(T value) if(canAssign!T){
        this.value = value;
    }
    
    @property auto type() const{
        return this.valuetype;
    }
    @property void type(Type type){
        this.valuetype = type;
        final switch(this.type){
            case Type.Boolean:
                this.store.booleanval = false;
                break;
            case Type.Integer:
                this.store.integerval = 0;
                break;
            case Type.Float:
                // Floats initialized to 0 instead of NaN because the json spec
                // doesn't typically allow an accurate representation of NaN.
                this.store.floatval = 0;
                break;
            case Type.String:
                this.store.stringval = "";
                break;
            case Type.Array:
                this.store.arrayval = this.store.arrayval.init;
                break;
            case Type.Object:
                this.store.objectval = this.store.objectval.init;
                break;
            case Type.Null:
                break;
        }
    }
    
    enum canAssign(T) = (
        is(T : JsonValue) ||
        isNull!T ||
        isBoolean!T ||
        isIntegral!T ||
        isCharacter!T ||
        isFloatingPoint!T ||
        isString!T ||
        canAssignArray!T ||
        canAssignAssociativeArray!T
    );
    template canAssignArray(T){
        static if(isArray!T){
            enum bool canAssignArray = canAssign!(ArrayElementType!T);
        }else{
            enum bool canAssignArray = false;
        }
    }
    template canAssignAssociativeArray(T){
        static if(isAssociativeArray!T){
            enum bool canAssignAssociativeArray = (
                canAssign!(ArrayValueType!T) && is(typeof({
                    auto k = ArrayKeyType!T.init; string x = k;
                }))
            );
        }else{
            enum bool canAssignAssociativeArray = false;
        }
    }
    
    @property void value(T)(auto ref T value) if(canAssign!T){
        static if(is(T : JsonValue)){
            this.type = value.type;
            if(this.type is Type.String){
                this.store.stringval = value.store.stringval.dup;
            }else if(this.type is Type.Array){
                this.store.arrayval = value.store.arrayval.dup;
            }else if(this.type is Type.Object){
                this.store.objectval = cast(Object) value.store.objectval.dup;
            }else{
                this.store = value.store;
            }
        }else static if(isNull!T){
            this.type = Type.Null;
        }else static if(isBoolean!T){
            this.type = Type.Boolean;
            this.store.booleanval = value;
        }else static if(isIntegral!T || isCharacter!T){
            this.type = Type.Integer;
            this.store.integerval = cast(Integer) value;
        }else static if(isFloatingPoint!T){
            this.type = Type.Float;
            this.store.floatval = cast(Float) value;
        }else static if(isString!T){
            this.type = Type.String;
            this.store.stringval = cast(string) value.utf8encode.asarray!(immutable char);
        }else static if(isArray!T){
            this.type = Type.Array;
            JsonValue[] array;
            array.reserve(value.length);
            foreach(e; value) array ~= JsonValue(e);
            this.store.arrayval = array;
        }else static if(is(T : Object)){
            this.type = Type.Object;
            this.store.objectval = value;
        }else static if(isAssociativeArray!T){
            this.type = Type.Object;
            JsonValue[string] object;
            foreach(k, v; value) object[k] = JsonValue(v);
            this.store.objectval = object;
        }else{
            assert(false, "Failed to set value."); // Shouldn't happen
        }
    }
    
    string encode(
        WriteFloatSettings floatsettings = EncodeFloatSettingsDefault
    )() const{
        final switch(this.type){
            case Type.Null:
                return NullLiteral;
            case Type.Boolean:
                return this.store.booleanval ? TrueLiteral : FalseLiteral;
            case Type.Integer:
                return this.store.integerval.writeint;
            case Type.Float:
                return this.encodefloat!floatsettings(this.store.floatval);
            case Type.String:
                return '"' ~ jsonescape(this.store.stringval) ~ '"';
            case Type.Array:
                auto parts = this.store.arrayval.map!(
                    e => e.encode!floatsettings
                );
                return cast(string)('[' ~ parts.join(',').asarray ~ ']');
            case Type.Object:
                auto parts = this.store.objectval.map!((e){
                    return '"' ~ jsonescape(e.key) ~ "\":" ~ e.value.encode!floatsettings;
                });
                return cast(string)('{' ~ parts.join(',').asarray ~ '}');
        }
    }
    
    string pretty(
        string indent = "  ",
        WriteFloatSettings floatsettings = EncodeFloatSettingsDefault,
        string newline = "\n", size_t width = 80
    )(in string prefix = "", in string key = null) const{
        auto keyprefix(){
            return key is null ? prefix : prefix ~ "\"" ~ key ~ "\": ";
        }
        final switch(this.type){
            case Type.Null:
            case Type.Boolean:
            case Type.Integer:
            case Type.Float:
            case Type.String:
                if(key is null) return prefix ~ this.encode!floatsettings;
                else return keyprefix() ~ this.encode!floatsettings;
            case Type.Array:
                // Arrays get some special handling in that short ones are
                // outputted on a single line and long ones, or ones with nested
                // array or object members, are outputted on multiple lines.
                if(this.store.arrayval.length == 0){
                    return keyprefix() ~ "[]";
                }else if(this.store.arrayval.all!(
                    e => e.type !is Type.Array && e.type !is Type.Object
                )){
                    auto values = this.store.arrayval.map!(e => e.encode!floatsettings);
                    immutable vlength = values.map!(e => e.length).sum + (values.length - 1) * 2;
                    immutable klength = key is null ? 0 : key.length + 4;
                    if(prefix.length + klength + 2 + vlength <= width){
                        return keyprefix() ~ "[" ~ values.join(", ").asarray ~ "]";
                    }else{
                        return(
                            keyprefix() ~ "[" ~ newline ~
                            values.map!(e => prefix ~ indent ~ e).join("," ~ newline).asarray ~ "\n" ~
                            prefix ~ "]"
                        );
                    }
                }else{
                    auto values = this.store.arrayval.map!(
                        e => e.pretty!(indent, floatsettings, newline, width)(
                            prefix ~ indent
                        )
                    );
                    return(
                        keyprefix() ~ "[" ~ newline ~
                        values.join("," ~ newline).asarray ~ newline ~
                        prefix ~ "]"
                    );
                }
            case Type.Object:
                if(this.store.objectval.length == 0){
                    return keyprefix() ~ "{}";
                }else{
                    auto values = this.store.objectval.keys.keysort!(
                        (a, b) => orderstrings(a, b) == -1
                    ).map!(
                        key => this[key].pretty!(indent, floatsettings, newline, width)(
                            prefix ~ indent, key
                        )
                    );
                    return(
                        keyprefix() ~ "{" ~ newline ~
                        values.join("," ~ newline).asarray ~ newline ~
                        prefix ~ "}"
                    );
                }
        }
    }
    
    static enum WriteFloatSettings EncodeFloatSettingsStandard = {
        PosNaNLiteral: "null",
        NegNaNLiteral: "null",
        PosInfLiteral: "null",
        NegInfLiteral: "null",
        trailingfraction: true,
    };
    static enum WriteFloatSettings EncodeFloatSettingsExtended = {
        PosNaNLiteral: NaNLiteral,
        NegNaNLiteral: NaNLiteral,
        PosInfLiteral: PosInfLiteral,
        NegInfLiteral: NegInfLiteral,
        trailingfraction: true,
    };
    
    static if(FloatLiteralsDefault){
        alias EncodeFloatSettingsDefault = EncodeFloatSettingsExtended;
    }else{
        alias EncodeFloatSettingsDefault = EncodeFloatSettingsStandard;
    }
    
    static string encodefloat(
        WriteFloatSettings floatsettings = EncodeFloatSettingsDefault
    )(in double value){
        return value.writefloat!floatsettings;
    }
    
    @property typeof(this) dup(){
        final switch(this.type){
            case Type.Null:
                return typeof(this)(null);
            case Type.Boolean:
                return typeof(this)(this.store.booleanval);
            case Type.Integer:
                return typeof(this)(this.store.integerval);
            case Type.Float:
                return typeof(this)(this.store.floatval);
            case Type.String:
                return typeof(this)(this.store.stringval.dup);
            case Type.Array:
                return typeof(this)(this.store.arrayval.dup);
            case Type.Object:
                return typeof(this)(this.store.objectval.dup);
        }
    }
    
    @property auto length() const{
        if(this.type is Type.String){
            return this.store.stringval.length;
        }else if(this.type is Type.Array){
            return this.store.arrayval.length;
        }else if(this.type is Type.Object){
            return this.store.objectval.length;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    @property bool empty() const{
        return this.length == 0;
    }
    
    string toString(
        WriteFloatSettings floatsettings = EncodeFloatSettingsDefault
    )() const{
        return this.encode!floatsettings;
    }
    
    void opAssign(T)(auto ref T value) if(canAssign!T){
        this.value = value;
    }
    
    enum isNumericOp(string op) = (
        op == "+" || op == "-" || op == "*" ||
        op == "/" || op == "%" || op == "^^"
    );
    enum isIntegerOp(string op) = (
        op == "&" || op == "|" || op == "^" ||
        op == "<<" || op == ">>" || op == ">>>"
    );
    
    /// Implements arithmetic operators with numeric types.
    auto opBinary(string op, T)(auto ref T value) if(isNumericOp!op && isNumeric!T){
        if(this.type is Type.Integer){
            mixin(`return JsonValue(this.store.integerval ` ~ op ~ ` value);`);
        }else if(this.type is Type.Float){
            mixin(`return JsonValue(this.store.floatval ` ~ op ~ ` value);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinaryRight(string op, T)(auto ref T value) if(isNumericOp!op && isNumeric!T){
        if(this.type is Type.Integer){
            mixin(`return JsonValue(value ` ~ op ~ ` this.store.integerval);`);
        }else if(this.type is Type.Float){
            mixin(`return JsonValue(value ` ~ op ~ ` this.store.floatval);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinary(string op)(JsonValue value) if(isNumericOp!op){
        if(this.type is Type.Integer && value.type is Type.Integer){
            mixin(`return JsonValue(this.store.integerval ` ~ op ~ ` value.store.integerval);`);
        }else if(this.type is Type.Integer && value.type is Type.Float){
            mixin(`return JsonValue(this.store.integerval ` ~ op ~ ` value.store.floatval);`);
        }else if(this.type is Type.Float && value.type is Type.Integer){
            mixin(`return JsonValue(this.store.floatval ` ~ op ~ ` value.store.integerval);`);
        }else if(this.type is Type.Float && value.type is Type.Float){
            mixin(`return JsonValue(this.store.floatval ` ~ op ~ ` value.store.floatval);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opOpAssign(string op, T)(auto ref T value) if(isNumericOp!op && isNumeric!T){
        if(this.type is Type.Integer){
            mixin(`this.store.integerval ` ~ op ~ `= value;`);
        }else if(this.type is Type.Float){
            mixin(`this.store.floatval ` ~ op ~ `= value;`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opOpAssign(string op)(JsonValue value) if(isNumericOp!op){
        if(this.type is Type.Integer && value.type is Type.Integer){
            mixin(`this.store.integerval ` ~ op ~ `= value.store.integerval;`);
        }else if(this.type is Type.Integer && value.type is Type.Float){
            mixin(`this.store.integerval ` ~ op ~ `= value.store.floatval;`);
        }else if(this.type is Type.Float && value.type is Type.Integer){
            mixin(`this.store.floatval ` ~ op ~ `= value.store.integerval;`);
        }else if(this.type is Type.Float && value.type is Type.Float){
            mixin(`this.store.floatval ` ~ op ~ `= value.store.floatval;`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Implements bit math operators with integral types.
    auto opBinary(string op, T)(auto ref T value) if(isIntegerOp!op && isIntegral!T){
        if(this.type is Type.Integer){
            mixin(`return JsonValue(this.store.integerval ` ~ op ~ ` value);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinaryRight(string op, T)(auto ref T value) if(isIntegerOp!op && isIntegral!T){
        if(this.type is Type.Integer){
            mixin(`return JsonValue(value ` ~ op ~ ` this.store.integerval);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinary(string op)(JsonValue value) if(isIntegerOp!op){
        if(this.type is Type.Integer && value.type is Type.Integer){
            mixin(`return JsonValue(this.store.integerval ` ~ op ~ ` value.store.integerval);`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opOpAssign(string op, T)(auto ref T value) if(isIntegerOp!op && isIntegral!T){
        if(this.type is Type.Integer){
            mixin(`this.store.integerval ` ~ op ~ `= value;`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opOpAssign(string op)(JsonValue value) if(isIntegerOp!op){
        if(this.type is Type.Integer && value.type is Type.Integer){
            mixin(`this.store.integerval ` ~ op ~ `= value.store.integerval;`);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Append a value to an array type or string type.
    auto append(T)(auto ref T value) if(canAssign!T){
        static if(is(T : string) && !isNull!T){
            if(this.type is Type.String){
                this.store.stringval ~= value;
                return;
            }
        }else static if(is(T : JsonValue)){
            if(this.type is Type.String && value.type is Type.String){
                this.store.stringval ~= value.store.stringval;
                return;
            }
        }
        if(this.type is Type.Array){
            this.store.arrayval ~= JsonValue(value);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Append values from an array to an array type.
    auto extend(T)(auto ref T value) if(canAssignArray!T){
        if(this.type is Type.Array){
            this.store.arrayval.reserve(
                this.store.arrayval.length + value.length
            );
            foreach(i; value) this.store.arrayval ~= JsonValue(i);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto extend(JsonValue value){
        if(this.type is Type.Array && value.type is Type.Array){
            this.store.arrayval.reserve(
                this.store.arrayval.length + value.store.arrayval.length
            );
            foreach(i; value.store.arrayval) this.store.arrayval ~= i.dup;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Remove a key from an object type.
    bool remove(in string key){
        if(this.type is Type.Object){
            return this.store.objectval.remove(key);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Clear all values in an array or object type.
    void clear(){
        if(this.type is Type.Array){
            this.store.arrayval.length = 0;
        }else if(this.type is Type.Object){
            this.store.objectval.clear();
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Append a value to an array type or string type.
    auto opOpAssign(string op: "~", T)(auto ref T value) if(canAssign!T){
        this.append(value);
    }
    /// Append a character to a string type.
    auto opOpAssign(string op: "~")(in char value){
        if(this.type is Type.String){
            this.store.stringval ~= value;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Concatenate two strings.
    auto opBinary(string op: "~")(in string value){
        if(this.type is Type.String){
            return JsonValue(this.store.stringval ~ value);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinary(string op: "~")(in JsonValue value){
        if(this.type is Type.String && value.type is Type.String){
            return JsonValue(this.store.stringval ~ value.store.stringval);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinaryRight(string op: "~")(in string value){
        if(this.type is Type.String){
            return JsonValue(value ~ this.store.stringval);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Check for the presence of a value for array types.
    auto contains(T)(auto ref T value) if(canAssign!T){
        if(this.type is Type.Array){
            foreach(i; this.store.arrayval){
                if(i == value) return true;
            }
            return false;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Check for the presence of a key for object types.
    auto haskey(in string key) const{
        if(this.type is Type.Object){
            return key in this.store.objectval;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opBinaryRight(string op: "in")(in string key) const{
        return this.haskey(key);
    }
    
    /// Implements negation for numeric types.
    auto opUnary(string op: "-")() const{
        if(this.type is Type.Integer){
            return JsonValue(-this.store.integerval);
        }else if(this.type is Type.Float){
            return JsonValue(-this.store.floatval);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Implements kind of pointless '+' operator for numeric types.
    auto opUnary(string op: "+")() const{
        if(this.type is Type.Integer || this.type is Type.Float){
            return this;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Implements the complement operator for integral types.
    auto opUnary(string op: "~")() const{
        if(this.type is Type.Integer){
            return JsonValue(~this.store.integerval);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Implements the increment operator for numeric types.
    auto opUnary(string op: "++")(){
        if(this.type is Type.Integer){
            this.store.integerval++;
            return this;
        }else if(this.type is Type.Float){
            this.store.floatval++;
            return this;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// Implements the decrement operator for numeric types.
    auto opUnary(string op: "--")(){
        if(this.type is Type.Integer){
            this.store.integerval--;
            return this;
        }else if(this.type is Type.Float){
            this.store.floatval--;
            return this;
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Implements numeric index operator for string and array types.
    auto opIndex(in size_t index) const{
        if(this.type is Type.String){
            return JsonValue(this.store.stringval[index]);
        }else if(this.type is Type.Array){
            return this.store.arrayval[index];
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opIndexAssign(T)(auto ref T value, in size_t index) if(canAssign!T){
        if(this.type is Type.Array){
            return this.store.arrayval[index] = JsonValue(value);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Implements key index operator for object types.
    auto opIndex(in string key) const{
        if(this.type is Type.Object){
            return this.store.objectval[key];
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    /// ditto
    auto opIndexAssign(T)(auto ref T value, in string key) if(canAssign!T){
        if(this.type is Type.Object){
            return this.store.objectval[key] = JsonValue(value);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    /// Implements slice operator for string and array types.
    auto opSlice(in size_t low, in size_t high) const in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        if(this.type is Type.String){
            return JsonValue(this.store.stringval[low .. high]);
        }else if(this.type is Type.Array){
            return JsonValue(this.store.arrayval[low .. high]);
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    bool opEquals(T)(auto ref T value) const if(canAssign!T){
        static if(is(T : JsonValue)){
            if(this.type is value.type){
                final switch(this.type){
                    case Type.Null:
                        return true;
                    case Type.Boolean:
                        return this.store.booleanval == value.store.booleanval;
                    case Type.Integer:
                        return this.store.integerval == value.store.integerval;
                    case Type.Float:
                        return this.store.floatval == value.store.floatval;
                    case Type.String:
                        return this.store.stringval == value.store.stringval;
                    case Type.Array:
                        return this.store.arrayval == value.store.arrayval;
                    case Type.Object:
                        return this.store.objectval == cast(const Object) value.store.objectval;
                }
            }else if(this.type is Type.Integer && value.type is Type.Float){
                return this.store.integerval == value.store.floatval;
            }else if(this.type is Type.Float && value.type is Type.Integer){
                return this.store.floatval == value.store.integerval;
            }else{
                return false;
            }
        }else static if(isNull!T){
            if(this.type is Type.Null) return true;
            else throw new JsonInvalidOperationException();
        }else static if(isBoolean!T){
            if(this.type is Type.Boolean) return value == this.store.booleanval;
            else throw new JsonInvalidOperationException();
        }else static if(isNumeric!T){
            if(this.type is Type.Integer) return value == this.store.integerval;
            else if(this.type is Type.Float) return value == this.store.floatval;
            else throw new JsonInvalidOperationException();
        }else static if(isCharacter!T){
            if(this.type is Type.Integer) return value == this.store.integerval;
            else throw new JsonInvalidOperationException();
        }else static if(is(T : string)){
            if(this.type is Type.String) return value == this.store.stringval;
            else throw new JsonInvalidOperationException();
        }else static if(is(T : Array)){
            if(this.type is Type.Array) return value == this.store.arrayval;
            else throw new JsonInvalidOperationException();
        }else static if(is(T : Object)){
            if(this.type is Type.Object) return cast(const Object) value == this.store.objectval;
            else throw new JsonInvalidOperationException();
        }else static if(canAssignArray!T){
            if(this.type is Type.Array){
                if(this.store.arrayval.length != value.length) return false;
                for(size_t i = 0; i < this.store.arrayval.length; i++){
                    if(this.store.arrayval[i] != value[i]) return false;
                }
                return true;
            }else{
                throw new JsonInvalidOperationException();
            }
        }else static if(canAssignAssociativeArray!T){
            if(this.type is Type.Object){
                if(this.store.objectval.length != value.length) return false;
                foreach(k; value.byKey){
                    if(k !in this.store.objectval) return false;
                }
                foreach(k, v0; this.store.objectval){
                    if(auto v1 = k in value){
                        if(v0 != *v1) return false;
                    }else{
                        return false;
                    }
                }
                return true;
            }else{
                throw new JsonInvalidOperationException();
            }
        }else{
            throw new JsonInvalidOperationException();
        }
    }
    
    auto opCast(T)() const{
        final switch(this.type){
            case Type.Boolean:
                static if(isBoolean!T) return cast(T) this.store.booleanval;
                else static if(isIntegral!T) return cast(T) this.store.booleanval;
                else throw new JsonInvalidOperationException();
            case Type.Integer:
                static if(isBoolean!T) return cast(T)(this.store.integerval != 0);
                else static if(isNumeric!T) return cast(T) this.store.integerval;
                else throw new JsonInvalidOperationException();
            case Type.Float:
                static if(isBoolean!T) return cast(T)(this.store.floatval != 0);
                else static if(isNumeric!T) return cast(T) this.store.floatval;
                else throw new JsonInvalidOperationException();
            case Type.String:
                static if(is(T : string) && !isNull!T) return cast(T) this.store.stringval;
                else throw new JsonInvalidOperationException();
            case Type.Array:
                static if(isArray!T){
                    T array;
                    foreach(e; this.store.arrayval){
                        array ~= cast(ArrayElementType!T) e;
                    }
                    return array;
                }else{
                    throw new JsonInvalidOperationException();
                }
            case Type.Object:
                static if(isAssociativeArray!T && is(ArrayKeyType!T : string)){
                    T array;
                    foreach(k, v; this.store.objectval){
                        array[k] = cast(ArrayValueType!T) v;
                    }
                    return array;
                }else{
                    throw new JsonInvalidOperationException();
                }
            case Type.Null:
                static if(isBoolean!T) return cast(T) false;
                else static if(isFloatingPoint!T) return T.nan;
                else static if(is(typeof({cast(T) null;}))) return cast(T) null;
                else throw new JsonInvalidOperationException();
        }
    }
}



version(unittest){
    private:
    import mach.test;
    alias Type = JsonValue.Type;
    
enum prettyjsonarray = `[
  0,
  1,
  2,
  "hi",
  ["hello", "again"]
]`;
enum prettyjsonobject = `{
  "a": "apple",
  "b": "bear",
  "c": "car"
}`;
enum prettyjsonobjectnested = `{
  "a": "apple",
  "array": [],
  "b": "bear",
  "booleans": [true, false],
  "c": "car",
  "float": 1.0,
  "int": 1,
  "null": null,
  "object": {
    "d": "drop"
  }
}`;

}
unittest{
    tests("Json value", {
        tests("Null", {
            auto x = JsonValue(Type.Null);
            auto y = JsonValue(null);
            testis(x.type, Type.Null);
            testis(y.type, Type.Null);
            testeq(x, null);
            testeq(y, null);
            testeq(x, y);
            testeq(x.encode, "null");
            testeq(x.pretty, "null");
        });
        tests("Boolean", {
            auto x = JsonValue(Type.Boolean);
            auto y = JsonValue(false);
            auto z = JsonValue(true);
            testis(x.type, Type.Boolean);
            testis(y.type, Type.Boolean);
            testis(z.type, Type.Boolean);
            testeq(x, false);
            testeq(y, false);
            testeq(z, true);
            testeq(x.encode, "false");
            testeq(x.pretty, "false");
            testeq(y.encode, "false");
            testeq(y.pretty, "false");
            testeq(z.encode, "true");
            testeq(z.pretty, "true");
        });
        tests("Numeric", {
            auto x = JsonValue(Type.Integer);
            auto y = JsonValue(int(0));
            auto z = JsonValue(Type.Float);
            auto w = JsonValue(double(0));
            testis(x.type, Type.Integer);
            testis(y.type, Type.Integer);
            testis(z.type, Type.Float);
            testis(w.type, Type.Float);
            foreach(n; [x, y, z, w]){
                // String
                if(n.type is Type.Integer){
                    testeq(n.encode, "0");
                    testeq(n.pretty, "0");
                }else{
                    testeq(n.encode, "0.0");
                    testeq(n.pretty, "0.0");
                }
                // Equality
                testeq(n, int(0));
                testeq(n, long(0));
                testeq(n, uint(0));
                testeq(n, ulong(0));
                testeq(n, float(0));
                testeq(n, double(0));
                testneq(n, int(1));
                testneq(n, long(1));
                testneq(n, uint(1));
                testneq(n, ulong(1));
                testneq(n, float(1));
                testneq(n, double(1));
                // Assignment
                JsonValue i;
                i = n;
                testeq(i, n);
                i = true;
                testneq(i, n);
                // Artihmetic OpBinary/OpBinaryRight
                auto sum0 = n + 1;
                auto sum1 = 1 + n;
                auto sum2 = n + JsonValue(1);
                auto sum3 = n + JsonValue(1.0);
                testis(sum0.type, n.type);
                testis(sum1.type, n.type);
                testis(sum2.type, n.type);
                testis(sum3.type, Type.Float); // Verify type promotion
                foreach(s; [sum0, sum1, sum2, sum3]) testeq(s, 1);
                testeq(n - 1, -1);
                testeq((n + 1) * 10, 10);
                testeq((n + 10) / 2, 5);
                testeq((n + 3) % 2, 1);
                testeq((n + 2) ^^ 3, 8);
                // Bit math OpBinary/OpBinaryRight
                if(n.type is Type.Integer){
                    testeq(n | 1, 1);
                    testeq(n & 1, 0);
                    testeq(n ^ 1, 1);
                    testeq((n + 1) << 1, 2);
                    testeq((n + 2) >> 1, 1);
                    testeq((n + 2) >>> 1, 1);
                }else{
                    testfail({n | 0;});
                    testfail({n & 0;});
                    testfail({n ^ 0;});
                    testfail({n << 0;});
                    testfail({n >> 0;});
                    testfail({n >>> 0;});
                }
                // OpUnary const
                testeq(+(n + 1), 1);
                testeq(-(n + 1), -1);
                if(n.type is Type.Integer) testeq(~(n + 1), ~1);
                else testfail({~n;}); // Complement unsupported for floats
                // Increment/Decrement
                auto j = n;
                testeq(++j, 1);
                testeq(--j, 0);
                // OpOpAssign
                auto k = n;
                k += 1;
                testeq(k, 1);
                k -= 2;
                testeq(k, -1);
                k *= -4;
                testeq(k, 4);
                k /= 2;
                testeq(k, 2);
                k %= 2;
                testeq(k, 0);
                k += 2; k ^^= 3;
                testeq(k, 8);
                if(n.type is Type.Integer){
                    k |= 7;
                    testeq(k, 15);
                    k &= 7;
                    testeq(k, 7);
                    k ^= 1;
                    testeq(k, 6);
                    k <<= 1;
                    testeq(k, 12);
                    k >>= 1;
                    testeq(k, 6);
                    k >>>= 1;
                    testeq(k, 3);
                }else{
                    testfail({n |= 0;});
                    testfail({n &= 0;});
                    testfail({n ^= 0;});
                    testfail({n <<= 0;});
                    testfail({n >>= 0;});
                    testfail({n >>>= 0;});
                } 
                // Unsupported operations
                testfail({n.empty;});
                testfail({n.length;});
                testfail({n.contains(0);});
                testfail({n.haskey("");});
                testfail({n.append(0);});
                testfail({n.extend([0]);});
                testfail({n ~= 0;});
            }
        });
        tests("String", {
            {
                auto x = JsonValue(Type.String);
                auto y = JsonValue("");
                foreach(str; [x, y]){
                    testis(str.type, Type.String);
                    testeq(str, "");
                    testeq(str.length, 0);
                    test(str.empty);
                }
            }{
                auto hi = JsonValue("Hello");
                testeq(hi, "Hello");
                testeq(hi.length, 5);
                testf(hi.empty);
                hi ~= " World";
                testeq(hi, "Hello World");
                hi ~= '!';
                testeq(hi, "Hello World!");
                hi ~= JsonValue(" Hiya");
                testeq(hi, "Hello World! Hiya");
                testeq(hi[0], 'H');
                JsonValue slice = hi[0 .. 5];
                testeq(slice, "Hello");
                testeq(hi.encode(), `"Hello World! Hiya"`);
                testeq(hi.pretty(), `"Hello World! Hiya"`);
                testeq(slice.encode(), `"Hello"`);
                testeq(slice.pretty(), `"Hello"`);
                JsonValue concat = slice ~ " There";
                testeq(concat, "Hello There");
                testeq(slice ~ slice, "HelloHello");
            }
        });
        tests("Array", {
            {
                auto array = JsonValue(Type.Array);
                testeq(array.length, 0);
                test(array.empty);
                testeq(array, new int[0]);
            }{
                auto array = JsonValue([0, 1, 2]);
                testeq(array.length, 3);
                testf(array.empty);
                testeq(array, [0, 1, 2]);
                testeq(array[0], 0);
                testeq(array[1], 1);
                testeq(array[2], 2);
                testeq(array[0 .. 0], new int[0]);
                testeq(array[0 .. 2], [0, 1]);
                testeq(array[1 .. 3], [1, 2]);
                testeq(array[0 .. 3], array);
                // Test string encoding
                testeq(JsonValue(Type.Array).encode, `[]`);
                testeq(JsonValue(Type.Array).pretty, `[]`);
                testeq(array.encode, `[0,1,2]`);
                array.append("hi");
                testeq(array.encode, `[0,1,2,"hi"]`);
                testeq(array.pretty, `[0, 1, 2, "hi"]`);
                // And where pretty results in multi-line
                array.append(JsonValue(["hello", "again"]));
                testeq(array.encode, `[0,1,2,"hi",["hello","again"]]`);
                testeq(array.pretty, prettyjsonarray);
                // Test append/extend
                testeq(array.length, 5);
                array.append(null);
                testeq(array.length, 6);
                array.extend([0, 1, 2]);
                testeq(array.length, 9);
            }
        });
        tests("Object", {
            tests("Empty object", {
                auto obj = JsonValue(Type.Object);
                testeq(obj.length, 0);
                test(obj.empty);
                string[string] aa;
                testeq(obj, aa);
            });
            tests("Encode empty object", {
                testeq(JsonValue(Type.Object).encode, `{}`);
                testeq(JsonValue(Type.Object).pretty, `{}`);
            });
            tests("Encoding", {
                auto aa = ["a": "apple", "b": "bear", "c": "car"];
                auto obj = JsonValue(aa);
                testeq(obj.length, 3);
                testf(obj.empty);
                testeq(obj, aa);
                testeq(obj["a"], "apple");
                obj.encode; // Can't compare because order of keys not guaranteed
                testeq(obj.pretty, prettyjsonobject);
                obj["null"] = null;
                obj["booleans"] = [true, false];
                obj["int"] = int(1);
                obj["float"] = double(1);
                obj["array"] = new int[0];
                obj["object"] = JsonValue(["d": "drop"]);
                testeq(obj["array"], JsonValue(Type.Array));
                testeq(obj.length, 9);
                testeq(obj.pretty, prettyjsonobjectnested);
            });
            tests("Clear and remove keys", {
                auto obj = JsonValue(["a": "apple", "b": "bear", "c": "car"]);
                testeq(obj.length, 3);
                test("a" in obj);
                test("b" in obj);
                test("c" in obj);
                testf(obj.remove("x"));
                testeq(obj.length, 3);
                test(obj.remove("a"));
                testeq(obj.length, 2);
                testf("a" in obj);
                obj.clear();
                testeq(obj.length, 0);
                testf("b" in obj);
                testf("c" in obj);
            });
        });
    });
}
