module mach.math.matrix;

private:

import mach.meta : Repeat, Retro, All, NumericSequence, varmap, varzip, varsum, ctint;
import mach.types : tuple;
import mach.traits : isNumeric, CommonType, hasCommonType;
import mach.error : IndexOutOfBoundsError;
import mach.text.str : str;
import mach.math.trig : Angle;
import mach.math.vector : Vector, vector, isVector, isVectorComponent;

/++ Docs

The `Matrix` template type represents a [matrix]
(https://en.wikipedia.org/wiki/Matrix_(mathematics)) with arbitrary
dimensionality and any signed numeric primitive type for its components.
It is represented as a tuple of column Vectors.

Several convenience symbols are defined including `Matrix2i` and `Matrix2f`,
`Matrix3i` and `Matrix3f`, and `Matrix4i` and `Matrix4f`, referring to square
matrixes of different dimensionalities with either integral or floating point
component types.
It is recommended to use their `Rows` and `Cols` static methods to initialize
matrixes because they are maximally explicit in the structure of its arguments.
Note that Matrix constructors behave similarly to calling `Cols` with various
argument types.

The `matrix`, `matrixrows`, and `matrixcols` functions are also defined for
concisely initializing matrixes. Any time that it is not otherwise specified,
values are interpreted as columns first, rows second, e.g. the inputs
`1, 2, 3, 4` would produce a matrix where `2` is at X coordinate 0 and Y
coordinate 1, and `3` at X coordinate 1 and Y coordinate 0.
This differs from rows first, columns second where the same inputs `1, 2, 3, 4`
would product a matrix where `2` is at X coordinate 1 and Y coordinate 0,
and `3` at X coordinate 0 and Y coordinate 1.
Functions which accept a flat series of values can alternatively accept a series
of row or column vectors.

+/

unittest{ /// Example
    auto mat = Matrix3i.Rows(
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    );
    assert(mat[0][0] == 1); // Column 0, row 0
    assert(mat[2][0] == 3); // Column 2, row 0
    assert(mat[0][2] == 7); // Column 0, row 2
    assert(mat[2][2] == 9); // Column 2, row 2
}

unittest{ /// Example
    auto mat = Matrix3i.Cols(
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    );
    assert(mat[0][0] == 1);
    assert(mat[2][0] == 7);
    assert(mat[0][2] == 3);
    assert(mat[2][2] == 9);
}

/++ Docs

The individual components of a matrix may be accessed using indexes known at
compile time via the `matrix[x][y]` syntax or, alternatively, `matrix.index!(x, y)`.
If indexes are known only at runtime, `matrix.index(x, y)` may be used.

Attempting to access an out-of-bounds index with compile time values will
result in a compile error. Attempting to do so with runtime values will cause
an `IndexOutOfBoundsError` to be thrown.

+/

unittest{ /// Example
    import mach.math.vector : vector;
    import mach.test.assertthrows : assertthrows;
    auto mat = Matrix2i.Rows(
        vector(1, 2),
        vector(3, 4),
    );
    // Accessing legal indexes
    assert(mat[0][0] == 1);
    assert(mat.index!(1, 1) == 4);
    assert(mat.index(1, 0) == 2);
    // Accessing out-of-bounds indexes
    static assert(!is(typeof({
        mat[100][100];
    })));
    assertthrows({
        auto x = mat.index(200, 200);
    });
}

/++ Docs

Matrixes may be compared for equality using the `==` operator, or with the
`equals` method which accepts an optional per-component epsilon.

+/

unittest{ /// Example
    assert(Matrix2i(1, 2, 3, 4) == Matrix2f(1, 2, 3, 4));
    assert(Matrix2f(5, 6, 7, 8).equals(Matrix2f(5, 6, 7, 8)));
    assert(Matrix2f(5, 6, 7, 8).equals(Matrix2f(5, 6, 7, 8 + 1e-16), 1e-8));
}

/++ Docs

The rows and columns of a matrix may be accessed and modified using the
`row`, `col`, `rows`, and `cols` methods.
`row` and `col` return vectors and `rows` and `cols` return tuples of vectors.
The vectors returned by `row` and `rows` have a number of components equal to
the width of the matrix, and those returned by `col` and `cols` have a number
of components equal to its height.

+/

unittest{ /// Example
    auto mat = Matrix3i.Rows(
        vector(1, 2, 3),
        vector(4, 5, 6),
        vector(7, 8, 9),
    );
    // Get the row at an index
    assert(mat.row!0 == vector(1, 2, 3));
    // Get the column at an index
    assert(mat.col!0 == vector(1, 4, 7));
    // Get a tuple of row vectors
    auto rows = mat.rows;
    static assert(rows.length == mat.height);
    assert(rows[1] == vector(4, 5, 6));
    // Get a tuple of column vectors
    auto cols = mat.cols;
    static assert(cols.length == mat.width);
    assert(cols[1] == vector(2, 5, 8));
}

/++ Docs

A matrix can be multiplied by another matrix or by a column vector using the `*`
operator.
Other matrix binary operators are component-wise, meaning that the operation is
applied to each pair of corresponding components. For component-wise
multiplication as opposed to normal matrix multiplication, the `matrix.scale`
method may be used.

Matrixes also support component-wise binary operations with numbers.

+/

unittest{ /// Example
    auto a = Matrix2i.Rows(
        1, 2,
        3, 4,
    );
    auto b = Matrix2i.Rows(
        5, 6,
        7, 8,
    );
    // Matrix multiplication
    assert(a * b == Matrix2i.Rows(
        19, 22,
        43, 50
    ));
    // Component-wise addition
    assert(a + b == Matrix2i.Rows(
        6, 8,
        10, 12,
    ));
    // Component-wise multiplication
    assert(a.scale(b) == Matrix2i.Rows(
        5, 12,
        21, 32,
    ));
}

unittest{ /// Example
    import mach.math.vector : Vector2i;
    auto a = Matrix2i.Rows(
        1, 2,
        3, 4,
    );
    auto b = Vector2i(5, 6);
    assert(a * b == Vector2i(17, 39));
}

unittest{ /// Example
    auto mat = Matrix2i.Rows(
        1, 2,
        3, 4,
    );
    assert(mat * 3 == Matrix2i.Rows(
        3, 6,
        9, 12,
    ));
    assert(mat + 1 == Matrix2i.Rows(
        2, 3,
        4, 5,
    ));
}

/++ Docs

Matrixes also provide utilities where applicable for finding their [determinant]
(https://en.wikipedia.org/wiki/Determinant), a [minor matrix]
(https://en.wikipedia.org/wiki/Minor_(linear_algebra)), the [cofactor matrix]
(https://en.wikipedia.org/wiki/Minor_(linear_algebra)#Inverse_of_a_matrix),
the [adjugate or adjoint](https://en.wikipedia.org/wiki/Adjugate_matrix),
the [transpose](https://en.wikipedia.org/wiki/Transpose), and the [inverse]
(https://en.wikipedia.org/wiki/Invertible_matrix).

Additionally, methods such as `flip`, `scroll`, and `rotate` can be used to
perform simple transformations on the positions of elements in a matrix.

+/

unittest{ /// Example
    auto mat = Matrix2f.Rows(
        vector(1, 2),
        vector(3, 4),
    );
    // Get the determinant
    assert(mat.determinant == -2);
    // Get a minor matrix, i.e. a matrix with a column and row omitted.
    assert(mat.minor!(0, 0) == matrixrows(vector(4)));
    // Transpose the matrix
    assert(mat.transpose == matrixrows(
        vector(1, 3),
        vector(2, 4),
    ));
    // Get the cofactor matrix
    assert(mat.cofactor == matrixrows(
        vector(4, -3),
        vector(-2, 1),
    ));
    // Get the adjugate
    assert(mat.adjugate == matrixrows(
        vector(4, -2),
        vector(-3, 1),
    ));
    // Get the inverse: Multiplying by a matrix's inverse produces the identity matrix.
    assert(mat * mat.inverse == Matrix2f.identity);
}

unittest{ /// Example
    auto mat = matrixrows!(3, 2)(
        1, 2, 3,
        4, 5, 6,
    );
    assert(mat.flipv == matrixrows!(3, 2)(
        4, 5, 6,
        1, 2, 3,
    ));
    assert(mat.fliph == matrixrows!(3, 2)(
        3, 2, 1,
        6, 5, 4,
    ));
    assert(mat.rotate!1 == matrixrows!(2, 3)(
        4, 1,
        5, 2,
        6, 3,
    ));
    assert(mat.scroll!(2, 0) == matrixrows!(3, 2)(
        2, 3, 1,
        5, 6, 4,
    ));
}

public:



/// Get whether a type is valid as a matrix component.
alias isMatrixComponent = isVectorComponent;

/// Determine whether a Matrix could be created from arguments of the given
/// types; essentially checks whether they have a common signed numeric type.
template canMatrix(T...){
    static if(T.length && hasCommonType!T){
        enum bool canMatrix = isMatrixComponent!(CommonType!T);
    }else{
        enum bool canMatrix = false;
    }
}



/// Determine whether some type is a Matrix of any dimensionality and
/// component type.
template isMatrix(T){
    enum bool isMatrix = false;
}
/// Ditto
template isMatrix(T: Matrix!(width, height, X), size_t width, size_t height, X){
    enum bool isMatrix = true;
}
/// Determine whether some type is a Vector of the given width and height and
/// of any component type.
template isMatrix(size_t size, T){
    enum bool isMatrix = isMatrix!(size, size, T);
}
/// Ditto
template isMatrix(size_t width, size_t height, T){
    static if(isMatrix!T){
        enum bool isMatrix = T.width == width && T.height == height;
    }else{
        enum bool isMatrix = false;
    }
}



/// Get a matrix using vectors to represent its columns.
auto matrixcols(V...)(in V vectors) if(All!(isVector, V) && V.length > 0){
    foreach(i, _; V[0 .. $ - 1]) static assert(V[i].size == V[i + 1].size,
        "All input vectors must be of the same size."
    );
    return matrixcols!(typeof(varsum(vectors)).Value)(vectors);
}
/// Ditto
auto matrixcols(T, V...)(in V vectors) if(
    isMatrixComponent!T && All!(isVector, V) && V.length > 0
){
    foreach(i, _; V[0 .. $ - 1]) static assert(V[i].size == V[i + 1].size,
        "All input vectors must be of the same size."
    );
    return Matrix!(vectors.length, vectors[0].size, T).Cols(vectors);
}

/// Get a matrix represented by its components given in columns first, then rows.
auto matrixcols(size_t width, size_t height, T...)(in T values) if(
    canMatrix!T && T.length == width * height
){
    return Matrix!(width, height, CommonType!T).Cols(values);
}
/// Ditto
auto matrixcols(size_t size, T...)(in T values) if(canMatrix!T && T.length == size){
    return matrixcols!(size, size)(values);
}



/// Get a matrix using vectors to represent its rows.
auto matrixrows(V...)(in V vectors) if(All!(isVector, V) && V.length > 0){
    foreach(i, _; V[0 .. $ - 1]) static assert(V[i].size == V[i + 1].size,
        "All input vectors must be of the same size."
    );
    return matrixrows!(typeof(varsum(vectors)).Value)(vectors);
}
/// Ditto
auto matrixrows(T, V...)(in V vectors) if(
    isMatrixComponent!T && All!(isVector, V) && V.length > 0
){
    foreach(i, _; V[0 .. $ - 1]) static assert(V[i].size == V[i + 1].size,
        "All input vectors must be of the same size."
    );
    return Matrix!(vectors[0].size, vectors.length, T).Rows(vectors);
}

/// Get a matrix represented by its components given in rows first, then columns.
auto matrixrows(size_t width, size_t height, T...)(in T values) if(
    canMatrix!T && T.length == width * height
){
    return Matrix!(width, height, CommonType!T).Rows(values);
}
/// Ditto
auto matrixrows(size_t size, T...)(in T values) if(canMatrix!T && T.length == size){
    return matrixrows!(size, size)(values);
}



/// Get a matrix with no components.
auto matrix(T)() if(isMatrixComponent!T){
    return Matrix!(0, 0, T).zero;
}

/// Get a matrix using vectors to represent its columns.
auto matrix(V...)(in V vectors) if(All!(isVector, V) && V.length > 0){
    return matrixcols(vectors);
}
/// Ditto
auto matrix(T, V...)(in V vectors) if(
    isMatrixComponent!T && All!(isVector, V) && V.length > 0
){
    return matrixcols!T(vectors);
}

/// Get a matrix represented by its components given in columns first, then rows.
auto matrix(size_t width, size_t height, T...)(in T values) if(
    canMatrix!T && T.length == width * height
){
    return matrixcols!(width, height)(values);
}
/// Ditto
auto matrix(size_t size, T...)(in T values) if(canMatrix!T && T.length == size){
    return matrixcols!(size, size)(values);
}



/// Mixin for the `Matrix.row` getter property.
private string MatrixGetRowMixin(in size_t index, in size_t width){
    string codegen = ``;
    foreach(i; 0 .. width){
        if(i != 0) codegen ~= `, `;
        codegen ~= `this[` ~ ctint(i) ~ `][` ~ ctint(index) ~ `]`;
    }
    return `return vector(` ~ codegen ~ `);`;
}

/// Mixin for the `Matrix.row` setter property.
private string MatrixSetRowMixin(in size_t index, in size_t width){
    string codegen = ``;
    foreach(i; 0 .. width){
        immutable istr = ctint(i);
        codegen ~= `this[` ~ istr ~ `][` ~ ctint(index) ~ `] = values[` ~ istr ~ `]; `;
    }
    return codegen;
}

/// Mixin for the `Matrix.rows` method.
private string MatrixGetRowsMixin(in size_t height){
    string codegen = ``;
    foreach(i; 0 .. height){
        if(i != 0) codegen ~= `, `;
        codegen ~= `this.row!` ~ ctint(i);
    }
    return `return tuple(` ~ codegen ~ `);`;
}

/// Mixin for the `Matrix.Rows(values...)` static method.
private string MatrixRowsValuesInitMixin(in size_t width, in size_t height){
    string codegen = ``;
    foreach(i; 0 .. width){
        if(i != 0) codegen ~= `, `;
        codegen ~= `vector(`;
        foreach(j; 0 .. height){
            if(j != 0) codegen ~= `, `;
            codegen ~= `values[` ~ ctint(i + j * width) ~ `]`;
        }
        codegen ~= `)`;
    }
    return `return typeof(this)(` ~ codegen ~ `);`;
}

/// Mixin for the `Matrix.Rows(vectors...)` static method.
private string MatrixRowsVectorsInitMixin(in size_t width, in size_t height){
    string codegen = ``;
    foreach(i; 0 .. width){
        if(i != 0) codegen ~= `, `;
        codegen ~= `vector(`;
        foreach(j; 0 .. height){
            if(j != 0) codegen ~= `, `;
            codegen ~= `vectors[` ~ ctint(j) ~ `][` ~ ctint(i) ~ `]`;
        }
        codegen ~= `)`;
    }
    return `return typeof(this)(` ~ codegen ~ `);`;
}

/// Mixin for computing the determinant of a square matrix with a width and
/// height of at least 2.
string MatrixDeterminantMixin(in size_t size){
    string codegen = ``;
    foreach(i; 0 .. size){
        if(i != 0) codegen ~= ` + `;
        codegen ~= `this[` ~ ctint(i) ~ `][0] * (`;
        foreach(j; 1 .. size){
            if(j != 1) codegen ~= ` * `;
            immutable k = (i + j) % size;
            codegen ~= `this[` ~ ctint(k) ~ `][` ~ ctint(j) ~ `]`;
        }
        codegen ~= ` - `;
        foreach(j; 1 .. size){
            if(j != 1) codegen ~= ` * `;
            immutable k = ((i + size) - j) % size;
            codegen ~= `this[` ~ ctint(k) ~ `][` ~ ctint(j) ~ `]`;
        }
        codegen ~= `)`;
    }
    return `return ` ~ codegen ~ `;`;
}

/// Mixin for the `Matrix.cofactor` method.
private string MatrixCofactorMixin(in size_t size){
    string codegen = ``;
    foreach(i; 0 .. size){
        if(i != 0) codegen ~= `, `;
        foreach(j; 0 .. size){
            if(j != 0) codegen ~= `, `;
            if((i + j) % 2) codegen ~= `-`;
            codegen ~= `this.minor!(` ~ ctint(i) ~ `, ` ~ ctint(j) ~ `).determinant`;
        }
    }
    return `return matrix!(width, height)(` ~ codegen ~ `);`;
}

/// Mixin for the `Matrix.product` method.
private string MatrixProductMixin(in size_t width, in size_t height){
    string codegen = ``;
    foreach(i; 0 .. width){
        if(i != 0) codegen ~= `, `;
        foreach(j; 0 .. height){
            if(j != 0) codegen ~= `, `;
            codegen ~= `this.row!` ~ ctint(j) ~ `.dot(mat.col!` ~ ctint(i) ~ `)`;
        }
    }
    return `return matrix!(` ~ ctint(width) ~ `, ` ~ ctint(height) ~ `)(` ~ codegen ~ `);`;
}

/// Mixin to implement the `Matrix.scroll` method.
private string MatrixScrollMixin(in size_t width, in size_t height, in size_t x, in size_t y){
    string codegen = ``;
    foreach(i; 0 .. width){
        foreach(j; 0 .. height){
            if(j != 0 || i != 0) codegen ~= `, `;
            immutable xv = (i + x) % width;
            immutable yv = (j + y) % height;
            codegen ~= `this[` ~ ctint(xv) ~ `][` ~ ctint(yv) ~ `]`;
        }
    }
    return `return typeof(this)(` ~ codegen ~ `);`;
}

/// Mixin to generate a tuple representing the contents of an identity matrix.
private string MatrixIdentityTupleMixin(in size_t size){
    string codegen = ``;
    foreach(i; 0 .. size){
        foreach(j; 0 .. size){
            if(i != 0 || j != 0) codegen ~= `, `;
            codegen ~= (i == j ? '1' : '0');
        }
    }
    return `return tuple(` ~ codegen ~ `);`;
}

/// Get a tuple representing the contents of an identity matrix.
private auto MatrixIdentityTuple(size_t size)(){
    mixin(MatrixIdentityTupleMixin(size));
}



template Matrix2(T){
    alias Matrix2 = Matrix!(2, T);
}
alias Matrix2i = Matrix2!long;
alias Matrix2f = Matrix2!double;

template Matrix3(T){
    alias Matrix3 = Matrix!(3, T);
}
alias Matrix3i = Matrix3!long;
alias Matrix3f = Matrix3!double;

template Matrix4(T){
    alias Matrix4 = Matrix!(4, T);
}
alias Matrix4i = Matrix4!long;
alias Matrix4f = Matrix4!double;



/// Convenience template to get a square Matrix type of a given size.
template Matrix(size_t size, T){
    alias Matrix = Matrix!(size, size, T);
}

/// Represents a two-dimensional dense matrix of signed numeric values.
struct Matrix(size_t valueswidth, size_t valuesheight, T) if(isMatrixComponent!T){
    /// The number of columns in the matrix.
    static enum size_t width = valueswidth;
    /// The number of rows in the matrix.
    static enum size_t height = valuesheight;
    /// The total number of cells in the matrix, i.e. the product of width and height.
    static enum size_t size = width * height;
    
    /// The component type, necessarily a signed numeric type.
    alias Value = T;
    
    /// Get whether a vector is the correct size to represent a column of this matrix.
    template isColumnVector(T){
        enum bool isColumnVector = isVector!(height, T);
    }
    /// Get whether a vector is the correct size to represent a row of this matrix.
    template isRowVector(T){
        enum bool isRowVector = isVector!(width, T);
    }
    
    /// True when width is equal to height, false otherwise.
    static enum bool square = (width == height);
    
    alias Column = Vector!(height, T);
    alias Columns = Repeat!(width, Column);
    
    Columns columns;
    alias columns this;
    
    /// Represents a matrix with all-zero components.
    static enum zero = typeof(this)(0);
    
    static if(square){
        /// The identity matrix; implemented only for square matrixes.
        static enum identity = typeof(this)(MatrixIdentityTuple!width.expand);
    }
    
    /// Create a matrix where every component is set to the given value.
    this(N)(in N value) if(isNumeric!N){
        foreach(i, _; Columns){
            this.columns[i] = Column.fill(value);
        }
    }
    /// Create a matrix using vectors to represent the columns.
    static if(width > 0) this(V...)(in V vectors) if(
        All!(isColumnVector, V) && vectors.length == width
    ){
        foreach(i, _; Columns){
            this.columns[i] = cast(Column) vectors[i];
        }
    }
    /// Create a matrix specifying each of its components.
    static if(size > 0) this(N...)(in N values) if(
        All!(isVectorComponent, N) && values.length == size
    ){
        foreach(i, _; Columns){
            this.columns[i] = vector(values[i * height .. i * height + height]);
        }
    }
    
    /// Create a matrix from vectors representing each column.
    static auto Cols(V...)(in V vectors) if(
        All!(isColumnVector, V) && vectors.length == width
    ){
        static if(size == 0){
            return typeof(this).zero;
        }else{
            return typeof(this)(vectors);
        }
    }
    /// Create a matrix from values representing columns, and then rows.
    static auto Cols(N...)(in N values) if(
        All!(isVectorComponent, N) && values.length == size
    ){
        static if(size == 0){
            return typeof(this).zero;
        }else{
            return typeof(this)(values);
        }
    }
    
    /// Create a matrix from vectors representing each row.
    static auto Rows(V...)(in V vectors) if(
        All!(isRowVector, V) && vectors.length == height
    ){
        mixin(MatrixRowsVectorsInitMixin(width, height));
    }
    /// Create a matrix from values representing rows, and then columns.
    static auto Rows(N...)(in N values) if(
        All!(isVectorComponent, N) && values.length == size
    ){
        mixin(MatrixRowsValuesInitMixin(width, height));
    }
    
    /// Get a tuple of vectors where each vector represents a row of the matrix.
    @property auto rows() const{
        static if(height == 0){
            return tuple();
        }else static if(width == 0){
            return tuple(Repeat!(height, vector!T()));
        }else{
            mixin(MatrixGetRowsMixin(height));
        }
    }
    /// Set the contents of the matrix using vectors representing each row.
    static if(height > 0) void setrows(V...)(in V vectors) if(
        All!(isRowVector, V) && vectors.length == height
    ){
        foreach(i, _; Column.Values) this.row!i = vectors[i];
    }
    /// Get a vector representing a row at an index.
    @property auto row(size_t index)() const{
        mixin(MatrixGetRowMixin(index, width));
    }
    /// Set the row at an index using a vector.
    @property void row(size_t index, X)(in Vector!(width, X) row){
        static if(width) this.row!index(row.values);
    }
    /// Set the row at an index using individual components.
    void row(size_t index, N...)(in N values) if(
        All!(isVectorComponent, N) && values.length == width
    ){
        mixin(MatrixSetRowMixin(index, width));
    }
    
    /// Get a tuple of vectors where each vector represents a column of the matrix.
    @property auto cols() const{
        return tuple(this.columns);
    }
    /// Set the contents of the matrix using vectors representing each column.
    static if(width > 0) void setcols(V...)(in V vectors) if(
        All!(isColumnVector, V) && vectors.length == width
    ){
        foreach(i, _; Columns) this.columns[i] = cast(Column) vectors[i];
    }
    /// Get a vector representing a column at an index.
    @property auto col(size_t index)() const{
        return this.columns[index];
    }
    /// Set the column at an index using a vector.
    @property void col(size_t index, X)(in Vector!(height, X) col){
        static if(height) this.columns[index] = cast(Column) col;
    }
    /// Set the column at an index using individual components.
    void col(size_t index, N...)(in N values) if(
        All!(isVectorComponent, N) && values.length == height
    ){
        this.columns[index] = vector(values);
    }
    
    /// Transpose this matrix, i.e. flip components across the top-left to
    /// bottom-right diagonal.
    /// https://en.wikipedia.org/wiki/Transpose
    @property auto transpose() const{
        static if(width == 0 || height == 0){
            return Matrix!(height, width, T).zero;
        }else{
            return Matrix!(height, width, T).Rows(this.columns);
        }
    }
    
    /// Get the determinant of a square matrix.
    /// The determinant of an empty matrix is 1.
    /// https://en.wikipedia.org/wiki/Determinant
    /// https://people.richland.edu/james/lecture/m116/matrices/determinant.html
    /// https://www.quora.com/What-is-the-determinant-of-an-empty-matrix-such-as-a-0x0-matrix
    /// https://en.wikipedia.org/wiki/Matrix_(mathematics)#Empty_matrices
    static if(square) @property auto determinant() const{
        static if(width == 0){
            return 1;
        }else static if(width == 1){
            return this[0][0];
        }else static if(width == 2){
            return this[0][0] * this[1][1] - this[0][1] * this[1][0];
        }else{
            mixin(MatrixDeterminantMixin(width));
        }
    }
    
    /// Get the cofactor matrix of a square matrix.
    /// http://www.mathwords.com/c/cofactor_matrix.htm
    static if(square) @property auto cofactor() const{
        static if(width == 0){
            return this;
        }else{
            mixin(MatrixCofactorMixin(width));
        }
    }
    
    /// Get the adjugate of a square matrix, defined as the transpose of its
    /// cofactor matrix.
    static if(square) @property auto adjugate() const{
        return this.cofactor.transpose;
    }
    
    /// Get the inverse of a square matrix.
    /// If the matrix is singular (non-invertible), returns the identity matrix.
    /// Answers may be very inaccurate for matrixes with integer components.
    /// http://mathworld.wolfram.com/MatrixInverse.html
    /// TODO: This becomes surprisingly inaccurate for larger matrixes
    /// presumably because of poor mitigation of floating point errors.
    static if(square) auto inverse() const{
        static if(width <= 1){
            return this;
        }else{
            immutable det = this.determinant;
            alias R = typeof(this.adjugate / det);
            if(det == 0){
                return R.identity; // Matrix cannot be inverted
            }else{
                static if(this.width == 2){
                    return R(
                        this[1][1], -this[0][1], -this[1][0], this[0][0]
                    ) / det;
                }else{
                    return this.adjugate / det;
                }
            }
        }
    }
    
    /// Get whether a square matrix is singular as opposed to nonsingular.
    /// Singular matrixes do not have an inverse.
    /// Matrixes are singular when their determinant is zero.
    static if(square) @property bool singular() const{
        return this.determinant == 0;
    }
    
    /// Get a minor matrix, defined as the matrix with a given row and
    /// column omitted.
    /// https://en.wikipedia.org/wiki/Minor_(linear_algebra)
    auto minor(size_t col, size_t row)() const{
        static assert(col < width, "Column index out of bounds.");
        static assert(row < height, "Row index out of bounds.");
        return Matrix!(width - 1, height - 1, T)(
            this.columns[0 .. col].varmap!(
                v => v.slice!(0, row).concat(v.slice!(row + 1, v.size))
            ).concat(
                this.columns[col + 1 .. $].varmap!(
                    v => v.slice!(0, row).concat(v.slice!(row + 1, v.size))
                )
            ).expand
        );
    }
    
    /// Rotate the contents of a matrix clockwise.
    /// `matrix.rotate!0` returns the matrix itself.
    /// `matrix.rotate!1` returns the matrix rotated clockwise by 90 degrees.
    /// `matrix.rotate!2` returns the matrix rotated clockwise by 180 degrees.
    /// `matrix.rotate!3` returns the matrix rotated clockwise by 270 degrees.
    auto rotate(size_t amount = 1)() const{
        static if(width == 0 && height == 0){
            return this;
        }else static if(width == 0 || height == 0){
            static if(amount % 2 == 0) return this;
            else return Matrix!(height, width, T).zero;
        }else{
            enum amountmod = amount % 4;
            static if(amountmod == 0){
                return this;
            }else static if(amountmod == 1){
                return Matrix!(height, width, T).Rows(
                    this.columns.varmap!(v => v.flip).expand
                );
            }else static if(amountmod == 2){
                return this.flipvh();
            }else{
                return Matrix!(height, width, T).Rows(Retro!(this.columns));
            }
        }
    }
    
    /// Mirror the contents of the matrix vertically and/or horizontally.
    auto flip(bool vertical, bool horizontal)() const{
        static if(vertical && horizontal){
            return this.flipvh;
        }else static if(vertical){
            return this.flipv;
        }else static if(horizontal){
            return this.fliph;
        }else{
            return this;
        }
    }
    /// Mirror the contents of the matrix vertically.
    auto flipv() const{
        static if(height <= 1){
            return this;
        }else{
            return typeof(this)(this.columns.varmap!(v => v.flip).expand);
        }
    }
    /// Mirror the contents of the matrix horizontally.
    auto fliph() const{
        static if(width <= 1){
            return this;
        }else{
            return typeof(this)(Retro!(this.columns));
        }
    }
    /// Mirror the contents of the matrix both vertically and horizontally.
    auto flipvh() const{
        static if(width <= 1){
            return this.flipv;
        }else static if(height <= 1){
            return this.fliph;
        }else{
            return typeof(this)(Retro!(this.columns).varmap!(v => v.flip).expand);
        }
    }
    
    /// Compare equality of two matrixes with optional epsilon.
    bool opEquals(X)(in Matrix!(width, height, X) mat) const{
        return this.equals(mat);
    }
    /// Ditto
    bool equals(X, E)(
        in Matrix!(width, height, X) mat, in E epsilon
    ) const if(isNumeric!E){
        assert(epsilon >= 0, "Epsilon must be non-negative.");
        foreach(i, _; Columns){
            if(!this.columns[i].equals(mat.columns[i], epsilon)) return false;
        }
        return true;
    }
    /// Ditto
    bool equals(X)(in Matrix!(width, height, X) mat) const{
        foreach(i, _; Columns){
            if(!this.columns[i].equals(mat.columns[i])) return false;
        }
        return true;
    }
    
    /// Compare equality of a 1-width matrix with a column vector, with
    /// optional epsilon.
    static if(width == 1) bool opEquals(X)(in Vector!(height, X) vec) const{
        return this.equals(vec);
    }
    /// Ditto
    static if(width == 1) bool equals(X, E)(
        in Vector!(height, X) vec, in E epsilon
    ) const if(isNumeric!E){
        assert(epsilon >= 0, "Epsilon must be non-negative.");
        return this[0].equals(vec, epsilon);
    }
    /// Ditto
    static if(width == 1) bool equals(X)(in Vector!(height, X) vec) const{
        return this[0].equals(vec);
    }
    
    /// Multiply two matrixes.
    /// https://en.wikipedia.org/wiki/Matrix_multiplication
    auto product(size_t Z, X)(in Matrix!(Z, width, X) mat) const{
        static if(this.width == 0 || this.height == 0 || mat.width == 0){
            return Matrix!(mat.width, this.height, typeof(T.init * mat.Value.init)).zero;
        }else{
            mixin(MatrixProductMixin(mat.width, this.height));
        }
    }
    /// Ditto
    auto opBinary(string op: "*", size_t Z, X)(in Matrix!(Z, width, X) mat) const{
        return this.product(mat);
    }
    /// Ditto
    static if(square) auto opOpAssign(string op: "*", X)(
        in Matrix!(width, height, X) mat
    ) const{
        this = cast(typeof(this)) this.product(mat);
        return this;
    }
    
    /// Multiply a matrix by a a column vector. Returns a vector.
    /// Essentially equivalent to `matrix.product(matrix(vector))[0]`.
    /// Multiplying a vector by a zero-width matrix produces the vector itself.
    auto product(X)(in Vector!(height, X) vec) const{
        static if(width == 0 || height == 0){
            return cast(Vector!(height, typeof(T.init * vec.Value.init))) vec;
        }else{
            return vector(this.rows.expand.varmap!(x => x.dot(vec)));
        }
    }
    /// Ditto
    auto opBinary(string op: "*", X)(in Vector!(height, X) vec) const{
        return this.product(vec);
    }
    /// Ditto
    auto opOpAssign(string op: "*", X)(in Vector!(height, X) vec){
        foreach(i, _; Columns) this.columns[i] *= vec[i];
        return this;
    }
    
    static if(width == 4 && height == 4){
        /// Get an orthographic projection matrix specifically for use with
        /// OpenGL rendering contexts.
        /// http://www.songho.ca/opengl/gl_projectionmatrix.html#ortho
        static auto glortho(N)(
            in N leftx, in N rightx,
            in N topy, in N bottomy,
            in N nearz = +1, in N farz = -1
        ) if(isNumeric!N){
            immutable dx = cast(T)(rightx - leftx);
            immutable dy = cast(T)(topy - bottomy);
            immutable dz = cast(T)(farz - nearz);
            return typeof(this)(
                +2 / dx, 0, 0, 0,
                0, +2 / dy, 0, 0,
                0, 0, -2 / dz, 0,
                (rightx + leftx) / -dx,
                (topy + bottomy) / -dy,
                (farz + nearz) / -dz, 1
            );
        }
        /// Get a perspective matrix specifically for use with
        /// OpenGL rendering contexts.
        /// http://www.songho.ca/opengl/gl_projectionmatrix.html#perspective
        static auto glperspective(N)(
            in N leftx, in N rightx,
            in N topy, in N bottomy,
            in N nearz = +1, in N farz = -1
        ) if(isNumeric!N){
            immutable dx = cast(T)(rightx - leftx);
            immutable dy = cast(T)(topy - bottomy);
            immutable dz = cast(T)(farz - nearz);
            immutable n2 = cast(T)(nearz + nearz);
            return typeof(this)(
                n2 / dx, 0, 0, 0,
                0, n2 / dy, 0, 0,
                (rightx + leftx) / dx,
                (topy + bottomy) / dy,
                (farz + nearz) / -dz, -1,
                0, 0, 2 * nearz * farz / -dz, 0
            );
        }
        /// Get an OpenGL perspective matrix given a field of view,
        /// aspect ratio, and near and far z.
        static auto glperspective(A, B, C)(
            in Angle!A fov, in B aspect, in C nearz, in C farz
        ) if(isNumeric!B && isNumeric!C){
            immutable height = fov.tan * nearz;
            immutable width = height * aspect;
            return typeof(this).glperspective(
                -width, width, -height, height, nearz, farz
            );
        }
    }
    
    /// Perform a component-wise binary operation with some number.
    auto opBinary(string op, N)(in N value) const if(isNumeric!N && (
        op == "+" || op == "-" || op == "*" || op == "/" || op == "^^"
    )){
        mixin(`alias X = typeof(T.init ` ~ op ~ ` value);`);
        return Matrix!(width, height, X)(this.columns.varmap!((v){
            mixin(`return v ` ~ op ~ ` value;`);
        }).expand);
    }
    /// Ditto
    auto opBinaryRight(string op: "*", N)(in N value) const if(isNumeric!N){
        return this.opBinary!(op)(value);
    }
    /// Ditto
    auto opOpAssign(string op, N)(in N value) if(isNumeric!N && (
        op == "+" || op == "-" || op == "*" || op == "/" || op == "^^"
    )){
        foreach(i, _; Columns) mixin(`this.columns[i] ` ~ op ~ `= value;`);
        return this;
    }
    
    /// Perform a component-wise binary operation with some other matrix
    /// of identical dimensions.
    /// Note that the "*" operator overload is a normal matrix multiplication
    /// operation. To perform a component-wise multiplication, use the
    /// `matrix.scale(matrix)` method.
    auto opBinary(string op, X)(in Matrix!(width, height, X) mat) const if(
        op == "+" || op == "-" || op == "/" || op == "^^"
    ){
        static if(width == 0 || height == 0){
            return Matrix!(width, height, typeof(T.init * mat.Value.init)).zero;
        }else{
            immutable zip = varzip(tuple(this.columns), tuple(mat.columns));
            return matrix(zip.expand.varmap!((x){
                mixin(`return x[0] ` ~ op ~ ` x[1];`);
            }).expand);
        }
    }
    /// Ditto
    auto opOpAssign(string op, X)(in Matrix!(width, height, X) mat) if(
        op == "+" || op == "-" || op == "/" || op == "^^"
    ){
        foreach(i, _; Columns) mixin(`this.columns[i] ` ~ op ~ `= mat.columns[i];`);
        return this;
    }
    
    /// Perform a component-wise multiplication of two matrixes.
    auto scale(X)(in Matrix!(width, height, X) mat) const{
        static if(width == 0 || height == 0){
            return Matrix!(width, height, typeof(T.init * mat.Value.init)).zero;
        }else{
            immutable zip = varzip(tuple(this.columns), tuple(mat.columns));
            return matrix(zip.expand.varmap!(x => x[0].scale(x[1])).expand);
        }
    }
    
    static if(width == 2 && height == 2){
        /// Get a two-dimensional rotation matrix.
        /// https://en.wikipedia.org/wiki/Rotation_matrix#In_two_dimensions
        /// TODO: Can this be generalized? (A: Probably?)
        static auto rotation(X)(in Angle!X angle){
            immutable s = angle.sin;
            immutable c = angle.cos;
            return typeof(this)(c, s, -s, c);
        }
        /// Ditto
        static auto rotation(R)(in R radians) if(isNumeric!R){
            return typeof(this).rotation(Angle!().Radians(radians));
        }
    }else static if(width == 3 && height == 3){
        /// Get a three-dimensional rotation matrix.
        /// https://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
        static auto rotation(X)(
            in Angle!X yaw, in Angle!X pitch, in Angle!X roll
        ){
            return (
                typeof(this).pitchrotation(pitch) *
                typeof(this).yawrotation(yaw) *
                typeof(this).rollrotation(roll)
            );
        }
        /// Ditto
        static auto rotation(R)(in R yaw, in R pitch, in R roll) if(isNumeric!R){
            return typeof(this)(
                Angle!().Radians(yaw), Angle!().Radians(pitch), Angle!().Radians(roll)
            );
        }
        /// Ditto
        static auto yawrotation(X)(in Angle!X pitch){
            immutable s = pitch.sin;
            immutable c = pitch.cos;
            return typeof(this)(c, 0, -s, 0, 1, 0, s, 0, c);
        }
        /// Ditto
        static auto pitchrotation(X)(in Angle!X roll){
            immutable s = roll.sin;
            immutable c = roll.cos;
            return typeof(this)(1, 0, 0, 0, c, s, 0, -s, c);
        }
        /// Ditto
        static auto rollrotation(X)(in Angle!X yaw){
            immutable s = yaw.sin;
            immutable c = yaw.cos;
            return typeof(this)(c, s, 0, -s, c, 0, 0, 0, 1);
        }
    }
    
    /// Cast to another matrix type.
    /// Truncates components when the width or height is smaller.
    /// Fills in bottommost or rightmost values with those of the identity
    /// matrix when the width or height is larger if both this and the
    /// target matrix type are square.
    /// Casting to a larger matrix type when this matrix is not square or the
    /// target matrix is not square is an invalid operation.
    auto opCast(To: Matrix!(W, H, X), size_t W, size_t H, X)() const{
        static if(W == width && H == height){
            return To(this.columns.varmap!(v => cast(To.Column) v).expand);
        }else static if(W <= width && H <= height){
            return To(this.columns[0 .. W].varmap!(v => To.Column(v)).expand);
        }else static if(this.square && To.square){
            return To(
                this.columns.varmap!(v => To.Column(v)).concat(
                    tuple(To.identity.columns[width .. $])
                ).expand
            );
        }else{
            static assert(false,
                "Cannot cast to a larger matrix when either type is not square."
            );
        }
    }
    
    /// Cast a single-column matrix to a column vector.
    static if(width == 1) auto opCast(To: Vector!(height, X), X)(){
        return cast(To) this.columns[0];
    }
    
    /// Get a two-dimensional slice of this matrix.
    auto slice(size_t xlow, size_t xhigh, size_t ylow, size_t yhigh)() const{
        static assert(
            xlow >= 0 && xhigh >= xlow && width >= xhigh &&
            ylow >= 0 && yhigh >= ylow && height >= yhigh,
            "Invalid matrix slice bounds."
        );
        static if(xhigh == xlow && yhigh == ylow){
            return Matrix!(0, 0, T).zero;
        }else static if(xhigh == xlow){
            return Matrix!(0, yhigh - ylow, T).zero;
        }else static if(yhigh == ylow){
            return Matrix!(xhigh - xlow, 0, T).zero;
        }else{
            return Matrix!(xhigh - xlow, yhigh - ylow, T)(
                this.columns[xlow .. xhigh].varmap!(v => v.slice!(ylow, yhigh)).expand
            );
        }
    }
    
    /// Scroll the components of the matrix.
    auto scroll(ptrdiff_t x, ptrdiff_t y)() const{
        static if(width == 0 || height == 0 || (width == 1 && height == 1)){
            return this;
        }else{
            enum xs = -x % cast(ptrdiff_t) width;
            enum ys = -y % cast(ptrdiff_t) height;
            enum xm = cast(size_t)(xs >= 0 ? xs : cast(ptrdiff_t) width + xs);
            enum ym = cast(size_t)(ys >= 0 ? ys : cast(ptrdiff_t) height + ys);
            static assert(xm < width && ym < height); // Verify assumption
            mixin(MatrixScrollMixin(width, height, xm, ym));
        }
    }
    
    /// Get the component at an X and Y coordinate.
    auto ref index(size_t x, size_t y)(){
        return this[x][y];
    }
    /// Ditto
    auto ref index(size_t x, size_t y)() const{
        return this[x][y];
    }
    /// Ditto
    auto ref index()(in size_t x, in size_t y){
        static const error = new IndexOutOfBoundsError();
        foreach(i, _; Columns){
            if(x == i){
                foreach(j, __; Column.Values){
                    if(y == j) return this[i][j];
                }
            }
        }
        throw error;
    }
    /// Ditto
    auto ref index()(in size_t x, in size_t y) const{
        static const error = new IndexOutOfBoundsError();
        foreach(i, _; Columns){
            if(x == i){
                foreach(j, __; Column.Values){
                    if(y == j) return this[i][j];
                }
            }
        }
        throw error;
    }
    
    /// Get a string representation. Output appears as a tuple of rows.
    string toString() const{
        return str(this.rows);
    }
    
    /// Get a pretty multi-line string representation.
    string pretty() const{
        string[] numbers;
        numbers.reserve(size);
        size_t longest = 1;
        foreach(i, _; Column.Values){
            foreach(j, __; Columns){
                immutable nstr = str(this[j][i]);
                numbers ~= nstr;
                longest = nstr.length > longest ? nstr.length : longest;
            }
        }
        string result = "";
        size_t index = 0;
        foreach(i, _; Column.Values){
            if(i != 0) result ~= "\n";
            foreach(j, __; Columns){
                if(j != 0) result ~= " ";
                if(numbers[index].length < longest){
                    foreach(k; 0 .. longest - numbers[index].length){
                        result ~= " ";
                    }
                }
                result ~= numbers[index];
                index++;
            }
        }
        return result;
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.test.assertthrows : assertthrows;
    // Sequence of types that a Matrix can legally be made from.
    alias Types = Aliases!(byte, short, int, long, float, double, real);
}

unittest{ /// isMatrix template
    static assert(isMatrix!(Matrix2f));
    static assert(isMatrix!(Matrix2i));
    static assert(isMatrix!(Matrix3f));
    static assert(isMatrix!(Matrix3i));
    static assert(isMatrix!(Matrix4f));
    static assert(isMatrix!(Matrix4i));
    static assert(isMatrix!(Matrix!(1, 2, int)));
    static assert(isMatrix!(2, Matrix2i));
    static assert(isMatrix!(3, Matrix3i));
    static assert(isMatrix!(4, Matrix4i));
    static assert(isMatrix!(2, 2, Matrix2i));
    static assert(isMatrix!(3, 4, Matrix!(3, 4, int)));
    static assert(!isMatrix!(int));
    static assert(!isMatrix!(void));
    static assert(!isMatrix!(Vector!(2, int)));
    static assert(!isMatrix!(2, int));
    static assert(!isMatrix!(2, void));
    static assert(!isMatrix!(2, Matrix3i));
    static assert(!isMatrix!(2, Matrix!(1, 2, int)));
    static assert(!isMatrix!(2, Matrix!(2, 1, int)));
    static assert(!isMatrix!(2, 2, Matrix3i));
    static assert(!isMatrix!(3, 4, Matrix!(4, 3, int)));
}

unittest{ /// Initialization and equality
    foreach(width; Aliases!(1, 2, 3)){
        foreach(height; Aliases!(1, 2, 3)){
            foreach(T; Aliases!(byte, int, long, double)){
                alias Mat = Matrix!(width, height, T);
                assert(Mat.zero == Mat.zero);
                assert(Mat(1) == Mat(1));
                assert(Mat(1) != Mat.zero);
                assert(Mat.zero != Mat(1));
                static if(width == height){
                    assert(Mat.identity == Mat.identity);
                    assert(Mat.zero != Mat.identity);
                    assert(Mat.identity != Mat.zero);
                }
            }
        }
    }
}

unittest{ /// Matrix equality
    assert(Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 4)));
    assert(Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 4), 1e-8));
    assert(Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 4 + 1e-16), 1e-8));
    assert(Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 4 - 1e-16), 1e-8));
    assert(!Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 5)));
    assert(!Matrix2f(1, 2, 3, 4).equals(Matrix2f(1, 2, 3, 5), 1e-8));
}

