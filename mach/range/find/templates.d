module mach.range.find.templates;

private:

import std.traits : isIntegral;
import mach.traits : isIterable, isIterableReverse, hasNumericLength;

public:



alias DefaultFindPredicate = (element, subject) => (element == subject);
alias DefaultFindIndex = size_t;
alias validFindIndex = isIntegral;

enum canFindIn(Iter, bool forward) = (
    (forward && isIterable!Iter) ||
    (!forward && isIterableReverse!Iter && hasNumericLength!Iter)
);
