module mach.sdl.framelimiter;

private:

import core.thread : Thread, dur;
import std.datetime : StopWatch, AutoStart;

public:



/// Can be used to limit the maximum number of times a loop executes per second.
/// Uses thread sleep when a loop - generally a rendering frame - takes less
/// time than the imposed limit.
/// TODO: Is the current implementation vulnerable to this?
/// http://stackoverflow.com/questions/23258650/sleep1-and-sdl-delay1-takes-15-ms
struct FrameLimiter{
    /// Target milliseconds per frame.
    real mspflimit = real(1000) / 60;
    /// Implementation detail to help maintain fractional mspf limits.
    real mspferror = 0;
    
    /// Estimated milliseconds recently spent rendering each frame.
    real rendermspf = 0;
    /// Most recent milliseconds spent rendering for a frame.
    ulong lastrenderms = 0;
    /// Estimated milliseconds recently spent sleeping each frame.
    real sleepmspf = 0;
    /// Most recent milliseconds spent sleeping for a frame.
    ulong lastsleepms = 0;
    
    /// Determine whether tracking has started. This indicates, for example,
    /// whether mspf estimations are available yet.
    bool tracking = false;
    
    /// Used to track how much time is passing.
    StopWatch stopwatch = StopWatch(AutoStart.no);
    
    /// Milliseconds on the stopwatch when the previous frame ended.
    ulong lastframems = 0;
    
    /// Current frame, incremented every time update is called.
    ulong frame = 0;
    
    this(ulong fpslimit){
        this.fpslimit = fpslimit;
    }
    
    /// Get target frames per second.
    @property ulong fpslimit() const{
        return cast(ulong)(1000 / this.mspflimit);
    }
    /// Set target frames per second.
    @property void fpslimit(ulong limit) in{
        assert(limit >= 0);
    }body{
        this.mspflimit = real(1000) / limit;
    }
    
    /// Estimated milliseconds recently spent each frame.
    @property auto actualmspf() const{
        return this.rendermspf + this.sleepmspf;
    }
    /// Most recent milliseconds spent for a frame.
    @property auto lastactualms() const{
        return this.lastrenderms + this.lastsleepms;
    }
    /// Estimated frame rate.
    @property auto actualfps() const{
        return 1000 / this.actualmspf;
    }
    
    /// To be called once per rendering loop. Keeps track of the amount of time
    /// spent rendering a frame and, if the rendering time was less than the
    /// limit, suspends the thread to eat up time.
    /// Probably best to call right after swapping buffers. Though that's more
    /// intuition and experience than any empirical advice, so take it with a
    /// grain of salt.
    void update() in{
        assert(this.mspflimit >= 0);
    }body{
        if(!this.stopwatch.running){
            // Start the stopwatch if it hasn't been started already
            this.stopwatch.start;
            this.lastframems = 0;
        }else{
            auto now = this.stopwatch.peek().msecs;
            auto renderms = now - this.lastframems;
            this.lastrenderms = cast(ulong) renderms;
            // Determine whether it is necessary to sleep
            if(renderms < this.mspflimit){
                // Determine how long to sleep
                auto intmspflimit = cast(ulong) this.mspflimit;
                // Account for error caused by having a fractional mspf limit
                this.mspferror += this.mspflimit - intmspflimit;
                if(this.mspferror >= 1){
                    this.mspferror--;
                    intmspflimit++;
                }
                // Do the actual sleeping
                ulong sleepms = cast(ulong)(intmspflimit - renderms);
                this.lastsleepms = sleepms;
                this.sleep(sleepms);
            }else{
                // Don't sleep
                this.lastsleepms = 0;
            }
            this.lastframems = cast(ulong) this.stopwatch.peek().msecs;
            // Track running estimates for sleep and render mspf
            if(this.tracking){
                this.rendermspf = this.lastrenderms * 0.25 + this.rendermspf * 0.75;
                this.sleepmspf = this.lastsleepms * 0.25 + this.sleepmspf * 0.75;
            }else{
                this.rendermspf = this.lastrenderms;
                this.sleepmspf = this.lastsleepms;
                this.tracking = true;
            }
        }
        this.frame++;
    }
    
    /// Reset the frame limiter. (I'm not sure what you'd want to do this for,
    /// but here you go anyway.)
    void reset(){
        this.mspferror = 0;
        this.rendermspf = 0;
        this.lastrenderms = 0;
        this.sleepmspf = 0;
        this.lastsleepms = 0;
        this.tracking = false;
        this.stopwatch.stop();
        this.stopwatch.reset();
        this.lastframems = 0;
        this.frame = 0;
    }
    
    /// Sleep on the current thread for a given number of milliseconds.
    static void sleep(ulong ms){
        Thread.sleep(dur!("msecs")(ms));
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import std.math : abs;
    import std.stdio : writeln;
}
unittest{
    tests("Frame limiter", {
        FrameLimiter fps;
        fps.fpslimit = 60;
        testeq(fps.fpslimit, 60);
        fps.fpslimit = 30;
        testeq(fps.fpslimit, 30);
        foreach(i; 0 .. 10){
            fps.sleep(2);
            // Values are not accurate until at least one frame has been evaluated
            if(fps.frame > 1){
                // Test correct recording of sleep ms
                testgt(fps.lastsleepms, 0);
                // Test correct recording of render ms
                testgt(fps.lastrenderms, 0);
                // Test that frame rate limiting is accurate within a margin of 2ms
                // Note: Possibly not 100% deterministic (Sorry)
                testgte(fps.lastactualms - fps.mspflimit, -2);
            }
            fps.update();
        }
    });
}