unittest{ /// One-width matrix equality with column vector
    assert(matrix(vector(1, 2, 3)) == vector(1, 2, 3));
    assert(matrix(vector(1, 2, 3)).equals(vector(1, 2, 3)));
    assert(matrix(vector(-3, -2, -1)).equals(vector(-3, -2, -1)));
    assert(!matrix(vector(1, 2, 3)).equals(vector(5, 5, 5)));
    assert(matrix(vector(1, 2, 3)).equals(vector(1, 2, 3 + 0e-12), 0e-8));
    assert(!matrix(vector(1, 2, 3)).equals(vector(1, 2, 4), 0e-8));
}

unittest{ /// Initialization via Rows/Cols
    auto mat = Matrix3!int.Rows(
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    );
    assert(mat[0][0] == 0);
    assert(mat[0][1] == 3);
    assert(mat[0][2] == 6);
    assert(mat[1][0] == 1);
    assert(mat[1][1] == 4);
    assert(mat[1][2] == 7);
    assert(mat[2][0] == 2);
    assert(mat[2][1] == 5);
    assert(mat[2][2] == 8);
    assert(mat.row!0 == vector(0, 1, 2));
    assert(mat.row!1 == vector(3, 4, 5));
    assert(mat.row!2 == vector(6, 7, 8));
    assert(mat.col!0 == vector(0, 3, 6));
    assert(mat.col!1 == vector(1, 4, 7));
    assert(mat.col!2 == vector(2, 5, 8));
    assert(mat.rows == tuple(
        vector(0, 1, 2),
        vector(3, 4, 5),
        vector(6, 7, 8),
    ));
    assert(mat.cols == tuple(
        vector(0, 3, 6),
        vector(1, 4, 7),
        vector(2, 5, 8),
    ));
    assert(mat == Matrix3!int.Cols(
        0, 3, 6,
        1, 4, 7,
        2, 5, 8,
    ));
    assert(mat == Matrix3!int.Rows(
        vector(0, 1, 2),
        vector(3, 4, 5),
        vector(6, 7, 8),
    ));
    assert(mat == Matrix3!int.Cols(
        vector(0, 3, 6),
        vector(1, 4, 7),
        vector(2, 5, 8),
    ));
}

