module mach.range.interpolate;

private:

import std.traits : isNumeric, isIntegral, isFloatingPoint;

public:



enum validInterpolationRange(Step, Sample) = (
    validInterpolationStep!Step &&
    validInterpolationSample!Sample
);

alias validInterpolationStep = isNumeric;
alias validInterpolationSample = isFloatingPoint;

alias DefaultInterpolationStep = size_t;
alias DefaultInterpolationSample = real;



/// Linear interpolation function, used by lerp
alias LinearInterpolation = (start, end, t){
    return start + (end - start) * t;
};

/// Cosine interpolation function, used by coslerp
alias CosineInterpolation = (start, end, t){
    import std.math : PI, cos;
    auto f = (1 - cos(t * PI)) * .5;
    return (1 - f) * start + f * end;
};



/// Create a range which interpolates from start to end in a given number of
/// steps.
auto interpolate(
    alias func, bool inclusive = true, Element,
    Step = DefaultIterpolationStep, Sample = DefaultInterpolationSample
)(Element start, Element end, Step length) if(
    validInterpolationRange!(Step, Sample)
){
    return InterpolationRange!(
        func, Element, inclusive, Step, Sample
    )(
        start, end, length
    );
}

/// Create a range which interpolates from 0 to end in a given number of steps.
auto interpolate(
    alias func, bool inclusive = true, Element,
    Step = DefaultIterpolationStep, Sample = DefaultInterpolationSample
)(Element end, Step length) if(
    validInterpolationRange!(Step, Sample)
){
    return InterpolationRange!(
        func, Element, inclusive, Step, Sample
    )(
        Element.init, end, length
    );
}



/// Create a range which linearly interpolates from start to end in a given
/// number of steps.
auto lerp(
    bool inclusive = true, Element, Step = DefaultIterpolationStep
)(Element start, Element end, Step length) if(validInterpolationStep!Step){
    return InterpolationRange!(
        LinearInterpolation, Element, inclusive, Step
    )(start, end, length);
}

/// Create a range which linearly interpolates from 0 to end in a given number
/// of steps.
auto lerp(
    bool inclusive = true, Element, Step = DefaultIterpolationStep
)(Element end, Step length) if(validInterpolationStep!Step){
    return InterpolationRange!(
        LinearInterpolation, Element, inclusive, Step
    )(Element.init, end, length);
}



/// Create a range which cosine-interpolates from start to end in a given number
/// of steps.
auto coslerp(
    bool inclusive = true, Element, Step = DefaultIterpolationStep
)(Element start, Element end, Step length) if(validInterpolationStep!Step){
    return InterpolationRange!(
        CosineInterpolation, Element, inclusive, Step
    )(start, end, length);
}

/// Create a range which cpsine-interpolates from 0 to end in a given number of
/// steps.
auto coslerp(
    bool inclusive = true, Element, Step = DefaultIterpolationStep
)(Element end, Step length) if(validInterpolationStep!Step){
    return InterpolationRange!(
        CosineInterpolation, Element, inclusive, Step
    )(Element.init, end, length);
}



struct InterpolationRange(
    alias func, Element,
    bool inclusive = true, // When false, "end" is not part of the range
    Step = DefaultIterpolationStep,
    Sample = DefaultInterpolationSample
) if(
    validInterpolationRange!(Step, Sample)
){
    Element start;
    Element end;
    Step length; // Total number of steps
    Step frontstep;
    Step backstep;
    
    alias step = frontstep;
    
    this(typeof(this) range){
        this(
            range.start, range.end, range.length,
            range.frontstep, range.backstep
        );
    }
    this(Element start, Element end, Step length, Step frontstep = Step.init){
        this(start, end, length, frontstep, length);
    }
    this(Element start, Element end, Step length, Step frontstep, Step backstep){
        this.start = start;
        this.end = end;
        this.length = length;
        this.frontstep = frontstep;
        this.backstep = backstep;
    }
    
    @property auto front() const{
        return this[this.frontstep];
    }
    @property auto popFront(){
        this.frontstep++;
    }
    
    @property auto back() const{
        return this[this.backstep - 1];
    }
    @property auto popBack(){
        this.backstep--;
    }
    
    @property bool empty() const{
        return this.frontstep >= this.backstep;
    }
    
    auto opIndex(in Step step) const{
        Sample sample = (cast(Sample) step) / (cast(Sample) (this.length - inclusive));
        return func(start, end, sample);
    }
    
    static if(is(typeof(this.opIndex) == Element)){
        auto opSlice(in Step low, in Step high) const in{
            assert(low >= 0 && high >= low && high < this.length);
        }body{
            return typeof(this)(this[low], this[high], high - low);
        }
    }
    
    @property auto save() const{
        return typeof(this)(this);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Interpolation", {
        test(lerp!true(0, 4, 5).equals([0, 1, 2, 3, 4]));
        test(lerp!false(0, 4, 4).equals([0, 1, 2, 3]));
        test(lerp!true(0, 1, 5).equals([0, 0.25, 0.5, 0.75, 1]));
    });
}
