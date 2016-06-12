module mach.collect.heap;

private:

import mach.traits : isIterableOf;

public:



/// Put the greatest element on top by default.
alias DefaultHeapCompare = (a, b) => (a > b);



/// Binary heap implementation.
struct Heap(T, alias compare = DefaultHeapCompare){
    T[] elements;
    
    this(typeof(this) heap){
        this.elements = heap.elements;
    }
    this(T[] values...){
        this.clear();
        this.push(values);
    }
    this(Iter)(Iter values) if(isIterableOf!(Iter, T)){
        this.clear();
        this.push(values);
    }
    
    @property auto length(){
        if(this.elements.length){
            return this.elements.length - 1;
        }else{
            return 0;
        }
    }
    @property bool empty(){
        return this.elements.length <= 1;
    }
    
    void clear(){
        this.elements = new T[1];
    }
    
    auto push(ref T value){
        if(!this.elements.length) this.clear();
        this.elements ~= value;
        auto index = this.perlocateup(this.length);
        if(index > 0) index = this.perlocatedown(index);
        return index;
    }
    auto push(T[] values...){
        foreach(value; values) this.push(value);
    }
    auto push(Iter)(Iter values...) if(isIterableOf!(Iter, T)){
        foreach(value; values) this.push(value);
    }
    
    @property auto top() in{assert(!this.empty);} body{
        return this.elements[1];
    }
    @property auto pop() in{assert(!this.empty);} body{
        auto element = this.elements[1];
        this.elements[1] = this.elements[this.length];
        this.elements.length = this.elements.length - 1;
        this.perlocatedown(1);
        return element;
    }
    
    auto perlocateup(size_t index){
        while(index / 2 > 0){
            auto temp = this.elements[index / 2];
            this.elements[index / 2] = this.elements[index];
            this.elements[index] = temp;
            index /= 2;
        }
        return index;
    }
    auto perlocatedown(size_t index){
        while(index * 2 <= this.length){
            auto min = this.child(index);
            if(compare(this.elements[min], this.elements[index])){
                auto temp = this.elements[index];
                this.elements[index] = this.elements[min];
                this.elements[min] = temp;
            }
            index = min;
        }
        return index;
    }
    auto child(size_t index){
        if(index * 2 + 1 > this.length){
            return index * 2;
        }else if(compare(this.elements[index * 2], this.elements[index * 2 + 1])){
            return index * 2;
        }else{
            return index * 2 + 1;
        }
    }
    
    @property typeof(this) dup(){
        typeof(this) heap;
        heap.elements = this.elements.dup;
        return heap;
    }
    
    // Make it a range
    alias front = top;
    alias popFront = pop;
    alias save = dup;
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.traits : isRange;
    import mach.range.compare : equals;
}
unittest{
    tests("Heap", {
        static assert(isRange!(Heap!int));
        tests("Iteration", {
            test(Heap!int(2, -1, -2, 1, 0).equals([2, 1, 0, -1, -2]));
            test(Heap!int(2, 1, 1, 2, 1).equals([2, 2, 1, 1, 1]));
        });
        tests("Length", {
            Heap!int heap;
            test(heap.empty);
            testeq(heap.length, 0);
            heap.push(1, 2);
            testeq(heap.length, 2);
            heap.push(3);
            testeq(heap.length, 3);
            heap.pop();
            testeq(heap.length, 2);
            heap.clear();
            testeq(heap.length, 0);
        });
    });
}
