module mach.sdl.glenum;

private:

//import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import mach.traits : isFloatingPoint;

public:
    
alias glenum = uint;

// https://www.opengl.org/sdk/docs/man/html/glReadPixels.xhtml
// https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml
enum PixelsFormat : glenum {
    Red = GL_RED,
    RG = GL_RG,
    Green = GL_GREEN,
    Blue = GL_BLUE,
    RGB = GL_RGB,
    BGR = GL_BGR,
    RGBA = GL_RGBA,
    BGRA = GL_BGRA,
    RedInteger = GL_RED_INTEGER,
    RGInteger = GL_RG_INTEGER,
    RGBInteger = GL_RGB_INTEGER,
    BGRInteger = GL_BGR_INTEGER,
    RGBAInteger = GL_RGBA_INTEGER,
    BGRAInteger = GL_BGRA_INTEGER,
    StencilIndex = GL_STENCIL_INDEX,
    DepthComponent = GL_DEPTH_COMPONENT,
    DepthStencil = GL_DEPTH_STENCIL,
}

// https://www.opengl.org/sdk/docs/man/html/glReadPixels.xhtml
// https://www.khronos.org/opengles/sdk/docs/man/xhtml/glReadPixels.xml
enum PixelsType : glenum {
    Ubyte = GL_UNSIGNED_BYTE,
    Byte = GL_BYTE,
    Ushort= GL_UNSIGNED_SHORT,
    Short = GL_SHORT,
    Uint = GL_UNSIGNED_INT,
    Int = GL_INT,
    HalfFloat = GL_HALF_FLOAT,
    Float = GL_FLOAT,
    Ubyte332 = GL_UNSIGNED_BYTE_3_3_2,
    Byte233 = GL_UNSIGNED_BYTE_2_3_3_REV,
    Ushort565 = GL_UNSIGNED_SHORT_5_6_5,
    Ushort565rev = GL_UNSIGNED_SHORT_5_6_5_REV,
    Ushort4444 = GL_UNSIGNED_SHORT_4_4_4_4,
    Ushort444rev = GL_UNSIGNED_SHORT_4_4_4_4_REV,
    Ushort5551 = GL_UNSIGNED_SHORT_5_5_5_1,
    Ushort5551ref = GL_UNSIGNED_SHORT_1_5_5_5_REV,
    Uint8888 = GL_UNSIGNED_INT_8_8_8_8,
    Uint8888rev = GL_UNSIGNED_INT_8_8_8_8_REV,
    Uint1010102 = GL_UNSIGNED_INT_10_10_10_2,
    Uint1010102rev = GL_UNSIGNED_INT_2_10_10_10_REV,
    Uint248 = GL_UNSIGNED_INT_24_8,
    Uint101111rev = GL_UNSIGNED_INT_10F_11F_11F_REV,
    Uint5999rev = GL_UNSIGNED_INT_5_9_9_9_REV,
    Uint248rev = GL_FLOAT_32_UNSIGNED_INT_24_8_REV,
}

// https://www.opengl.org/sdk/docs/man2/xhtml/glVertexPointer.xml
enum VertexType : glenum {
    Short = GL_SHORT,
    Int = GL_INT,
    Float = GL_FLOAT,
    Double = GL_DOUBLE
}
VertexType getvertextype(Type)(){
    static if(is(Type == short)) return VertexType.Short;
    static if(is(Type == int)) return VertexType.Int;
    static if(is(Type == float)) return VertexType.Float;
    static if(is(Type == double)) return VertexType.Double;
    else assert(false, "Unrecognized vertex type.");
}
enum bool validvertextype(Type) = (
    is(Type == short) || is(Type == int) ||
    is(Type == float) || is(Type == double)
);

// https://www.opengl.org/sdk/docs/man/html/glReadBuffer.xhtml
enum ColorBufferMode : glenum {
    FrontLeft = GL_FRONT_LEFT, 
    FrontRight = GL_FRONT_RIGHT, 
    BackLeft = GL_BACK_LEFT, 
    BackRight = GL_BACK_RIGHT, 
    Front = GL_FRONT, 
    Back = GL_BACK, 
    Left = GL_LEFT, 
    Right = GL_RIGHT,
    ColorAttachment00 = GL_COLOR_ATTACHMENT0,
    ColorAttachment01 = GL_COLOR_ATTACHMENT1,
    ColorAttachment02 = GL_COLOR_ATTACHMENT2,
    ColorAttachment03 = GL_COLOR_ATTACHMENT3,
    ColorAttachment04 = GL_COLOR_ATTACHMENT4,
    ColorAttachment05 = GL_COLOR_ATTACHMENT5,
    ColorAttachment06 = GL_COLOR_ATTACHMENT6,
    ColorAttachment07 = GL_COLOR_ATTACHMENT7,
    ColorAttachment08 = GL_COLOR_ATTACHMENT8,
    ColorAttachment09 = GL_COLOR_ATTACHMENT9,
    ColorAttachment10 = GL_COLOR_ATTACHMENT10,
    ColorAttachment11 = GL_COLOR_ATTACHMENT11,
    ColorAttachment12 = GL_COLOR_ATTACHMENT12,
    ColorAttachment13 = GL_COLOR_ATTACHMENT13,
    ColorAttachment14 = GL_COLOR_ATTACHMENT14,
    ColorAttachment15 = GL_COLOR_ATTACHMENT15,
}

