#ifndef EMD_HAT_CHECK_MEX_HXX__
#define EMD_HAT_CHECK_MEX_HXX__

#include "mex.h"

void emd_hat_check_mex(
    int nout, mxArray *out[],
    int nin, const mxArray *in[]) {

    const char* NIN_WRONG_MSG= "3 or 4 or 5 arguments are required";
    const char* NOUT_WRONG_MSG= "Too many output arguments";
    const char* IN_NOT_NUMERIC_MSG= "Input arguments must be numeric matrices";
    const char* IN_SPARSE_MSG= "Sparse matrices are not supported";
    const char* IN_MULTI_DIMENSIONAL_MSG= "Multidimensional arrays are not supported";
    const char* IN_NOT_SAME_CLASS_MSG= "All inputs should be of the same class";
    const char* PQ_EMPTY_MSG= "P and Q can not be empty";
    const char* PQ_NOT_COLUMN_MSG= "P and Q should be column vectors";
    const char* PQC_NOT_CORRESPONDING_SIZE_MSG= "P and Q and C should have the same corresponding size";
        
    //-------------------------------------------------------
    // Check the arguments
    //-------------------------------------------------------
    if (nin!=3&&nin!=4&&nin!=5) {
        mexErrMsgTxt(NIN_WRONG_MSG);
    }
    
    if (nout>2) {
        mexErrMsgTxt(NOUT_WRONG_MSG);
    }
    
    if(!mxIsNumeric(in[0]) || !mxIsNumeric(in[1]) || !mxIsNumeric(in[2]) ||
       ((nin>=4)&&(!mxIsNumeric(in[3]))) ||
       ((nin>=5)&&(!mxIsNumeric(in[4])))) {
           mexErrMsgTxt(IN_NOT_NUMERIC_MSG);
    }
       
    if( mxIsSparse(in[0]) || mxIsSparse(in[1]) || mxIsSparse(in[2]) ||
        ((nin>=4)&&(mxIsSparse(in[3]))) ||
        ((nin>=5)&&(mxIsSparse(in[4])))) {
        mexErrMsgTxt(IN_SPARSE_MSG);
    }
       
    if (mxGetNumberOfDimensions(in[0])>2 ||
        mxGetNumberOfDimensions(in[1])>2 ||
        mxGetNumberOfDimensions(in[2])>2 ||
        ((nin>=4)&&(mxGetNumberOfDimensions(in[3])>2)) ||
        ((nin>=5)&&(mxGetNumberOfDimensions(in[4])>2))) {
        mexErrMsgTxt(IN_MULTI_DIMENSIONAL_MSG);
    }
              
    if (mxGetClassID(in[0])!=mxGetClassID(in[1]) ||
        mxGetClassID(in[0])!=mxGetClassID(in[2]) ||
        ((nin>=4)&&mxGetClassID(in[0])!=mxGetClassID(in[3])) ||
        ((nin>=5)&&mxGetClassID(in[0])!=mxGetClassID(in[4]))) {
        mexErrMsgTxt(IN_NOT_SAME_CLASS_MSG);
    }
        
    int sizeP= mxGetM(in[0]);
    int sizeQ= mxGetM(in[1]);
    int sizeC= mxGetM(in[2]);
    
    if(sizeP==0 || sizeQ==0) {
        mexErrMsgTxt(PQ_EMPTY_MSG);
    }

    if(1!=mxGetN(in[0]) || 1!=mxGetN(in[1])) {
        mexErrMsgTxt(PQ_NOT_COLUMN_MSG);
    }
        
    if (sizeP!=sizeQ||
        sizeQ!=sizeC||
        sizeC!=static_cast<int>(mxGetN(in[2]))) {
        mexErrMsgTxt(PQC_NOT_CORRESPONDING_SIZE_MSG);
    }

} // end emd_hat_check_mex

#endif

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
