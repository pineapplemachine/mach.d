module mach.range.find.findlazy;

private:

import mach.types : Rebindable;
import mach.traits : ElementType, hasNumericLength, isPredicate, isRange;
import mach.traits : isFiniteIterable, isRandomAccessIterable;
import mach.traits : isFiniteRange, isSlicingRange, isSavingRange;
import mach.range.asrange : asrange, validAsRange, validAsSavingRange;
import mach.range.find.result;
import mach.range.find.templates;
import mach.range.find.threads;

public:



template canFindAllLazy(alias pred, Index, Iter, Subject){
    static if(
        validAsRange!Iter && isFiniteIterable!Subject && hasNumericLength!Subject &&
        (isRandomAccessIterable!Subject || validAsSavingRange!Subject)
    ){
        enum bool canFindAllLazy = (
            validFindIndex!Index &&
            isPredicate!(pred, ElementType!Iter, ElementType!Subject)
        );
    }else{
        enum bool canFindAllLazy = false;
    }
}

enum canFindAllLazyRange(alias pred, Index, Range, Subject) = (
    canFindAllLazy!(pred, Index, Range, Subject) && 
    (isRandomAccessIterable!Subject || isSavingRange!Subject) &&
    isRange!Range
);



/// Find all instances of some iterable subject within an iterable, using the
/// given predicate to compare elements for equality.
auto findalliterlazy(
    alias pred = DefaultFindPredicate, Index = DefaultFindIndex, Iter, Subject
)(auto ref Iter iter, auto ref Subject subject) if(
    canFindAllLazy!(pred, Index, Iter, Subject)
){
    static if(isRandomAccessIterable!Subject) auto sub = subject;
    else static if(isSavingRange!Subject) auto sub = subject;
    else static if(validAsSavingRange!Subject) auto sub = subject.asrange;
    else assert(false); // Shouldn't ever happen
    auto range = iter.asrange;
    return FindAllRange!(pred, typeof(range), typeof(sub), Index)(range, sub);
}



