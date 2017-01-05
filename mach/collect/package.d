module mach.collect;

public:

import mach.collect.heap : Heap, heapify;
import mach.collect.linkedlist;
import mach.collect.sortedlist;
import mach.collect.hashmap;

alias LinkedList = DoublyLinkedList;
alias aslist = asdoublylinkedlist;

alias HashMap = DenseHashMap;
alias ashashmap = asdensehashmap;
alias HashSet = DenseHashSet;
alias ashashset = asdensehashset;
alias Map = HashMap;
alias asmap = ashashmap;
alias Set = HashSet;
alias asset = ashashset;