static immutable glenum[16] ColorAttachment = [
    ColorBufferMode.ColorAttachment00,
    ColorBufferMode.ColorAttachment01,
    ColorBufferMode.ColorAttachment02,
    ColorBufferMode.ColorAttachment03,
    ColorBufferMode.ColorAttachment04,
    ColorBufferMode.ColorAttachment05,
    ColorBufferMode.ColorAttachment06,
    ColorBufferMode.ColorAttachment07,
    ColorBufferMode.ColorAttachment08,
    ColorBufferMode.ColorAttachment09,
    ColorBufferMode.ColorAttachment10,
    ColorBufferMode.ColorAttachment11,
    ColorBufferMode.ColorAttachment12,
    ColorBufferMode.ColorAttachment13,
    ColorBufferMode.ColorAttachment14,
    ColorBufferMode.ColorAttachment15,
];

// https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml
enum TextureTarget : glenum {
    Texture2D = GL_TEXTURE_2D,
    ProxyTexture2D = GL_PROXY_TEXTURE_2D,
    Texture1D = GL_TEXTURE_1D_ARRAY,
    ProxyTexture1D = GL_PROXY_TEXTURE_1D_ARRAY,
    TextureRect = GL_TEXTURE_RECTANGLE,
    ProxyTextureRect = GL_PROXY_TEXTURE_RECTANGLE,
    CubemapPosX = GL_TEXTURE_CUBE_MAP_POSITIVE_X,
    CubemapNegX = GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
    CubemapPosY = GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
    CubemapNegY = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
    CubemapPosZ = GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
    CubemapNegZ = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
}

// https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml
enum InternalFormat : glenum {
    DepthComponent = GL_DEPTH_COMPONENT,
    DepthStencil = GL_DEPTH_STENCIL,
    Red = GL_RED,
    RG = GL_RG,
    RGB = GL_RGB,
    RGBA = GL_RGBA,
    R8 = GL_R8,
    R8SNorm = GL_R8_SNORM,
    R16 = GL_R16,
    R16SNorm = GL_R16_SNORM,
    RG8 = GL_RG8,
    RG8_SNORM = GL_RG8_SNORM,
    RG16 = GL_RG16,
    RG16SNorm = GL_RG16_SNORM,
    R3_G3_B2 = GL_R3_G3_B2,
    RGB4 = GL_RGB4,
    RGB5 = GL_RGB5,
    RGB8 = GL_RGB8,
    RGB8SNorm = GL_RGB8_SNORM,
    RGB10 = GL_RGB10,
    RGB12 = GL_RGB12,
    RGB16SNorm = GL_RGB16_SNORM,
    RGBA2 = GL_RGBA2,
    RGBA4 = GL_RGBA4,
    RGB5_A1 = GL_RGB5_A1,
    RGBA8 = GL_RGBA8,
    RGBA8SNorm = GL_RGBA8_SNORM,
    RGB10A2 = GL_RGB10_A2,
    RGB10A2UI = GL_RGB10_A2UI,
    RGBA12 = GL_RGBA12,
    RGBA16 = GL_RGBA16,
    SRGB8 = GL_SRGB8,
    SRGBA8 = GL_SRGB8_ALPHA8,
    R16F = GL_R16F,
    RG16F = GL_RG16F,
    RGB16F = GL_RGB16F,
    RGBA16F = GL_RGBA16F,
    R32F = GL_R32F,
    RG32F = GL_RG32F,
    RGB32F = GL_RGB32F,
    RGBA32F = GL_RGBA32F,
    R11FG11FB10F = GL_R11F_G11F_B10F,
    RGB9E5 = GL_RGB9_E5,
    R8I = GL_R8I,
    R8UI = GL_R8UI,
    R16I = GL_R16I,
    R16UI = GL_R16UI,
    R32I = GL_R32I,
    R32UI = GL_R32UI,
    RG8I = GL_RG8I,
    RG8UI = GL_RG8UI,
    RG16I = GL_RG16I,
    RG16UI = GL_RG16UI,
    RG32I = GL_RG32I,
    RG32UI = GL_RG32UI,
    RGB8I = GL_RGB8I,
    RGB8UI = GL_RGB8UI,
    RGB16I = GL_RGB16I,
    RGB16UI = GL_RGB16UI,
    RGB32I = GL_RGB32I,
    RGB32UI = GL_RGB32UI,
    RGBA8I = GL_RGBA8I,
    RGBA8UI = GL_RGBA8UI,
    RGBA16I = GL_RGBA16I,
    RGBA16UI = GL_RGBA16UI,
    RGBA32I = GL_RGBA32I,
    RGBA32UI = GL_RGBA32UI,
    CompressedRed = GL_COMPRESSED_RED,
    CompressedRG = GL_COMPRESSED_RG,
    CompressedRGB = GL_COMPRESSED_RGB,
    CompressedRGBA = GL_COMPRESSED_RGBA,
    CompressedSRGB = GL_COMPRESSED_SRGB,
    CompressedSRGBA = GL_COMPRESSED_SRGB_ALPHA,
    CompressedRedRGTC1 = GL_COMPRESSED_RED_RGTC1,
    CompressedSignedRedRGTC1 = GL_COMPRESSED_SIGNED_RED_RGTC1,
    CompressedRGRGTC2 = GL_COMPRESSED_RG_RGTC2,
    CompressedRGRedRGTC1 = GL_COMPRESSED_SIGNED_RG_RGTC2,
}