unittest{ /// Initialize matrix with one row/column
    auto matr = Matrix!(4, 1, int)(1, 2, 3, 4);
    assert(matr[0][0] == 1);
    assert(matr[1][0] == 2);
    assert(matr[2][0] == 3);
    assert(matr[3][0] == 4);
    auto matc = Matrix!(1, 4, int)(1, 2, 3, 4);
    assert(matc[0][0] == 1);
    assert(matc[0][1] == 2);
    assert(matc[0][2] == 3);
    assert(matc[0][3] == 4);
}

unittest{ /// Set rows/columns
    auto mat = Matrix3!int.Rows(
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    );
    mat.row!0 = vector(10, 11, 12);
    assert(mat.row!0 == vector(10, 11, 12));
    mat.col!0 = vector(13, 14, 15);
    assert(mat.col!0 == vector(13, 14, 15));
    assert(mat == Matrix3!int.Rows(
        13, 11, 12,
        14, 4, 5,
        15, 7, 8,
    ));
    mat.setrows(
        vector(0, 1, 2),
        vector(3, 4, 5),
        vector(6, 7, 8),
    );
    assert(mat == Matrix3!int.Rows(
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    ));
    mat.setcols(
        vector(0, 1, 2),
        vector(3, 4, 5),
        vector(6, 7, 8),
    );
    assert(mat == Matrix3!int.Cols(
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    ));
}

