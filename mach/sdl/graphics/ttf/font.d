module mach.sdl.graphics.ttf.font;

private:

import derelict.sdl2.ttf;
import derelict.sdl2.types;

import core.stdc.config : c_long;

import mach.text.cstring : tocstring, fromcstring;
import mach.math : Vector, Vector2;
import mach.sdl.graphics.color;
import mach.sdl.graphics.surface;
import mach.sdl.graphics.texture;
import mach.sdl.error : SDLException;
import mach.sdl.graphics.ttf.glyph;
import mach.sdl.graphics.ttf.style;

public:



struct Font{
    alias Style = FontStyle;
    alias Styles = FontStyles;
    alias GlyphMetrics = .GlyphMetrics;
    
    static enum Hinting: int{
        Normal = TTF_HINTING_NORMAL,
        Light = TTF_HINTING_LIGHT,
        Mono = TTF_HINTING_MONO,
        None = TTF_HINTING_NONE,
    }
    
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_42.html
    static enum RenderMode{
        Solid, /// Drawn cheaply, with rigid edges
        Blended, /// Drawn expensively, with blended edges
    }
    
    TTF_Font* font;
    
    this(TTF_Font* font){
        this.font = font;
    }
    this(string path, int size, c_long index = 0){
        this.font = TTF_OpenFontIndex(path.tocstring, size, index);
        if(this.font is null) throw new SDLException(
            "Failed to load font from path \"" ~ path ~ "\"."
        );
    }
    
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_16.html
    static typeof(this) open(string path, int size, c_long index = 0){
        return typeof(this)(path, size, index);
    }
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_18.html
    void close(){
        TTF_CloseFont(this.font);
    }
    
    /// Get font style.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_21.html
    @property auto style() in{assert(this.font !is null);} body{
        return Styles(TTF_GetFontStyle(this.font));
    }
    /// Set font style.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_22.html
    @property void style(Styles styles) in{assert(this.font !is null);} body{
        TTF_SetFontStyle(this.font, styles.flags);
    }
    
    /// Get outline pixel width.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_23.html
    @property auto outline() in{assert(this.font !is null);} body{
        return TTF_GetFontOutline(this.font);
    }
    /// Set outline pixel width.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_24.html
    @property void outline(int outline) in{assert(this.font !is null);} body{
        TTF_SetFontOutline(this.font, outline);
    }
    
    /// Get hinting setting.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_25.html
    @property auto hinting() in{assert(this.font !is null);} body{
        return cast(Hinting) TTF_GetFontHinting(this.font);
    }
    /// Set hinting setting.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_26.html
    @property void hinting(Hinting hinting) in{assert(this.font !is null);} body{
        TTF_SetFontHinting(this.font, cast(int) hinting);
    }
    
    /// Get whether kerning is enabled.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_27.html
    @property auto kerning() in{assert(this.font !is null);} body{
        return cast(bool) TTF_GetFontKerning(this.font);
    }
    /// Set whether kerning is enabled.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_28.html
    @property void kerning(bool enabled) in{assert(this.font !is null);} body{
        TTF_SetFontKerning(this.font, cast(int) enabled);
    }
    
    /// Get the maximum pixel height of all glyphs.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_29.html
    @property auto height() in{assert(this.font !is null);} body{
        return TTF_FontHeight(this.font);
    }
    /// Get the maximum pixel ascent of all glyphs.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_30.html
    @property auto ascent() in{assert(this.font !is null);} body{
        return TTF_FontAscent(this.font);
    }
    /// Get the maximum pixel descent of all glyphs.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_31.html
    @property auto descent() in{assert(this.font !is null);} body{
        return TTF_FontDescent(this.font);
    }
    
    /// Get the recommended pixel height of a rendered line of text.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_32.html
    @property auto lineheight() in{assert(this.font !is null);} body{
        return TTF_FontLineSkip(this.font);
    }
    
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_33.html
    @property auto faces() in{assert(this.font !is null);} body{
        return TTF_FontFaces(this.font);
    }
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_34.html
    @property bool fixedwidth() in{assert(this.font !is null);} body{
        return cast(bool) TTF_FontFaceIsFixedWidth(this.font);
    }
    