// https://www.opengl.org/sdk/docs/man/html/glTexParameter.xhtml
enum TextureMagFilter : glenum {
    Nearest = GL_NEAREST,
    Linear = GL_LINEAR,
}
enum TextureMinFilter : glenum {
    Nearest = GL_NEAREST,
    Linear = GL_LINEAR,
    NearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
    LinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
    NearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
    LinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR,
}
alias TextureFilter = TextureMagFilter;

/// Enumeration of meaningful texture wrapping modes.
/// https://open.gl/textures
/// https://www.khronos.org/opengl/wiki/GLAPI/glSamplerParameter
enum TextureWrap : glenum {
    ClampEdge = GL_CLAMP_TO_EDGE,
    ClampBorder = GL_CLAMP_TO_BORDER,
    Repeat = GL_REPEAT,
    MirrorRepeat = GL_MIRRORED_REPEAT,
    MirrorClampEdge = GL_MIRROR_CLAMP_TO_EDGE,
}

// https://www.opengl.org/sdk/docs/man/html/glTexParameter.xhtml
enum TextureParam : glenum {
    DepthStencilMode = GL_DEPTH_STENCIL_TEXTURE_MODE,
    BaseLevel = GL_TEXTURE_BASE_LEVEL,
    CompareFunc = GL_TEXTURE_COMPARE_FUNC,
    CompareMode = GL_TEXTURE_COMPARE_MODE,
    LODBias = GL_TEXTURE_LOD_BIAS,
    MinFilter = GL_TEXTURE_MIN_FILTER,
    MagFilter = GL_TEXTURE_MAG_FILTER,
    MinLOD = GL_TEXTURE_MIN_LOD,
    MaxLOD = GL_TEXTURE_MAX_LOD,
    MaxLevel = GL_TEXTURE_MAX_LEVEL,
    SwizzleRed = GL_TEXTURE_SWIZZLE_R,
    SwizzleGreen = GL_TEXTURE_SWIZZLE_G,
    SwizzleBlue = GL_TEXTURE_SWIZZLE_B,
    SwizzleAlpha = GL_TEXTURE_SWIZZLE_A,
    WrapS = GL_TEXTURE_WRAP_S,
    WrapT = GL_TEXTURE_WRAP_T,
    WrapR = GL_TEXTURE_WRAP_R,
    BorderColor = GL_TEXTURE_BORDER_COLOR,
    SwizzleRGBA = GL_TEXTURE_SWIZZLE_RGBA,
}

