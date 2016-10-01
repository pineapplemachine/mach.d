module mach.range.find.templates;

private:

import mach.traits : isIntegral, isIterable, isIterableReverse, hasNumericLength;

public:



alias DefaultFindPredicate = (element, subject) => (element == subject);
alias DefaultFindIndex = size_t;
alias validFindIndex = isIntegral;

enum canFindIn(Iter, bool forward) = (
    (forward && isIterable!Iter) ||
    (!forward && isIterableReverse!Iter && hasNumericLength!Iter)
);
