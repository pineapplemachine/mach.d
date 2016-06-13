module mach.range.find.templates;

private:

import std.traits : isIntegral;
import mach.traits : isIterable, isIterableReverse, ElementType, isPredicate;
import mach.traits : isRange, hasNumericIndex, hasNumericLength;
import mach.range.asrange : validAsSavingRange, validAsBidirectionalRange;

public:



alias DefaultFindPredicate = (element, subject) => (element == subject);

alias DefaultFindIndex = size_t;

alias validFindIndex = isIntegral;

enum canFindIn(Iter, bool forward) = (
    (forward && isIterable!Iter) ||
    (!forward && isIterableReverse!Iter && hasNumericLength!Iter)
);

enum canFindElement(alias pred, Index, Iter, bool forward = true) = (
    canFindIn!(Iter, forward) && validFindIndex!Index &&
    isPredicate!(pred, ElementType!Iter)
);

enum canFindIterable(alias pred, Index, Iter, Find, bool forward = true) = (
    canFindRandomAccess!(pred, Index, Iter, Find, forward) ||
    canFindSaving!(pred, Index, Iter, Find, forward)
);

enum canFindRandomAccess(alias pred, Index, Iter, Find, bool forward = true) = (
    canFindIn!(Iter, forward) && validFindIndex!Index &&
    hasNumericIndex!Find && hasNumericLength!Find &&
    isPredicate!(pred, ElementType!Iter, ElementType!Find)
);

enum canFindSaving(alias pred, Index, Iter, Find, bool forward = true) = (
    canFindIn!(Iter, forward) && validFindIndex!Index &&
    validAsSavingRange!Find && (forward || validAsBidirectionalRange!Find) &&
    isPredicate!(pred, ElementType!Iter, ElementType!Find)
);

enum canFindSavingRange(alias pred, Index, Iter, Find, bool forward = true) = (
    isRange!Find && canFindSaving!(pred, Index, Iter, Find, forward)
);
