module mach.error.enforce;

public:

import mach.error.enforce.bounds : OutOfBoundsException, enforcebounds, enforcelowbound, enforcehighbound;
import mach.error.enforce.errno : enforceerrno, asserterrno, Errno, ErrnoException;