unittest{ /// Casting to different component type
    Matrix2f matf = Matrix2f(1, 2, 3, 4);
    Matrix2i mati = cast(Matrix2i) matf;
    assert(mati == matf);
}

unittest{ /// Casting to a smaller size
    immutable mat3 = Matrix3i.Rows(
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    );
    assert(cast(Matrix2i) mat3 == Matrix2i.Rows(1, 2, 4, 5));
    assert(cast(Matrix!(2, 3, int)) mat3 == matrixrows!(2, 3)(1, 2, 4, 5, 7, 8));
    assert(cast(Matrix!(3, 2, int)) mat3 == matrixrows!(3, 2)(1, 2, 3, 4, 5, 6));
}

unittest{ /// Casting square matrix to a larger size
    immutable mat2 = Matrix2i.Rows(1, 2, 3, 4);
    assert(cast(Matrix3i) mat2 == Matrix3i.Rows(
        1, 2, 0,
        3, 4, 0,
        0, 0, 1,
    ));
    assert(cast(Matrix4i) mat2 == Matrix4i.Rows(
        1, 2, 0, 0,
        3, 4, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ));
}

unittest{ /// Casting single-column matrix to a column vector
    assert(cast(Vector!(1, int)) matrix(vector(1)) == vector(1));
    assert(cast(Vector!(2, int)) matrix(vector(1, 2)) == vector(1, 2));
    assert(cast(Vector!(3, int)) matrix(vector(1, 2, 3)) == vector(1, 2, 3));
}

