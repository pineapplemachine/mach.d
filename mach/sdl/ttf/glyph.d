module mach.sdl.ttf.glyph;

private:

import mach.math : Vector;

public:



/// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_38.html
struct GlyphMetrics{
    int minx;
    int miny;
    int maxx;
    int maxy;
    int advance;
    @property auto width() const{
        return this.maxx - this.minx;
    }
    @property auto height() const{
        return this.maxy - this.miny;
    }
    @property auto size() const{
        return Vector(this.width, this.height);
    }
    
}
