import java.util.Random;

/**
 This demo efficiently computes the emd_hat between two 1-dimensional
 histograms where the ground distance between the bins is thresholded L_1
 emd_hat was described in the paper: <br>
   A Linear Time Histogram Metric for Improved SIFT Matching <br>
   Ofir Pele, Michael Werman <br>
   ECCV 2008 <br>
 The efficient algorithm is described in the paper: <br>
   Fast and Robust Earth Mover's Distances <br>
   Ofir Pele, Michael Werman <br>
   ICCV 2009 
 @see emd_hat
 @author Ofir Pele
*/
public class demo_FastEMD {


    public static void main(String args[]) {

        int N= 10;
        int threshold= 3;
        
        double[] P= randomDoubleArray(N);
        double[] Q= randomDoubleArray(N);

        double[][] C= new double[N][N];
        for (int i=0; i<N; ++i) {
            for (int j=0; j<N; ++j) {
                int abs_diff= Math.abs(i-j);
                C[i][j]= Math.min(abs_diff,threshold);
            }
        }
        
        double extra_mass_penalty= -1;

        double dist= emd_hat.dist_gd_metric(P,Q,C,extra_mass_penalty,null);

        System.out.print("Distance==");
        System.out.println(dist);

        /*
        // Computation with flow
        
        double[][] F= new double[N][N];

        double dist_with_flow= emd_hat.dist_gd_metric(P,Q,C,extra_mass_penalty,F);

        System.out.print("Distance==");
        System.out.println(dist_with_flow);

        System.out.println();
        System.out.println("Flow matrix: ");
        for (int i=0; i<N; ++i) {
            for (int j=0; j<N; ++j) {
                System.out.print(F[i][j]);
                System.out.print(" ");
            }
            System.out.println();
        }
        */
        
    }

    private static double[] randomDoubleArray(int N) {
        double[] randArr= new double[N];
        Random generator = new Random();
        for (int i= 0; i<N; ++i) {
            randArr[i]= generator.nextDouble();
        }
        return randArr;
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

