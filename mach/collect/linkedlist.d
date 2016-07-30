module mach.collect.linkedlist;

private:

import std.experimental.allocator : make, dispose;
import std.experimental.allocator.mallocator : Mallocator;
import std.traits : isIntegral, isImplicitlyConvertible, Unqual;
import mach.traits : isFiniteIterable, isIterableOf, ElementType;
import mach.traits : canReassign, isAllocator, canIncrement;

public:



alias DefaultLinkedListAllocator = Mallocator;

template canLinkedList(T, Allocator = DefaultLinkedListAllocator){
    enum bool canLinkedList = isAllocator!Allocator;
}

template validAsLinkedList(Iter, Allocator = DefaultLinkedListAllocator){
    static if(isFiniteIterable!Iter){
        enum bool validAsLinkedList = canLinkedList!(ElementType!Iter, Allocator);
    }else{
        enum bool validAsLinkedList = false;
    }
}



auto aslist(Allocator = DefaultLinkedListAllocator, Iter)(
    auto ref Iter iter
) if(validAsLinkedList!(Iter, Allocator)){
    return new LinkedList!(ElementType!Iter, Allocator)(iter);
}



/// Implements a cyclic doubly-linked list.
class LinkedList(T, Allocator = DefaultLinkedListAllocator) if(
    canLinkedList!(T, Allocator)
){
    alias Node = LinkedListNode!(T, Allocator);
    alias Nodes = LinkedListNodes!(T, Allocator);
    alias opDollar = length;
    alias insert = insertbefore;
    alias Element = T;
    
    private enum isNodes(N) = is(N == Node*) || is(N == Nodes);
    
    Node* frontnode; /// First node in the list.
    Node* backnode; /// Last node in the list.
    size_t length; /// Number of nodes currently in the list.
    
    this(){}
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
    //this(this) @disable;
    
    void setnodes(Node* node) pure nothrow @safe @nogc in{
        assert(this.empty, "Unsafe to perform this operation upon a list that is not empty.");
    }body{
        node.prev = node;
        node.next = node;
        this.frontnode = node;
        this.backnode = node;
        this.length = 1;
    }
    void setnodes(Nodes nodes) pure nothrow @safe @nogc in{
        assert(this.empty, "Unsafe to perform this operation upon a list that is not empty.");
    }body{
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
    /// Get the backmost value in the list.
    @property auto ref back() const pure nothrow @safe @nogc in{
        assert(!this.empty);
    } body{
        return this.backnode.value;
    }
    
    static if(canReassign!T){
        /// Set the frontmost value in the list.
        @property void front(ref T value) pure nothrow @safe @nogc in{
            assert(!this.empty);
        } body{
            this.frontnode.value = value;
        }
        /// Set the frontmost value in the list.
        @property void back(ref T value) pure nothrow @safe @nogc in{
            assert(!this.empty);
        } body{
            this.backnode.value = value;
        }
    }
    
    bool contains(in Node* node) const pure @safe nothrow @nogc{
        foreach(listnode; this.nodes){
            if(listnode is node) return true;
        }
        return false;
    }
    bool contains(in T value) const{
        foreach(listvalue; this.values){
            if(listvalue == value) return true;
        }
        return false;
    }
    
    alias insertbefore = AddAtAction!true;
    alias insertafter = AddAtAction!false;
    alias prepend = AddAction!true;
    alias append = AddAction!false;
    
    enum canAdd(X) = (
        isImplicitlyConvertible!(X, T) ||
        isIterableOf!(X, T) || isNodes!X
    );
    
    /// Used to define append and prepend methods
    private template AddAction(bool front){
        auto action(T value) nothrow @nogc{
            auto node = Allocator.instance.make!Node(value);
            action(node);
            return node;
        }
        auto action(T[] values...) nothrow @nogc{
            auto nodes = Node.many(values);
            action(nodes);
            return nodes;
        }
        auto action(Iter)(auto ref Iter values) nothrow @nogc if(isIterableOf!(Iter, T)){
            auto nodes = Node.many(values);
            action(nodes);
            return nodes;
        }
        
        auto action(ref typeof(this) list) nothrow @nogc{
            auto range = list.asrange;
            static assert(isIterableOf!(typeof(range), T));
            return action!(typeof(range))(range);
        }
        void action(N)(ref N nodes) pure nothrow @safe @nogc if(isNodes!N){
            if(this.empty){
                this.setnodes(nodes);
            }else{
                static if(front) this.insertbefore(this.frontnode, nodes);
                else this.insertafter(this.backnode, nodes);
            }
        }
        
        alias AddAction = action;
    }
    
    /// Used to define insertbefore and insertafter methods
    private template AddAtAction(bool before){
        auto action(size_t index, T value){
            auto node = Allocator.instance.make!Node(value);
            action(index, node);
            return node;
        }
        auto action(size_t index, T[] values...){
            auto nodes = Node.many(values);
            action(index, nodes);
            return nodes;
        }
        auto action(Iter)(size_t index, Iter values) if(isIterableOf!(Iter, T)){
            auto nodes = Node.many(values);
            action(index, nodes);
            return nodes;
        }
        
        auto action(Node* atnode, T value){
            auto node = Allocator.instance.make!Node(value);
            action(atnode, node);
            return node;
        }
        auto action(Node* atnode, T[] values...){
            auto nodes = Node.many(values);
            action(atnode, nodes);
            return nodes;
        }
        auto action(Iter)(Node* atnode, Iter values) if(isIterableOf!(Iter, T)){
            auto nodes = Node.many(values);
            action(atnode, nodes);
            return nodes;
        }
        
        void action(N)(size_t index, N nodes) pure nothrow @safe @nogc if(
            isNodes!N
        ) in{
            assert(index >= 0 && index < this.length);
        }body{
            if(this.empty) this.setnodes(nodes);
            else action(this.nodeat(index), nodes);
        }
        
        void action(Node* atnode, Node* node) pure nothrow @safe @nogc{
            action(atnode, node, node, 1);
        }
        
        void action(Iter)(Node* atnode, Iter values) pure nothrow @safe @nogc if(
            isIterableOf!(Iter, T)
        ){
            action(atnode, Node.many(values));
        }
        
        void action(Node* atnode, Nodes nodes) pure nothrow @safe @nogc{
            action(atnode, nodes.front, nodes.back, nodes.length);
        }
        
        void action(
            Node* atnode, Node* front, Node* back, size_t length
        ) pure nothrow @safe @nogc{
            static if(before){
                alias before = atnode;
                back.next = before;
                front.prev = before.prev;
                before.prev.next = front;
                before.prev = back;
                this.length += length;
                if(before is this.frontnode) this.frontnode = front;
            }else{
                alias after = atnode;
                front.prev = after;
                back.next = after.next;
                after.next.prev = back;
                after.next = front;
                this.length += length;
                if(after is this.backnode) this.backnode = back;
            }
        }
        
        alias AddAtAction = action;
    }
    
    /// Remove some node from this list.
    auto remove(Node* node) nothrow @nogc in{
        assert(!this.empty);
    }body{
        auto value = node.value;
        node.prev.next = node.next;
        node.next.prev = node.prev;
        if(node is this.frontnode){
            if(node is this.backnode){
                this.frontnode = null;
                this.backnode = null;
            }else{
                this.frontnode = node.next;
            }
        }else if(node is this.backnode){
            this.backnode = node.prev;
        }
        Allocator.instance.dispose(node);
        this.length--;
        return value;
    }
    
    auto removefront() nothrow @nogc in{assert(!this.empty);} body{
        return this.remove(this.frontnode);
    }
    auto removeback() nothrow @nogc in{assert(!this.empty);} body{
        return this.remove(this.backnode);
    }
    alias popfront = removefront;
    alias popback = removeback;
    
    /// Clear the list, optionally calling some callbacks on each element of the
    /// list, for example a function that frees newly-unused memory.
    void clear() nothrow @nogc{
        if(!this.empty){
            Node* current = this.frontnode;
            do{
                auto next = current.next;
                Allocator.instance.dispose(current);
                current = next;
            } while(current != this.frontnode);
            this.frontnode = null;
            this.backnode = null;
            this.length = 0;
        }
    }
    
    /// Create a new list containing the same elements as this one.
    @property typeof(this) dup() nothrow{
        auto list = new typeof(this);
        foreach(value; this.values) list.append(value);
        return list;
    }
    
    /// Concatenate this list with some other value.
    typeof(this) concat(Rhs, callbacks...)(ref Rhs rhs) if(canAdd!Rhs){
        typeof(this) list = this.copy!callbacks();
        list.append(rhs);
        return list;
    }
    
    /// Get the list node at some index.
    auto nodeat(Index)(in Index index) const pure nothrow @trusted @nogc if(
        isIntegral!Index
    )in{
        assert(index >= 0 && index < this.length);
    }body{
        if(index < this.length / 2){
            Index i = 0;
            for(auto range = this.nodes; !range.empty; range.popFront()){
                if(i++ == index) return range.front;
            }
        }else{
            Index i = this.length - 1;
            for(auto range = this.nodes; !range.empty; range.popBack()){
                if(i-- == index) return range.back;
            }
        }
        assert(false);
    }
    
    /// Get the index of some node in this list.
    auto nodeindex(Index = size_t)(
        in Node* node, Index start = Index.init
    ) const pure nothrow @trusted @nogc if(
        canIncrement!Index
    ){
        Index index = start;
        foreach(listnode; this.nodes){
            if(listnode is node) return index;
            index++;
        }
        assert(false, "Node is not a member of the list.");
    }
    
    /// Get a range for iterating over this list whose contents can be mutated.
    auto asrange()() pure nothrow @safe @nogc{
        return this.asrange!(canReassign!(typeof(this)));
    }
    /// ditto
    auto asrange(bool mutable)() pure nothrow @safe @nogc if(mutable){
        return LinkedListRange!(typeof(this))(this);
    }
    /// Get a range for iterating over this list which may not itself alter the list.
    auto asrange(bool mutable)() pure nothrow @safe @nogc const if(!mutable){
        return LinkedListRange!(const typeof(this))(this);
    }
    
    /// Get the contents of this list as an array.
    auto asarray() pure nothrow @safe{
        T[] array;
        array.reserve(this.length);
        foreach(value; this.values) array ~= value;
        return array;
    }
    
    /// Get a range representing the values in this list.
    alias values = this.asrange!false;
    /// Get a range representing the nodes in this list.
    auto nodes() pure const nothrow @safe @nogc{
        return Nodes(this.frontnode, this.backnode, this.length);
    }
    
    /// Get the element at an index.
    /// Please note, this is not especially efficient.
    auto ref opIndex(in size_t index) const pure nothrow @trusted @nogc in{
        assert(index >= 0 && index < this.length);
    }body{
        return this.nodeat(index).value;
    }
    
    static if(canReassign!T){
        /// Assign the element at an index.
        /// Please note, this is not especially efficient.
        void opIndexAssign(T value, in size_t index) pure nothrow @trusted @nogc in{
            assert(index >= 0 && index < this.length);
        }body{
            this.nodeat(index).value = value;
        }
    }
    
    /// Get a list containing elements of this one from a low until a high index.
    auto ref opSlice()(in size_t low, in size_t high) nothrow in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        auto slice = new typeof(this);
        size_t index = 0;
        foreach(value; this.values){
            if(index >= low){
                if(index >= high) break;
                slice.append(value);
            }
            index++;
        }
        return slice;
    }
    
    /// Append some value to this list.
    void opOpAssign(string op: "~", Rhs)(Rhs rhs) if(canAdd!Rhs){
        this.append(rhs);
    }
    
    /// Concatenate this list with some other value.
    auto opBinary(string op: "~", Rhs)(Rhs rhs) if(canAdd!Rhs){
        auto result = this.dup;
        result.append(rhs);
        return result;
    }
    /// ditto
    auto opBinaryRight(string op: "~", Lhs)(Lhs lhs) if(canAdd!Lhs){
        auto result = typeof(this)(lhs);
        result.append(this);
        return result;
    }
    
    /// ditto
    auto opBinary(string op: "~")(ref typeof(this) rhs){
        auto result = this.dup;
        result.append(rhs);
        return result;
    }
    
    /// Determine if a node is contained within this list.
    auto opBinaryRight(string op: "in")(ref Node* node){
        return this.contains(node);
    }
    /// Determine if a value is contained within this list.
    auto opBinaryRight(string op: "in")(T value){
        return this.contains(value);
    }
    
    override string toString() const nothrow{
        import std.conv : to;
        string str = "";
        string append;
        for(auto range = this.asrange!false; !range.empty; range.popFront()){
            if(str.length) str ~= ", ";
            try{
                append = range.front.to!string;
            }catch(Exception){
                append = "";
            }
            str ~= append;
        }
        return "[" ~ str ~ "]";
    }
}