unittest{ /// Zero-width and zero-height matrix
    auto mat = Matrix!(0, 0, int).zero;
    assert(mat == mat);
    assert(mat.identity == mat);
    assert(mat.rows is tuple());
    assert(mat.cols is tuple());
    assert(mat.equals(mat));
    assert(mat.equals(mat, 0));
    assert(mat.determinant == 1);
    assert(!mat.singular); // Correct consequence of determinant == 1 (I think?)
    assert(mat.transpose == mat);
    assert(mat.cofactor == mat);
    assert(mat.adjugate == mat);
    assert(mat.inverse == mat);
    foreach(n; Aliases!(0, 1, 2, 3, 4, 5)) assert(mat.rotate!n == mat);
    assert(mat.flipv == mat);
    assert(mat.fliph == mat);
    assert(mat.flipvh == mat);
    assert(mat.slice!(0, 0, 0, 0) is mat);
    assert(mat * mat == mat);
    assert(mat * vector!int() == vector!int());
    assert(mat + 2 == mat);
    assert(mat - 2 == mat);
    assert(mat * 2 == mat);
    assert(mat / 2 == mat);
    assert(mat ^^ 2 == mat);
    assert((mat += 2) == mat);
    assert((mat -= 2) == mat);
    assert((mat *= 2) == mat);
    assert((mat /= 2) == mat);
    assert((mat ^^= 2) == mat);
    assert(mat + mat == mat);
    assert(mat - mat == mat);
    assert(mat / mat == mat);
    assert(mat ^^ mat == mat);
    assert((mat += mat) == mat);
    assert((mat -= mat) == mat);
    assert((mat /= mat) == mat);
    assert((mat ^^= mat) == mat);
    assert(mat.scale(mat) == mat);
    assert(cast(Matrix!(0, 0, float)) mat == mat);
    assert(cast(Matrix4i) mat == Matrix4i.identity);
}