struct FindAllRange(alias pred, Range, Subject, Index = DefaultFindIndex) if(
    canFindAllLazyRange!(pred, Index, Range, Subject)
){
    static enum isFinite = isFiniteRange!Range;
    static enum isSlicing = isSlicingRange!Range;
    static enum isRandomAccess = isRandomAccessIterable!Subject;
    
    static if(isRandomAccess){
        alias Thread = FindRandomAccessThread!(pred, true, Index);
    }else{
        alias Thread = FindSavingThread!(pred, true, Index, Subject);
    }
    static if(isSlicing){
        alias Result = Rebindable!(FindResultPlural!(Index, Range));
    }else{
        alias Result = FindResultIndexPlural!Index;
    }
    
    alias ThreadManager = FindThreadManager!Thread;
    alias SubjectFront = ElementType!Subject;
    
    Range source; /// Range being searched
    Subject subject; /// Iterable being searched for in source
    SubjectFront subjectfront; /// First element of subject
    ThreadManager threads; /// Interface for handling search threads
    Index index; /// Current index in source range
    Result result; /// Current front of range
    
    static if(isFinite){
        bool isempty; /// Whether the range is currently empty
        @property bool empty() const{return this.isempty;}
    }else{
        static enum bool empty = false;
    }
    
    this(Range source, Subject subject) in{
        assert(subject.length, "Subjects of zero length are not allowed.");
    }body{
        static if(!isRange!Subject && isRandomAccessIterable!Subject){
            SubjectFront subjectfront = subject[0];
        }else{
            SubjectFront subjectfront = subject.front;
        }
        static if(isFinite){
            bool isempty = source.empty;
            static if(hasNumericLength!Range){
                isempty = isempty || (source.length < subject.length);
            }
            this(source, subject, subjectfront, ThreadManager(64), 0, isempty);
        }else{
            this(source, subject, subjectfront, ThreadManager(64), 0);
        }
    }
    static if(isFinite){
        this(
            Range source, Subject subject, SubjectFront subjectfront,
            ThreadManager threads, Index index, bool isempty
        ){
            this.source = source;
            this.subject = subject;
            this.subjectfront = subjectfront;
            this.threads = threads;
            this.index = index;
            this.isempty = isempty;
            if(!this.isempty) this.popFront(); // Prepares the range
        }
        this(
            Range source, Subject subject, SubjectFront subjectfront,
            ThreadManager threads, Index index, Result result, bool isempty
        ){
            this.source = source;
            this.subject = subject;
            this.subjectfront = subjectfront;
            this.threads = threads;
            this.index = index;
            this.result = result;
            this.isempty = isempty;
        }
    }else{
        this(
            Range source, Subject subject, SubjectFront subjectfront,
            ThreadManager threads, Index index
        ){
            this.source = source;
            this.subject = subject;
            this.subjectfront = subjectfront;
            this.threads = threads;
            this.index = index;
            this.popFront(); // Prepares the range
        }
        this(
            Range source, Subject subject, SubjectFront subjectfront,
            ThreadManager threads, Index index, Result result
        ){
            this.source = source;
            this.subject = subject;
            this.subjectfront = subjectfront;
            this.threads = threads;
            this.index = index;
            this.result = result;
        }
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.result;
    }
    
    void popFront() in{assert(!this.empty);} body{
        bool found = false;
        while(!this.source.empty){
            found = this.stepthreads(this.source.front);
            this.source.popFront();
            this.index++;
            if(found) break;
        }
        static if(isFinite){
            if(!found) this.isempty = this.source.empty;
        }
    }
    
    bool stepthreads(ElementType!Range element){
        auto found = false;
        // Progress living threads
        foreach(ref thread; this.threads){
            static if(isRandomAccess) bool matched = thread.next(element, this.subject);
            else bool matched = thread.next(element);
            if(matched){
                this.result = cast(Result) thread.result(this.source, this.index);
                found = true;
            }
        }
        // Spawn new threads
        if(pred(element, this.subjectfront)){
            static if(isRandomAccess){
                auto thread = Thread(this.index, 1);
            }else{
                auto thread = Thread(this.index, this.subject.save);
                thread.searchrange.popFront();
            }
            if(this.subject.length == 1){
                this.result = cast(Result) thread.result(this.source, this.index);
                found = true;
            }else{
                this.threads.add(thread);
            }
        }
        return found;
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            static if(isFinite){
                return typeof(this)(
                    this.source.save, this.subject, this.subjectfront,
                    this.threads.dup, this.index, this.result, this.isempty
                );
            }else{
                return typeof(this)(
                    this.source.save, this.subject, this.subjectfront,
                    this.threads.dup, this.index, this.result
                );
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.pluck : pluck;
    struct StringRange{
        string source; size_t index;
        @property auto length(){return this.source.length;}
        @property bool empty(){return this.index >= this.length;}
        @property auto front(){return this.source[this.index];}
        void popFront(){this.index++;}
        @property typeof(this) save(){return typeof(this)(this.source, this.index);}
    }
    template FindAllTests(alias transformsubject){
        void FindAllTests(){
            tests("Iteration", {
                auto range = "hihi yo hi".findalliterlazy(transformsubject("hi"));
                testeq(range.front.index, 0);
                test(range.front.value.equals("hi"));
                test(range.pluck!`index`.equals([0, 2, 8]));
                test(range.pluck!`value`.equals(["hi", "hi", "hi"]));
            });
            tests("Empty source", {
                auto range = "".findalliterlazy(transformsubject("hi"));
                test(range.empty);
            });
            tests("Empty Subject", {
                testfail({
                    auto range = "test".findalliterlazy(transformsubject(""));
                });
            });
            tests("Single-length subject", {
                auto range = "abcabc".findalliterlazy(transformsubject("a"));
                test(range.pluck!`index`.equals([0, 3]));
                test(range.pluck!`value`.equals(["a", "a"]));
                range.popFront();
                range.popFront();
                test(range.empty);
                testfail({range.front;});
            });
            tests("Single occurence", {
                auto range = ".hi.".findalliterlazy(transformsubject("hi"));
                test(range.pluck!`index`.equals([1]));
            });
            tests("Overlapping", {
                import mach.range.asarray;
                auto range = "etetet".findalliterlazy(transformsubject("etet"));
                testeq(range.front.index, 0);
                test(range.front.value.equals("etet"));
                range.popFront();
                testeq(range.front.index, 2);
                test(range.front.value.equals("etet"));
                range.popFront();
                test(range.empty);
            });
            tests("Saving", {
                auto range = "hihi yo hi".findalliterlazy(transformsubject("hi"));
                testeq(range.front.index, 0);
                range.popFront();
                testeq(range.front.index, 2);
                auto saved = range.save;
                range.popFront();
                testeq(saved.front.index, 2);
                testeq(range.front.index, 8);
            });
        }
    }
}
unittest{
    tests("Find all", {
        tests("Random access subject", {
            FindAllTests!(i => i)();
            FindAllTests!(i => i.asrange)();
        });
        tests("Saving subject", {
            FindAllTests!(i => StringRange(i))();
        });
    });
}
