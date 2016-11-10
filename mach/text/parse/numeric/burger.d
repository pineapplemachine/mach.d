// Free-format floating point printer
// http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.67.4438&rep=rep1&type=pdf
// https://web.archive.org/web/20100324065255/http://www.cs.indiana.edu/~burger/fp/index.html
// https://web.archive.org/web/20100324060707/http://www.cs.indiana.edu/~burger/fp/free.c
// Credit Robert G. Burger and R. Kent Dybvig

// Translated from C to D by Sophie Kirschner
// Comments prefixed with "Sophie:" written by Sophie Kirschner,
// all others are present in the original C code.

// Thanks to this code for filling in some missing pieces of the original C code.
// https://bugs.python.org/file8910/short_float_repr.diff

// The license for the translated C code is as follows:
//
// All software © 1996 Robert G. Burger.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software, to deal in the software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the software.
//
// The software is provided “as is,” without warranty of any kind, express or
// implied, including but not limited to the warranties of merchantability,
// fitness for a particular purpose and noninfringement. In no event shall the
// author be liable for any claim, damages or other liability, whether in an
// action of contract, tort or otherwise, arising from, out of or in connection
// with the software or the use or other dealings in the software.



module mach.text.parse.numeric.burger;

private:

import mach.math.floats : fextractsgn, fextractexp, fextractsig;

public:



alias Bigit = ulong;
enum BIGSIZE = 24;
enum MIN_E = -1074;  // Sophie: Function of min biased exponent and mantissa size
enum MAX_FIVE = 325;
enum B_P1 = ulong(1) << 52;
enum bias = 1023;
enum bitstoright = 52;



struct Bignum{
    int l;
    Bigit[BIGSIZE] d;
    
    /+
    string toString() const{
        import mach.text.parse.numeric.integrals : writehex;
        string str = "";
        for(int i = this.l; i >= 0; i--){
            str ~= writehex(this.d[i]);
        }
        return str;
    }
    +/
}

Bignum five[MAX_FIVE];



/// Sophie: Previously known as `free_init`.
/// Calculates powers of 5 and stores them in a table.
static this(){
    int five_idx = 1;
    int l = 0;
    five[0].l = 0;
    five[0].d[0] = 5;
    for(int n = MAX_FIVE - 1; n > 0; n--){
        Bigit k = 0;
        int p = 0;
        for(int i = l; i >= 0; i--){
            five[five_idx].d[p] = mul(five[five_idx - 1].d[p], 5, k);
            p++;
        }
        if(k != 0){
            five[five_idx].d[p] = k;
            l++;
        }
        five[five_idx].l = l;
        five_idx++;
    }
}



/// Sophie: Implements addition with `k` representing overflow in and out.
auto add(in Bigit x, in Bigit y, ref bool k){
    Bigit z = void;
    if(k){
        z = x + y + 1;
        k = (z <= x);
    }else{
        z = x + y;
        k = (z < x);
    }
    return z;
}

/// Sophie: Implements subtraction with `k` representing underflow in and out.
auto sub(in Bigit x, in Bigit y, ref bool b){
    Bigit z = void;
    if(b){
        z = x - y - 1;
        b = (y >= x);
    }else{
        z = x - y;
        b = (y > x);
    }
    return z;
}

/// Sophie: Implements multiply with `k` representing overflow in and out.
auto mul(in Bigit x, in Bigit y, ref Bigit k){
    immutable low = (x & uint.max) * y + k;
    immutable high = (x >> 32) * y + (low >> 32);
    k = high >> 32;
    Bigit z = (low & uint.max) | (high << 32);
    return z;
}

auto sll(in Bigit x, in Bigit y, ref Bigit k){
    Bigit z = (x << y) | k;
    k = x >> (64 - y);
    return z;
}



/// Sophie: Multiplies a Bignum by 10 in-place.
auto mul10(ref Bignum x){
    int p = 0;
    Bigit k = 0;
    for(int i = x.l; i >= 0; i--){
        x.d[p] = mul(x.d[p], 10, k);
        p++;
    }
    if(k != 0){
        x.d[p] = k;
        x.l++;
    }
}

