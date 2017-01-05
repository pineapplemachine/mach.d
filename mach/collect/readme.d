module mach.collect.readme;

private:

version(unittest){
    import mach.collect;
    import mach.range.compare : equals;
}

/++ md

# mach.collect

This package provides some collection types.

All collections in this package are either valid as ranges, or are
themselves ranges.

## mach.collect.hashmap

Defines a dense hash map, or hash table, and a dense hash set.
A hash map functions like an associative array.
A hash set is similar, but it recognizes keys and not values.

Hash maps and sets come in both statically- and dynamically-sized flavors.
Either can be rehashed via explicit calls, but only dynamically-sized
maps and sets will grow when nearly full and shrink when nearly empty.

Note that `DenseHashMap` and `DenseHashSet` instances are uncopyable,
and in most cases a reference should be maintained.

+/

unittest{
    auto map = new HashMap!(string, string)();
    map.set("hello", "world");
    map.set("how", "are you?");
    assert(map.length == 2);
    assert(map.contains("hello"));
    assert(map.contains("how"));
    assert(map.get("hello") == "world");
    assert(!map.contains("not a key"));
    map.remove("how");
    assert(!map.contains("how"));
}

unittest{
    auto set = new HashSet!string();
    set.add("abc");
    set.add("xyz");
    assert(set.length == 2);
    assert(set.contains("abc"));
    assert(set.contains("xyz"));
    assert(!set.contains("123"));
    set.remove("abc");
    assert(!set.contains("abc"));
}

/++ md

These types define operator overloads but, when using pointers,
it becomes necessary to use the dereference operator `*`.

+/

unittest{
    HashMap!(string, string) map;
    map["hello"] = "world";
    assert("hello" in map);
    assert(map["hello"] == "world");
}

unittest{
    auto map = new HashMap!(string, string)();
    (*map)["hello"] = "world";
    assert("hello" in *map);
    assert((*map)["hello"] == "world");
}

/++ md

## mach.collect.heap

Defines a [binary heap](https://en.wikipedia.org/wiki/Binary_heap) data structure,
implemented using an array.

+/

unittest{
    Heap!int heap;
    heap.push(3);
    heap.push(1);
    heap.push(2);
    assert(heap.pop == 1);
    assert(heap.pop == 2);
    assert(heap.pop == 3);
}

/++ md

## mach.collect.linkedlist

Defines a cyclic doubly-linked list type.
Linked lists are more efficient than array lists for random insertions and
removals, but are suboptimal for random access.
Because the memory of a linked list is not stored sequentially, unlike an
array list, traversal is also slower.

Note that `DoublyLinkedList` instances are uncopyable,
and in most cases a reference should be maintained.

+/

unittest{
    auto list = new LinkedList!string();
    // Construct a list with the contents ["front", "middle", "back"].
    list.append("back");
    auto front = list.prepend("front");
    list.insertafter(front, "middle");
    // Verify the content of the list
    assert(list.equals(["front", "middle", "back"]));
    // Remove a node
    list.remove(front);
    assert(list.equals(["middle", "back"]));
}

/++ md

The `DoublyLinkedList` type defines operator overloads but, when using pointers,
it becomes necessary to use the dereference operator `*`.

+/

unittest{
    LinkedList!string list;
    list ~= "a";
    list ~= ["b", "c"];
    assert(list.equals(["a", "b", "c"]));
}

unittest{
    auto list = new LinkedList!string();
    *list ~= "a";
    *list ~= ["b", "c"];
    assert(list.equals(["a", "b", "c"]));
}

/++ md

## mach.collect.sortedlist

The `SortedList` type is built on top of the `DoublyLinkedList` type.
Its contents are maintained in sorted order as they are inserted using
what amounts to a simple insertion sort.

Note that `SortedList` instances are uncopyable,
and in most cases a reference should be maintained.

+/

unittest{
    auto list = new SortedList!int();
    auto one = list.insert(1);
    list.insert(4);
    list.insert(3);
    list.insert(2);
    assert(list.equals([1, 2, 3, 4]));
    list.remove(one);
    assert(list.equals([2, 3, 4]));
}

/++ md

Groups of elements can be inserted at once, and different methods are provided
for inserting elements that are or are not guaranteed to themselves be in
sorted order.

+/

unittest{
    auto list = new SortedList!int();
    list.insert([6, 2, 4]); // Values not sorted
    assert(list.equals([2, 4, 6]));
    list.insertsorted([1, 2, 3]); // Values already sorted
    assert(list.equals([1, 2, 2, 3, 4, 6]));
}

/++ md

The `SortedList` type defines operator overloads but, when using pointers,
it becomes necessary to use the dereference operator `*`.

+/

unittest{
    SortedList!int list;
    list ~= 3;
    list ~= 2;
    list ~= 1;
    assert(list.equals([1, 2, 3]));
}

unittest{
    auto list = new SortedList!int();
    *list ~= 3;
    *list ~= 2;
    *list ~= 1;
    assert(list.equals([1, 2, 3]));
}
