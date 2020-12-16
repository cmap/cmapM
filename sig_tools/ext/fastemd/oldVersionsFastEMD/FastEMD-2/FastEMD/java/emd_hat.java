/**
   A class that provides efficient emd_hat functions. 
   emd_hat was described in the paper: <br>
   A Linear Time Histogram Metric for Improved SIFT Matching <br>
   Ofir Pele, Michael Werman <br>
   ECCV 2008 <br>
 The efficient algorithm is described in the paper: <br>
   Fast and Robust Earth Mover's Distances <br>
   Ofir Pele, Michael Werman <br>
   ICCV 2009 
   @author Ofir Pele
*/
public class emd_hat {

    /**
       Fastest version of EMD. Also, in my experience metric ground distance yields better performance.
       @param P a histogram of size N
       @param Q a histogram of size N
       @param C The NxN matrix of the ground distance between bins of P and Q. Must be a metric.
       I recommend it to be a thresholded metric (which is also a metric, see ICCV paper).
       @param extra_mass_penalty The penalty for extra mass - If you want the
       resulting distance to be a metric, it should be
       at least half the diameter of the space (maximum
       possible distance between any two points). If you
       want partial matching you can set it to zero (but
       then the resulting distance is not guaranteed to be a metric).
       Default value is -1 which means 1*max_element_in_C
       @param F if not null, F is filled with the flows between all bins, except the flow
       to the extra mass bin.
       Note that EMD and EMD-HAT does not necessarily have a unique flow solution.
       @return the distance
       @see "demo_FastEMD.java ../emd_hat.hpp ../demo_FastEMD#.m"
    */
    public static double dist_gd_metric(
        double[] P, double[] Q, double[][] C, double extra_mass_penalty,
        double[][] F) {
        double dist= dist_compute(P,Q,C,extra_mass_penalty, F, true);
        return dist;
    } // dist_gd_metric
    
    /**
       Same as dist_gd_metric, but does not assume metric property for the ground distance (C).
       Note that C should still be symmetric and non-negative!
       @see emd_hat#dist_gd_metric
    */
    public static double dist(
        double[] P, double[] Q, double[][] C, double extra_mass_penalty,
        double[][] F) {
        return dist_compute(P,Q,C,extra_mass_penalty, F, false);
    } // dist
     

    

    // private functions

    private static double dist_compute(
        double[] P, double[] Q, double[][] C, double extra_mass_penalty,
        double[][] F,
        boolean gd_metric) {

        int N= P.length;

        double[] Cv= convert_to_row_by_row(C);
        double[] Fv= null;
        if (F!=null) Fv= convert_to_row_by_row(F);

        int Fv_is_null_int= 0;
        if (Fv==null) Fv_is_null_int= 1;

        int gd_metric_int= 0;
        if (gd_metric) gd_metric_int= 1;
        
        double dist= native_dist_compute(P,Q,Cv,extra_mass_penalty, Fv, N,gd_metric_int,Fv_is_null_int);
        if (F!=null) convert_back_from_row_by_row(Fv,F);
        return dist;
    } // dist_compute

    private static double[] convert_to_row_by_row(double[][] M) {
        int N= M.length;
        double[] Mv= new double[N*N];
        int Mv_i= 0;
        for (int i= 0; i<N; ++i) {
            for (int j= 0; j<N; ++j) {
                Mv[Mv_i]= M[i][j];
                ++Mv_i;
            }
        }
        return Mv;
    }

    private static double[][] convert_back_from_row_by_row(double[] Mv,double[][] M) {
        int N= (int)Math.sqrt(Mv.length);
        int Mv_i= 0;
        for (int i= 0; i<N; ++i) {
            for (int j= 0; j<N; ++j) {
                M[i][j]= Mv[Mv_i];
                ++Mv_i;
            }
        }
        return M;
    }

    // P,Q histograms
    // Cv  ground distance matrix row by row
    // Fv  returned flow row by row, may be null if no flow is needed
    //
    // gd_metric is ground distance a metric or not
    private static native double native_dist_compute(
        double[] P, double[] Q, double[] Cv, double extra_mass_penalty,
        double[] Fv,
        int N, int gd_metric, int Fv_is_null);
    
    static {
        // We used here loadLibrary which means that you'll have to run your main function with -Djava.library.path=.
        // For example if your main function is in demo_FastEMD.java like here. You'll run it with:
        // java -Djava.library.path=. demo_FastEMD
        // Another option is to use here load instead of loadLibrary with the full path. Something like this:
        // System.load("/cs/vis/ofirpele/emd/FastEMD/FastEMD/JAVA/libemd_hat_native.so");
        // Use System.out.println(System.mapLibraryName("emd_hat_native")); to see how your specific architectecture
        // names shared libraries.
        try{
            System.loadLibrary("emd_hat_native");
        } catch (java.lang.UnsatisfiedLinkError e) {
            System.out.println("====================================================");
            System.out.println("Could not find emd_hat_native library. Run with:");
            System.out.println("java -Djava.library.path=.");
            System.out.println("If it's not the problem, you'll need to copy a compiled library that suites your architectecture from compiled_emd_hat_native_libs/");
            System.out.println("Or compile the library (from emd_hat_native.cpp)");
	    System.out.println("====================================================");
            System.out.println("");
            throw e;
        }
    }
    
}
// Copyright (2009-2010), The Hebrew University of Jerusalem.
// All Rights Reserved.

// Created by Ofir Pele
// The Hebrew University of Jerusalem

// This software is being made available for individual non-profit research use only.
// Any commercial use of this software requires a license from the Hebrew University
// of Jerusalem.

// For further details on obtaining a commercial license, contact Ofir Pele
// (ofirpele@cs.huji.ac.il) or Yissum, the technology transfer company of the
// Hebrew University of Jerusalem.

// THE HEBREW UNIVERSITY OF JERUSALEM MAKES NO REPRESENTATIONS OR WARRANTIES OF
// ANY KIND CONCERNING THIS SOFTWARE.

// IN NO EVENT SHALL THE HEBREW UNIVERSITY OF JERUSALEM BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST
// PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// THE THE HEBREW UNIVERSITY OF JERUSALEM HAS BEEN ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE. THE HEBREW UNIVERSITY OF JERUSALEM SPECIFICALLY DISCLAIMS ANY
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
// HEREUNDER IS ON AN "AS IS" BASIS, AND THE HEBREW UNIVERSITY OF JERUSALEM HAS NO
// OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
// MODIFICATIONS.
