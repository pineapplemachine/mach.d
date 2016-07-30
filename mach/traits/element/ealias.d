module mach.traits.element.ealias;

private:

//

public:



/// Determine if a type has an Element alias member.
/// Collections that should return something sensible for the ElementType
/// template but fall under none of its other checks can specify their element
/// type by assigning an Element alias.
template hasElementAlias(Tx...) if(Tx.length == 1){
    enum bool hasElementAlias = __traits(compiles, {alias E = Tx[0].Element;});
}



unittest{
    class Class{alias Element = int;}
    struct Struct{alias Element = int;}
    struct NoAlias{alias E = int;}
    Class c; Struct s;
    static assert(hasElementAlias!c);
    static assert(hasElementAlias!s);
    static assert(hasElementAlias!Class);
    static assert(hasElementAlias!Struct);
    static assert(!hasElementAlias!NoAlias);
    static assert(!hasElementAlias!int);
}
