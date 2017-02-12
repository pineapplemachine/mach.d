module mach.sys.platform;

private:

/++ Docs

Defines several enum values pertinent to the compile target platform.

`InlineAsm_X86_Any` is true when inline x86 assembly is available,
as determined by the `D_InlineAsm_X86` and `D_InlineAsm_X86_64`
version identifiers.

`X86_Any` is true when compiling to an x86 target, as determined by the `X86`
and `X86_64` version identifiers.

`PPC_Any` is true when compiling to an x86 target, as determined by the `PPC`
and `PPC64` version identifiers.

`Any_32` is true when compiling to a 32-bit target.
`Any_64` is true when compiling to a 64-bit target.

+/

public:



enum Any_32 = size_t.sizeof == 4;
enum Any_64 = size_t.sizeof == 8;



version(D_InlineAsm_X86){
    enum InlineAsm_X86_Any = true;
}else version(D_InlineAsm_X86_64){
    enum InlineAsm_X86_Any = true;
}else{
    enum InlineAsm_X86_Any = false;
}



version(X86){
    enum X86_Any = true;
    static assert(Any_32 && !Any_64);
}else version(X86_64){
    enum X86_Any = true;
    static assert(!Any_32 && Any_64);
}else{
    enum X86_Any = false;
}



version(PPC){
    enum PPC_Any = true;
    static assert(Any_32 && !Any_64);
}else version(PPC64){
    enum PPC_Any = true;
    static assert(!Any_32 && Any_64);
}else{
    enum PPC_Any = false;
}
