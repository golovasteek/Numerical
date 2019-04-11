//
//  Brent.swift
//  Numerical
//
//  Created by Adam Roberts on 3/22/19.
//

import Foundation

/// Van Wijngaarden-Dekker-Brent root finding method
///
/// This method attempts to use inverse quadratic interpolation on each
/// step, but if that goes beyond the brackets it falls back on bisection.
///
/// Numerical Recipes §9.3
public func brentRoot(f: @escaping (Double) -> Double, a: Double, b: Double, fa: Double, fb: Double, epsilon: Double) -> Double {
    let maxIter = 50
    
    // start out c equal to b
    let c = b
    let fc = fb
    
    // initial run of bookkeeping
    let (a0,b0,c0,fa0,fb0,fc0,d0,e0,xm,tol1) = brentBookkeeping(a: a, b: b, c: c, fa: fa, fb: fb, fc: fc, d: 0, e: 9999, epsilon: epsilon, tol: epsilon)

    let r = (0..<maxIter).lazy.scan( (state: (a: a0, b: b0, c: c0, fa: fa0, fb: fb0, fc: fc0, d: d0, e: e0, xm: xm, tol1: tol1), guess: fb0) ) { arg0, i in
        let (a0,b0,c0,fa0,fb0,fc0,d0,e0,xm,tol1) = arg0.state
        let (a1,b1,c1,fa1,fb1,fc1,d1,e1) = brentStep(f: f, a: a0, b: b0, c: c0, fa: fa0, fb: fb0, fc: fc0, d: d0, e: e0, xm: xm, tol1: tol1)
        let state1 = brentBookkeeping(a: a1, b: b1, c: c1, fa: fa1, fb: fb1, fc: fc1, d: d1, e: e1, epsilon: epsilon, tol: epsilon)
        return (state: state1, guess: state1.b)
        }.converge { s1, s2 in abs(s2.state.xm) <= s2.state.tol1 || abs(s2.state.fb) <= epsilon }
    guard let res = r else { return .nan }
    return res.guess
}

func brentBookkeeping(a: Double, b: Double, c: Double, fa: Double, fb: Double, fc: Double, d: Double, e: Double, epsilon: Double, tol: Double) -> (a: Double, b: Double, c: Double, fa: Double, fb: Double, fc: Double, d: Double, e: Double, xm: Double, tol1: Double) {
    let (c_,fc_,d_,e_) = (fb > 0.0 && fc > 0.0) || (fb < 0.0 && fc < 0.0) ? (a,fa,b - a,b - a) : (c,fc,d,e)
    let (a0,b0,c0,fa0,fb0,fc0) = abs(fc_) < abs(fb) ? (b,c_,b,fb,fc_,fb) : (a,b,c_,fa,fb,fc_)
    let xm = (c0 - b0) * 0.5
    let tol1 = 2 * epsilon * abs(b0) + 0.5 * tol
    return (a0,b0,c0,fa0,fb0,fc0,d_,e_,xm,tol1)
}

func brentStep(f: (Double) -> Double, a: Double, b: Double, c: Double, fa: Double, fb: Double, fc: Double, d: Double, e: Double, xm: Double, tol1: Double) -> (a: Double, b: Double, c: Double, fa: Double, fb: Double, fc: Double, d: Double, e: Double) {
    let (d1,e1): (Double, Double) = {
        // Check if last step moved enough and that it moved closer
        if abs(e) >= tol1 && abs(fa) > abs(fb) {
            
            // inverse quadratic interpolation
            let s = fb / fa
            let (p_,q_): (Double, Double) = {
                if a == c {
                    let p = 2 * xm * s
                    let q = 1 - s
                    return (p,q)
                } else {
                    let t = fa / fc
                    let r = fb / fc
                    let p = s * (2 * xm * t * (t - r) - (b - a) * (r - 1))
                    let q = (t - 1) * (r - 1) * (s - 1)
                    return (p,q)
                }
            }()
            let q = p_ > 0 ? -q_ : q_
            let p = abs(p_)

            // check if interpolation is within bounds
            let min1 = 3 * xm * q - abs(tol1 * q)
            let min2 = abs(e * q)
            if 2 * p < min(min1,min2) {
                return (p / q, d)
            }
        }
        // Otherwise go with bisection
        return (xm, xm)
    }()
    let a1 = b
    let fa1 = fb
    let b1 = abs(d1) > tol1 ? b + d1 : b + Double(signOf: xm, magnitudeOf: tol1)
    let fb1 = f(b1)
    return (a: a1, b: b1, c: c, fa: fa1, fb: fb1, fc: fc, d: d1, e: e1)
}