    /// Get the font face family name if available, or null if not.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_35.html
    @property string familyname() in{assert(this.font !is null);} body{
        return TTF_FontFaceFamilyName(this.font).fromcstring;
    }
    /// Get the font face style name if available, or null if not.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_36.html
    @property string stylename() in{assert(this.font !is null);} body{
        return TTF_FontFaceStyleName(this.font).fromcstring;
    }
    
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_37.html
    auto glyphprovided(ushort character) in{assert(this.font !is null);} body{
        return TTF_GlyphIsProvided(this.font, character);
    }
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_38.html
    auto glyphmetrics(ushort character) in{assert(this.font !is null);} body{
        GlyphMetrics glyph;
        auto result = TTF_GlyphMetrics(
            this.font, character,
            &glyph.minx, &glyph.maxx,
            &glyph.miny, &glyph.maxy,
            &glyph.advance
        );
        if(result != 0) throw new SDLException("Failed to get glyph metrics.");
        return glyph;
    }

    /// Get the width of some UTF8 text if it were to be rendered.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_40.html
    auto textwidth(in string text) in{assert(this.font !is null);} body{
        if(text !is null){
            int width;
            auto result = TTF_SizeUTF8(this.font, text.tocstring, &width, null);
            if(result != 0) throw new SDLException("Failed to get text width.");
            return width;
        }else{
            return 0;
        }
    }
    /// Get the size of some UTF8 text if it were to be rendered.
    /// Height will always be the same as the font object's height property.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_40.html
    auto textsize(in string text) in{assert(this.font !is null);} body{
        if(text !is null){
            Vector2!int size;
            auto result = TTF_SizeUTF8(this.font, text.tocstring, &size.x, &size.y);
            if(result != 0) throw new SDLException("Failed to get text size.");
            return size;
        }else{
            return Vector2!int(0, this.height);
        }
    }
    
    /// Returns a surface with the given text cheaply drawn onto it.
    /// The background of the surface will be transparent.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_44.html
    auto rendertextsolid(C)(C foreground, in string text) if(isColor!C) in{
        assert(this.font !is null);
        assert(text !is null, "Can't render null string.");
    }body{
        auto surface = TTF_RenderUTF8_Solid(
            this.font, text.tocstring, cast(SDL_Color) foreground
        );
        if(surface is null) throw new SDLException("Failed to render text.");
        return Surface(surface);
    }
    /// Returns a surface with the given text drawn onto it.
    /// The background will be of the given color.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_48.html
    auto rendertextshaded(C0, C1)(C0 foreground, C1 background, in string text) if(
        isColor!C0 && isColor!C1
    )in{
        assert(this.font !is null);
        assert(text !is null, "Can't render null string.");
    }body{
        auto surface = TTF_RenderUTF8_Shaded(
            this.font, text.tocstring,
            cast(SDL_Color) foreground, cast(SDL_Color) background
        );
        if(surface is null) throw new SDLException("Failed to render text.");
        return Surface(surface);
    }
    /// Returns a surface with the given text expensively drawn onto it.
    /// The background of the surface will be transparent.
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_52.html
    auto rendertextblended(C)(C foreground, in string text) if(isColor!C) in{
        assert(this.font !is null);
        assert(text !is null, "Can't render null string.");
    }body{
        auto surface = TTF_RenderUTF8_Blended(
            this.font, text.tocstring, cast(SDL_Color) foreground
        );
        if(surface is null) throw new SDLException("Failed to render text.");
        return Surface(surface);
    }
    
    /// Returns a surface with the given text drawn onto it.
    /// The background of the surface will be transparent.
    auto surface(C)(C foreground, string text, RenderMode mode = RenderMode.Solid) if(isColor!C){
        final switch(mode){
            case RenderMode.Solid: return this.rendertextsolid(foreground, text);
            case RenderMode.Blended: return this.rendertextblended(foreground, text);
        }
    }
    
    /// Returns a texture with the given text drawn onto it.
    auto texture(C)(C foreground, string text, RenderMode mode = RenderMode.Solid) if(isColor!C){
        return Texture(this.surface(foreground, text, mode));
    }
}