enum Param : glenum {
    ActiveTexture = GL_ACTIVE_TEXTURE,
    AliasedLineWidthRange = GL_ALIASED_LINE_WIDTH_RANGE,
    ArrayBufferBinding = GL_ARRAY_BUFFER_BINDING,
    Blend = GL_BLEND,
    BlendColor = GL_BLEND_COLOR,
    BlendDestAlpha = GL_BLEND_DST_ALPHA,
    BlendDestRGB = GL_BLEND_DST_RGB,
    BlendEqationRGB = GL_BLEND_EQUATION_RGB,
    BlendEqationAlpha= GL_BLEND_EQUATION_ALPHA,
    BlendSourceAlpha = GL_BLEND_SRC_ALPHA,
    BlendSourceRGB = GL_BLEND_SRC_RGB,
    ColorClearValue = GL_COLOR_CLEAR_VALUE,
    ColorLogicOperation = GL_COLOR_LOGIC_OP,
    ColorWriteMask = GL_COLOR_WRITEMASK,
    CompressedTextureFormats = GL_COMPRESSED_TEXTURE_FORMATS,
    MaxComputeShaderStorageBlocks = GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS,
    MaxCombinedShaderStorageBlocks = GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS,
    MaxComputeUniformBlocks = GL_MAX_COMPUTE_UNIFORM_BLOCKS,
    MaxComputeTextureImageUnits = GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS,
    MaxComputeUniformComponents = GL_MAX_COMPUTE_UNIFORM_COMPONENTS,
    MaxComputeAtomicCounters = GL_MAX_COMPUTE_ATOMIC_COUNTERS,
    MaxComputeAtomicCounterBuffers = GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS,
    MaxCombinedComputeUniformComponents = GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS,
    MaxComputeWorkGroupInvocations = GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS,
    MaxComputeWorkGroupCount = GL_MAX_COMPUTE_WORK_GROUP_COUNT,
    MaxComputeWorkGroupSize = GL_MAX_COMPUTE_WORK_GROUP_SIZE,
    DispatchIndirectBufferBinding = GL_DISPATCH_INDIRECT_BUFFER_BINDING,
    MaxDebugGroupStackDepth = GL_MAX_DEBUG_GROUP_STACK_DEPTH,
    DebugGroupStackDepth = GL_DEBUG_GROUP_STACK_DEPTH,
    ContextFlags = GL_CONTEXT_FLAGS,
    CullFace = GL_CULL_FACE,
    CurrentProgram = GL_CURRENT_PROGRAM,
    DepthClearValue = GL_DEPTH_CLEAR_VALUE,
    DepthFunc = GL_DEPTH_FUNC,
    DepthRange = GL_DEPTH_RANGE,
    DepthTest = GL_DEPTH_TEST,
    DepthWriteMask = GL_DEPTH_WRITEMASK,
    Dither = GL_DITHER,
    DoubleBuffer = GL_DOUBLEBUFFER,
    DrawBuffer = GL_DRAW_BUFFER,
    DrawBuffer00 = GL_DRAW_BUFFER0,
    DrawBuffer01 = GL_DRAW_BUFFER1,
    DrawBuffer02 = GL_DRAW_BUFFER2,
    DrawBuffer03 = GL_DRAW_BUFFER3,
    DrawBuffer04 = GL_DRAW_BUFFER4,
    DrawBuffer05 = GL_DRAW_BUFFER5,
    DrawBuffer06 = GL_DRAW_BUFFER6,
    DrawBuffer07 = GL_DRAW_BUFFER7,
    DrawBuffer08 = GL_DRAW_BUFFER8,
    DrawBuffer09 = GL_DRAW_BUFFER9,
    DrawBuffer10 = GL_DRAW_BUFFER10,
    DrawBuffer11 = GL_DRAW_BUFFER11,
    DrawBuffer12 = GL_DRAW_BUFFER12,
    DrawBuffer13 = GL_DRAW_BUFFER13,
    DrawBuffer14 = GL_DRAW_BUFFER14,
    DrawBuffer15 = GL_DRAW_BUFFER15,
    DrawFrameBu0fferBinding = GL_DRAW_FRAMEBUFFER_BINDING,
    ReadFrameBufferBinding = GL_READ_FRAMEBUFFER_BINDING,
    ElementArrayBufferBinding = GL_ELEMENT_ARRAY_BUFFER_BINDING,
    FragmentShaderDerivativeHint = GL_FRAGMENT_SHADER_DERIVATIVE_HINT,
    ImplColorReadFormat = GL_IMPLEMENTATION_COLOR_READ_FORMAT,
    ImplColorReadType = GL_IMPLEMENTATION_COLOR_READ_TYPE,
    LineSmooth = GL_LINE_SMOOTH,
    LineSmoothHint = GL_LINE_SMOOTH_HINT,
    LineWidth = GL_LINE_WIDTH,
    LayerProvokingVertex = GL_LAYER_PROVOKING_VERTEX,
    LogicOpMode = GL_LOGIC_OP_MODE,
    MajorVersion = GL_MAJOR_VERSION,
    Max3DTextureSize = GL_MAX_3D_TEXTURE_SIZE,
    MaxArrayTextureLayers = GL_MAX_ARRAY_TEXTURE_LAYERS,
    MaxClipDistances = GL_MAX_CLIP_DISTANCES,
    MaxColorTextureSamples = GL_MAX_COLOR_TEXTURE_SAMPLES,
    MaxCombinedAtomicCounters = GL_MAX_COMBINED_ATOMIC_COUNTERS,
    MaxCombinedFragmentUniformComponents = GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
    MaxCombinedGeometryUniformComponents = GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS,
    MaxCombinedTextureImageUnits= GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
    MaxCombinedUniformBlocks= GL_MAX_COMBINED_UNIFORM_BLOCKS,
    MaxCombinedVertexUniformComponents= GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
    MaxCubemapTextureSize = GL_MAX_CUBE_MAP_TEXTURE_SIZE,
    MaxDepthTextureSamples = GL_MAX_DEPTH_TEXTURE_SAMPLES,
    MaxDrawBuffers = GL_MAX_DRAW_BUFFERS,
    MaxDualSourceDrawBuffers = GL_MAX_DUAL_SOURCE_DRAW_BUFFERS,
    MaxElementsIndices = GL_MAX_ELEMENTS_INDICES,
    MaxElementsVertices = GL_MAX_ELEMENTS_VERTICES,
    MaxElementsIndexes = GL_MAX_ELEMENTS_INDICES,
    MaxElementsVertexes = GL_MAX_ELEMENTS_VERTICES,
    MaxFragmentAtomicCounters = GL_MAX_FRAGMENT_ATOMIC_COUNTERS,
    MaxFragmentShaderStorageBlocks = GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS,
    MaxFragmentInputComponents = GL_MAX_FRAGMENT_INPUT_COMPONENTS,
    MaxFragmentUniformComponents = GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
    MaxFragmentUniformVectors = GL_MAX_FRAGMENT_UNIFORM_VECTORS,
    MaxFragmentUniformBlocks = GL_MAX_FRAGMENT_UNIFORM_BLOCKS,
    MaxFrameBufferWidth = GL_MAX_FRAMEBUFFER_WIDTH,
    MaxFrameBufferHeight = GL_MAX_FRAMEBUFFER_HEIGHT,
    MaxFrameBufferLayers = GL_MAX_FRAMEBUFFER_LAYERS,
    MaxFrameBufferSamples = GL_MAX_FRAMEBUFFER_SAMPLES,
    MaxGeometryAtomicCounters = GL_MAX_GEOMETRY_ATOMIC_COUNTERS,
    MaxGeometryShaderStorageBlocks = GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS,
    MaxGeometryInputComponents = GL_MAX_GEOMETRY_INPUT_COMPONENTS,
    MaxGeometryOutputComponents = GL_MAX_GEOMETRY_OUTPUT_COMPONENTS,
    MaxGeometryTextureImageUnits = GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS,
    MaxGeometryUniformBlocks = GL_MAX_GEOMETRY_UNIFORM_BLOCKS,
    MaxGeometryUniformComponents = GL_MAX_GEOMETRY_UNIFORM_COMPONENTS,
    MaxIntegerSamples = GL_MAX_INTEGER_SAMPLES,
    MinMapBufferAlignment = GL_MIN_MAP_BUFFER_ALIGNMENT,
    MaxLabelLength = GL_MAX_LABEL_LENGTH,
    MaxProgramTexelOffset = GL_MAX_PROGRAM_TEXEL_OFFSET,
    MinProgramTexelOffset = GL_MIN_PROGRAM_TEXEL_OFFSET,
    MaxRectTextureSize = GL_MAX_RECTANGLE_TEXTURE_SIZE,
    MaxRenderBufferSize = GL_MAX_RENDERBUFFER_SIZE,
    MaxSampleMaskWords = GL_MAX_SAMPLE_MASK_WORDS,
    MaxServerWaitTimeout = GL_MAX_SERVER_WAIT_TIMEOUT,
    MaxShaderStorageBufferBindings = GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS,
    MaxTessControlAtomicCounters = GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS,
    MaxTessEvaluationAtomicCounters = GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS,
    MaxTessControlShaderStorageBlocks = GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS,
    MaxTessEvaluationShaderStorageBlocks = GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS,
    MaxTextureBufferSize = GL_MAX_TEXTURE_BUFFER_SIZE,
    MaxTextureImageUnits = GL_MAX_TEXTURE_IMAGE_UNITS,
    MaxTextureLODBias = GL_MAX_TEXTURE_LOD_BIAS,
    MaxTextureSize = GL_MAX_TEXTURE_SIZE,
    MaxUniformBufferBindings = GL_MAX_UNIFORM_BUFFER_BINDINGS,
    MaxUniformBlockSize = GL_MAX_UNIFORM_BLOCK_SIZE,
    MaxUniformLocations = GL_MAX_UNIFORM_LOCATIONS,
    MaxVaryingComponents = GL_MAX_VARYING_COMPONENTS,
    MaxVaryingVectors = GL_MAX_VARYING_VECTORS,
    MaxVaryingFloats = GL_MAX_VARYING_FLOATS,
    MaxVertexAtomicCounters = GL_MAX_VERTEX_ATOMIC_COUNTERS,
    MaxVertexAttributes = GL_MAX_VERTEX_ATTRIBS,
    MaxVertexShaderStorageBlocks = GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS,
    MaxVertexTextureImageUnits = GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
    MaxVertexUniformComponents = GL_MAX_VERTEX_UNIFORM_COMPONENTS,
    MaxVertexUniformVectors = GL_MAX_VERTEX_UNIFORM_VECTORS,
    MaxVertexOutputComponents = GL_MAX_VERTEX_OUTPUT_COMPONENTS,
    MaxVertexUniformBlocks = GL_MAX_VERTEX_UNIFORM_BLOCKS,
    MaxViewportDims = GL_MAX_VIEWPORT_DIMS,
    MaxViewports = GL_MAX_VIEWPORTS,
    MinorVersion = GL_MINOR_VERSION,
    NumCompressedTextureFormats = GL_NUM_COMPRESSED_TEXTURE_FORMATS,
    NumExtensions = GL_NUM_EXTENSIONS,
    NumProgramBinaryFormats = GL_NUM_PROGRAM_BINARY_FORMATS,
    NumShaderBinaryFormats = GL_NUM_SHADER_BINARY_FORMATS,
    PackAlignment = GL_PACK_ALIGNMENT,
    PackImageHeight = GL_PACK_IMAGE_HEIGHT,
    PackLSBFirst = GL_PACK_LSB_FIRST,
    PackRowLength = GL_PACK_ROW_LENGTH,
    PackSkipImages = GL_PACK_SKIP_IMAGES,
    PackSkipPixels = GL_PACK_SKIP_PIXELS,
    PackSkipRows = GL_PACK_SKIP_ROWS,
    PackSwapBytes = GL_PACK_SWAP_BYTES,
    PixelPackBufferBinding = GL_PIXEL_PACK_BUFFER_BINDING,
    PixelUnpackBufferBinding = GL_PIXEL_UNPACK_BUFFER_BINDING,
    PointFadeThresholdSize = GL_POINT_FADE_THRESHOLD_SIZE,
    PrimitiveRestartIndex = GL_PRIMITIVE_RESTART_INDEX,
    ProgramBinaryFormats = GL_PROGRAM_BINARY_FORMATS,
    ProgramPipelineBinding = GL_PROGRAM_PIPELINE_BINDING,
    ProgramPointSize = GL_PROGRAM_POINT_SIZE,
    ProvokingVertex = GL_PROVOKING_VERTEX,
    PointSize = GL_POINT_SIZE,
    PointSizeGranularity = GL_POINT_SIZE_GRANULARITY,
    PointSizeRange = GL_POINT_SIZE_RANGE,
    PolygonOffsetFactor = GL_POLYGON_OFFSET_FACTOR,
    PolygonOffsetUnits = GL_POLYGON_OFFSET_UNITS,
    PolygonOffsetFill = GL_POLYGON_OFFSET_FILL,
    PolygonOffsetLine = GL_POLYGON_OFFSET_LINE,
    PolygonOffsetPoint = GL_POLYGON_OFFSET_POINT,
    PolygonSmooth = GL_POLYGON_SMOOTH,
    PolygonSmoothHint = GL_POLYGON_SMOOTH_HINT,
    ReadBuffer = GL_READ_BUFFER,
    RenderBufferBinding = GL_RENDERBUFFER_BINDING,
    SampleBuffers = GL_SAMPLE_BUFFERS,
    SampleCoverageValue = GL_SAMPLE_COVERAGE_VALUE,
    SampleCoverageInvert = GL_SAMPLE_COVERAGE_INVERT,
    SamplerBinding = GL_SAMPLER_BINDING,
    Samples = GL_SAMPLES,
    ScissorBox  = GL_SCISSOR_BOX,
    ScissorTest = GL_SCISSOR_TEST,
    ShaderCompiler = GL_SHADER_COMPILER,
    ShaderStorageBufferBinding = GL_SHADER_STORAGE_BUFFER_BINDING,
    ShaderStorageBufferOffsetAlign = GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT,
    ShaderStorageBufferStart = GL_SHADER_STORAGE_BUFFER_START,
    ShaderStorageBufferSize = GL_SHADER_STORAGE_BUFFER_SIZE,
    SmoothLineWidthRange = GL_SMOOTH_LINE_WIDTH_RANGE,
    SmoothLineWidthGranularity = GL_SMOOTH_LINE_WIDTH_GRANULARITY,
    StencilBackFail = GL_STENCIL_BACK_FAIL,
    StencilBackFunc = GL_STENCIL_BACK_FUNC,
    StencilBackPassDepthFail = GL_STENCIL_BACK_PASS_DEPTH_FAIL,
    StencilBackPassDepthPass = GL_STENCIL_BACK_PASS_DEPTH_PASS,
    StencilBackRef = GL_STENCIL_BACK_REF,
    StencilBackValueMask = GL_STENCIL_BACK_VALUE_MASK,
    StencilBackWriteMask = GL_STENCIL_BACK_WRITEMASK,
    StencilClearValue = GL_STENCIL_CLEAR_VALUE,
    StencilFail = GL_STENCIL_FAIL,
    StencilFunc = GL_STENCIL_FUNC,
    StencilPassDepthFail = GL_STENCIL_PASS_DEPTH_FAIL,
    StencilPassDepthPass = GL_STENCIL_PASS_DEPTH_PASS,
    StencilRef = GL_STENCIL_REF,
    StencilTest = GL_STENCIL_TEST,
    StencilValueMask = GL_STENCIL_VALUE_MASK,
    StencilWriteMask = GL_STENCIL_WRITEMASK,
    Stereo = GL_STEREO,
    SubpixelBits = GL_SUBPIXEL_BITS,
    TextureBinding1D = GL_TEXTURE_BINDING_1D,
    TextureBinding1DArray = GL_TEXTURE_BINDING_1D_ARRAY,
    TextureBinding2D = GL_TEXTURE_BINDING_2D,
    TextureBinding2DArray = GL_TEXTURE_BINDING_2D_ARRAY,
    TextureBinding2DMultisample = GL_TEXTURE_BINDING_2D_MULTISAMPLE,
    TextureBinding2DMultisampleArray = GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY,
    TextureBinding3D = GL_TEXTURE_BINDING_3D,
    TextureBindingBuffer = GL_TEXTURE_BINDING_BUFFER,
    TextureBindingCubemap = GL_TEXTURE_BINDING_CUBE_MAP,
    TextureBindingRect = GL_TEXTURE_BINDING_RECTANGLE,
    TextureCompressionHint = GL_TEXTURE_COMPRESSION_HINT,
    TextureBufferOffsetAlignment = GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT,
    Timestamp = GL_TIMESTAMP,
    TransformFeedbackBufferBinding = GL_TRANSFORM_FEEDBACK_BUFFER_BINDING,
    TransformFeedbackBufferStart = GL_TRANSFORM_FEEDBACK_BUFFER_START,
    TransformFeedbackBufferSize = GL_TRANSFORM_FEEDBACK_BUFFER_SIZE,
    UniformBufferBinding = GL_UNIFORM_BUFFER_BINDING,
    UniformBufferOffsetAlign = GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT,
    UniformBufferSize = GL_UNIFORM_BUFFER_SIZE,
    UniformBufferStart = GL_UNIFORM_BUFFER_START,
    UnpackAlignment = GL_UNPACK_ALIGNMENT,
    UnpackImageHeight = GL_UNPACK_IMAGE_HEIGHT,
    UnpackLSBFirst = GL_UNPACK_LSB_FIRST,
    UnpackRowLength = GL_UNPACK_ROW_LENGTH,
    UnpackSkipImages = GL_UNPACK_SKIP_IMAGES,
    UnpackSkipPixels = GL_UNPACK_SKIP_PIXELS,
    UnpackSkipRows = GL_UNPACK_SKIP_ROWS,
    UnpackSwapBytes = GL_UNPACK_SWAP_BYTES,
    VertexArrayBinding = GL_VERTEX_ARRAY_BINDING,
    VertexBindingDivisor = GL_VERTEX_BINDING_DIVISOR,
    VertexBindingOffset = GL_VERTEX_BINDING_OFFSET,
    VertexBindingStride = GL_VERTEX_BINDING_STRIDE,
    MaxVertexAttribRelativeOffset = GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET,
    MaxVertexAttribBindings = GL_MAX_VERTEX_ATTRIB_BINDINGS,
    Viewport = GL_VIEWPORT,
    ViewportBoundsRange = GL_VIEWPORT_BOUNDS_RANGE,
    ViewportIndexProvokingVertex = GL_VIEWPORT_INDEX_PROVOKING_VERTEX,
    ViewportSubpixelBits = GL_VIEWPORT_SUBPIXEL_BITS,
    MaxElementIndex = GL_MAX_ELEMENT_INDEX,
}

