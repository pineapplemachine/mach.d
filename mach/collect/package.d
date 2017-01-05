module mach.collect;

private:

import mach.collect.readme;

public:

import mach.collect.hashmap;
import mach.collect.heap : Heap, heapify;
import mach.collect.linkedlist;
import mach.collect.sortedlist;

alias LinkedList = DoublyLinkedList;
alias aslist = asdoublylinkedlist;

alias HashMap = DenseHashMap;
alias StaticHashMap = StaticDenseHashMap;
alias ashashmap = asdensehashmap;
alias HashSet = DenseHashSet;
alias StaticHashSet = HashSet;
alias ashashset = asdensehashset;
alias Map = HashMap;
alias asmap = ashashmap;
alias Set = HashSet;
alias asset = ashashset;
