module mach.collect.sortedlist;

private:

import mach.traits : isIterableOf, ElementType;
import mach.types : Rebindable;
import mach.collect.linkedlist;

public:



alias DefaultSortedListCompare = (a, b) => (a < b);



/// Wraps a `DoublyLinkedList` instance such that its contents are kept
/// ordered according to the comparison function.
struct SortedList(T, alias compare = DefaultSortedListCompare) if(is(typeof({
    if(compare(T.init, T.init)){}
}))){
    alias List = DoublyLinkedList!T;
    alias Node = DoublyLinkedListNode!T;
    
    List list = null;
    
    /// True when the list contains no values.
    @property bool empty() const{
        return this.list.empty;
    }
    
    /// Get the first node in the list.
    @property Node* head(){
        return this.list.head;
    }
    /// ditto
    @property const(Node*) head() const{
        return this.list.head;
    }
    
    /// Get the last node in the list.
    @property Node* tail(){
        return this.list.tail;
    }
    /// ditto
    @property const(Node*) tail() const{
        return this.list.tail;
    }
    
    /// Returns a range for iterating over the nodes in this list.
    /// The resulting range does not allow modification.
    @property auto inodes() const{
        return this.list.inodes;
    }
    /// Returns a range for iterating over the values in this list.
    /// The resulting range does not allow modification.
    @property auto ivalues() const{
        return this.list.ivalues;
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
            DoublyLinkedListRangeMutability.Removable
        )(&this.list);
    }
    /// Returns a range for iterating over the values in a list.
    /// The resulting range allows modification.
    @property auto values(){
        return DoublyLinkedListRange!(
            T, DoublyLinkedListRangeValues.Values,
            DoublyLinkedListRangeMutability.Removable
        )(&this.list);
    }
    /// Returns a range for iterating over the values in a list.
    /// The resulting range allows modification.
    @property auto asrange(){
        return this.values;
    }
    
    /// Insert a value into the list.
    Node* insert(T value){
        Node* node = new Node(value);
        this.insert(node);
        return node;
    }
    /// Insert values into the list where the input is not guaranteed to be
    /// sorted.
    void insert(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        foreach(value; values) this.insert(new Node(value));
    }
    /// Insert a node into the list.
    void insert(Node* node){
        if(this.list.empty){
            list.setnode(node);
        }else{
            foreach(search; this.nodes){
                if(compare(node.value, search.value)){
                    this.list.insertbefore(search, node);
                    return;
                }
            }
            this.list.append(node);
        }
    }
    
    /// Insert a sequence of values which are assumed to be themselves sorted by
    /// this list's comparison function.
    void insertsorted(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        if(this.empty){
            this.list.append(values);
        }else{
            auto nodes = this.nodes;
            version(unittest){
                Rebindable!T last;
                bool first = true;
            }
            foreach(value; values){
                version(unittest){
                    // When running unittests, verify the input is indeed sorted.
                    if(first) first = false;
                    else assert(!compare(value, last), "Input is not sorted.");
                    last = value;
                }
                while(!nodes.empty){
                    if(compare(value, nodes.front.value)){
                        this.list.insertbefore(nodes.front, value);
                        goto midlist;
                    }
                    nodes.popFront();
                }
                this.list.append(value);
                midlist:
            }
        }
    }
    
    /// Remove a node from the list.
    void remove(Node* node){
        this.list.remove(node);
    }
    
    /// Clear all values from the list.
    void clear(){
        this.list.clear();
    }
    
    /// Determine whether a node belongs to this list.
    bool contains(in Node* node) const{
        return this.list.contains(node);
    }
    
    /// Determine whether the contents of an iterable are
    /// sorted order according to the comparison function.
    static bool issorted(Values)(auto ref Values values) @safe if(
        isIterableOf!(Values, T)
    ){
        Rebindable!T last;
        bool first = true;
        foreach(value; values){
            if(!first){
                if(compare(value, last)) return false;
            }else{
                first = false;
            }
            last = value;
        }
        return true;
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.math : abs;
    import mach.range : walklength, equals, map;
    import mach.range.asrange : validAsRange;
    alias List = DoublyLinkedList;
    alias Node = DoublyLinkedListNode;
    
    import mach.io.log;
}
unittest{
    tests("Sorted list", {
        tests("Is sorted", {
            test(SortedList!int.issorted(new int[0]));
            test(SortedList!int.issorted([0]));
            test(SortedList!int.issorted([0, 1]));
            test(SortedList!int.issorted([0, 1, 2, 3, 4]));
            test(SortedList!int.issorted([0, 0]));
            test(SortedList!int.issorted([0, 0, 1, 2, 2]));
            testf(SortedList!int.issorted([1, 0]));
            testf(SortedList!int.issorted([0, 1, 2, 3, 1]));
            test(SortedList!int.issorted(new List!int(0, 1, 2).ivalues));
            test(SortedList!(const(int)).issorted(new List!(const(int))(0, 1, 2).ivalues));
        });
        tests("Construction", {
            auto list = new SortedList!int();
            test(list.empty);
            test!equals(list.ivalues, new int[0]);
        });
        tests("Insert", {
            auto list = new SortedList!int();
            list.insert(0);
            test!equals(list.ivalues, [0]);
            list.insert(1);
            test!equals(list.ivalues, [0, 1]);
            list.insert(-1);
            test!equals(list.ivalues, [-1, 0, 1]);
            list.insert(0);
            test!equals(list.ivalues, [-1, 0, 0, 1]);
            list.insert([0, 2]);
            test!equals(list.ivalues, [-1, 0, 0, 0, 1, 2]);
        });
        tests("Insert sorted", {
            auto list = new SortedList!int();
            list.insertsorted([0, 2, 4, 5]);
            test!equals(list.ivalues, [0, 2, 4, 5]);
            list.insertsorted([1, 2]);
            test!equals(list.ivalues, [0, 1, 2, 2, 4, 5]);
            list.insertsorted([3, 6, 8, 9]);
            test!equals(list.ivalues, [0, 1, 2, 2, 3, 4, 5, 6, 8, 9]);
            list.insertsorted(new int[0]);
            test!equals(list.ivalues, [0, 1, 2, 2, 3, 4, 5, 6, 8, 9]);
        });
        tests("Stability", {
            alias compare = (a, b) => (abs(a) < abs(b));
            {
                auto list = new SortedList!(int, compare)();
                list.insert([0, 1, -2]);
                test!equals(list.ivalues, [0, 1, -2]);
                list.insert(-1);
                test!equals(list.ivalues, [0, 1, -1, -2]);
                list.insert(2);
                test!equals(list.ivalues, [0, 1, -1, -2, 2]);
            }{
                auto list = new SortedList!(int, compare)();
                list.insertsorted([0, -1, 3, -4]);
                test!equals(list.ivalues, [0, -1, 3, -4]);
                list.insertsorted([1, 2, -2, -3, 5]);
                test!equals(list.ivalues, [0, -1, 1, 2, -2, 3, -3, -4, 5]);
            }
        });
        tests("Range", {
            {
                auto list = new SortedList!int();
                list.insertsorted([0, 1, 2, 3]);
                auto values = list.values;
                test!equals(list.ivalues, [0, 1, 2, 3]);
                values.removeFront();
                test!equals(list.ivalues, [1, 2, 3]);
                values.removeBack();
                test!equals(list.ivalues, [1, 2]);
                static assert(!is(typeof({values.front = 1;})));
                static assert(!is(typeof({values.back = 1;})));
            }{
                auto list = new SortedList!int();
                list.insertsorted([0, 1, 2, 3]);
                auto nodes = list.nodes;
                test!equals(list.ivalues, [0, 1, 2, 3]);
                nodes.removeFront();
                test!equals(list.ivalues, [1, 2, 3]);
                nodes.removeBack();
                test!equals(list.ivalues, [1, 2]);
                static assert(!is(typeof({nodes.front = 1;})));
                static assert(!is(typeof({nodes.back = 1;})));
            }
        });
    });
}
