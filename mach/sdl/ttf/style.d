module mach.sdl.ttf.style;

private:

import derelict.sdl2.ttf;
import mach.sdl.flags;

public:



alias FontStyles = BitFlagAggregate!(int, FontStyle);

/// Possible styles for TTF fonts.
enum FontStyle: int{
    Normal = TTF_STYLE_NORMAL, None = Normal,
    Bold = TTF_STYLE_BOLD,
    Italic = TTF_STYLE_ITALIC,
    Underline = TTF_STYLE_UNDERLINE,
    Strike = TTF_STYLE_STRIKETHROUGH,
    All = Bold | Italic | Underline | Strike,
}
