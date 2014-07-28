# = NMatrix
#
# A linear algebra library for scientific computation in Ruby.
# NMatrix is part of SciRuby.
#
# NMatrix was originally inspired by and derived from NArray, by
# Masahiro Tanaka: http://narray.rubyforge.org
#
# == Copyright Information
#
# SciRuby is Copyright (c) 2010 - 2014, Ruby Science Foundation
# NMatrix is Copyright (c) 2012 - 2014, John Woods and the Ruby Science Foundation
#
# Please see LICENSE.txt for additional copyright notices.
#
# == Contributing
#
# By contributing source code to SciRuby, you agree to be bound by
# our Contributor Agreement:
#
# * https://github.com/SciRuby/sciruby/wiki/Contributor-Agreement
#
# == lapack_spec.rb
#
# Tests for properly exposed LAPACK functions.
#

require 'spec_helper'

describe NMatrix::LAPACK do
  # where integer math is allowed
  [:byte, :int8, :int16, :int32, :int64, :rational32, :rational64, :rational128, :float32, :float64, :complex64, :complex128].each do |dtype|
    context dtype do
      it "exposes clapack laswp" do
        a = NMatrix.new(:dense, [3,4], [1,2,3,4,5,6,7,8,9,10,11,12], dtype)
        NMatrix::LAPACK::clapack_laswp(3, a, 4, 0, 3, [2,1,3,0], 1)
        b = NMatrix.new(:dense, [3,4], [3,2,4,1,7,6,8,5,11,10,12,9], dtype)
        expect(a).to eq(b)
      end

      it "exposes NMatrix#permute_columns and #permute_columns! (user-friendly laswp)" do
        a = NMatrix.new(:dense, [3,4], [1,2,3,4,5,6,7,8,9,10,11,12], dtype)
        b = NMatrix.new(:dense, [3,4], [3,2,4,1,7,6,8,5,11,10,12,9], dtype)
        piv = [2,1,3,0]
        r = a.permute_columns(piv)
        expect(r).not_to eq(a)
        expect(r).to eq(b)
        a.permute_columns!(piv)
        expect(a).to eq(b)
      end
    end
  end

  # where integer math is not allowed
  [:rational32, :rational64, :rational128, :float32, :float64, :complex64, :complex128].each do |dtype|
    context dtype do

      it "exposes clapack_gesv" do
        a = NMatrix[[1.quo(1), 2, 3], [0,1.quo(2),4],[3,3,9]].cast(dtype: dtype)
        b = NMatrix[[1.quo(1)],[2],[3]].cast(dtype: dtype)
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-8
                else
                  1e-64
              end
        expect(NMatrix::LAPACK::clapack_gesv(:row,a.shape[0],b.shape[1],a,a.shape[0],b,b.shape[0])).to be_within(err).of(NMatrix[[-1.quo(2)], [0], [1.quo(2)]].cast(dtype: dtype))
      end


      it "exposes clapack_getrf" do
        a = NMatrix.new(3, [4,9,2,3,5,7,8,1,6], dtype: dtype)
        NMatrix::LAPACK::clapack_getrf(:row, 3, 3, a, 3)

        # delta varies for different dtypes
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-15
                else
                  1e-64 # FIXME: should be 0, but be_within(0) does not work.
              end

        expect(a[0,0]).to eq(9) # 8
        expect(a[0,1]).to be_within(err).of(2.quo(9)) # 1
        expect(a[0,2]).to be_within(err).of(4.quo(9)) # 6
        expect(a[1,0]).to eq(5) # 1.quo(2)
        expect(a[1,1]).to be_within(err).of(53.quo(9)) # 17.quo(2)
        expect(a[1,2]).to be_within(err).of(7.quo(53)) # -1
        expect(a[2,0]).to eq(1) # 3.quo(8)
        expect(a[2,1]).to be_within(err).of(52.quo(9))
        expect(a[2,2]).to be_within(err).of(360.quo(53))
      end

      it "exposes clapack_potrf" do
        # first do upper
        begin
          a = NMatrix.new(:dense, 3, [25,15,-5, 0,18,0, 0,0,11], dtype)
          NMatrix::LAPACK::clapack_potrf(:row, :upper, 3, a, 3)
          b = NMatrix.new(:dense, 3, [5,3,-1, 0,3,1, 0,0,3], dtype)
          expect(a).to eq(b)
        rescue NotImplementedError => e
          pending e.to_s
        end

        # then do lower
        a = NMatrix.new(:dense, 3, [25,0,0, 15,18,0,-5,0,11], dtype)
        NMatrix::LAPACK::clapack_potrf(:row, :lower, 3, a, 3)
        b = NMatrix.new(:dense, 3, [5,0,0, 3,3,0, -1,1,3], dtype)
        expect(a).to eq(b)
      end

      # Together, these calls are basically xGESV from LAPACK: http://www.netlib.org/lapack/double/dgesv.f
      it "exposes clapack_getrs" do
        a     = NMatrix.new(3, [-2,4,-3,3,-2,1,0,-4,3], dtype: dtype)
        ipiv  = NMatrix::LAPACK::clapack_getrf(:row, 3, 3, a, 3)
        b     = NMatrix.new([3,1], [-1, 17, -9], dtype: dtype)

        NMatrix::LAPACK::clapack_getrs(:row, false, 3, 1, a, 3, ipiv, b, 3)

        expect(b[0]).to eq(5)
        expect(b[1]).to eq(-15.quo(2))
        expect(b[2]).to eq(-13)
      end

      it "exposes clapack_getri" do
        a = NMatrix.new(:dense, 3, [1,0,4,1,1,6,-3,0,-10], dtype)
        ipiv = NMatrix::LAPACK::clapack_getrf(:row, 3, 3, a, 3) # get pivot from getrf, use for getri

        begin
          NMatrix::LAPACK::clapack_getri(:row, 3, a, 3, ipiv)

          b = NMatrix.new(:dense, 3, [-5,0,-2,-4,1,-1,1.5,0,0.5], dtype)
          expect(a).to eq(b)
        rescue NotImplementedError => e
          pending e.to_s
        end
      end

      it "exposes lapack_gesdd" do
        if [:float32, :float64].include? dtype
          a = NMatrix.new([5,6], %w|8.79 9.93 9.83 5.45 3.16
                                    6.11 6.91 5.04 -0.27 7.98
                                    -9.15 -7.93 4.86 4.85 3.01
                                    9.57 1.64 8.83 0.74 5.80
                                    -3.49 4.02 9.80 10.00 4.27
                                    9.84 0.15 -8.99 -6.02 -5.31|.map(&:to_f), dtype: dtype)
          s_true = NMatrix.new([1,5], [27.468732418221848, 22.643185009774697, 8.558388228482576, 5.985723201512133, 2.014899658715756], dtype: dtype)
          right_true = NMatrix.new([5,6], [0.5911423764124365, 0.2631678147140568, 0.35543017386282716, 0.3142643627269275, 0.2299383153647484, 0.0, 0.39756679420242547, 0.24379902792633046, -0.22239000068544604, -0.7534661509534584, -0.36358968669749664, 0.0, 0.03347896906244727, -0.6002725806935828, -0.45083926892230763, 0.23344965724471425, -0.3054757327479317, 0.0, 0.4297069031370182, 0.23616680628112555, -0.6858628638738117, 0.3318600182003095, 0.1649276348845103, 0.0, 0.4697479215666587, -0.350891398883702, 0.38744460309967327, 0.15873555958215635, -0.5182574373535355, 0.0, -0.29335875846440357, 0.57626211913389, -0.020852917980871258, 0.3790776670601607, -0.6525516005923976, 0.0], dtype: dtype)
          #right_true = NMatrix.new([5,6],
          # %w|-0.59 0.26   0.36   0.31   0.23
          #   -0.40   0.24  -0.22  -0.75  -0.36
          #   -0.03  -0.60  -0.45   0.23  -0.31
          #   -0.43   0.24  -0.69   0.33   0.16
          #   -0.47  -0.35   0.39   0.16  -0.52
          #    0.29   0.58  -0.02   0.38  -0.65|.map(&:to_f),
          #  dtype)
          left_true = NMatrix.new([5,5], [0.25138279272049635, 0.3968455517769292, 0.6921510074703637, 0.3661704447722309, 0.4076352386533525, 0.814836686086339, 0.3586615001880027, -0.24888801115928438, -0.3685935379446176, -0.09796256926688672, -0.2606185055842211, 0.7007682094072526, -0.22081144672043734, 0.38593848318854174, -0.49325014285102375, 0.3967237771305971, -0.4507112412166429, 0.2513211496937535, 0.4342486014366711, -0.6226840720358049, -0.21802776368654594, 0.14020994987112056, 0.5891194492399431, -0.6265282503648172, -0.4395516923423326], dtype: dtype)
          #left_true = NMatrix.new([5,5],
          #  %w|-0.25  -0.40  -0.69  -0.37  -0.41
          #    0.81   0.36  -0.25  -0.37  -0.10
          #   -0.26   0.70  -0.22   0.39  -0.49
          #    0.40  -0.45   0.25   0.43  -0.62
          #   -0.22   0.14   0.59  -0.63  -0.44|.map(&:to_f),
          # dtype)
          s   = NMatrix.new([5,1], 0, dtype: dtype)
          u   = NMatrix.new([5,5], 0, dtype: dtype)
          ldu = 5
          vt  = NMatrix.new([6,6], 0, dtype: dtype)
          ldvt= 6
        elsif [:complex64, :complex128].include? dtype
          #http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/cgesvd_ex.c.htm
          pending "Example may be wrong"
        else
          pending "Not implemented for non-LAPACK dtypes"
          a = NMatrix.new([4,3], dtype: dtype)
        end
        err = case dtype
              when :float32, :complex64
                1e-6
              when :float64, :complex128
                1e-15
              else
                1e-64 # FIXME: should be 0, but be_within(0) does not work.
              end
        err = err *5e1
        begin

          info = NMatrix::LAPACK::lapack_gesdd(:a, a.shape[0], a.shape[1], a, a.shape[0], s, u, ldu, vt, ldvt, 500)

        rescue NotImplementedError => e
          pending e.to_s
        end

        expect(u).to be_within(err).of(left_true)
        #FIXME: Is the next line correct? check http://www.oraclebytes.com/reference/packages/view/UTL_NLA/lapack_gesdd-%28p%29
        expect(vt[0...right_true.shape[0], 0...right_true.shape[1]-1]).to be_within(err).of(right_true[0...right_true.shape[0],0...right_true.shape[1]-1])
        expect(s.transpose).to be_within(err).of(s_true.row(0))
      end


     it "exposes lapack_gesvd" do
        # http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/dgesvd_ex.c.htm
        if [:float32, :float64].include? dtype
          a = NMatrix.new([5,6], %w|8.79 9.93 9.83 5.45 3.16
                                    6.11 6.91 5.04 -0.27 7.98
                                    -9.15 -7.93 4.86 4.85 3.01
                                    9.57 1.64 8.83 0.74 5.80
                                    -3.49 4.02 9.80 10.00 4.27
                                    9.84 0.15 -8.99 -6.02 -5.31|.map(&:to_f), dtype: dtype)
          s_true = NMatrix.new([1,5], [27.468732418221848, 22.643185009774697, 8.558388228482576, 5.985723201512133, 2.014899658715756], dtype: dtype)
          right_true = NMatrix.new([5,6], [0.5911423764124365, 0.2631678147140568, 0.35543017386282716, 0.3142643627269275, 0.2299383153647484, 0.0, 0.39756679420242547, 0.24379902792633046, -0.22239000068544604, -0.7534661509534584, -0.36358968669749664, 0.0, 0.03347896906244727, -0.6002725806935828, -0.45083926892230763, 0.23344965724471425, -0.3054757327479317, 0.0, 0.4297069031370182, 0.23616680628112555, -0.6858628638738117, 0.3318600182003095, 0.1649276348845103, 0.0, 0.4697479215666587, -0.350891398883702, 0.38744460309967327, 0.15873555958215635, -0.5182574373535355, 0.0, -0.29335875846440357, 0.57626211913389, -0.020852917980871258, 0.3790776670601607, -0.6525516005923976, 0.0], dtype: dtype)
          #right_true = NMatrix.new([5,6],
          # %w|-0.59 0.26   0.36   0.31   0.23
          #   -0.40   0.24  -0.22  -0.75  -0.36
          #   -0.03  -0.60  -0.45   0.23  -0.31
          #   -0.43   0.24  -0.69   0.33   0.16
          #   -0.47  -0.35   0.39   0.16  -0.52
          #    0.29   0.58  -0.02   0.38  -0.65|.map(&:to_f),
          #  dtype)
          left_true = NMatrix.new([5,5], [0.25138279272049635, 0.3968455517769292, 0.6921510074703637, 0.3661704447722309, 0.4076352386533525, 0.814836686086339, 0.3586615001880027, -0.24888801115928438, -0.3685935379446176, -0.09796256926688672, -0.2606185055842211, 0.7007682094072526, -0.22081144672043734, 0.38593848318854174, -0.49325014285102375, 0.3967237771305971, -0.4507112412166429, 0.2513211496937535, 0.4342486014366711, -0.6226840720358049, -0.21802776368654594, 0.14020994987112056, 0.5891194492399431, -0.6265282503648172, -0.4395516923423326], dtype: dtype)
          #left_true = NMatrix.new([5,5],
          #  %w|-0.25  -0.40  -0.69  -0.37  -0.41
          #    0.81   0.36  -0.25  -0.37  -0.10
          #   -0.26   0.70  -0.22   0.39  -0.49
          #    0.40  -0.45   0.25   0.43  -0.62
          #   -0.22   0.14   0.59  -0.63  -0.44|.map(&:to_f),
          # dtype)
          s   = NMatrix.new([5,1], 0, dtype: dtype)
          u   = NMatrix.new([5,5], 0, dtype: dtype)
          ldu = 5
          vt  = NMatrix.new([6,6], 0, dtype: dtype)
          ldvt= 6
        elsif [:complex64, :complex128].include? dtype
          #http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/cgesvd_ex.c.htm
          pending "Example may be wrong"
          a = NMatrix.new([4,3], [[  5.91, -5.69], [  7.09,  2.72], [  7.78, -4.06], [ -0.79, -7.21], [ -3.15, -4.08], [ -1.89,  3.27], [  4.57, -2.07], [ -3.88, -3.30], [ -4.89,  4.20], [  4.10, -6.70], [  3.28, -3.84], [  3.84,  1.19]].map {|e| Complex(*e) } , dtype: dtype)
          s_true = NMatrix.new([3,1], [17.63, 11.61, 6.78], dtype: dtype)
          left_true = NMatrix.new([4,4], [[-0.86, 0.0], [0.4, 0.0], [0.32, 0.0], [-0.35, 0.13], [-0.24, -0.21], [-0.63, 0.6], [0.15, 0.32], [0.61, 0.61], [-0.36, 0.1]].map {|e| Complex(*e)}, dtype: dtype)
          right_true = NMatrix.new([4,3], [[ -0.22, 0.51], [ -0.37, -0.32], [ -0.53, 0.11], [ 0.15, 0.38], [ 0.31, 0.31], [ 0.09, -0.57], [ 0.18, -0.39], [ 0.38, -0.39], [ 0.53, 0.24], [ 0.49, 0.28], [ -0.47, -0.25], [ -0.15, 0.19]].map {|e| Complex *e} , dtype: dtype)

          s   = NMatrix.new([3,1], 0, dtype: dtype)
          u   = NMatrix.new([4,4], 0, dtype: dtype)
          ldu = 4
          vt  = NMatrix.new([3,3], 0, dtype: dtype)
          ldvt= 3
        else 
          a = NMatrix.new([4,3], dtype: dtype)
        end
        err = case dtype
              when :float32, :complex64
                1e-6
              when :float64, :complex128
                1e-15
              else
                1e-64 # FIXME: should be 0, but be_within(0) does not work.
              end
        err = err *5e1
        begin

          info = NMatrix::LAPACK::lapack_gesvd(:a, :a, a.shape[0], a.shape[1], a, a.shape[0], s, u, ldu, vt, ldvt, 500)

        rescue NotImplementedError => e
          pending e.to_s
        end

        expect(u).to be_within(err).of(left_true)
        #FIXME: Is the next line correct?
        expect(vt[0...right_true.shape[0], 0...right_true.shape[1]-1]).to be_within(err).of(right_true[0...right_true.shape[0],0...right_true.shape[1]-1])
        expect(s.transpose).to be_within(err).of(s_true.row(0))

      end
 
      it "exposes the convenience gesvd method" do
        # http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/dgesvd_ex.c.htm
        if [:float32, :float64].include? dtype
          a = NMatrix.new([5,6], %w|8.79 9.93 9.83 5.45 3.16
                                    6.11 6.91 5.04 -0.27 7.98
                                    -9.15 -7.93 4.86 4.85 3.01
                                    9.57 1.64 8.83 0.74 5.80
                                    -3.49 4.02 9.80 10.00 4.27
                                    9.84 0.15 -8.99 -6.02 -5.31|.map(&:to_f), dtype: dtype)
          s_true = NMatrix.new([1,5], [27.468732418221848, 22.643185009774697, 8.558388228482576, 5.985723201512133, 2.014899658715756], dtype: dtype)
          right_true = NMatrix.new([5,6], [0.5911423764124365, 0.2631678147140568, 0.35543017386282716, 0.3142643627269275, 0.2299383153647484, 0.0, 0.39756679420242547, 0.24379902792633046, -0.22239000068544604, -0.7534661509534584, -0.36358968669749664, 0.0, 0.03347896906244727, -0.6002725806935828, -0.45083926892230763, 0.23344965724471425, -0.3054757327479317, 0.0, 0.4297069031370182, 0.23616680628112555, -0.6858628638738117, 0.3318600182003095, 0.1649276348845103, 0.0, 0.4697479215666587, -0.350891398883702, 0.38744460309967327, 0.15873555958215635, -0.5182574373535355, 0.0, -0.29335875846440357, 0.57626211913389, -0.020852917980871258, 0.3790776670601607, -0.6525516005923976, 0.0], dtype: dtype)
          #right_true = NMatrix.new([5,6],
          # %w|-0.59 0.26   0.36   0.31   0.23
          #   -0.40   0.24  -0.22  -0.75  -0.36
          #   -0.03  -0.60  -0.45   0.23  -0.31
          #   -0.43   0.24  -0.69   0.33   0.16
          #   -0.47  -0.35   0.39   0.16  -0.52
          #    0.29   0.58  -0.02   0.38  -0.65|.map(&:to_f),
          #  dtype)
          left_true = NMatrix.new([5,5], [0.25138279272049635, 0.3968455517769292, 0.6921510074703637, 0.3661704447722309, 0.4076352386533525, 0.814836686086339, 0.3586615001880027, -0.24888801115928438, -0.3685935379446176, -0.09796256926688672, -0.2606185055842211, 0.7007682094072526, -0.22081144672043734, 0.38593848318854174, -0.49325014285102375, 0.3967237771305971, -0.4507112412166429, 0.2513211496937535, 0.4342486014366711, -0.6226840720358049, -0.21802776368654594, 0.14020994987112056, 0.5891194492399431, -0.6265282503648172, -0.4395516923423326], dtype: dtype)
          #left_true = NMatrix.new([5,5],
          #  %w|-0.25  -0.40  -0.69  -0.37  -0.41
          #    0.81   0.36  -0.25  -0.37  -0.10
          #   -0.26   0.70  -0.22   0.39  -0.49
          #    0.40  -0.45   0.25   0.43  -0.62
          #   -0.22   0.14   0.59  -0.63  -0.44|.map(&:to_f),
          # dtype)
          s   = NMatrix.new([5,1], 0, dtype: dtype)
          u   = NMatrix.new([5,5], 0, dtype: dtype)
          ldu = 5
          vt  = NMatrix.new([6,6], 0, dtype: dtype)
          ldvt= 6
        elsif [:complex64, :complex128].include? dtype
          #http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/cgesvd_ex.c.htm
          pending "Example may be wrong"
          a = NMatrix.new([4,3], [[  5.91, -5.69], [  7.09,  2.72], [  7.78, -4.06], [ -0.79, -7.21], [ -3.15, -4.08], [ -1.89,  3.27], [  4.57, -2.07], [ -3.88, -3.30], [ -4.89,  4.20], [  4.10, -6.70], [  3.28, -3.84], [  3.84,  1.19]].map {|e| Complex(*e) } , dtype: dtype)
          s_true = NMatrix.new([3,1], [17.63, 11.61, 6.78], dtype: dtype)
          left_true = NMatrix.new([4,4], [[-0.86, 0.0], [0.4, 0.0], [0.32, 0.0], [-0.35, 0.13], [-0.24, -0.21], [-0.63, 0.6], [0.15, 0.32], [0.61, 0.61], [-0.36, 0.1]].map {|e| Complex(*e)}, dtype: dtype)
          right_true = NMatrix.new([4,3], [[ -0.22, 0.51], [ -0.37, -0.32], [ -0.53, 0.11], [ 0.15, 0.38], [ 0.31, 0.31], [ 0.09, -0.57], [ 0.18, -0.39], [ 0.38, -0.39], [ 0.53, 0.24], [ 0.49, 0.28], [ -0.47, -0.25], [ -0.15, 0.19]].map {|e| Complex *e} , dtype: dtype)

          s   = NMatrix.new([3,1], 0, dtype: dtype)
          u   = NMatrix.new([4,4], 0, dtype: dtype)
          ldu = 4
          vt  = NMatrix.new([3,3], 0, dtype: dtype)
          ldvt= 3
        else 
          a = NMatrix.new([4,3], dtype: dtype)
        end
        err = case dtype
              when :float32, :complex64
                1e-6
              when :float64, :complex128
                1e-15
              else
                1e-64 # FIXME: should be 0, but be_within(0) does not work.
              end
        err = err *5e1
        begin
          u, s, vt = a.gesvd
        rescue NotImplementedError => e
          pending e.to_s
        end
        expect(u).to be_within(err).of(left_true)
        #FIXME: Is the next line correct?
        expect(vt[0...right_true.shape[0], 0...right_true.shape[1]-1]).to be_within(err).of(right_true[0...right_true.shape[0],0...right_true.shape[1]-1])
        expect(s.transpose).to be_within(err).of(s_true.row(0))

      end
      it "exposes the convenience gesdd method" do
        # http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/dgesvd_ex.c.htm
        if [:float32, :float64].include? dtype
          a = NMatrix.new([5,6], %w|8.79 9.93 9.83 5.45 3.16
                                    6.11 6.91 5.04 -0.27 7.98
                                    -9.15 -7.93 4.86 4.85 3.01
                                    9.57 1.64 8.83 0.74 5.80
                                    -3.49 4.02 9.80 10.00 4.27
                                    9.84 0.15 -8.99 -6.02 -5.31|.map(&:to_f), dtype: dtype)
          s_true = NMatrix.new([1,5], [27.468732418221848, 22.643185009774697, 8.558388228482576, 5.985723201512133, 2.014899658715756], dtype: dtype)
          right_true = NMatrix.new([5,6], [0.5911423764124365, 0.2631678147140568, 0.35543017386282716, 0.3142643627269275, 0.2299383153647484, 0.0, 0.39756679420242547, 0.24379902792633046, -0.22239000068544604, -0.7534661509534584, -0.36358968669749664, 0.0, 0.03347896906244727, -0.6002725806935828, -0.45083926892230763, 0.23344965724471425, -0.3054757327479317, 0.0, 0.4297069031370182, 0.23616680628112555, -0.6858628638738117, 0.3318600182003095, 0.1649276348845103, 0.0, 0.4697479215666587, -0.350891398883702, 0.38744460309967327, 0.15873555958215635, -0.5182574373535355, 0.0, -0.29335875846440357, 0.57626211913389, -0.020852917980871258, 0.3790776670601607, -0.6525516005923976, 0.0], dtype: dtype)
          left_true = NMatrix.new([5,5], [0.25138279272049635, 0.3968455517769292, 0.6921510074703637, 0.3661704447722309, 0.4076352386533525, 0.814836686086339, 0.3586615001880027, -0.24888801115928438, -0.3685935379446176, -0.09796256926688672, -0.2606185055842211, 0.7007682094072526, -0.22081144672043734, 0.38593848318854174, -0.49325014285102375, 0.3967237771305971, -0.4507112412166429, 0.2513211496937535, 0.4342486014366711, -0.6226840720358049, -0.21802776368654594, 0.14020994987112056, 0.5891194492399431, -0.6265282503648172, -0.4395516923423326], dtype: dtype)
          u   = NMatrix.new([5,5], 0, dtype: dtype)
          ldu = 5
          vt  = NMatrix.new([6,6], 0, dtype: dtype)
          ldvt= 6
        elsif [:complex64, :complex128].include? dtype
          #http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/cgesvd_ex.c.htm
          pending "Example may be wrong"
          a = NMatrix.new([4,3], [[  5.91, -5.69], [  7.09,  2.72], [  7.78, -4.06], [ -0.79, -7.21], [ -3.15, -4.08], [ -1.89,  3.27], [  4.57, -2.07], [ -3.88, -3.30], [ -4.89,  4.20], [  4.10, -6.70], [  3.28, -3.84], [  3.84,  1.19]].map {|e| Complex(*e) } , dtype: dtype)
          s_true = NMatrix.new([3,1], [17.63, 11.61, 6.78], dtype: dtype)
          left_true = NMatrix.new([4,4], [[-0.86, 0.0], [0.4, 0.0], [0.32, 0.0], [-0.35, 0.13], [-0.24, -0.21], [-0.63, 0.6], [0.15, 0.32], [0.61, 0.61], [-0.36, 0.1]].map {|e| Complex(*e)}, dtype: dtype)
          right_true = NMatrix.new([4,3], [[ -0.22, 0.51], [ -0.37, -0.32], [ -0.53, 0.11], [ 0.15, 0.38], [ 0.31, 0.31], [ 0.09, -0.57], [ 0.18, -0.39], [ 0.38, -0.39], [ 0.53, 0.24], [ 0.49, 0.28], [ -0.47, -0.25], [ -0.15, 0.19]].map {|e| Complex *e} , dtype: dtype)

          s   = NMatrix.new([3,1], 0, dtype: dtype)
          u   = NMatrix.new([4,4], 0, dtype: dtype)
          ldu = 4
          vt  = NMatrix.new([3,3], 0, dtype: dtype)
          ldvt= 3
        else 
          a = NMatrix.new([4,3], dtype: dtype)
        end
        s   = NMatrix.new([5,1], 0, dtype: dtype)
        u   = NMatrix.new([5,5], 0, dtype: dtype)
        ldu = 5
        vt  = NMatrix.new([6,6], 0, dtype: dtype)
        ldvt= 6
        err = case dtype
              when :float32, :complex64
                1e-6
              when :float64, :complex128
                1e-15
              else
                1e-64 # FIXME: should be 0, but be_within(0) does not work.
              end
        err = err *5e1
        begin

          u, s, vt = a.gesdd(500)

        rescue NotImplementedError => e
          pending e.to_s
        end
        expect(u).to be_within(err).of(left_true)
        #FIXME: Is the next line correct?
        expect(vt[0...right_true.shape[0], 0...right_true.shape[1]-1]).to be_within(err).of(right_true[0...right_true.shape[0],0...right_true.shape[1]-1])
        expect(s.transpose).to be_within(err).of(s_true.row(0))
      end


      it "exposes geev" do
        pending("needs rational implementation") if dtype.to_s =~ /rational/
        ary = %w|-1.01 0.86 -4.60 3.31 -4.81
                     3.98 0.53 -7.04 5.29 3.55
                     3.30 8.26 -3.89 8.20 -1.51
                     4.43 4.96 -7.66 -7.33 6.18
                     7.31 -6.43 -6.16 2.47 5.58|
        ary = dtype.to_s =~ /complex/ ? ary.map(&:to_c) : ary.map(&:to_f)

        a   = NMatrix.new(:dense, 5, ary, dtype).transpose
        lda = 5
        n   = 5

        wr  = NMatrix.new(:dense, [n,1], 0, dtype)
        wi  = dtype.to_s =~ /complex/ ? nil : NMatrix.new(:dense, [n,1], 0, dtype)
        vl  = NMatrix.new(:dense, n, 0, dtype)
        vr  = NMatrix.new(:dense, n, 0, dtype)
        ldvr = n
        ldvl = n

        info = NMatrix::LAPACK::lapack_geev(:left, :right, n, a.clone, lda, wr.clone, wi.nil? ? nil : wi.clone, vl.clone, ldvl, vr.clone, ldvr, -1)
        expect(info).to eq(0)

        info = NMatrix::LAPACK::lapack_geev(:left, :right, n, a, lda, wr, wi, vl, ldvl, vr, ldvr, 2*n)

        # Negate these and we get a correct result:
        vr = vr.transpose
        vl = vl.transpose

        pending("Need complex example") if dtype.to_s =~ /complex/
        vl_true = NMatrix.new(:dense, 5, [0.04,  0.29,  0.13,  0.33, -0.04,
                                          0.62,  0.0,  -0.69,  0.0,  -0.56,
                                         -0.04, -0.58,  0.39,  0.07,  0.13,
                                          0.28,  0.01,  0.02,  0.19,  0.80,
                                         -0.04,  0.34,  0.40, -0.22, -0.18 ], :float64)

        expect(vl.abs).to be_within(1e-2).of(vl_true.abs)
        # Not checking vr_true.
        # Example from:
        # http://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/lapacke_dgeev_row.c.htm
        #
        # This is what the result should look like:
        # [
        #  [0.10806497186422348,  0.16864821314811707,   0.7322341203689575,                  0.0, -0.46064677834510803]
        #  [0.40631288290023804, -0.25900983810424805, -0.02646319754421711, -0.01694658398628235, -0.33770373463630676]
        #  [0.10235744714736938,  -0.5088024139404297,  0.19164878129959106, -0.29256555438041687,  -0.3087439239025116]
        #  [0.39863115549087524,  -0.0913335531949997, -0.07901126891374588, -0.07807594537734985,   0.7438457012176514]
        #  [ 0.5395349860191345,                  0.0, -0.29160499572753906, -0.49310219287872314, -0.15852922201156616]
        # ]
        #

      end
    end
  end
end
