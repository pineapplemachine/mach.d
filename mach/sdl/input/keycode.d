module mach.sdl.input.keycode;

private:

import derelict.sdl2.sdl;
import std.string : fromStringz;

public:



// Regarding the difference between SDL_Keycode and SDL_Scancode:
// http://stackoverflow.com/a/31941562/3478907
// In short, scancodes describe physical locations on the keyboard whereas
// keycodes describe keys as defined by the user's keyboard layout settings.



/// Get the keycode corresponding to some scancode.
KeyCode keycode(in ScanCode scancode){
    return cast(KeyCode) SDL_GetKeyFromScancode(cast(SDL_Scancode) scancode);
}
/// Get the scancode corresponding to some keycode.
ScanCode scancode(in KeyCode keycode){
    return cast(ScanCode) SDL_GetScancodeFromKey(cast(SDL_Keycode) keycode);
}

/// Get the name of a keycode. Names sometimes differ between platforms, names
/// are not always unique per code, and some codes have no names. (In which case
/// the function will return an empty string.)
string name(in KeyCode code){
    return code.transientname.dup;
}
/// Get the name of a scancode. Names sometimes differ between platforms, names
/// are not always unique per code, and some codes have no names. (In which case
/// the function will return an empty string.)
string name(in ScanCode code){
    return code.transientname.dup;
}

/// Get the name of a keycode.
/// Remains valid at least until the next call to SDL_GetKeyName.
string transientname(in KeyCode code){
    return cast(string) fromStringz(SDL_GetKeyName(cast(SDL_Keycode) code));
}
/// Get the name of a scancode.
/// Remains valid at least until the next call to SDL_GetScancodeName.
string transientname(in ScanCode code){
    return cast(string) fromStringz(SDL_GetScancodeName(cast(SDL_Scancode) code));
}



// I am conspicuously neglecting to include wrappers for SDL_GetScancodeFromName
// and SDL_GetKeyFromName because I think you'd have to be an idiot to use them.



// Reference: https://wiki.libsdl.org/SDL_Scancode
enum ScanCode: SDL_Scancode{
    Unknown = SDL_SCANCODE_UNKNOWN,
    Return = SDL_SCANCODE_RETURN, Enter = Return,
    Escape = SDL_SCANCODE_ESCAPE,
    Backspace = SDL_SCANCODE_BACKSPACE,
    Tab = SDL_SCANCODE_TAB,
    Space = SDL_SCANCODE_SPACE,
    Quote = SDL_SCANCODE_APOSTROPHE, Apostrophe = Quote,
    Comma = SDL_SCANCODE_COMMA,
    Minus = SDL_SCANCODE_MINUS,
    Period = SDL_SCANCODE_PERIOD, Dot = Period,
    Slash = SDL_SCANCODE_SLASH, ForwardSlash = Slash,
    Num0 = SDL_SCANCODE_0, Zero = Num0, /// Number 0
    Num1 = SDL_SCANCODE_1, One = Num1, /// Number 1
    Num2 = SDL_SCANCODE_2, Two = Num2, /// Number 2
    Num3 = SDL_SCANCODE_3, Three = Num3, /// Number 3
    Num4 = SDL_SCANCODE_4, Four = Num4, /// Number 4
    Num5 = SDL_SCANCODE_5, Five = Num5, /// Number 5
    Num6 = SDL_SCANCODE_6, Six = Num6, /// Number 6
    Num7 = SDL_SCANCODE_7, Seven = Num7, /// Number 7
    Num8 = SDL_SCANCODE_8, Eight = Num8, /// Number 8
    Num9 = SDL_SCANCODE_9, Nine = Num9, /// Number 9
    Semicolon = SDL_SCANCODE_SEMICOLON,
    Equals = SDL_SCANCODE_EQUALS,

    LeftBracket = SDL_SCANCODE_LEFTBRACKET, LBracket = LeftBracket,
    Backslash = SDL_SCANCODE_BACKSLASH, BackSlash = Backslash,
    RightBracket = SDL_SCANCODE_RIGHTBRACKET, RBracket = RightBracket,
    BackQuote = SDL_SCANCODE_GRAVE, Backtick = BackQuote, Grave = BackQuote,
    