auto big_short_mul(in Bignum x, in Bigit y){
    Bignum z = void;
    Bigit k = 0;
    int p = 0;
    z.l = x.l;
    immutable high = y >> 32;
    immutable low = y & uint.max;
    for(int i = x.l; i >= 0; i--, p++){
        immutable xlow = x.d[p] & uint.max;
        immutable xhigh = x.d[p] >> 32;
        immutable z0 = (xlow * low) + k; // Cout is (z0 < k)
        Bigit t = xhigh * low;
        Bigit z1 = (xlow * high) + t;
        Bigit c = (z1 < t);
        t = z0 >> 32;
        z1 += t;
        c += (z1 < t);
        z.d[p] = (z1 << 32) | (z0 & uint.max);
        k = (xhigh * high) + (c << 32) + (z1 >> 32) + (z0 < k);
    }
    if(k != 0){
        z.d[p] = k;
        z.l++;
    }
    return z;
}

int estimate(in int n){
    if(n < 0){
        return cast(int)(n*0.3010299956639812);
    }else{
        return cast(int)(n*0.3010299956639811) + 1;
    }
}

/// Sophie: Returns `1 << y` as a Bignum.
auto one_shift_left(in int y){
    immutable n = y / 64;
    immutable m = y % 64;
    Bignum z;
    z.l = n;
    z.d[n] = (cast(Bigit) 1) << m;
    return z;
}

auto short_shift_left(in Bigit x, in int y){
    immutable n = y / 64;
    immutable m = y % 64;
    Bignum z;
    z.l = n;
    if(m == 0){
        z.d[n] = x;
    }else{
        immutable high = x >> (64 - m);
        z.d[n] = x << m;
        if(high != 0){
            z.d[n + 1] = high;
            z.l++;
        }
    }
    return z;
}

auto big_shift_left(in Bignum x, in int y){
    immutable n = y / 64;
    immutable m = y % 64;
    Bignum z;
    z.l = x.l + n;
    if(m == 0){
        int p = 0;
        for(int i = x.l; i >= 0; i--){
            z.d[p] = x.d[p];
            p++;
        }
    }else{
        int p = 0;
        Bigit k = 0;
        for(int i = x.l; i >= 0; i--){
            z.d[p] = sll(x.d[p], m, k);
            p++;
        }
        if(k != 0){
            z.d[p] = k;
            z.l++;
        }
    }
    return z;
}

int big_comp(in Bignum x, in Bignum y){
    if(x.l > y.l){
        return 1;
    }else if(x.l < y.l){
        return -1;
    }else{
        int p = x.l;
        for(int i = x.l; i >= 0; i--){
            if(x.d[p] > y.d[p]){
                return 1;
            }else if(x.d[p] < y.d[p]){
                return -1;
            }
            p--;
        }
    }
    return 0;
}

auto sub_big(in Bignum x, in Bignum y){
    Bignum z;
    bool b = 0;
    int p = 0;
    int i = void;
    for(i = y.l; i >= 0; i--){
        z.d[p] = sub(x.d[p], y.d[p], b);
        p++;
    }
    for(i = x.l - y.l; b && i > 0; i--){
        z.d[p] = x.d[p] - 1;
        b = (z.d[p] == 0);
        p++;
    }
    while(i > 0){
        z.d[p] = x.d[p];
        i--;
        p++;
    }
    if(b){
        // Sophie: Represents an error state, i.e. x < y
        assert(false);
    }else{
        z.l = x.l;
        // Sophie: This loop altered from the original C to include a bounds
        // check for p.
        while((p > 0) && (z.d[--p] == 0)){
            z.l--;
        }
        return z;
    }
}

Bignum add_big(in Bignum x, in Bignum y){
    if(y.l > x.l){
        return add_big(y, x);
    }else{
        Bignum z;
        bool k = 0;
        size_t p = 0;
        int i;
        for(i = y.l; i >= 0; i--){
            z.d[p] = add(x.d[p], y.d[p], k);
            p++;
        }
        for(i = x.l - y.l; k && i > 0; i--){
            z.d[p] = x.d[p] + 1;
            k = (z.d[p] == 0);
            p++;
        }
        while(i > 0){
            z.d[p] = x.d[p];
            i--;
            p++;
        }
        if(k){
            z.d[p] = 1;
            z.l = x.l + 1;
        }else{
            z.l = x.l;
        }
        return z;
    }
}

