module mach.collect.linkedlist;

private:

import std.typecons : Tuple;
import std.experimental.allocator : make, dispose;
import std.experimental.allocator.gc_allocator : GCAllocator;
import std.traits : isImplicitlyConvertible;
import mach.traits : isMutable, isIterableOf, ElementType;

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
    
    @property Node* firstnode()(in bool delegate(in Node* value) pred) const{
        for(auto range = this.asrange!false; !range.empty; range.popFront()){
            if(pred(range.frontnode)) return range.frontnode;
        }
        return null;
    }
    @property Node* lastnode()(in bool delegate(in Node* value) pred) const{
        for(auto range = this.asrange!false; !range.empty; range.popBack()){
            if(pred(range.backnode)) return range.backnode;
        }
        return null;
    }
    
    @property auto first(in bool delegate(in T value) pred, T fallback = T.init) const{
        for(auto range = this.asrange!false; !range.empty; range.popFront()){
            if(pred(range.front)) return range.front;
        }
        return fallback;
    }
    @property auto last(in bool delegate(in T value) pred, T fallback = T.init) const{
        for(auto range = this.asrange!false; !range.empty; range.popBack()){
            if(pred(range.back)) return range.back;
        }
        return fallback;
    }
    
    bool contains(Node* node){
        return this.firstnode(n => n is node) !is null;
    }
    bool contains(ref T value){
        return this.firstnode(n => n.value == value) !is null;
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
        auto action(ref T value){
            auto node = Allocator.instance.make!Node(value);
            action(node);
            return node;
        }
        auto action(T[] values...){
            auto nodes = Node.many(values);
            action(nodes);
            return nodes;
        }
        auto action(Iter)(ref Iter values) if(isIterableOf!(Iter, T)){
            auto nodes = Node.many(values);
            action(nodes);
            return nodes;
        }
        
        auto action(ref typeof(this) list){
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
        
        auto action(in bool delegate(in T value) pred, T value){
            auto node = this.firstnode(node => pred(node.value));
            if(node !is null) return action(node, value);
            else return this.append(value);
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
    
    auto insertsorted(T value){
        return this.insertsorted((a, b) => (a > b), value);
    }
    auto insertsorted(in bool delegate(in T a, in T b) compare, T value){
        auto node = this.firstnode(node => compare(value, node.value));
        if(node is null){
            return this.append(value);
        }else{
            return this.insertbefore(node, value);
        }
    }
    
    /// Remove some node from this list.
    void remove(callbacks...)(Node* node) in{
        assert(!this.empty);
    }body{
        node.prev.next = node.next;
        node.next.prev = node.prev;
        foreach(callback; callbacks) callback(node.value);
        Allocator.instance.dispose(node);
        this.length--;
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
            for(auto range = this.asrange; !range.empty; range.popFront()){
                foreach(callback; callbacks) callback(range.front);
                list.append(range.front);
            }
        }
        return list;
    }
    
    /// Concatenate this list with some other value.
    typeof(this) concat(Rhs, callbacks...)(ref Rhs rhs) if(canAdd!Rhs){
        typeof(this) list = this.copy!callbacks();
        list.append(rhs);
        return list;
    }
    
    auto nodes() pure nothrow @safe @nogc{
        return Nodes(this.frontnode, this.backnode, this.length);
    }
    
    /// Get the list node at some index.
    auto nodeat(in size_t index) const pure nothrow @trusted @nogc in{
        assert(index >= 0 && index < this.length);
    }body{
        if(index < this.length / 2){
            size_t i = 0;
            for(auto range = this.asrange!false; !range.empty; range.popFront()){
                if(i++ == index) return range.frontnode;
            }
        }else{
            size_t i = this.length - 1;
            for(auto range = this.asrange!false; !range.empty; range.popBack()){
                if(i-- == index) return range.backnode;
            }
        }
        assert(false);
    }
    
    /// Get a range for iterating over this list whose contents can be mutated.
    auto asrange()() pure nothrow @safe @nogc{
        return this.asrange!true;
    }
    /// ditto
    auto asrange(bool mutable)() pure nothrow @safe @nogc if(mutable){
        return LinkedListRange!(typeof(this))(&this);
    }
    /// Get a range for iterating over this list which may not itself alter the list.
    auto asrange(bool mutable)() pure nothrow @safe @nogc const if(!mutable){
        return LinkedListRange!(const typeof(this))(&this);
    }
    
    /// Get the contents of this list as an array.
    auto asarray(callbacks...)() pure nothrow @safe{
        T[] array = new T[this.length];
        size_t index = 0;
        for(auto range = this.asrange; !range.empty; range.popFront()){
            foreach(callback; callbacks) callback(range.front);
            array[index++] = range.front;
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
    
    /// Get the element at an index.
    auto ref opIndex(in size_t index) const pure nothrow @trusted @nogc in{
        assert(index >= 0 && index < this.length);
    }body{
        return this.nodeat(index).value;
    }
    
    /// Get a list containing elements of this one from a low until a high index.
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
    
    /// Append some value to this list.
    void opOpAssign(string op: "~", Rhs)(Rhs rhs) if(canAdd!Rhs){
        this.append(rhs);
    }
    
    /// Concatenate this list with some other value.
    auto opBinary(string op: "~", Rhs)(Rhs rhs) if(canAdd!Rhs){
        auto result = this.copy();
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
        auto result = this.copy();
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
}



struct LinkedListNode(T, Allocator = DefaultLinkedListAllocator){
    alias Node = typeof(this);
    alias Nodes = NodesTuple!(T, Allocator);
    
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



struct LinkedListRange(List){
    alias Element = ElementType!List;
    alias Node = List.Node;
    
    List* list;
    Node* frontnode;
    Node* backnode;
    bool empty;
    
    this(List* list) @trusted{
        this.list = list;
        this.frontnode = cast(Node*) list.frontnode;
        this.backnode = cast(Node*) list.backnode;
        this.empty = list.empty;
    }
    
    @property auto length() const{
        return this.list.length;
    }
    
    @property Element front() const{
        return this.frontnode.value;
    }
    @property void front(ref Element value){
        this.frontnode.value = value;
    }
    void popFront(){
        this.frontnode = this.frontnode.next;
        this.empty = this.frontnode.prev is this.backnode;
    }
    
    @property Element back() const{
        return this.backnode.value;
    }
    @property void back(ref Element value){
        this.backnode.value = value;
    }
    void popBack(){
        this.backnode = this.backnode.prev;
        this.empty = this.frontnode.prev is this.backnode;
    }
    
    static if(isMutable!List){
        enum bool mutable = true;
        
        auto removeFront(callbacks...)(){
            auto next = this.frontnode.next;
            this.list.remove!callbacks(this.frontnode);
            this.frontnode = next;
        }
        auto insertFront(ref Element value){
            this.frontnode = this.list.insertafter(this.frontnode, value);
        }
        
        auto removeBack(callbacks...)(){
            auto prev = this.backnode.prev;
            this.list.remov!callbackse(this.backnode);
            this.backnode = prev;
        }
        auto insertBack(ref Element value){
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
            void itertest(T)(auto ref T iter){
                foreach(element; iter) testeq(element, list[element]);
            }
            foreach(element; list) testeq(element, list[element]);
            itertest(list);
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
        tests("Maintaining order", {
            auto sorted = LinkedList!int(0, 4);
            foreach(value; [5, 1, 3, 2]) sorted.insertsorted((a, b) => (a < b), value);
            testeq(sorted.asarray, [0, 1, 2, 3, 4, 5]);
            sorted.clear();
            foreach(value; [5, 1, 4, 0, 3, 2]) sorted.insertsorted((a, b) => (a < b), value);
            testeq(sorted.asarray, [0, 1, 2, 3, 4, 5]);
        });
        tests("Contains", {
            test(0 in list);
            test(1 in list);
            testf(11 in list);
        });
        tests("Concatenation", {
            auto copy = list.copy();
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
    });
}