    // Letters
    A = SDL_SCANCODE_A,
    B = SDL_SCANCODE_B,
    C = SDL_SCANCODE_C,
    D = SDL_SCANCODE_D,
    E = SDL_SCANCODE_E,
    F = SDL_SCANCODE_F,
    G = SDL_SCANCODE_G,
    H = SDL_SCANCODE_H,
    I = SDL_SCANCODE_I,
    J = SDL_SCANCODE_J,
    K = SDL_SCANCODE_K,
    L = SDL_SCANCODE_L,
    M = SDL_SCANCODE_M,
    N = SDL_SCANCODE_N,
    O = SDL_SCANCODE_O,
    P = SDL_SCANCODE_P,
    Q = SDL_SCANCODE_Q,
    R = SDL_SCANCODE_R,
    S = SDL_SCANCODE_S,
    T = SDL_SCANCODE_T,
    U = SDL_SCANCODE_U,
    V = SDL_SCANCODE_V,
    W = SDL_SCANCODE_W,
    X = SDL_SCANCODE_X,
    Y = SDL_SCANCODE_Y,
    Z = SDL_SCANCODE_Z,
    
    // Modifier keys
    LeftCtrl = SDL_SCANCODE_LCTRL, LCtrl = LeftCtrl,
    RightCtrl = SDL_SCANCODE_RCTRL, RCtrl = RightCtrl,
    LeftShift = SDL_SCANCODE_LSHIFT, LShift = LeftShift,
    RightShift = SDL_SCANCODE_RSHIFT, RShift = RightShift,
    LeftAlt = SDL_SCANCODE_LALT, LAlt = LeftAlt,
    RightAlt = SDL_SCANCODE_RALT, RAlt = RightAlt,
    LeftGui = SDL_SCANCODE_LGUI, LGui = LeftGui, // Depending on OS: Windows key, Cmd key, Meta key
    RightGui = SDL_SCANCODE_RGUI, RGui = RightGui, // Depending on OS: Windows key, Cmd key, Meta key
    
    // Function keys
    F1 = SDL_SCANCODE_F1,
    F2 = SDL_SCANCODE_F2,
    F3 = SDL_SCANCODE_F3,
    F4 = SDL_SCANCODE_F4,
    F5 = SDL_SCANCODE_F5,
    F6 = SDL_SCANCODE_F6,
    F7 = SDL_SCANCODE_F7,
    F8 = SDL_SCANCODE_F8,
    F9 = SDL_SCANCODE_F9,
    F10 = SDL_SCANCODE_F10,
    F11 = SDL_SCANCODE_F11,
    F12 = SDL_SCANCODE_F12,
    // Extended function keys
    F13 = SDL_SCANCODE_F13,
    F14 = SDL_SCANCODE_F14,
    F15 = SDL_SCANCODE_F15,
    F16 = SDL_SCANCODE_F16,
    F17 = SDL_SCANCODE_F17,
    F18 = SDL_SCANCODE_F18,
    F19 = SDL_SCANCODE_F19,
    F20 = SDL_SCANCODE_F20,
    F21 = SDL_SCANCODE_F21,
    F22 = SDL_SCANCODE_F22,
    F23 = SDL_SCANCODE_F23,
    F24 = SDL_SCANCODE_F24,
    
    CapsLock = SDL_SCANCODE_CAPSLOCK,
    
    // That bay of nine keys toward the right side of my keyboard
    PrintScreen = SDL_SCANCODE_PRINTSCREEN,
    ScrollLock = SDL_SCANCODE_SCROLLLOCK,
    Pause = SDL_SCANCODE_PAUSE,
    Insert = SDL_SCANCODE_INSERT,
    Delete = SDL_SCANCODE_DELETE,
    Home = SDL_SCANCODE_HOME,
    End = SDL_SCANCODE_END,
    PageUp = SDL_SCANCODE_PAGEUP,
    PageDown = SDL_SCANCODE_PAGEDOWN,
    
    // Arrows
    Right = SDL_SCANCODE_RIGHT, RightArrow = Right,
    Left = SDL_SCANCODE_LEFT, LeftArrow = Left,
    Down = SDL_SCANCODE_DOWN, DownArrow = Down,
    Up = SDL_SCANCODE_UP, UpArrow = Up,
    