/// Sophie: Effectively returns `big_comp(add_big(r, m), s)`
int add_cmp(in Bignum r, in Bignum m, in Bignum s){
    immutable suml = r.l >= m.l ? r.l : m.l;
    if((s.l > suml + 1) || ((s.l == suml + 1) && (s.d[s.l] > 1))){
        return -1;
    }else if(s.l < suml){
        return 1;
    }else{
        immutable sum = add_big(r, m);
        return big_comp(sum, s);
    }
}

int qr(
    ref Bignum r, in Bignum s,
    in Bignum s2, in Bignum s3, in Bignum s4, in Bignum s5,
    in Bignum s6, in Bignum s7, in Bignum s8, in Bignum s9
){
    if(big_comp(r, s5) < 0){
        if(big_comp(r, s2) < 0){
            if(big_comp(r, s) < 0){
                return 0;
            }else{
                r = sub_big(r, s);
                return 1;
            }
        }else if(big_comp(r, s3) < 0){
            r = sub_big(r, s2);
            return 2;
        }else if(big_comp(r, s4) < 0){
            r = sub_big(r, s3);
            return 3;
        }else{
            r = sub_big(r, s4);
            return 4;
        }
    }else if(big_comp(r, s7) < 0){
        if(big_comp(r, s6) < 0){
            r = sub_big(r, s5);
            return 5;
        }else{
            r = sub_big(r, s6);
            return 6;
        }
    }else if(big_comp(r, s9) < 0){
        if(big_comp(r, s8) < 0){
            r = sub_big(r, s7);
            return 7;
        }else{
            r = sub_big(r, s8);
            return 8;
        }
    }else{
        r = sub_big(r, s9);
        return 9;
    }
}



/// Sophie: Represents the result of evaluating Burger's algorithm.
struct DragonResult{
    /// Sophie: When true, the value was negative.
    bool sign;
    /// Sophie: Contains as a string digits comprising the value.
    string digits;
    /// Sophie: Effectively represents the index at which to insert '.'.
    /// When k < 0, that many zeros precede the digits in the string,
    /// including the single zero to the left of the decimal point.
    /// When k == 0, the decimal point belongs to the right of the first digit.
    /// When (k >= digits.length), (digits.length - k + 1) zeros follow the
    /// digits in the string, not including zeros to the right of the decimal
    /// point.
    int k;
}

