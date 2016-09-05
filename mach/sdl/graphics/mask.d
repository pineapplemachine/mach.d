module mach.sdl.graphics.mask;

private:

import derelict.sdl2.sdl;

public:

struct Mask{
    static immutable Mask Zero = Mask(0, 0, 0, 0);
    version(LittleEndian){
        static immutable Mask Default = Mask(0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
        static immutable Mask Opaque = Mask(0xff000000, 0x00ff0000, 0x0000ff00, 0);
    }else{
        static immutable Mask Default = Mask(0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
        static immutable Mask Opaque = Mask(0x000000ff, 0x0000ff00, 0x00ff0000, 0);
    }
    
    uint red, green, blue, alpha;
    alias r = red, g = green, b = blue, a = alpha;
    
    this(uint[4] rgba){
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    this(uint r, uint g, uint b, uint a){
        this.r = r; this.g = g; this.b = b; this.a = a;
    }
    this(in SDL_PixelFormat* format){
        this.r = format.Rmask;
        this.g = format.Gmask;
        this.b = format.Bmask;
        this.a = format.Amask;
    }
    
    uint opIndex(in size_t index){
        if(index == 0) return this.r;
        else if(index == 1) return this.g;
        else if(index == 2) return this.b;
        else if(index == 3) return this.a;
        else assert(false);
    }
}