    // Keypad
    NumLockClear = SDL_SCANCODE_NUMLOCKCLEAR, NumLock = NumLockClear,
    KPDivide = SDL_SCANCODE_KP_DIVIDE, KPSlash = KPDivide,
    KPMultiply = SDL_SCANCODE_KP_MULTIPLY, KPAsterisk = KPMultiply, KPStar = KPMultiply,
    KPMinus = SDL_SCANCODE_KP_MINUS,
    KPPlus = SDL_SCANCODE_KP_PLUS,
    KPEnter = SDL_SCANCODE_KP_ENTER,
    KPPeriod = SDL_SCANCODE_KP_PERIOD, KPDot = KPPeriod,
    KP0 = SDL_SCANCODE_KP_0, /// Keypad 0
    KP1 = SDL_SCANCODE_KP_1, /// Keypad 1
    KP2 = SDL_SCANCODE_KP_2, /// Keypad 2
    KP3 = SDL_SCANCODE_KP_3, /// Keypad 3
    KP4 = SDL_SCANCODE_KP_4, /// Keypad 4
    KP5 = SDL_SCANCODE_KP_5, /// Keypad 5
    KP6 = SDL_SCANCODE_KP_6, /// Keypad 6
    KP7 = SDL_SCANCODE_KP_7, /// Keypad 7
    KP8 = SDL_SCANCODE_KP_8, /// Keypad 8
    KP9 = SDL_SCANCODE_KP_9, /// Keypad 9
    // Extended keypad
    KPComma = SDL_SCANCODE_KP_COMMA,
    KPEquals = SDL_SCANCODE_KP_EQUALS,
    KPEqualsAS400 = SDL_SCANCODE_KP_EQUALSAS400,
    KP00 = SDL_SCANCODE_KP_00,
    KP000 = SDL_SCANCODE_KP_000,
    KPLeftparen = SDL_SCANCODE_KP_LEFTPAREN,
    KPRightparen = SDL_SCANCODE_KP_RIGHTPAREN,
    KPLeftbrace = SDL_SCANCODE_KP_LEFTBRACE,
    KPRightbrace = SDL_SCANCODE_KP_RIGHTBRACE,
    KPTab = SDL_SCANCODE_KP_TAB,
    KPBackspace = SDL_SCANCODE_KP_BACKSPACE,
    KPA = SDL_SCANCODE_KP_A,
    KPB = SDL_SCANCODE_KP_B,
    KPC = SDL_SCANCODE_KP_C,
    KPD = SDL_SCANCODE_KP_D,
    KPE = SDL_SCANCODE_KP_E,
    KPF = SDL_SCANCODE_KP_F,
    KPXor = SDL_SCANCODE_KP_XOR,
    KPPower = SDL_SCANCODE_KP_POWER,
    KPPercent = SDL_SCANCODE_KP_PERCENT,
    KPLess = SDL_SCANCODE_KP_LESS, KPLesser = KPLess,
    KPGreater = SDL_SCANCODE_KP_GREATER,
    KPAmpersand = SDL_SCANCODE_KP_AMPERSAND,
    KPDoubleAmpersand = SDL_SCANCODE_KP_DBLAMPERSAND,
    KPVerticalBar = SDL_SCANCODE_KP_VERTICALBAR,
    KPDoubleVerticalBar = SDL_SCANCODE_KP_DBLVERTICALBAR,
    KPColon = SDL_SCANCODE_KP_COLON,
    KPHash = SDL_SCANCODE_KP_HASH,
    KPSpace = SDL_SCANCODE_KP_SPACE,
    KPAt = SDL_SCANCODE_KP_AT,
    KPExclam = SDL_SCANCODE_KP_EXCLAM, KPExclaim = KPExclam,
    KPMemStore = SDL_SCANCODE_KP_MEMSTORE,
    KPMemRecall = SDL_SCANCODE_KP_MEMRECALL,
    KPMemClear = SDL_SCANCODE_KP_MEMCLEAR,
    KPMemAdd = SDL_SCANCODE_KP_MEMADD,
    KPMemSubtract = SDL_SCANCODE_KP_MEMSUBTRACT,
    KPMemMultiply = SDL_SCANCODE_KP_MEMMULTIPLY,
    KPMemDivide = SDL_SCANCODE_KP_MEMDIVIDE,
    KPPlusMinus = SDL_SCANCODE_KP_PLUSMINUS,
    KPClear = SDL_SCANCODE_KP_CLEAR,
    KPClearEntry = SDL_SCANCODE_KP_CLEARENTRY,
    KPBinary = SDL_SCANCODE_KP_BINARY,
    KPOctal = SDL_SCANCODE_KP_OCTAL,
    KPDecimal = SDL_SCANCODE_KP_DECIMAL,
    KPHexadecimal = SDL_SCANCODE_KP_HEXADECIMAL,
    