static immutable glenum[16] DrawBuffer = [
    Param.DrawBuffer00,
    Param.DrawBuffer01,
    Param.DrawBuffer02,
    Param.DrawBuffer03,
    Param.DrawBuffer04,
    Param.DrawBuffer05,
    Param.DrawBuffer06,
    Param.DrawBuffer07,
    Param.DrawBuffer08,
    Param.DrawBuffer09,
    Param.DrawBuffer10,
    Param.DrawBuffer11,
    Param.DrawBuffer12,
    Param.DrawBuffer13,
    Param.DrawBuffer14,
    Param.DrawBuffer15,
];

// https://www.opengl.org/sdk/docs/man/html/glDrawArrays.xhtml
enum GLPrimitive : glenum {
    Points = GL_POINTS,
    LineStrip = GL_LINE_STRIP,
    LineLoop = GL_LINE_LOOP,
    Lines = GL_LINES,
    LineStripAdjacency = GL_LINE_STRIP_ADJACENCY,
    LinesAdjacency = GL_LINES_ADJACENCY,
    TriangleStrip = GL_TRIANGLE_STRIP,
    TriangleFan = GL_TRIANGLE_FAN,
    Triangles = GL_TRIANGLES,
    TriangleStripAdjacency = GL_TRIANGLE_STRIP_ADJACENCY,
    TrianglesAdjacency = GL_TRIANGLES_ADJACENCY,
    Patches = GL_PATCHES,
    Quads = GL_QUADS,
    QuadStrip = GL_QUAD_STRIP,
    Polygon = GL_POLYGON
}

