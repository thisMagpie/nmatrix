/////////////////////////////////////////////////////////////////////
// = NMatrix
//
// A linear algebra library for scientific computation in Ruby.
// NMatrix is part of SciRuby.
//
// NMatrix was originally inspired by and derived from NArray, by
// Masahiro Tanaka: http://narray.rubyforge.org
//
// == Copyright Information
//
// SciRuby is Copyright (c) 2010 - 2014, Ruby Science Foundation
// NMatrix is Copyright (c) 2012 - 2014, John Woods and the Ruby Science Foundation
//
// Please see LICENSE.txt for additional copyright notices.
//
// == Contributing
//
// By contributing source code to SciRuby, you agree to be bound by
// our Contributor Agreement:
//
// * https://github.com/SciRuby/sciruby/wiki/Contributor-Agreement
//
// == imax.h
//
// BLAS level 1 function imax.
//

#ifndef IMAX_H
#define IMAX_H

namespace nm { namespace math {

template<typename DType>
inline int imax(const int n, const DType *x, const int incx) {

  if (n < 1 || incx <= 0) {
    return -1;
  }
  if (n == 1) {
    return 0;
  }

  DType dmax;
  int imax = 0;

  if (incx == 1) { // if incrementing by 1

    dmax = abs(x[0]);

    for (int i = 1; i < n; ++i) {
      if (std::abs(x[i]) > dmax) {
        imax = i;
        dmax = std::abs(x[i]);
      }
    }

  } else { // if incrementing by more than 1

    dmax = std::abs(x[0]);

    for (int i = 1, ix = incx; i < n; ++i, ix += incx) {
      if (std::abs(x[ix]) > dmax) {
        imax = i;
        dmax = std::abs(x[ix]);
      }
    }
  }
  return imax;
}

#if defined HAVE_CBLAS_H || defined HAVE_ATLAS_CBLAS_H
template<>
inline int imax(const int n, const float* x, const int incx) {
  return cblas_isamax(n, x, incx);
}

template<>
inline int imax(const int n, const double* x, const int incx) {
  return cblas_idamax(n, x, incx);
}

template<>
inline int imax(const int n, const Complex64* x, const int incx) {
  return cblas_icamax(n, x, incx);
}

template <>
inline int imax(const int n, const Complex128* x, const int incx) {
  return cblas_izamax(n, x, incx);
}
#endif

template<typename DType>
inline int cblas_imax(const int n, const void* x, const int incx) {
  return imax<DType>(n, reinterpret_cast<const DType*>(x), incx);
}

}} // end of namespace nm::math

#endif /* IMAX_H */