    Application = SDL_SCANCODE_APPLICATION,
    Power = SDL_SCANCODE_POWER, // May actually be a status flag
    
    Execute = SDL_SCANCODE_EXECUTE,
    Help = SDL_SCANCODE_HELP,
    Menu = SDL_SCANCODE_MENU,
    Select = SDL_SCANCODE_SELECT,
    Stop = SDL_SCANCODE_STOP,
    Again = SDL_SCANCODE_AGAIN,
    Undo = SDL_SCANCODE_UNDO,
    Cut = SDL_SCANCODE_CUT,
    Copy = SDL_SCANCODE_COPY,
    Paste = SDL_SCANCODE_PASTE,
    Find = SDL_SCANCODE_FIND,
    Mute = SDL_SCANCODE_MUTE,
    VolumeUp = SDL_SCANCODE_VOLUMEUP,
    VolumeDown = SDL_SCANCODE_VOLUMEDOWN,

    AltErase = SDL_SCANCODE_ALTERASE,
    SysRq = SDL_SCANCODE_SYSREQ,
    Cancel = SDL_SCANCODE_CANCEL,
    Clear = SDL_SCANCODE_CLEAR,
    Prior = SDL_SCANCODE_PRIOR,
    Return2 = SDL_SCANCODE_RETURN2,
    Separator = SDL_SCANCODE_SEPARATOR,
    Out = SDL_SCANCODE_OUT,
    Oper = SDL_SCANCODE_OPER,
    ClearAgain = SDL_SCANCODE_CLEARAGAIN,
    CrSel = SDL_SCANCODE_CRSEL,
    ExSel = SDL_SCANCODE_EXSEL,

    ThousandsSeparator = SDL_SCANCODE_THOUSANDSSEPARATOR,
    DecimalSeparator = SDL_SCANCODE_DECIMALSEPARATOR,
    CurrencyUnit = SDL_SCANCODE_CURRENCYUNIT,
    CurrencySubUnit = SDL_SCANCODE_CURRENCYSUBUNIT,
    
    Mode = SDL_SCANCODE_MODE,

    AudioNext = SDL_SCANCODE_AUDIONEXT,
    AudioPrev = SDL_SCANCODE_AUDIOPREV,
    AudioStop = SDL_SCANCODE_AUDIOSTOP,
    AudioPlay = SDL_SCANCODE_AUDIOPLAY,
    AudioMute = SDL_SCANCODE_AUDIOMUTE,
    MediaSelect = SDL_SCANCODE_MEDIASELECT,
    WWW = SDL_SCANCODE_WWW,
    Mail = SDL_SCANCODE_MAIL,
    Calculator = SDL_SCANCODE_CALCULATOR,
    Computer = SDL_SCANCODE_COMPUTER,
    
    // Application control keypad
    ACSearch = SDL_SCANCODE_AC_SEARCH,
    ACHome = SDL_SCANCODE_AC_HOME,
    ACBack = SDL_SCANCODE_AC_BACK,
    ACForward = SDL_SCANCODE_AC_FORWARD,
    ACStop = SDL_SCANCODE_AC_STOP,
    ACRefresh = SDL_SCANCODE_AC_REFRESH,
    ACBookmarks = SDL_SCANCODE_AC_BOOKMARKS,

    BrightnessDown = SDL_SCANCODE_BRIGHTNESSDOWN,
    BrightnessUp = SDL_SCANCODE_BRIGHTNESSUP,
    DisplaySwitch = SDL_SCANCODE_DISPLAYSWITCH,
    
    Eject = SDL_SCANCODE_EJECT,
    Sleep = SDL_SCANCODE_SLEEP,
    
    // Keyboard illumination
    KIUp = SDL_SCANCODE_KBDILLUMUP,
    KIDown = SDL_SCANCODE_KBDILLUMDOWN,
    KIToggle = SDL_SCANCODE_KBDILLUMTOGGLE,
}