// https://www.opengl.org/sdk/docs/man/html/glBlendFunc.xhtml
enum BlendFactor : glenum {
    Zero = GL_ZERO,
    One = GL_ONE,
    SrcColor = GL_SRC_COLOR,
    OneMinusSrcColor = GL_ONE_MINUS_SRC_COLOR,
    DstColor = GL_DST_COLOR,
    OneMinusDstColor = GL_ONE_MINUS_DST_COLOR,
    SrcAlpha = GL_SRC_ALPHA,
    OneMinusSrcAlpha = GL_ONE_MINUS_SRC_ALPHA,
    DstAlpha = GL_DST_ALPHA,
    OneMinusDstAlpha = GL_ONE_MINUS_DST_ALPHA,
    ConstantColor = GL_CONSTANT_COLOR,
    OneMinusConstantColor = GL_ONE_MINUS_CONSTANT_COLOR,
    ConstantAlpha = GL_CONSTANT_ALPHA,
    OneMinusConstantAlpha = GL_ONE_MINUS_CONSTANT_ALPHA,
}

// http://docs.gl/gl3/glMatrixMode
enum MatrixMode : glenum {
    ModelView = GL_MODELVIEW,
    Projection = GL_PROJECTION,
    Texture = GL_TEXTURE,
    Color = GL_COLOR
}

