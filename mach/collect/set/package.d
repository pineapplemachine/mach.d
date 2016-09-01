module mach.collect.set;

public:

import mach.collect.set.templates : SetMixin, isSet;

import mach.collect.set.densehash : DenseHashSet, asdensehashset;

// Sensible default aliases
alias HashSet = DenseHashSet;
alias Set = HashSet;