// Reference: https://wiki.libsdl.org/SDL_Scancode
enum KeyCode: SDL_Keycode{
    Unknown = SDLK_UNKNOWN,
    Return = SDLK_RETURN, Enter = Return,
    Escape = SDLK_ESCAPE,
    Backspace = SDLK_BACKSPACE,
    Tab = SDLK_TAB,
    Space = SDLK_SPACE,
    Exclaim = SDLK_EXCLAIM, Exclamation = Exclaim, ExclamationMark = Exclaim, Bang = Exclaim,
    DoubleQuote = SDLK_QUOTEDBL,
    Hash = SDLK_HASH, Pound = Hash, Octothorpe = Hash,
    Percent = SDLK_PERCENT,
    Dollar = SDLK_DOLLAR,
    Ampersand = SDLK_AMPERSAND,
    Quote = SDLK_QUOTE, Apostrophe = Quote,
    LeftParen = SDLK_LEFTPAREN, LParen = LeftParen,
    RightParen = SDLK_RIGHTPAREN, RParen = RightParen,
    Asterisk = SDLK_ASTERISK, Star = Asterisk,
    Plus = SDLK_PLUS,
    Comma = SDLK_COMMA,
    Minus = SDLK_MINUS,
    Period = SDLK_PERIOD, Dot = Period,
    Slash = SDLK_SLASH, ForwardSlash = Slash,
    Num0 = SDLK_0, Zero = Num0, /// Number 0
    Num1 = SDLK_1, One = Num1, /// Number 1
    Num2 = SDLK_2, Two = Num2, /// Number 2
    Num3 = SDLK_3, Three = Num3, /// Number 3
    Num4 = SDLK_4, Four = Num4, /// Number 4
    Num5 = SDLK_5, Five = Num5, /// Number 5
    Num6 = SDLK_6, Six = Num6, /// Number 6
    Num7 = SDLK_7, Seven = Num7, /// Number 7
    Num8 = SDLK_8, Eight = Num8, /// Number 8
    Num9 = SDLK_9, Nine = Num9, /// Number 9
    Colon = SDLK_COLON,
    Semicolon = SDLK_SEMICOLON,
    Less = SDLK_LESS, Lesser = Less, LessThan = Less, LeftAngle = Less, LAngle = Less,
    Equals = SDLK_EQUALS,
    Greater = SDLK_GREATER, GreaterThan = Greater, RightAngle = Greater, RAngle = Greater,
    Question = SDLK_QUESTION, QuestionMark = Question,
    At = SDLK_AT,

    LeftBracket = SDLK_LEFTBRACKET, LBracket = LeftBracket,
    Backslash = SDLK_BACKSLASH, BackSlash = Backslash,
    RightBracket = SDLK_RIGHTBRACKET, RBracket = RightBracket,
    Caret = SDLK_CARET,
    Underscore = SDLK_UNDERSCORE,
    BackQuote = SDLK_BACKQUOTE, Backtick = BackQuote, Grave = BackQuote,
    
    // Letters
    A = SDLK_a,
    B = SDLK_b,
    C = SDLK_c,
    D = SDLK_d,
    E = SDLK_e,
    F = SDLK_f,
    G = SDLK_g,
    H = SDLK_h,
    I = SDLK_i,
    J = SDLK_j,
    K = SDLK_k,
    L = SDLK_l,
    M = SDLK_m,
    N = SDLK_n,
    O = SDLK_o,
    P = SDLK_p,
    Q = SDLK_q,
    R = SDLK_r,
    S = SDLK_s,
    T = SDLK_t,
    U = SDLK_u,
    V = SDLK_v,
    W = SDLK_w,
    X = SDLK_x,
    Y = SDLK_y,
    Z = SDLK_z,
    
    // Modifier keys
    LeftCtrl = SDLK_LCTRL, LCtrl = LeftCtrl,
    RightCtrl = SDLK_RCTRL, RCtrl = RightCtrl,
    LeftShift = SDLK_LSHIFT, LShift = LeftShift,
    RightShift = SDLK_RSHIFT, RShift = RightShift,
    LeftAlt = SDLK_LALT, LAlt = LeftAlt,
    RightAlt = SDLK_RALT, RAlt = RightAlt,
    LeftGui = SDLK_LGUI, LGui = LeftGui, // Depending on OS: Windows key, Cmd key, Meta key
    RightGui = SDLK_RGUI, RGui = RightGui, // Depending on OS: Windows key, Cmd key, Meta key
    
