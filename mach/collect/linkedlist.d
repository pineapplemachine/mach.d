module mach.collect.linkedlist;

private:

import std.typecons : Tuple;
import std.experimental.allocator : make, dispose;
import std.experimental.allocator.gc_allocator : GCAllocator;
import mach.traits : isIterableOf, ElementType;

template NodesTuple(T, Allocator){
    alias Node = LinkedListNode!(T, Allocator);
    alias NodesTuple = Tuple!(Node*, `front`, Node*, `back`, size_t, `length`);
}

public:



alias DefaultLinkedListAllocator = GCAllocator;



/// Implements a cyclic doubly-linked list.
struct LinkedList(T, Allocator = DefaultLinkedListAllocator){
    alias Node = LinkedListNode!(T, Allocator);
    alias Nodes = NodesTuple!(T, Allocator);
    alias opDollar = length;
    alias insert = insertbefore;
    
    private enum isNodes(T) = is(T == Node*) || is(T == Nodes);
    
    Node* frontnode; /// First node in the list.
    Node* backnode; /// Last node in the list.
    size_t length; /// Number of nodes currently in the list.
    
    this(T[] elements...){
        this.append(elements);
    }
    this(Iter)(Iter iter) if(isIterableOf!(Iter, T)){
        this.append(iter);
    }
    
    ~this(){
        this.clear();
    }
    
    /// Safe postblitting would require copying; since that's potentially
    /// expensive require that it be done explicitly.
    this(this) @disable;
    
    void setnodes(Node* node) pure nothrow @safe @nogc{
        node.prev = node;
        node.next = node;
        this.frontnode = node;
        this.backnode = node;
        this.length = 1;
    }
    void setnodes(Nodes nodes) pure nothrow @safe @nogc{
        this.frontnode = nodes.front;
        this.backnode = nodes.back;
        nodes.front.prev = this.backnode;
        nodes.back.next = this.frontnode;
        this.length = nodes.length;
    }
    
    /// True when the list contains no elements.
    @property bool empty() const pure nothrow @safe @nogc{
        return this.frontnode is null;
    }
    