unittest{ /// Zero-width and non-zero-height matrix
    auto mat = Matrix!(0, 2, int).zero;
    auto rmat = Matrix!(2, 0, int).zero;
    assert(mat == mat);
    assert(mat.rows == tuple(vector!int(), vector!int()));
    assert(mat.cols == tuple());
    assert(mat.equals(mat));
    assert(mat.equals(mat, 0));
    assert(mat.transpose == rmat);
    foreach(n; Aliases!(0, 2, 4)) assert(mat.rotate!n == mat);
    foreach(n; Aliases!(1, 3, 5)) assert(mat.rotate!n == rmat);
    assert(mat.flipv == mat);
    assert(mat.fliph == mat);
    assert(mat.flipvh == mat);
    assert(mat.slice!(0, 0, 0, 0) is Matrix!(0, 0, int).zero);
    assert(mat.slice!(0, 0, 0, 1) is Matrix!(0, 1, int).zero);
    assert(mat * vector(1, 2) == vector(1, 2));
    assert(mat + 2 == mat);
    assert(mat - 2 == mat);
    assert(mat * 2 == mat);
    assert(mat / 2 == mat);
    assert(mat ^^ 2 == mat);
    assert((mat += 2) == mat);
    assert((mat -= 2) == mat);
    assert((mat *= 2) == mat);
    assert((mat /= 2) == mat);
    assert((mat ^^= 2) == mat);
    assert(mat + mat == mat);
    assert(mat - mat == mat);
    assert(mat / mat == mat);
    assert(mat ^^ mat == mat);
    assert((mat += mat) == mat);
    assert((mat -= mat) == mat);
    assert((mat /= mat) == mat);
    assert((mat ^^= mat) == mat);
    assert(mat.scale(mat) == mat);
    assert(cast(Matrix!(0, 2, float)) mat == mat);
    assert(cast(Matrix!(0, 1, int)) mat == Matrix!(0, 1, int).zero);
}