struct LinkedListNode(T, Allocator = DefaultLinkedListAllocator){
    alias Node = typeof(this);
    alias Nodes = LinkedListNodes!(T, Allocator);
    
    T value;
    Node* prev;
    Node* next;
    
    static auto many(Iter)(ref Iter values) if(isIterableOf!(Iter, T)){
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

struct LinkedListNodes(T, Allocator){
    alias Node = LinkedListNode!(T, Allocator);
    Node* front = null;
    Node* back = null;
    size_t length = 0;
    
    this(const(Node*) front, const(Node*) back, in size_t length) @trusted @nogc nothrow{
        this(cast(Node*) front, cast(Node*) back, cast(size_t) length);
    }
    this(Node* front, Node* back, size_t length) @safe @nogc nothrow{
        this.front = front;
        this.back = back;
        this.length = length;
    }
    
    @property bool empty() @safe pure nothrow @nogc{
        return this.front is null || this.back is null;
    }
    void popFront() @safe pure nothrow @nogc in{assert(!this.empty);} body{
        if(this.front is this.back) this.front = null;
        else this.front = this.front.next;
    }
    void popBack() @safe pure nothrow @nogc in{assert(!this.empty);} body{
        if(this.front is this.back) this.back = null;
        else this.back = this.back.prev;
    }
}



struct LinkedListRange(List){
    alias Element = ElementType!List;
    alias Node = List.Node;
    
    List list = null;
    Node* frontnode = null;
    Node* backnode = null;
    bool empty = true;
    
    this(List list) @trusted{
        this(list, cast(Node*) list.frontnode, cast(Node*) list.backnode, list.empty);
    }
    this(List list, Node* frontnode, Node* backnode, bool empty){
        this.list = list;
        this.frontnode = frontnode;
        this.backnode = backnode;
        this.empty = empty;
    }
    
    @property auto length() const{
        return this.list.length;
    }
    
    @property Element front() pure @trusted const nothrow{
        return cast(Element) this.frontnode.value;
    }
    void popFront(){
        this.frontnode = this.frontnode.next;
        this.empty = this.frontnode.prev is this.backnode;
    }
    
    @property Element back() pure @trusted const nothrow{
        return cast(Element) this.backnode.value;
    }
    void popBack(){
        this.backnode = this.backnode.prev;
        this.empty = this.frontnode.prev is this.backnode;
    }
    
    static if(canReassign!List){
        enum bool mutable = true;
        
        static if(canReassign!Element){
            @property void front(Element value){
                this.frontnode.value = value;
            }
            @property void back(Element value){
                this.backnode.value = value;
            }
        }
        
        auto insert(Element value){
            this.backnode = this.list.append(value);
        }
        
        auto removeFront(){
            auto next = this.frontnode.next;
            this.list.remove(this.frontnode);
            this.frontnode = next;
        }
        auto insertFront(Element value){
            this.frontnode = this.list.insertbefore(this.frontnode, value);
        }
        
        auto removeBack(){
            auto prev = this.backnode.prev;
            this.list.remove(this.backnode);
            this.backnode = prev;
        }
        auto insertBack(Element value){
            this.backnode = this.list.insertafter(this.backnode, value);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Doubly-linked list", {
        static assert(canLinkedList!int);
        static assert(canLinkedList!string);
        static assert(canLinkedList!(const int));
        auto list = new LinkedList!int(0, 1, 2, 3, 4);
        testeq("Front",
            list.front, 0
        );
        testeq("Back",
            list.back, 4
        );
        testeq("Length",
            list.length, 5
        );
        tests("Random access", {
            testeq(list[0], 0);
            testeq(list[1], 1);
            testeq(list[2], 2);
            testeq(list[3], 3);
            testeq(list[$-1], 4);
        });
        tests("Slices", {
            auto slice = list[1 .. $-1];
            testeq("Length", slice.length, list.length - 2);
            testeq(slice[0], 1);
            testeq(slice[1], 2);
            testeq(slice[$-1], 3);
        });
        tests("Iteration", {
            foreach(value; list.values) testeq(value, list[value]);
        });
        tests("Iterate nodes", {
            auto nodes = list.nodes;
            size_t count = 0;
            foreach(node; nodes) count++;
            testeq(count, list.length);
        });
        tests("Appending", {
            auto copy = list.dup;
            copy.append(5);
            copy.append(6, 7);
            testeq(copy.asarray, [0, 1, 2, 3, 4, 5, 6, 7]);
        });
        tests("Prepending", {
            auto copy = list.dup;
            copy.prepend(-1);
            copy.prepend(-3, -2);
            testeq(copy.asarray, [-3, -2, -1, 0, 1, 2, 3, 4]);
        });
        tests("Insertion", {
            auto copy = list.dup;
            copy.insert(1, 8);
            copy.insert(3, 8, 8);
            testeq(copy.asarray, [0, 8, 1, 8, 8, 2, 3, 4]);
        });
        tests("Removal", {
            auto copy = list.dup;
            copy.removefront();
            copy.removeback();
            testeq(copy.asarray, [1, 2, 3]);
        });
        tests("Index assignment", {
            auto copy = list.dup;
            copy[0] = 1;
            copy[1] = 2;
            testeq(copy[0], 1);
            testeq(copy[1], 2);
        });
        tests("As range", {
            auto range = list.asrange;
            testeq(range.length, list.length);
            foreach(i; 0 .. list.length) range.popFront();
            test(range.empty);
        });
        tests("Contains", {
            test(0 in list);
            test(1 in list);
            testf(11 in list);
        });
        tests("Concatenation", {
            auto copy = list.dup;
            copy ~= 5;
            copy ~= [6, 7];
            testeq(copy.length, list.length + 3);
            auto concat = list ~ copy ~ 0 ~ [1, 2];
            testeq(concat.length, list.length + copy.length + 3);
            testeq(concat.asarray, [
                0, 1, 2, 3, 4,
                0, 1, 2, 3, 4, 5, 6, 7,
                0, 1, 2
            ]);
        });
        tests("Iterable as list", {
            auto input = "hello world";
            auto list = input.aslist;
            testeq(list.length, input.length);
            foreach(i; 0 .. input.length){
                testeq(list[i], input[i]);
            }
        });
        tests("Start blank", {
            auto list = new LinkedList!int;
            list.append(1, 2);
            testeq(list.asarray, [1, 2]);
        });
    });
}