    // Function keys
    F1 = SDLK_F1,
    F2 = SDLK_F2,
    F3 = SDLK_F3,
    F4 = SDLK_F4,
    F5 = SDLK_F5,
    F6 = SDLK_F6,
    F7 = SDLK_F7,
    F8 = SDLK_F8,
    F9 = SDLK_F9,
    F10 = SDLK_F10,
    F11 = SDLK_F11,
    F12 = SDLK_F12,
    // Extended function keys
    F13 = SDLK_F13,
    F14 = SDLK_F14,
    F15 = SDLK_F15,
    F16 = SDLK_F16,
    F17 = SDLK_F17,
    F18 = SDLK_F18,
    F19 = SDLK_F19,
    F20 = SDLK_F20,
    F21 = SDLK_F21,
    F22 = SDLK_F22,
    F23 = SDLK_F23,
    F24 = SDLK_F24,
    
    CapsLock = SDLK_CAPSLOCK,
    
    // That bay of nine keys toward the right side of my keyboard
    PrintScreen = SDLK_PRINTSCREEN,
    ScrollLock = SDLK_SCROLLLOCK,
    Pause = SDLK_PAUSE,
    Insert = SDLK_INSERT,
    Delete = SDLK_DELETE,
    Home = SDLK_HOME,
    End = SDLK_END,
    PageUp = SDLK_PAGEUP,
    PageDown = SDLK_PAGEDOWN,
    
    // Arrows
    Right = SDLK_RIGHT, RightArrow = Right,
    Left = SDLK_LEFT, LeftArrow = Left,
    Down = SDLK_DOWN, DownArrow = Down,
    Up = SDLK_UP, UpArrow = Up,
    
    // Keypad
    NumLockClear = SDLK_NUMLOCKCLEAR, NumLock = NumLockClear,
    KPDivide = SDLK_KP_DIVIDE, KPSlash = KPDivide,
    KPMultiply = SDLK_KP_MULTIPLY, KPAsterisk = KPMultiply, KPStar = KPMultiply,
    KPMinus = SDLK_KP_MINUS,
    KPPlus = SDLK_KP_PLUS,
    KPEnter = SDLK_KP_ENTER,
    KPPeriod = SDLK_KP_PERIOD, KPDot = KPPeriod,
    KP0 = SDLK_KP_0, /// Keypad 0
    KP1 = SDLK_KP_1, /// Keypad 1
    KP2 = SDLK_KP_2, /// Keypad 2
    KP3 = SDLK_KP_3, /// Keypad 3
    KP4 = SDLK_KP_4, /// Keypad 4
    KP5 = SDLK_KP_5, /// Keypad 5
    KP6 = SDLK_KP_6, /// Keypad 6
    KP7 = SDLK_KP_7, /// Keypad 7
    KP8 = SDLK_KP_8, /// Keypad 8
    KP9 = SDLK_KP_9, /// Keypad 9
    // Extended keypad
    KPComma = SDLK_KP_COMMA,
    KPEquals = SDLK_KP_EQUALS,
    KPEqualsAS400 = SDLK_KP_EQUALSAS400,
    KP00 = SDLK_KP_00,
    KP000 = SDLK_KP_000,
    KPLeftparen = SDLK_KP_LEFTPAREN,
    KPRightparen = SDLK_KP_RIGHTPAREN,
    KPLeftbrace = SDLK_KP_LEFTBRACE,
    KPRightbrace = SDLK_KP_RIGHTBRACE,
    KPTab = SDLK_KP_TAB,
    KPBackspace = SDLK_KP_BACKSPACE,
    KPA = SDLK_KP_A,
    KPB = SDLK_KP_B,
    KPC = SDLK_KP_C,
    KPD = SDLK_KP_D,
    KPE = SDLK_KP_E,
    KPF = SDLK_KP_F,
    KPXor = SDLK_KP_XOR,
    KPPower = SDLK_KP_POWER,
    KPPercent = SDLK_KP_PERCENT,
    KPLess = SDLK_KP_LESS, KPLesser = KPLess,
    KPGreater = SDLK_KP_GREATER,
    KPAmpersand = SDLK_KP_AMPERSAND,
    KPDoubleAmpersand = SDLK_KP_DBLAMPERSAND,
    KPVerticalBar = SDLK_KP_VERTICALBAR,
    KPDoubleVerticalBar = SDLK_KP_DBLVERTICALBAR,
    KPColon = SDLK_KP_COLON,
    KPHash = SDLK_KP_HASH,
    KPSpace = SDLK_KP_SPACE,
    KPAt = SDLK_KP_AT,
    KPExclam = SDLK_KP_EXCLAM, KPExclaim = KPExclam,
    KPMemStore = SDLK_KP_MEMSTORE,
    KPMemRecall = SDLK_KP_MEMRECALL,
    KPMemClear = SDLK_KP_MEMCLEAR,
    KPMemAdd = SDLK_KP_MEMADD,
    KPMemSubtract = SDLK_KP_MEMSUBTRACT,
    KPMemMultiply = SDLK_KP_MEMMULTIPLY,
    KPMemDivide = SDLK_KP_MEMDIVIDE,
    KPPlusMinus = SDLK_KP_PLUSMINUS,
    KPClear = SDLK_KP_CLEAR,
    KPClearEntry = SDLK_KP_CLEARENTRY,
    KPBinary = SDLK_KP_BINARY,
    KPOctal = SDLK_KP_OCTAL,
    KPDecimal = SDLK_KP_DECIMAL,
    KPHexadecimal = SDLK_KP_HEXADECIMAL,
    
