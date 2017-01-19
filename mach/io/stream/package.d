module mach.io.stream;

private:

/++ Docs

This package implements various stream types for reading or writing data,
and provides tools for operating upon those streams.

+/

public:

import mach.io.stream.asarray;
import mach.io.stream.asrange;
import mach.io.stream.exceptions;
import mach.io.stream.io;
import mach.io.stream.templates;

import mach.io.stream.filestream;
import mach.io.stream.memorystream;
import mach.io.stream.stdiostream;