DragonResult dragon(in double v){
    // decompose float into sign, mantissa & exponent
    immutable sign = fextractsgn(v);
    immutable unbiasede = fextractexp(v);
    immutable fraw = fextractsig(v);
    int e = void;
    Bigit f = void;
    if(unbiasede != 0){
        e = unbiasede - bias - bitstoright;
        f = fraw | B_P1;
    }else{
        // denormalized
        e = 1 - bias - bitstoright;
        f = fraw;
    }
    
    if(f == 0){
        return DragonResult(sign, "0", 0);
    }
    
    immutable int ruf = !(f & 1); // ruf = (even? f)
    
    // Compute the scaling factor estimate, k
    int k = void;
    if(e > MIN_E){
        k = estimate(e + 52);
    }else{
        int n = e + 52;
        Bigit y = B_P1;
        while(f < y){
            y >>= 1;
            n--;
        }
        k = estimate(n);
    }
    
    bool use_mp = void;
    int f_n = void;
    int s_n = void;
    int m_n = void;
    if(e >= 0){
        m_n = e;
        if(f != B_P1){
            use_mp = 0;
            f_n = e + 1;
            s_n = 1;
        }else{
            use_mp = 1;
            f_n = e + 2;
            s_n = 2;
        }
    }else{
        m_n = 0;
        if((e == MIN_E) || (f != B_P1)){
            use_mp = 0;
            f_n = 1;
            s_n = 1 - e;
        }else{
            use_mp = 1;
            f_n = 2;
            s_n = 2 - e;
        }
    }
    
    // Scale it!
    bool qr_shift;
    Bignum R, S, MP, MM;
    if(k == 0){
        R = short_shift_left(f, f_n);
        S = one_shift_left(s_n);
        MM = one_shift_left(m_n);
        if(use_mp) MP = one_shift_left(m_n + 1);
        qr_shift = 1;
    }else if(k > 0){
        s_n += k;
        if(m_n >= s_n){
            f_n -= s_n;
            m_n -= s_n;
            s_n = 0;
        }else{
            f_n -= m_n;
            s_n -= m_n;
            m_n = 0;
        }
        R = short_shift_left(f, f_n);
        S = big_shift_left(five[k - 1], s_n);
        MM = one_shift_left(m_n);
        if(use_mp) MP = one_shift_left(m_n + 1);
        qr_shift = 0;
    }else{
        immutable power = five[-k - 1];
        s_n += k;
        S = big_short_mul(power, f);
        R = big_shift_left(S, f_n);
        S = one_shift_left(s_n);
        MM = big_shift_left(power, m_n);
        if(use_mp) MP = big_shift_left(power, m_n + 1);
        qr_shift = 1;
    }
    
    // fixup
    if(add_cmp(R, use_mp ? MP : MM, S) <= -ruf){
        k--;
        mul10(R);
        mul10(MM);
        if(use_mp) mul10(MP);
    }
    
    int sl = void;
    int slr = void;
    Bignum S2, S3, S4, S5, S6, S7, S8, S9;
    if(qr_shift){
        sl = s_n / 64;
        slr = s_n % 64;
    }else{
        S2 = big_shift_left(S, 1);
        S3 = add_big(S2, S);
        S4 = big_shift_left(S2, 1);
        S5 = add_big(S4, S);
        S6 = add_big(S4, S2);
        S7 = add_big(S4, S3);
        S8 = big_shift_left(S4, 1);
        S9 = add_big(S8, S);
    }
    
    int d = void;
    bool tc1 = void;
    bool tc2 = void;
    string buf = "";
    
    again:
    
    if(qr_shift){ // Take advantage of the fact that S = (ash 1 s_n)
        if(R.l < sl){
            d = 0;
        }else if(R.l == sl){
            d = cast(int)(R.d[sl] >> slr);
            R.d[sl] &= (Bigit(1) << slr) - 1;
            while((R.l > 0) && (R.d[R.l] == 0)) R.l--;
        }else{
            d = cast(int)((R.d[sl + 1] << (64 - slr)) | (R.d[sl] >> slr));
            R.d[sl] &= (Bigit(1) << slr) - 1;
            R.l = sl;
            while(R.d[R.l] == 0) R.l--;
        }
    }else{ // We need to do quotient-remainder
        d = qr(R, S, S2, S3, S4, S5, S6, S7, S8, S9);
    }
    
    tc1 = big_comp(R, MM) < ruf;
    tc2 = add_cmp(R, use_mp ? MP : MM, S) > -ruf;
    if(!tc1){
        if(!tc2){
            mul10(R);
            mul10(MM);
            if(use_mp) mul10(MP);
            buf ~= d + '0';
            goto again;
        }else{
            buf ~= d + 1 + '0';
        }
    }else{
        if(!tc2){
            buf ~= d + '0';
        }else{
            MM = big_shift_left(R, 1);
            if(big_comp(MM, S) == -1){
                buf ~= d + '0';
            }else{
                buf ~= d + 1 + '0';
            }
        }
    }
    
    return DragonResult(sign, buf, k);
}



unittest{
    {
        auto result = dragon(0);
        assert(result.sign == 0);
        assert(result.digits == "0");
        assert(result.k == 0);
    }{
        auto result = dragon(1);
        assert(result.sign == 0);
        assert(result.digits == "1");
        assert(result.k == 0);
    }{
        auto result = dragon(-1);
        assert(result.sign == 1);
        assert(result.digits == "1");
        assert(result.k == 0);
    }{
        auto result = dragon(123.456);
        assert(result.sign == 0);
        assert(result.digits == "123456");
        assert(result.k == 2);
    }{
        auto result = dragon(69.6969);
        assert(result.sign == 0);
        assert(result.digits == "696969");
        assert(result.k == 1);
    }{
        auto result = dragon(0.00123);
        assert(result.sign == 0);
        assert(result.digits == "123");
        assert(result.k == -3);
    }{
        auto result = dragon(4560);
        assert(result.sign == 0);
        assert(result.digits == "456");
        assert(result.k == 3);
    }{
        auto result = dragon(9.001e-4);
        assert(result.sign == 0);
        assert(result.digits == "9001");
        assert(result.k == -4);
    }{
        auto result = dragon(1.79769e+308); // double.max
        assert(result.sign == 0);
        assert(result.digits == "179769");
        assert(result.k == 308);
    }{
        auto result = dragon(2.22507e-308); // double.min_normal
        assert(result.sign == 0);
        assert(result.digits == "222507");
        assert(result.k == -308);
    }
}