unittest{ /// Zero-height and non-zero-width matrix
    auto mat = Matrix!(2, 0, int).zero;
    auto rmat = Matrix!(0, 2, int).zero;
    assert(mat == mat);
    assert(mat.rows == tuple());
    assert(mat.cols == tuple(vector!int(), vector!int()));
    assert(mat.equals(mat));
    assert(mat.equals(mat, 0));
    assert(mat.transpose == rmat);
    foreach(n; Aliases!(0, 2, 4)) assert(mat.rotate!n == mat);
    foreach(n; Aliases!(1, 3, 5)) assert(mat.rotate!n == rmat);
    assert(mat.flipv == mat);
    assert(mat.fliph == mat);
    assert(mat.flipvh == mat);
    assert(mat.slice!(0, 0, 0, 0) is Matrix!(0, 0, int).zero);
    assert(mat.slice!(0, 1, 0, 0) is Matrix!(1, 0, int).zero);
    assert(mat * vector!int() == vector!int());
    assert(mat + 2 == mat);
    assert(mat - 2 == mat);
    assert(mat * 2 == mat);
    assert(mat / 2 == mat);
    assert(mat ^^ 2 == mat);
    assert((mat += 2) == mat);
    assert((mat -= 2) == mat);
    assert((mat *= 2) == mat);
    assert((mat /= 2) == mat);
    assert((mat ^^= 2) == mat);
    assert(mat + mat == mat);
    assert(mat - mat == mat);
    assert(mat / mat == mat);
    assert(mat ^^ mat == mat);
    assert((mat += mat) == mat);
    assert((mat -= mat) == mat);
    assert((mat /= mat) == mat);
    assert((mat ^^= mat) == mat);
    assert(mat.scale(mat) == mat);
    assert(cast(Matrix!(2, 0, float)) mat == mat);
    assert(cast(Matrix!(1, 0, int)) mat == Matrix!(1, 0, int).zero);
}

unittest{ /// Single-component matrix
    auto mat = Matrix!(1, 1, int)(2);
    assert(mat == mat);
    assert(mat.rows == tuple(vector(2)));
    assert(mat.cols == tuple(vector(2)));
    assert(mat.equals(mat));
    assert(mat.equals(mat, 0));
    assert(mat.determinant == 2);
    assert(!mat.singular);
    assert(mat.transpose == mat);
    foreach(n; Aliases!(0, 1, 2, 3, 4, 5)) assert(mat.rotate!n == mat);
    assert(mat.flipv == mat);
    assert(mat.fliph == mat);
    assert(mat.flipvh == mat);
    assert(mat.slice!(0, 1, 0, 1) is mat);
    assert(cast(Matrix!(1, 1, float)) mat == mat);
    assert(cast(Matrix4i) mat == Matrix4i.Rows(
        2, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ));
}

unittest{ /// Component-wise binary operations with numbers
    assert(Matrix2f(1, 2, 3, 4) + 2 == Matrix2f(3, 4, 5, 6));
    assert(Matrix2f(1, 2, 3, 4) - 2 == Matrix2f(-1, 0, 1, 2));
    assert(Matrix2f(1, 2, 3, 4) * 2 == Matrix2f(2, 4, 6, 8));
    assert(Matrix2f(1, 2, 3, 4) / 2 == Matrix2f(0.5, 1, 1.5, 2));
    assert(Matrix2f(1, 2, 3, 4) ^^ 2 == Matrix2f(1, 4, 9, 16));
    assert((Matrix2f(1, 2, 3, 4) += 2) == Matrix2f(3, 4, 5, 6));
    assert((Matrix2f(1, 2, 3, 4) -= 2) == Matrix2f(-1, 0, 1, 2));
    assert((Matrix2f(1, 2, 3, 4) *= 2) == Matrix2f(2, 4, 6, 8));
    assert((Matrix2f(1, 2, 3, 4) /= 2) == Matrix2f(0.5, 1, 1.5, 2));
    assert((Matrix2f(1, 2, 3, 4) ^^= 2) == Matrix2f(1, 4, 9, 16));
    assert(2 * Matrix2f(1, 2, 3, 4) == Matrix2f(2, 4, 6, 8));
}

unittest{ /// Component-wise binary operations with other matrixes
    assert(Matrix2i(1, 2, 3, 4) + Matrix2i(5, 3, 1, 0) == Matrix2i(6, 5, 4, 4));
    assert(Matrix2i(2, 3, 1, 0) - Matrix2i(1, 0, 3, 4) == Matrix2i(1, 3, -2, -4));
    assert(Matrix2i(4, 6, 8, 12) / Matrix2i(2) == Matrix2i(2, 3, 4, 6));
    assert(Matrix2i(1, 2, 3, 4) ^^ Matrix2i(2) == Matrix2i(1, 4, 9, 16));
    assert((Matrix2i(1, 2, 3, 4) += Matrix2i(5, 3, 1, 0)) == Matrix2i(6, 5, 4, 4));
    assert((Matrix2i(2, 3, 1, 0) -= Matrix2i(1, 0, 3, 4)) == Matrix2i(1, 3, -2, -4));
    assert((Matrix2i(4, 6, 8, 12) /= Matrix2i(2)) == Matrix2i(2, 3, 4, 6));
    assert((Matrix2i(1, 2, 3, 4) ^^= Matrix2i(2)) == Matrix2i(1, 4, 9, 16));
    assert(Matrix2i(1, 2, 3, 4).scale(Matrix2i(2, 3, 1, 0)) == Matrix2i(2, 6, 3, 0));
}

unittest{ /// Minor matrix
    immutable mat = Matrix3i.Rows(
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    );
    assert(mat.minor!(0, 0) == Matrix2i.Rows(4, 5, 7, 8));
    assert(mat.minor!(0, 1) == Matrix2i.Rows(1, 2, 7, 8));
    assert(mat.minor!(0, 2) == Matrix2i.Rows(1, 2, 4, 5));
    assert(mat.minor!(1, 0) == Matrix2i.Rows(3, 5, 6, 8));
    assert(mat.minor!(2, 0) == Matrix2i.Rows(3, 4, 6, 7));
}

