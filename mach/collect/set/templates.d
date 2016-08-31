module mach.collect.set.templates;

private:

import mach.traits : isIterableOf, hasNumericLength, hasEnumValue;
import mach.range : all;

public:



enum isSet(T) = hasEnumValue!(T, `isSet`, true);



template SetMixin(T){
    static enum bool isSet = true;
    
    /// Get the number of elements in the set.
    @property size_t length();
    /// True when the set contains no elements, false otherwise.
    @property bool empty();
    
    /// Determine whether the set contains some value.
    bool contains(T value){
        return this.containsvalue(value);
    }
    /// Determine whether the set contains all values in an iterable. This
    /// operation can also be used to determine whether another set is a subset
    /// of this one. Return true when the passed iterable of values is empty.
    bool contains(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        foreach(value; values){
            if(!this.contains(value)) return false;
        }
        return true;
    }
    
    /// Add an item to the set. If the item is already contained, then no
    /// change will be affected. Return true when the item was newly added, and
    /// false if the item was already in the set.
    bool add(T value){
        return this.addvalue(value);
    }
    /// Add all of the values contained in an iterable. Return the number of
    /// added values that had not previously been in the set.
    size_t add(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        size_t sum = 0;
        foreach(ref T value; values) sum += this.add(value);
        return sum;
    }
    /// Add multiple values at once. Return the number of added values that had
    /// not previously been in the set.
    size_t add(T[] values...){
        size_t sum = 0;
        foreach(ref T value; values) sum += this.add(value);
        return sum;
    }
    
    /// Remove an item from the set. If the item is already not contained, then
    /// no change will be affected. Return true when an item was removed, and
    /// false when the item did not exist in the set.
    bool remove(T value){
        return this.removevalue(value);
    }
    /// Remove all of the values contained in an iterable. Return the number of
    /// removed values that had previously been in the set.
    size_t remove(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        size_t sum = 0;
        foreach(ref T value; values) sum += this.remove(value);
        return sum;
    }
    /// Remove multiple values at once. Return the number of removed values that
    /// had previously been in the set.
    size_t remove(T[] values...){
        size_t sum = 0;
        foreach(ref T value; values) sum += this.remove(value);
        return sum;
    }
    
    /// Remove and return an arbitrary value from the set.
    T pop();
    
    /// Remove all values from the set.
    void clear();
    
    /// Return a set which is the union of this set and another iterable, such
    /// as a set.
    typeof(this) unity(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        auto result = this.dup;
        result.add(values);
        return result;
    }
    /// Return a set which is the difference of this set and another iterable,
    /// such as a set.
    typeof(this) difference(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        auto result = this.dup;
        result.remove(values);
        return result;
    }
    /// Return a set which is the intersection of this set and another iterable,
    /// such as a set.
    typeof(this) intersection(Values)(auto ref Values values) if(
        isIterableOf!(Values, T) /* TODO: && can use in op */
    ){
        auto result = this.dup;
        foreach(ref T value; result){
            if(value !in values) result.remove(value);
        }
        return result;
    }
    
    /// Determine whether two sets are equal or, if the object to which this set
    /// is being compared is an iterable not guaranteed to have unique values,
    /// whether this set contains all values that the iterable does and that
    /// the iterable contains all values that this set does.
    bool equals(Values)(auto ref Values values) if(
        isIterableOf!(Values, T) /* TODO: && can use in op */
    ){
        static if(.isSet!Values){
            return this.length == values.length && this.contains(values);
        }else{
            static if(hasNumericLength!Values){
                if(this.length != values.length) return false;
            }
            auto unity = this.dup;
            auto intersection = this.dup;
            foreach(value; values){
                if(unity.add(value)) return false;
                if(!intersection.remove(value)) return false;
            }
            return true;
        }
    }
    
    /// Create and return a shallow copy of this set.
    @property typeof(this) dup();
    
    /// Get the contents of this set as an array with arbitrary ordering.
    auto asarray(){
        T[] array;
        array.reserve(this.length);
        foreach(ref T value; this) array ~= value;
        return array;
    }
    
    auto opBinaryRight(string op: "in")(T value){
        return this.contains(value);
    }
    auto opBinaryRight(Values, string op: "in")(auto ref Values values) if(
        isIterableOf!(Values, T)
    ){
        return this.contains(values);
    }
    
    auto opBinary(Values, string op: "|")(auto ref Values values) if(
        isIterableOf!(Values, T)
    ){
        return this.unity(values);
    }
    auto opBinary(Values, string op: "-")(auto ref Values values) if(
        isIterableOf!(Values, T)
    ){
        return this.difference(values);
    }
    auto opBinary(Values, string op: "&")(auto ref Values values) if(
        isIterableOf!(Values, T)
    ){
        return this.intersection(values);
    }
    
    bool opEquals(Values)(auto ref Values values) if(
        isIterableOf!(Values, T)
    ){
        return this.equals(values);
    }
    
    string toString() const{
        import std.conv : to;
        string str = "";
        foreach(const ref T value; this){
            if(str.length) str ~= ", ";
            str ~= value.to!string;
        }
        return "[" ~ str ~ "]";
    }
}
