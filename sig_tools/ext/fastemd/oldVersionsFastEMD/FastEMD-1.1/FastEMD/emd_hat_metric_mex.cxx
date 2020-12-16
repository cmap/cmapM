#include "mex.h"
#include "emd_hat.hpp"
#include "emd_hat_check_and_extract_mex.hxx"
//#include "tictoc.hxx"

void mexFunction(int nout, mxArray *out[],
                 int nin, const mxArray *in[]) {


    //-------------------------------------------------------
    std::vector<int> Pv;
    std::vector<int> Qv;
    std::vector< std::vector<int> > Cv;
    NUM_T extra_mass_penalty;
    
    emd_hat_check_and_extract_mex(
        nout, out,
        nin, in,
        
        Pv,
        Qv,
        Cv,
        extra_mass_penalty);
    //-------------------------------------------------------
    
    //-------------------------------------------------------
    //tictoc timer;
    //timer.tic();
    NUM_T dist= emd_hat_metric(Pv,Qv,Cv, extra_mass_penalty);
    //timer.toc();
    //mexPrintf("\n----------\n time of emd_hat_metric == %Lf \n---------------\n",timer.totalTimeSec());
    
    int dims[]= {1};
    out[0]= mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    int* distPtr= (int*)mxGetData(out[0]);
    *distPtr= dist;
    //-------------------------------------------------------
      
      
      
} // end mexFunction

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