    Application = SDLK_APPLICATION,
    Power = SDLK_POWER, // May actually be a status flag
    
    Execute = SDLK_EXECUTE,
    Help = SDLK_HELP,
    Menu = SDLK_MENU,
    Select = SDLK_SELECT,
    Stop = SDLK_STOP,
    Again = SDLK_AGAIN,
    Undo = SDLK_UNDO,
    Cut = SDLK_CUT,
    Copy = SDLK_COPY,
    Paste = SDLK_PASTE,
    Find = SDLK_FIND,
    Mute = SDLK_MUTE,
    VolumeUp = SDLK_VOLUMEUP,
    VolumeDown = SDLK_VOLUMEDOWN,

    AltErase = SDLK_ALTERASE,
    SysRq = SDLK_SYSREQ,
    Cancel = SDLK_CANCEL,
    Clear = SDLK_CLEAR,
    Prior = SDLK_PRIOR,
    Return2 = SDLK_RETURN2,
    Separator = SDLK_SEPARATOR,
    Out = SDLK_OUT,
    Oper = SDLK_OPER,
    ClearAgain = SDLK_CLEARAGAIN,
    CrSel = SDLK_CRSEL,
    ExSel = SDLK_EXSEL,

    ThousandsSeparator = SDLK_THOUSANDSSEPARATOR,
    DecimalSeparator = SDLK_DECIMALSEPARATOR,
    CurrencyUnit = SDLK_CURRENCYUNIT,
    CurrencySubUnit = SDLK_CURRENCYSUBUNIT,
    
    Mode = SDLK_MODE,

    AudioNext = SDLK_AUDIONEXT,
    AudioPrev = SDLK_AUDIOPREV,
    AudioStop = SDLK_AUDIOSTOP,
    AudioPlay = SDLK_AUDIOPLAY,
    AudioMute = SDLK_AUDIOMUTE,
    MediaSelect = SDLK_MEDIASELECT,
    WWW = SDLK_WWW,
    Mail = SDLK_MAIL,
    Calculator = SDLK_CALCULATOR,
    Computer = SDLK_COMPUTER,
    
    // Application control keypad
    ACSearch = SDLK_AC_SEARCH,
    ACHome = SDLK_AC_HOME,
    ACBack = SDLK_AC_BACK,
    ACForward = SDLK_AC_FORWARD,
    ACStop = SDLK_AC_STOP,
    ACRefresh = SDLK_AC_REFRESH,
    ACBookmarks = SDLK_AC_BOOKMARKS,

    BrightnessDown = SDLK_BRIGHTNESSDOWN,
    BrightnessUp = SDLK_BRIGHTNESSUP,
    DisplaySwitch = SDLK_DISPLAYSWITCH,
    
    Eject = SDLK_EJECT,
    Sleep = SDLK_SLEEP,
    
    // Keyboard illumination
    KIUp = SDLK_KBDILLUMUP,
    KIDown = SDLK_KBDILLUMDOWN,
    KIToggle = SDLK_KBDILLUMTOGGLE,
}