    /// Get the frontmost value in the list.
    @property auto ref front() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    } body{
        return this.frontnode.value;
    }
    /// Set the frontmost value in the list.
    @property void front(ref T value) pure nothrow @safe @nogc in{
        assert(!this.empty);
    } body{
        this.frontnode.value = value;
    }
    /// Get the backmost value in the list.
    @property auto ref back() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    } body{
        return this.backnode.value;
    }
    /// Set the frontmost value in the list.
    @property void back(ref T value) pure nothrow @safe @nogc in{
        assert(!this.empty);
    } body{
        this.backnode.value = value;
    }
    
    /// Add a single value to the end of the list.
    auto append(T value){
        auto node = Allocator.instance.make!Node(value);
        this.append(node);
        return node;
    }
    /// Add many values to the end of the list.
    auto append(T[] values...){
        auto nodes = Node.many(values);
        this.append(nodes);
        return nodes;
    }
    /// ditto
    auto append(Iter)(Iter values) if(isIterableOf!(Iter, T)){
        auto nodes = Node.many(values);
        this.append(nodes);
        return nodes;
    }
    /// Add a single value to the beginning of the list.
    auto prepend(T value){
        auto node = Allocator.instance.make!Node(value);
        this.prepend(node);
        return node;
    }
    /// Add many values to the beginning of the list.
    auto prepend(T[] values...){
        auto nodes = Node.many(values);
        this.prepend(nodes);
        return nodes;
    }
    /// ditto
    auto prepend(Iter)(Iter values) if(isIterableOf!(Iter, T)){
        auto nodes = Node.many(values);
        this.prepend(nodes);
        return nodes;
    }
    
    
    /// Insert a single value at an arbitrary position in the list.
    auto insertbefore(size_t index, T value){
        auto node = Allocator.instance.make!Node(value);
        this.insertbefore(index, node);
        return node;
    }
    /// Insert many values at an arbitrary position in the list.
    auto insertbefore(size_t index, T[] values...){
        auto nodes = Node.many(values);
        this.insertbefore(index, nodes);
        return nodes;
    }
    /// ditto
    auto insertbefore(Iter)(size_t index, Iter values) if(isIterableOf!(Iter, T)){
        auto nodes = Node.many(values);
        this.insertbefore(index, nodes);
        return nodes;
    }
    /// Insert a single value at an arbitrary position in the list.
    auto insertafter(size_t index, T value){
        auto node = Allocator.instance.make!Node(value);
        this.insertafter(index, node);
        return node;
    }
    /// Insert many values at an arbitrary position in the list.
    auto insertafter(size_t index, T[] values...){
        auto nodes = Node.many(values);
        this.insertafter(index, nodes);
        return nodes;
    }
    /// ditto
    auto insertafter(Iter)(size_t index, Iter values) if(isIterableOf!(Iter, T)){
        auto nodes = Node.many(values);
        this.insertafter(index, nodes);
        return nodes;
    }
    
    void append(N)(N nodes) pure nothrow @safe @nogc if(isNodes!N){
        if(this.empty) this.setnodes(nodes);
        else this.insertafternode(this.backnode, nodes);
    }
    void prepend(N)(N nodes) pure nothrow @safe @nogc if(isNodes!N){
        if(this.empty) this.setnodes(nodes);
        else this.insertbeforenode(this.frontnode, nodes);
    }
    
    void insertbefore(N)(size_t index, N nodes) pure nothrow @safe @nogc if(isNodes!N) in{
        assert(index >= 0 && index < this.length);
    }body{
        if(this.empty) this.setnodes(nodes);
        else this.insertbeforenode(this.nodeat(index), nodes);
    }
    void insertafter(N)(size_t index, N nodes) pure nothrow @safe @nogc if(isNodes!N) in{
        assert(index >= 0 && index < this.length);
    }body{
        if(this.empty) this.setnodes(nodes);
        else this.insertafternode(this.nodeat(index), nodes);
    }
    
    void insertbeforenode(Node* before, Node* node) pure nothrow @safe @nogc{
        this.insertbeforenode(before, node, node, 1);
    }
    void insertafternode(Node* after, Node* node) pure nothrow @safe @nogc{
        this.insertafternode(after, node, node, 1);
    }
    
    void insertbeforenode(Iter)(Node* before, Iter values) pure nothrow @safe @nogc if(
        isIterableOf!(Iter, T)
    ){
        this.insertbeforenode(before, Node.many(values));
    }
    void insertafternode(Iter)(Node* after, Iter values) pure nothrow @safe @nogc if(
        isIterableOf!(Iter, T)
    ){
        this.insertafternode(after, Node.many(values));
    }
    
    void insertbeforenode(Node* before, Nodes nodes) pure nothrow @safe @nogc{
        this.insertbeforenode(before, nodes.front, nodes.back, nodes.length);
    }
    void insertafternode(Node* after, Nodes nodes) pure nothrow @safe @nogc{
        this.insertafternode(after, nodes.front, nodes.back, nodes.length);
    }
    
    void insertbeforenode(
        Node* before, Node* front, Node* back, size_t length
    ) pure nothrow @safe @nogc{
        back.next = before;
        front.prev = before.prev;
        before.prev.next = front;
        before.prev = back;
        this.length += length;
        if(before is this.frontnode) this.frontnode = front;
    }
    void insertafternode(
        Node* after, Node* front, Node* back, size_t length
    ) pure nothrow @safe @nogc{
        front.prev = after;
        back.next = after.next;
        after.next.prev = back;
        after.next = front;
        this.length += length;
        if(after is this.backnode) this.backnode = back;
    }
    
    /// Clear the list, optionally calling some callbacks on each element of the
    /// list, for example a function that frees newly-unused memory.
    void clear(callbacks...)(){
        if(!this.empty){
            Node* current = this.frontnode;
            do{
                auto next = current.next;
                foreach(callback; callbacks) callback(current.value);
                Allocator.instance.dispose(current);
                current = next;
            } while(current != this.frontnode);
            this.frontnode = null;
            this.backnode = null;
            this.length = 0;
        }
    }
    
    /// Create a new list containing the same elements as this one.
    typeof(this) copy(callbacks...)(){
        typeof(this) list;
        if(!this.empty){
            Node* current = this.frontnode;
            do{
                foreach(callback; callbacks) callback(current.value);
                list.append(current.value);
                current = current.next;
            } while(current != this.frontnode);
        }
        return list;
    }
    
    auto nodes() pure nothrow @safe @nogc{
        return Nodes(this.frontnode, this.backnode, this.length);
    }
    
    auto nodeat(in size_t index) const pure nothrow @trusted @nogc in{
        assert(index >= 0 && index < this.length);
    }body{
        if(index < this.length / 2){
            Node* current = cast(Node*) this.frontnode;
            size_t currentindex = 0;
            do{
                if(currentindex++ == index) return current;
                current = current.next;
            } while(current != this.frontnode);
        }else{
            Node* current = cast(Node*) this.backnode;
            size_t currentindex = this.length - 1;
            do{
                if(currentindex-- == index) return current;
                current = current.prev;
            } while(current != this.backnode);
        }
        assert(false);
    }
    
    auto asrange() pure nothrow @safe @nogc{
        return LinkedListRange!(typeof(this))(&this);
    }
    auto asarray() pure nothrow @safe{
        T[] array = new T[this.length];
        if(!this.empty){
            Node* current = cast(Node*) this.frontnode;
            size_t index = 0;
            do{
                array[index++] = current.value;
                current = current.next;
            } while(current != this.frontnode);
        }
        return array;
    }
    
    /// Iterate forwards through the list.
    int opApply(int delegate(ref T element) apply){
        int result = 0;
        if(!this.empty){
            Node* current = this.frontnode;
            do{
                result = apply(current.value);
                if(result) break;
                current = current.next;
            }while(current !is this.frontnode);
        }
        return result;
    }
    /// Iterate backwards through the list.
    int opApplyReverse(int delegate(ref T element) apply){
        int result = 0;
        if(!this.empty){
            Node* current = this.backnode;
            do{
                result = apply(current.value);
                if(result) break;
                current = current.prev;
            }while(current !is this.backnode);
        }
        return result;
    }
    
    auto ref opIndex(in size_t index) const pure nothrow @trusted @nogc in{
        assert(index >= 0 && index < this.length);
    }body{
        return this.nodeat(index).value;
    }
        
    auto ref opSlice(callbacks...)(in size_t low, in size_t high) const in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        LinkedList!T slice;
        Node* lownode;
        Node* highnode;
        Node* current = cast(Node*) this.frontnode;
        size_t index = 0;
        do{
            foreach(callback; callbacks) callback(current.value);
            if(index >= low){
                if(index >= high) break;
                slice.append(current.value);
            }
            current = current.next;
            index++;
        } while(current != this.frontnode);
        return slice;
    }
}



