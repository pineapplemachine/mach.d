module mach.collect.linkedlist;

private:

import mach.traits : isIterable, isIterableOf;

public:



auto asdoublylinkedlist(Values)(auto ref Values values) if(isIterable!Values){
    alias T = typeof({foreach(value; values) return value; assert(false);}());
    return DoublyLinkedList!T(values);
}



/// Node belonging to a `DoublyLinkedList` instance.
@safe pure nothrow struct DoublyLinkedListNode(T){
    alias Node = typeof(this);
    
    T value;
    Node* prev = null;
    Node* next = null;
}

/// Used to represent a pair of nodes, which themselves represent a contiguous
/// chain.
@safe pure nothrow struct DoublyLinkedListNodePair(T){
    alias Node = DoublyLinkedListNode!T;
    alias NodePair = typeof(this);
    
    Node* head;
    Node* tail;
    
    static NodePair make(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        Node* head = null;
        Node* tail = null;
        foreach(item; values){
            Node* node = new Node(item);
            if(head is null){
                head = node;
            }
            if(tail !is null){
                node.prev = tail;
                tail.next = node;
            }
            tail = node;
        }
        return NodePair(head, tail);
    }
}



/// Represents a cyclic doubly-linked list.
@safe pure nothrow struct DoublyLinkedList(T){
    alias Node = DoublyLinkedListNode!T;
    alias NodePair = DoublyLinkedListNodePair!T;
    
    Node* root = null;
    
    this(T[] values...){
        this.append(values);
    }
    this(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        this.append(values);
    }
    
    /// Get the first node in the list.
    @property Node* head(){
        return this.root;
    }
    /// ditto
    @property const(Node*) head() const{
        return this.root;
    }
    
    /// Get the last node in the list.
    @property Node* tail(){
        return this.root is null ? null : this.root.prev;
    }
    /// ditto
    @property const(Node*) tail() const{
        return this.root is null ? null : this.root.prev;
    }
    
    /// True when the list contains no values.
    @property bool empty() const{
        return this.root is null;
    }
    
    /// Clear all values from the list.
    void clear(){
        this.root = null;
    }
    
    /// Set the entire contents of the list to a single node.
    Node* setnode(Node* node){
        this.root = node;
        if(node !is null){
            node.prev = node;
            node.next = node;
        }
        return node;
    }
    /// Set the entire contents of the list to some nodes.
    NodePair setnodes(NodePair pair){
        if(pair.head is null || pair.tail is null){
            this.root = null;
        }else{
            pair.head.prev = pair.tail;
            pair.tail.next = pair.head;
            this.root = pair.head;
        }
        return pair;
    }
    
    /// Returns a range for iterating over the nodes in this list.
    /// The resulting range does not allow modification.
    @property auto inodes() const{
        return DoublyLinkedListRange!(
            T, DoublyLinkedListRangeValues.Nodes,
            DoublyLinkedListRangeMutability.Immutable
        )(this);
    }
    /// Returns a range for iterating over the values in this list.
    /// The resulting range does not allow modification.
    @property auto ivalues() const{
        return DoublyLinkedListRange!(
            T, DoublyLinkedListRangeValues.Values,
            DoublyLinkedListRangeMutability.Immutable
        )(this);
    }
    /// Make the list valid as a range.
    @property auto asrange() const{
        return this.ivalues;
    }
    
    /// Returns a range for iterating over the nodes in a list.
    /// The resulting range allows modification.
    @property auto nodes(){
        return DoublyLinkedListRange!(
            T, DoublyLinkedListRangeValues.Nodes,
            DoublyLinkedListRangeMutability.Mutable
        )(&this);
    }
    /// Returns a range for iterating over the values in a list.
    /// The resulting range allows modification.
    @property auto values(){
        return DoublyLinkedListRange!(
            T, DoublyLinkedListRangeValues.Values,
            DoublyLinkedListRangeMutability.Mutable
        )(&this);
    }
    /// Returns a range for iterating over the values in a list.
    /// The resulting range allows modification.
    @property auto asrange(){
        return this.values;
    }
    
    /// Determine whether a node belongs to this list.
    bool contains(in Node* find) const{
        if(find !is null){
            foreach(node; this.inodes){
                if(node is find) return true;
            }
        }
        return false;
    }
    
    /// Replace one node in the list with another.
    Node* replace(Node* replacenode, T value) in{
        assert(replacenode !is null, "Input must not be null.");
    }body{
        Node* replacewith = new Node(value);
        this.replace(replacenode, replacewith);
        return replacewith;
    }
    /// ditto
    void replace(Node* replacenode, Node* replacewith) in{
        assert(replacenode !is null && replacewith !is null, "Inputs must not be null.");
    }body{
        replacenode.prev.next = replacewith;
        replacenode.next.prev = replacewith;
        replacewith.next = replacenode.next;
        replacewith.prev = replacenode.prev;
        if(replacenode is this.root) this.root = replacewith;
    }
    
    /// Remove a node in the list.
    void remove(Node* node) in{
        assert(node !is null, "Input must not be null.");
        assert(node.prev !is null && node.next !is null,
            "Can't remove node without neighbors."
        );
    }body{
        node.prev.next = node.next;
        node.next.prev = node.prev;
        if(node is this.root){
            this.root = node.next is this.root ? null : node.next;
        }
    }
    
    /// Add a value to the back of the list.
    Node* append(T value){
        if(this.root is null) return this.setnode(new Node(value));
        else return this.insertafter(this.tail, value);
    }
    /// Add the values in an iterable to the back of the list.
    NodePair append(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        if(this.root is null) return this.setnodes(NodePair.make(values));
        else return this.insertafter(this.tail, values);
    }
    /// Add a node to the back of the list.
    void append(Node* node){
        if(this.root is null) this.setnode(node);
        else this.insertafter(this.tail, node);
    }
    /// Add nodes to the back of the list.
    void append(Node* head, Node* tail){
        if(this.root is null) this.setnodes(NodePair(head, tail));
        else this.insertafter(this.tail, head, tail);
    }
    
    /// Add a value to the front of the list.
    Node* prepend(T value){
        if(this.root is null) return this.setnode(new Node(value));
        else return this.insertbefore(this.head, value);
    }
    /// Add the values in an iterable to the front of the list.
    NodePair prepend(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        if(this.root is null) return this.setnodes(NodePair.make(values));
        else return this.insertbefore(this.head, values);
    }
    /// Add a node to the front of the list.
    void prepend(Node* node){
        if(this.root is null) this.setnode(node);
        else this.insertbefore(this.head, node);
    }
    /// Add nodes to the front of the list.
    void prepend(Node* head, Node* tail){
        if(this.root is null) this.setnodes(NodePair(head, tail));
        else this.insertbefore(this.head, head, tail);
    }
    
    /// Insert a value before a node in the list.
    Node* insertbefore(Node* node, T value) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        Node* insert = new Node(value);
        this.insertbefore(node, insert);
        return insert;
    }
    /// Insert the value in an iterable before a node in the list.
    NodePair insertbefore(Values)(Node* node, auto ref Values values) if(
        isIterableOf!(Values, T)
    )in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        NodePair pair = NodePair.make(values);
        this.insertbefore(node, pair.head, pair.tail);
        return pair;
    }
    /// Insert a new node before a node in the list.
    void insertbefore(Node* node, Node* insert) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        this.insertbefore(node, insert, insert);
    }
    /// Insert new nodes before a node in the list.
    void insertbefore(Node* node, Node* head, Node* tail) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        if(head !is null && tail !is null){
            if(this.root is null){
                this.root = head;
                this.root.prev = tail;
            }else{
                head.prev = node.prev;
                tail.next = node;
                node.prev.next = head;
                node.prev = tail;
                if(node is this.root) this.root = head;
            }
        }
    }
    
    /// Insert a value after a node in the list.
    Node* insertafter(Node* node, T value) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        Node* insert = new Node(value);
        this.insertafter(node, insert);
        return insert;
    }
    /// Insert the value in an iterable after a node in the list.
    NodePair insertafter(Values)(Node* node, auto ref Values values) if(
        isIterableOf!(Values, T)
    )in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        NodePair pair = NodePair.make(values);
        this.insertafter(node, pair.head, pair.tail);
        return pair;
    }
    /// Insert a new node after a node in the list.
    void insertafter(Node* node, Node* insert) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        this.insertafter(node, insert, insert);
    }
    /// Insert new nodes after a node in the list.
    void insertafter(Node* node, Node* head, Node* tail) in{
        assert(node !is null, "Reference node must not be null.");
    }body{
        if(head !is null && tail !is null){
            if(this.root is null){
                this.root = head;
                this.root.prev = tail;
            }else{
                head.prev = node;
                tail.next = node.next;
                node.next.prev = tail;
                node.next = head;
            }
        }
    }
}