// https://www.opengl.org/sdk/docs/man2/xhtml/glEnable.xml
enum Capability : glenum {
    //AlphaTest = GL_ALPHA_TEST, // Deprecated
    //AutoNormal = GL_AUTO_NORMAL, // Deprecated
    Blend = GL_BLEND,
    //ClipPlanei = GL_CLIP_PLANEi, // TODO: Not real?
    ColorLogicOp = GL_COLOR_LOGIC_OP,
    //ColorMaterial = GL_COLOR_MATERIAL, // Deprecated
    //ColorSum = GL_COLOR_SUM, // Deprecated
    //ColorTable = GL_COLOR_TABLE, // Deprecated
    //Convolution1D = GL_CONVOLUTION_1D, // Deprecated
    //Convolution2D = GL_CONVOLUTION_2D, // Deprecated
    CullFace = GL_CULL_FACE,
    DepthTest = GL_DEPTH_TEST,
    Dither = GL_DITHER,
    //Fog = GL_FOG, // Deprecated
    //Histogram = GL_HISTOGRAM, // Deprecated
    //IndexLogicOp = GL_INDEX_LOGIC_OP, // Deprecated
    //Light0 = GL_LIGHT0, // Deprecated
    //Light1 = GL_LIGHT1, // Deprecated
    //Light2 = GL_LIGHT2, // Deprecated
    //Light3 = GL_LIGHT3, // Deprecated
    //Light4 = GL_LIGHT4, // Deprecated
    //Light5 = GL_LIGHT5, // Deprecated
    //Light6 = GL_LIGHT6, // Deprecated
    //Light7 = GL_LIGHT7, // Deprecated
    //Lighting = GL_LIGHTING, // Deprecated
    LineSmooth = GL_LINE_SMOOTH,
    //LineStipple = GL_LINE_STIPPLE, // Deprecated
    //Map1Color4 = GL_MAP1_COLOR_4, // Deprecated
    //Map1Index = GL_MAP1_INDEX, // Deprecated
    //Map1Normal = GL_MAP1_NORMAL, // Deprecated
    //Map1TextureCoord1 = GL_MAP1_TEXTURE_COORD_1, // Deprecated
    //Map1TextureCoord2 = GL_MAP1_TEXTURE_COORD_2, // Deprecated
    //Map1TextureCoord3 = GL_MAP1_TEXTURE_COORD_3, // Deprecated
    //Map1TextureCoord4 = GL_MAP1_TEXTURE_COORD_4, // Deprecated
    //Map1Vertex3 = GL_MAP1_VERTEX_3, // Deprecated
    //Map1Vertex4 = GL_MAP1_VERTEX_4, // Deprecated
    //Map2Color4 = GL_MAP2_COLOR_4, // Deprecated
    //Map2Index = GL_MAP2_INDEX, // Deprecated
    //Map2Normal = GL_MAP2_NORMAL, // Deprecated
    //Map2TextureCoord1 = GL_MAP2_TEXTURE_COORD_1, // Deprecated
    //Map2TextureCoord2 = GL_MAP2_TEXTURE_COORD_2, // Deprecated
    //Map2TextureCoord3 = GL_MAP2_TEXTURE_COORD_3, // Deprecated
    //Map2TextureCoord4 = GL_MAP2_TEXTURE_COORD_4, // Deprecated
    //Map2Vertex3 = GL_MAP2_VERTEX_3, // Deprecated
    //Map2Vertex4 = GL_MAP2_VERTEX_4, // Deprecated
    //Minmax = GL_MINMAX, // Deprecated
    Multisample = GL_MULTISAMPLE,
    //Normalize = GL_NORMALIZE, // Deprecated
    //PointSmooth = GL_POINT_SMOOTH, // Deprecated
    //PointSprite = GL_POINT_SPRITE, // Deprecated
    PolygonOffsetFill = GL_POLYGON_OFFSET_FILL,
    PolygonOffsetLine = GL_POLYGON_OFFSET_LINE,
    PolygonOffsetPoint = GL_POLYGON_OFFSET_POINT,
    PolygonSmooth = GL_POLYGON_SMOOTH,
    //PolygonStipple = GL_POLYGON_STIPPLE, // Deprecated
    //PostColorMatrixColorTable = GL_POST_COLOR_MATRIX_COLOR_TABLE, // Deprecated
    //PostConvolutionColorTable = GL_POST_CONVOLUTION_COLOR_TABLE, // Deprecated
    //RescaleNormal = GL_RESCALE_NORMAL, // Deprecated
    SampleAlphaToCoverage = GL_SAMPLE_ALPHA_TO_COVERAGE,
    SampleAlphaToOne = GL_SAMPLE_ALPHA_TO_ONE,
    SampleCoverage = GL_SAMPLE_COVERAGE,
    //Separable2D = GL_SEPARABLE_2D, // Deprecated
    ScissorTest = GL_SCISSOR_TEST,
    StencilTest = GL_STENCIL_TEST,
    Texture1D = GL_TEXTURE_1D,
    Texture2D = GL_TEXTURE_2D,
    Texture3D = GL_TEXTURE_3D,
    TextureCubeMap = GL_TEXTURE_CUBE_MAP,
    //TextureGenQ = GL_TEXTURE_GEN_Q, // Deprecated
    //TextureGenR = GL_TEXTURE_GEN_R, // Deprecated
    //TextureGenS = GL_TEXTURE_GEN_S, // Deprecated
    //TextureGenT = GL_TEXTURE_GEN_T, // Deprecated
    VertexProgramPointSize = GL_VERTEX_PROGRAM_POINT_SIZE,
    //VertexProgramTwoSide = GL_VERTEX_PROGRAM_TWO_SIDE, // Deprecated
}

/+ Deprecated
static immutable glenum[8] Light = [
    Capability.Light0,
    Capability.Light1,
    Capability.Light2,
    Capability.Light3,
    Capability.Light4,
    Capability.Light5,
    Capability.Light6,
    Capability.Light7,
];
+/