struct LinkedListNode(T, Allocator = DefaultLinkedListAllocator){
    alias Node = typeof(this);
    alias Nodes = NodesTuple!(T, Allocator);
    
    T value;
    Node* prev;
    Node* next;
    
    static auto many(Iter)(Iter values) if(isIterableOf!(Iter, T)){
        Node* first;
        Node* current, previous;
        size_t length;
        foreach(value; values){
            current = Allocator.instance.make!Node(value);
            current.prev = previous;
            if(previous !is null){
                previous.next = current;
            }else{
                first = current;
            }
            previous = current;
            length++;
        }
        return Nodes(first, current, length);
    }
}



struct LinkedListRange(List){
    alias Element = ElementType!List;
    alias Node = List.Node;
    
    List* list;
    Node* frontnode;
    Node* backnode;
    bool empty;
    
    this(List* list){
        this.list = list;
        this.frontnode = list.frontnode;
        this.backnode = list.backnode;
        this.empty = list.empty;
    }
    
    @property auto length(){
        return this.list.length;
    }
    
    @property auto ref front(){
        return this.frontnode.value;
    }
    @property void front(ref Element value){
        this.frontnode.value = value;
    }
    void popFront(){
        this.frontnode = this.frontnode.next;
        this.empty = this.frontnode.prev is this.backnode;
    }
    
    @property auto ref back(){
        return this.backnode.value;
    }
    @property void back(ref Element value){
        this.backnode.value = value;
    }
    void popBack(){
        this.backnode = this.backnode.next;
        this.empty = this.frontnode.prev is this.backnode;
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Doubly-linked list", {
        auto list = LinkedList!int(0, 1, 2, 3, 4);
        testeq("Front",
            list.front, 0
        );
        testeq("Back",
            list.back, 4
        );
        testeq("Length",
            list.length, 5
        );
        tests("Iteration and random access", {
            foreach(element; list) testeq(list[element], element);
        });
        tests("Slices", {
            auto slice = list[1 .. $-1];
            testeq("Length", slice.length, list.length - 2);
            testeq(slice[0], 1);
            testeq(slice[1], 2);
            testeq(slice[$-1], 3);
        });
        tests("Appending", {
            auto copy = list.copy();
            copy.append(5);
            copy.append(6, 7);
            testeq(copy.asarray, [0, 1, 2, 3, 4, 5, 6, 7]);
        });
        tests("Prepending", {
            auto copy = list.copy();
            copy.prepend(-1);
            copy.prepend(-3, -2);
            testeq(copy.asarray, [-3, -2, -1, 0, 1, 2, 3, 4]);
        });
        tests("Insertion", {
            auto copy = list.copy();
            copy.insert(1, 8);
            copy.insert(3, 8, 8);
            testeq(copy.asarray, [0, 8, 1, 8, 8, 2, 3, 4]);
        });
        tests("As range", {
            auto range = list.asrange;
            testeq(range.length, list.length);
            foreach(element; list){
                testeq(element, range.front);
                range.popFront();
            }
            test(range.empty);
        });
    });
}