unittest{ /// Slicing
    auto mat = Matrix!(3, 4, int).Rows(
        0x1, 0x2, 0x3,
        0x4, 0x5, 0x6,
        0x7, 0x8, 0x9,
        0xA, 0xB, 0xC,
    );
    assert(mat.slice!(0, 0, 0, 0) == Matrix!(0, 0, int)());
    assert(mat.slice!(0, 0, 0, 1) == Matrix!(0, 1, int)());
    assert(mat.slice!(0, 1, 0, 0) == Matrix!(1, 0, int)());
    assert(mat.slice!(0, 1, 0, 1) == matrix!(1, 1)(0x1));
    assert(mat.slice!(0, 1, 3, 4) == matrix!(1, 1)(0xA));
    assert(mat.slice!(2, 3, 0, 1) == matrix!(1, 1)(0x3));
    assert(mat.slice!(2, 3, 3, 4) == matrix!(1, 1)(0xC));
    assert(mat.slice!(0, 2, 0, 2) == matrixrows!(2, 2)(0x1, 0x2, 0x4, 0x5));
    assert(mat.slice!(1, 3, 2, 4) == matrixrows!(2, 2)(0x8, 0x9, 0xB, 0xC));
}

unittest{ /// Indexing
    auto mat = Matrix2i.Rows(
        1, 2,
        3, 4,
    );
    // Access
    assert(mat[0][0] == 1);
    assert(mat.index!(0, 0) == 1);
    assert(mat.index!(0, 1) == 3);
    assert(mat.index!(1, 0) == 2);
    assert(mat.index!(1, 1) == 4);
    assert(mat.index(0, 0) == 1);
    assert(mat.index(0, 1) == 3);
    assert(mat.index(1, 0) == 2);
    assert(mat.index(1, 1) == 4);
    // Assignment
    mat[0][0] = 5;
    assert(mat == Matrix2i.Rows(5, 2, 3, 4));
    mat.index!(1, 0) = 6;
    assert(mat == Matrix2i.Rows(5, 6, 3, 4));
    mat.index(0, 1) = 7;
    assert(mat == Matrix2i.Rows(5, 6, 7, 4));
    // Out-of-bounds indexes
    static assert(!is(typeof({
        mat[2][2];
    })));
    static assert(!is(typeof({
        mat.index!(2, 2);
    })));
    assertthrows!IndexOutOfBoundsError({
        mat.index(2, 2);
    });
}

unittest{ /// Scrolling
    auto mat = Matrix3i.Rows(
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    );
    assert(mat.scroll!(0, 0) == mat);
    assert(mat.scroll!(3, 3) == mat);
    assert(mat.scroll!(-3, -3) == mat);
    assert(mat.scroll!(1, 0) == Matrix3i.Rows(
        3, 1, 2,
        6, 4, 5,
        9, 7, 8,
    ));
    assert(mat.scroll!(0, 1) == Matrix3i.Rows(
        7, 8, 9,
        1, 2, 3,
        4, 5, 6,
    ));
    assert(mat.scroll!(-1, 0) == Matrix3i.Rows(
        2, 3, 1,
        5, 6, 4,
        8, 9, 7,
    ));
    assert(mat.scroll!(0, -1) == Matrix3i.Rows(
        4, 5, 6,
        7, 8, 9,
        1, 2, 3,
    ));
}

unittest{ /// Transpose
    // Square matrix
    assert(Matrix2i(1, 2, 3, 4).transpose == Matrix2i(1, 3, 2, 4));
    assert(Matrix2i(1, 3, 2, 4).transpose == Matrix2i(1, 2, 3, 4));
    // Not square
    assert(
        matrix(vector(1, 3, 5), vector(2, 4, 6)).transpose ==
        matrix(vector(1, 2), vector(3, 4), vector(5, 6))
    );
}

unittest{ /// Flip
    immutable mat = Matrix!(3, 4, int).Rows(
        0x1, 0x2, 0x3,
        0x4, 0x5, 0x6,
        0x7, 0x8, 0x9,
        0xA, 0xB, 0xC,
    );
    assert(mat.fliph == Matrix!(3, 4, int).Rows(
        0x3, 0x2, 0x1,
        0x6, 0x5, 0x4,
        0x9, 0x8, 0x7,
        0xC, 0xB, 0xA,
    ));
    assert(mat.flipv == Matrix!(3, 4, int).Rows(
        0xA, 0xB, 0xC,
        0x7, 0x8, 0x9,
        0x4, 0x5, 0x6,
        0x1, 0x2, 0x3,
    ));
    assert(mat.flipvh == Matrix!(3, 4, int).Rows(
        0xC, 0xB, 0xA,
        0x9, 0x8, 0x7,
        0x6, 0x5, 0x4,
        0x3, 0x2, 0x1,
    ));
    assert(mat.flip!(false, false) == mat);
    assert(mat.flip!(false, true) == mat.fliph);
    assert(mat.flip!(true, false) == mat.flipv);
    assert(mat.flip!(true, true) == mat.flipvh);
}

unittest{ /// Rotate matrix components
    immutable mat = Matrix!(3, 4, int).Rows(
        0x1, 0x2, 0x3,
        0x4, 0x5, 0x6,
        0x7, 0x8, 0x9,
        0xA, 0xB, 0xC,
    );
    assert(mat.rotate!0 == mat);
    assert(mat.rotate!1 == Matrix!(4, 3, int).Rows(
        0xA, 0x7, 0x4, 0x1,
        0xB, 0x8, 0x5, 0x2,
        0xC, 0x9, 0x6, 0x3,
    ));
    assert(mat.rotate!2 == mat.flipvh);
    assert(mat.rotate!3 == Matrix!(4, 3, int).Rows(
        0x3, 0x6, 0x9, 0xC,
        0x2, 0x5, 0x8, 0xB,
        0x1, 0x4, 0x7, 0xA,
    ));
    assert(mat.rotate!4 == mat);
    assert(mat.rotate!5 == mat.rotate!1);
    assert(mat.rotate!6 == mat.rotate!2);
    assert(mat.rotate!7 == mat.rotate!3);
}

unittest{ /// Determinant
    // http://www.mathwords.com/d/determinant.htm
    assert(Matrix2i.Rows(1, 2, 3, 4).determinant == -2);
    assert(Matrix3i.Rows(
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    ).determinant == 0);
}

unittest{ /// Cofactor matrix
    // http://www.mathwords.com/c/cofactor_matrix.htm
    // http://www.mathwords.com/a/adjoint.htm
    // http://comnuan.com/cmnn01013/
    auto mat = Matrix3i.Rows(
        1, 2, 3,
        0, 4, 5,
        1, 0, 6,
    );
    assert(mat.cofactor == Matrix3i.Rows(
        24, 5, -4,
        -12, 3, 2,
        -2, -5, 4,
    ));
    assert(mat.adjugate == Matrix3i.Rows(
        24, -12, -2,
        5, 3, -5,
        -4, 2, 4,
    ));
}

unittest{ /// Inversion of nonsingular input
    // http://www.mathwords.com/i/inverse_of_a_matrix.htm
    auto mat2 = Matrix2i.Rows(
        4, 3,
        3, 2,
    );
    assert(!mat2.singular);
    assert(mat2.inverse == Matrix2i.Rows(
        -2, 3,
        3, -4,
    ));
    auto mat3 = Matrix3f.Rows(
        1, 2, 3,
        0, 4, 5,
        1, 0, 6,
    );
    assert(!mat3.singular);
    assert(mat3.inverse.equals(Matrix3f.Rows(
        12, -6, -1,
        2.5, 1.5, -2.5,
        -2, 1, 2,
    ) / 11, 1e-8));
}

unittest{ /// Inversion of singular input
    // http://www.mathwords.com/s/singular_matrix.htm
    auto mat = Matrix2i.Rows(2, 6, 1, 3);
    assert(mat.singular);
    assert(mat.inverse == mat.identity);
}

unittest{ /// Multiply matrixes
    // https://www.mathsisfun.com/algebra/matrix-multiplying.html
    // http://www.bluebit.gr/matrix-calculator/multiply.aspx
    assert(matrixrows(
        vector(1, 2, 3),
        vector(4, 5, 6),
    ) * matrixrows(
        vector(7, 8),
        vector(9, 10),
        vector(11, 12),
    ) == matrixrows(
        vector(58, 64),
        vector(139, 154),
    ));
    assert(matrixrows!(3, 1)(
        3, 4, 2,
    ) * matrixrows!(4, 3)(
        13, 9, 7, 15,
        8, 7, 4, 6,
        6, 4, 0, 3,
    ) == matrixrows!(4, 1)(
        83, 63, 37, 75,
    ));
}

unittest{ /// Multiply matrix by vector
    immutable a = Matrix3i(1, 2, 3, 4, 5, 6, 7, 8, 9);
    immutable b = Vector!(3, int)(1, -2, 0);
    assert(a * b == a * matrix(b));
}

unittest{ /// Rotation matrixes
    // TODO
}

unittest{ /// OpenGL orthographic matrix
    // TODO: More thorough testing
    assert(Matrix4f.glortho(0, 800, 0, 600).equals(
        Matrix4f.Rows(
            0.0025, 0, 0, -1,
            0, -0.0033, 0, 1,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ), 1e-4
    ));
}

unittest{ /// OpenGL perspective matrix
    // TODO
}