enum DoublyLinkedListRangeValues{
    Nodes, // The range enumerates nodes.
    Values // The range enumerates values.
}
enum DoublyLinkedListRangeMutability{
    Immutable, // The range is not mutable.
    Removable, // Elements may be removed, but not mutated.
    Mutable // Elements may be removed and mutated.
}

/// Range for enumerating the members of a `DoublyLinkedList` instance.
@safe pure nothrow struct DoublyLinkedListRange(
    T, DoublyLinkedListRangeValues values, DoublyLinkedListRangeMutability mutability
){
    alias Element = T;
    
    enum bool mutable = mutability !is DoublyLinkedListRangeMutability.Immutable;
    
    static if(mutable){
        alias Node = DoublyLinkedListNode!T;
        alias NodePair = DoublyLinkedListNodePair!T;
        alias List = DoublyLinkedList!T;
    }else{
        alias Node = const(DoublyLinkedListNode!T);
        alias NodePair = const(DoublyLinkedListNodePair!T);
        alias List = const(DoublyLinkedList!T);
    }
    
    Node* head;
    Node* tail;
    bool isempty = false;
    static if(mutable) List* list;
    
    static if(mutable){
        this(Node* head, Node* tail, List* list){
            this(head, tail, list, head is null || tail is null);
        }
        this(Node* head, Node* tail, List* list, bool isempty){
            this.head = head;
            this.tail = tail;
            this.list = list;
            this.isempty = isempty;
        }
        this(List* list){
            if(list is null){
                this(null, null, null, true);
            }else{
                this(list.head, list.tail, list);
            }
        }
    }else{
        this(Node* head, Node* tail){
            this(head, tail, head is null || tail is null);
        }
        this(Node* head, Node* tail, bool isempty = false){
            this.head = head;
            this.tail = tail;
            this.isempty = isempty;
        }
        this(List list){
            this(list.head, list.tail);
        }
        this(List* list){
            if(list is null){
                this(null, null, true);
            }else{
                this(list.head, list.tail);
            }
        }
    }
    
    @property bool empty() const{
        return this.isempty;
    }
    
    @property auto front() in{
        assert(!this.empty, "Range is empty.");
        assert(this.head !is null, "Range is not valid.");
    }body{
        static if(values) return this.head.value;
        else return this.head;
    }
    void popFront() in{
        assert(!this.empty, "Range is empty.");
        assert(this.head !is null, "Range is not valid.");
    }body{
        this.isempty = this.head is this.tail;
        this.head = this.head.next;
        assert(this.head !is null, "Range is not valid.");
    }
    
    @property auto back() in{
        assert(!this.empty, "Range is empty.");
        assert(this.tail !is null, "Range is not valid.");
    }body{
        static if(values) return this.tail.value;
        else return this.tail;
    }
    void popBack() in{
        assert(!this.empty, "Range is empty.");
        assert(this.tail !is null, "Range is not valid.");
    }body{
        this.isempty = this.head is this.tail;
        this.tail = this.tail.prev;
        assert(this.tail !is null, "Range is not valid.");
    }
    
    @property typeof(this) save(){
        static if(mutable){
            return typeof(this)(this.head, this.tail,  this.list, this.isempty);
        }else{
            return typeof(this)(this.head, this.tail, this.isempty);
        }
    }
    
    static if(mutable){
        /// Remove the frontmost element from the backing list.
        /// Progresses the front of the range to the next element as though
        /// popFront was called.
        @property void removeFront() in{
            assert(this.head !is null, "Range is not valid.");
            assert(!this.empty, "Range is empty.");
        }body{
            this.isempty = this.head is this.tail;
            this.list.remove(this.head);
            this.head = this.head.next;
        }
        /// Remove the backmost element from the backing list.
        /// Progresses the back of the range to the next element as though
        /// popBack was called.
        @property void removeBack() in{
            assert(this.tail !is null, "Range is not valid.");
            assert(!this.empty, "Range is empty.");
        }body{
            this.isempty = this.head is this.tail;
            this.list.remove(this.tail);
            this.tail = this.tail.prev;
        }
        
        static if(mutability is DoublyLinkedListRangeMutability.Mutable){
            @property void front(T value) in{
                assert(this.list !is null, "List associated with range must not be null.");
                assert(!this.empty, "Range is empty.");
            }body{
                this.front(new Node(value));
            }
            @property void front(Node* node) in{
                assert(this.list !is null, "List associated with range must not be null.");
                assert(node !is null, "Input must not be null.");
                assert(this.head !is null, "Range is not valid.");
                assert(!this.empty, "Range is empty.");
            }body{
                this.list.replace(this.head, node);
                if(this.head is this.tail) this.tail = node;
                this.head = node;
            }
            
            @property void back(T value) in{
                assert(this.list !is null, "List associated with range must not be null.");
                assert(!this.empty, "Range is empty.");
            }body{
                this.back(new Node(value));
            }
            @property void back(Node* node) in{
                assert(this.list !is null, "List associated with range must not be null.");
                assert(node !is null, "Input must not be null.");
                assert(this.tail !is null, "Range is not valid.");
                assert(!this.empty, "Range is empty.");
            }body{
                this.list.replace(this.tail, node);
                if(this.head is this.tail) this.head = node;
                this.tail = node;
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range : walklength, equals, map;
    import mach.range.asrange : validAsRange;
    alias List = DoublyLinkedList;
    alias Node = DoublyLinkedListNode;
    
    import mach.io.log;
}
unittest{
    tests("Doubly-linked list", {
        static assert(validAsRange!(List!int));
        tests("Empty", {
            auto list = new List!int();
            test(list.empty);
            test!equals(list.ivalues, new int[0]);
            list = new List!int(new int[0]);
            test(list.empty);
            test!equals(list.ivalues, new int[0]);
        });
        tests("Construction", {
            test!equals(new List!int(0), [0]);
            test!equals(new List!int(0, 1, 2), [0, 1, 2]);
            test!equals(new List!int([0, 1, 2]), [0, 1, 2]);
        });
        tests("Appending & prepending", {
            { // Append
                auto list = new List!int();
                list.append(0);
                test!equals(list.ivalues, [0]);
                testeq(list.ivalues.walklength, 1);
                list.append([1, 2]);
                test!equals(list.ivalues, [0, 1, 2]);
                testeq(list.ivalues.walklength, 3);
            }{ // Prepend
                auto list = new List!int();
                list.prepend(0);
                test!equals(list.ivalues, [0]);
                testeq(list.ivalues.walklength, 1);
                list.prepend([-2, -1]);
                test!equals(list.ivalues, [-2, -1, 0]);
                testeq(list.ivalues.walklength, 3);
            }{ // Both
                auto list = new List!int();
                list.append(0);
                list.append(1);
                list.prepend(-1);
                test!equals(list.ivalues, [-1, 0, 1]);
            }
        });
        tests("Insert before & after", {
            auto list = new List!int();
            list.append([0, 1]);
            auto node = list.append(2);
            list.append([3, 4]);
            test!equals(list.ivalues, [0, 1, 2, 3, 4]);
            auto five = list.insertbefore(node, 5);
            auto six = list.insertafter(node, 6);
            test!equals(list.ivalues, [0, 1, 5, 2, 6, 3, 4]);
            list.insertbefore(five, [-1, -2]);
            list.insertafter(six, [-3, -4]);
            test!equals(list.ivalues, [0, 1, -1, -2, 5, 2, 6, -3, -4, 3, 4]);
            list.insertbefore(list.head, 10);
            test!equals(list.ivalues, [10, 0, 1, -1, -2, 5, 2, 6, -3, -4, 3, 4]);
        });
        tests("Contains", {
            auto list = new List!int(0, 1, 2, 3);
            test(list.contains(list.head));
            test(list.contains(list.head.next));
            test(list.contains(list.tail));
            testf(list.contains(new Node!int(0)));
            testf(list.contains(new List!int(0, 1).head));
            testf(list.contains(null));
            auto empty = new List!int();
            testf(empty.contains(list.head));
            testf(empty.contains(list.tail));
            testf(empty.contains(null));
        });
        tests("Replace", {
            auto list = new List!int();
            auto head = list.append(0);
            list.append([1, 2]);
            auto tail = list.append(3);
            test!equals(list.ivalues, [0, 1, 2, 3]);
            list.replace(head, -1);
            test!equals(list.ivalues, [-1, 1, 2, 3]);
            list.replace(tail, -2);
            test!equals(list.ivalues, [-1, 1, 2, -2]);
        });
        tests("Remove", {
            auto list = new List!int();
            auto head = list.append(0);
            auto mid = list.append(1);
            auto tail = list.append(2);
            test!equals(list.ivalues, [0, 1, 2]);
            list.remove(mid);
            test!equals(list.ivalues, [0, 2]);
            list.remove(tail);
            test!equals(list.ivalues, [0]);
            list.remove(head);
            test!equals(list.ivalues, new int[0]);
            test(list.empty);
            list.append([0, 1, 2]);
            test!equals(list.ivalues, [0, 1, 2]);
            list.remove(list.head);
            test!equals(list.ivalues, [1, 2]);
        });
        tests("Clear", {
            auto list = new List!int(0, 1, 2);
            testf(list.empty);
            list.clear;
            test(list.empty);
        });
        tests("Immutable members", {
            auto list = new List!(const(int))(0, 1, 2);
            test!equals(list.values, [0, 1, 2]);
            test!equals(list.ivalues, [0, 1, 2]);
            list.append(3);
            test!equals(list.ivalues, [0, 1, 2, 3]);
            list.prepend(-1);
            test!equals(list.ivalues, [-1, 0, 1, 2, 3]);
            list.remove(list.tail);
            test!equals(list.ivalues, [-1, 0, 1, 2]);
            list.remove(list.head);
            test!equals(list.ivalues, [0, 1, 2]);
            list.replace(list.head, -1);
            test!equals(list.ivalues, [-1, 1, 2]);
            list.clear();
            test(list.empty);
        });
        tests("Range", {
            {
                auto empty = new List!int();
                test!equals(empty.values, new int[0]);
                test!equals(empty.ivalues, new int[0]);
                test!equals(empty.nodes.map!(e => e.value), new int[0]);
                test!equals(empty.inodes.map!(e => e.value), new int[0]);
                auto list = new List!int(0, 1, 2, 3);
                test!equals(list.values, [0, 1, 2, 3]);
                test!equals(list.ivalues, [0, 1, 2, 3]);
                test!equals(list.nodes.map!(e => e.value), [0, 1, 2, 3]);
                test!equals(list.inodes.map!(e => e.value), [0, 1, 2, 3]);
            }{
                auto list = new List!int(0, 1, 2, 3);
                auto values = list.values;
                testeq(values.front, 0);
                testeq(values.back, 3);
                values.popFront();
                testeq(values.front, 1);
                values.popBack();
                testeq(values.back, 2);
                auto saved = values.save();
                saved.popFront();
                testeq(saved.front, 2);
                testeq(values.front, 1);
                values.front = -1;
                values.back = -2;
                testeq(values.front, -1);
                testeq(values.back, -2);
                test!equals(list.ivalues, [0, -1, -2, 3]);
                values.removeFront();
                test!equals(list.ivalues, [0, -2, 3]);
                testeq(values.front, -2);
                values.removeBack();
                test!equals(list.ivalues, [0, 3]);
                test(values.empty);
                testfail({values.front;});
                testfail({values.popFront();});
                testfail({values.back;});
                testfail({values.popBack();});
            }{
                auto list = new List!int(0, 1, 2, 3);
                auto nodes = list.nodes;
                test(list.contains(nodes.head));
                test(list.contains(nodes.tail));
                test!equals(list.ivalues, [0, 1, 2, 3]);
                nodes.removeFront();
                testeq(nodes.front.value, 1);
                test!equals(list.ivalues, [1, 2, 3]);
                nodes.removeBack();
                testeq(nodes.back.value, 2);
                test!equals(list.ivalues, [1, 2]);
                nodes.popFront();
                testeq(nodes.front.value, 2);
                nodes.front = 5;
                testeq(nodes.front.value, 5);
                test!equals(list.ivalues, [1, 5]);
                nodes.popFront();
                test(nodes.empty);
                testfail({nodes.front;});
                testfail({nodes.popFront();});
                testfail({nodes.back;});
                testfail({nodes.popBack();});
            }
        });
    });
}
