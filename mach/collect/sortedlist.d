module mach.collect.sortedlist;

private:

import std.meta : AliasSeq;
import mach.traits : canReassign, isIterableOf;
import mach.collect.linkedlist : LinkedList, LinkedListRange, LinkedListNodes;
import mach.collect.linkedlist : DefaultLinkedListAllocator;

public:



alias DefaultSortedListCompare = (a, b) => (a > b);



struct SortedList(
    T, alias compare = DefaultSortedListCompare,
    Allocator = DefaultLinkedListAllocator
){
    alias List = LinkedList!(T, Allocator);
    alias Node = List.Node;
    alias opDollar = length;
    alias Element = T;
    
    List list = null;
    
    this(typeof(this) list){
        this.list = list.list;
    }
    this(T[] values...){
        this.insert(values);
    }
    this(Iter)(Iter values) if(isIterableOf!(Iter, T)){
        this.insert(values);
    }
    
    static typeof(this) fromsortedlinkedlist(List list){
        typeof(this) sorted;
        sorted.list = list;
        return sorted;
    }
    
    auto insert(T value){
        if(this.list is null) this.list = new List;
        for(auto range = this.nodes; !range.empty; range.popFront()){
            if(compare(value, range.front.value)){
                return this.list.insertbefore(range.front, value);
            }
        }
        return this.list.append(value);
    }
    auto insert(Node* node){
        if(this.list is null) this.list = new List;
        for(auto range = this.nodes; !range.empty; range.popFront()){
            if(compare(node.value, range.front.value)){
                return this.list.insertbefore(range.front, node);
            }
        }
        return this.list.append(node);
    }
    
    void insert(T[] values...){
        foreach(value; values) this.insert(value);
    }
    void insert(Iter)(Iter values...) if(isIterableOf!(Iter, T)){
        foreach(value; values) this.insert(value);
    }
    
    @property bool empty() const pure nothrow @safe @nogc{
        return this.list is null || this.list.empty;
    }
    @property auto length() const pure nothrow @safe @nogc{
        return this.list is null ? 0 : this.list.length;
    }
    @property auto ref frontnode() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    }body{
        return this.list.frontnode;
    }
    @property auto ref backnode() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    }body{
        return this.list.backnode;
    }
    @property auto ref front() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    }body{
        return this.list.frontnode.value;
    }
    @property auto ref back() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    }body{
        return this.list.backnode.value;
    }
    auto contains(in Node* node) const pure @safe nothrow @nogc{
        return !this.empty && this.list.contains(node);
    }
    auto contains(in T value) const{
        return !this.empty && this.list.contains(value);
    }
    auto remove(Node* node) nothrow @nogc in{
        assert(!this.empty);
    }body{
        return this.list.remove(node);
    }
    auto removefront() nothrow @nogc in{
        assert(!this.empty);
    }body{
        return this.list.removefront();
    }
    auto removeback() nothrow @nogc in{
        assert(!this.empty);
    }body{
        return this.list.removeback();
    }
    auto clear() nothrow @nogc{
        if(!this.empty) this.list.clear();
    }
    
    auto nodeat(Index)(Index index) const pure nothrow @trusted @nogc if(isIntegral!Index) in{
        assert(!this.empty);
    }body{
        return this.list.nodeat!Index(index);
    }
    auto nodeindex(Index = size_t)(in Node* node) const pure nothrow @trusted @nogc if(canIncrement!Index) in{
        assert(!this.empty);
    }body{
        return this.list.nodeindex!Index(node);
    }
    
    auto asrange()() pure nothrow @safe @nogc{
        return this.asrange!(canReassign!(typeof(this)));
    }
    auto asrange(bool mutable)() pure nothrow @safe @nogc if(mutable){
        if(!this.empty){
            return this.list.asrange!mutable;
        }else{
            LinkedListRange!(List) range;
            return range;
        }
    }
    auto asrange(bool mutable)() pure nothrow @safe @nogc const if(!mutable){
        if(!this.empty){
            return this.list.asrange!mutable;
        }else{
            LinkedListRange!(const List) range;
            return range;
        }
    }
    auto asarray() pure nothrow @safe{
        if(!this.empty){
            return this.list.asarray;
        }else{
            return new T[0];
        }
    }
    
    alias values = this.asrange!false;
    auto nodes() pure const nothrow @safe @nogc{
        if(!this.empty){
            return this.list.nodes;
        }else{
            LinkedListNodes!(T, Allocator) nodes;
            return nodes;
        }
    }
    
    auto ref opIndex(in size_t index) const pure nothrow @trusted @nogc in{
        assert(!this.empty);
        assert(index >= 0 && index < this.length);
    }body{
        return this.list[index];
    }
    auto ref opSlice()(in size_t low, in size_t high) nothrow in{
        assert(!this.empty);
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        return fromsortedlinkedlist(this.list[low .. high]);
    }
    
    void opOpAssign(string op: "~")(T rhs){
        this.insert(rhs);
    }
    
    @property auto dup(){
        return fromsortedlinkedlist(this.empty ? null : this.list.dup);
    }
    
    /// Determine if the elements of a linked list are currently sorted
    /// according to the sorting function.
    static bool issorted(List list){
        if(list !is null && !list.empty){
            auto range = list.asrange!false;
            while(true){
                T front = range.front;
                if(!range.empty){
                    range.popFront();
                    if(!compare(front, range.front)) return false;
                }else{
                    break;
                }
            }
        }
        return true;
    }
    
    string toString() const nothrow{
        return this.empty ? "" : this.list.toString();
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Sorted list", {
        tests("Basic sorting", {
            SortedList!int list;
            list.insert(1, 3);
            list.insert(4);
            list.insert(2);
            testeq(list.asarray, [4, 3, 2, 1]);
            testf(list.empty);
            testeq(list.length, 4);
        });
        tests("Random access", {
            auto list = SortedList!int(2, 1, 3);
            testeq(list[0], 3);
            testeq(list[1], 2);
            testeq(list[2], 1);
        });
        tests("Slicing", {
            auto list = SortedList!int(1, 2, 3, 4, 5);
            testeq(list[1 .. $-1].asarray, [4, 3, 2]);
        });
    });
}
