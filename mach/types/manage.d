module mach.types.manage;

private:

//

public:



/// If the passed value has a `begin` function, call it before the `apply`
/// statement. If the passed value has a `conclude` function, call it after the
/// `apply` statement.
/// This allows for automatic initialization and cleanup of a type. This is
/// especially relevant and useful for streams, which must be closed when they
/// are done being used.
/// Mainly just a way to avoid having to `scope(exit) file.close;` all over the
/// place, because I think that's ugly and tedious and easy to forget.
auto manage(alias apply, T)(auto ref T value){
    return value.manage!(
        (x){
            static if(is(typeof({x.begin();}))) x.begin();
        },
        (x){
            static if(is(typeof({x.conclude();}))) x.conclude();
        },
        apply
    );
}

auto manage(T)(auto ref T value){
    return value.manage!(
        (x){
            static if(is(typeof({x.begin();}))) x.begin();
        },
        (x){
            static if(is(typeof({x.conclude();}))) x.conclude();
        },
        (x){}
    );
}

auto manage(alias begin, alias conclude, alias apply, T)(auto ref T value){
    begin(value);
    scope(exit) conclude(value);
    return apply(value);
}



version(unittest){
    private:
    struct Contextual{
        static size_t alive = 0;
        static auto opCall(){typeof(this).alive++; Contextual t; return t;}
        void conclude(){typeof(this).alive--;}
    }
}
unittest{
    assert(Contextual.alive == 0);
    assert(0 == Contextual().manage!((c){
        assert(Contextual.alive == 1);
        return 0;
    }));
    assert(Contextual.alive == 0);
    auto c = Contextual();
    assert(Contextual.alive == 1);
    assert(1 == Contextual().manage!((c){
        assert(Contextual.alive == 2);
        return 1;
    }));
    assert(Contextual.alive == 1);
    Contextual().manage();
    assert(Contextual.alive == 1);
}
