#include "emd_hat_check_and_extract_mex.hxx"
#include "mex.h"

void emd_hat_check_and_extract_mex(
    int nout, mxArray *out[],
    int nin, const mxArray *in[],

    std::vector<int>& Pv,
    std::vector<int>& Qv,
    std::vector< std::vector<int> >& Cv,
    NUM_T& extra_mass_penalty

    ) {
    
    //-------------------------------------------------------
    // Check the arguments
    //-------------------------------------------------------
    if (nin!=3&&nin!=4) {
        mexErrMsgTxt("3 or 4 arguments are required.");
    }
    
    if (nout>1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    if(!mxIsNumeric(in[0]) || !mxIsNumeric(in[1]) || !mxIsNumeric(in[2])) {
        mexErrMsgTxt("Input arguments must be numeric matrices\n");
    }
    if (nin==4) {
        if (!mxIsNumeric(in[3])) {
            mexErrMsgTxt("Input arguments must be numeric matrices\n");
        }
    }
    
    if(mxIsSparse(in[0])||mxIsSparse(in[1])||mxIsSparse(in[2])) {
        mexErrMsgTxt("Sparse matrices are not supported.");
    }
    if (nin==4) {
        if(mxIsSparse(in[3])) {
            mexErrMsgTxt("Sparse matrices are not supported.");
        }
    }
    
    if (mxGetNumberOfDimensions(in[0])>2 ||
        mxGetNumberOfDimensions(in[1])>2 ||
        mxGetNumberOfDimensions(in[2])>2 ) {
        mexErrMsgTxt("Multidemnsionl arrays are not supported!\n");
    }
    if (nin==4) {
        if (mxGetNumberOfDimensions(in[2])>2) {
            mexErrMsgTxt("Multidemnsionl arrays are not supported!\n");
        }
    }
    
    
    if( mxGetClassID(in[0])!=mxINT32_CLASS ||
        mxGetClassID(in[1])!=mxINT32_CLASS ||
        mxGetClassID(in[2])!=mxINT32_CLASS ) {
        mexErrMsgTxt("Currently only int32 type is supported.\n");
    }
    if (nin==4) {
        if( mxGetClassID(in[3])!=mxINT32_CLASS ) {
            mexErrMsgTxt("Currently only int32 type is supported.\n");
        }
    }
    
    int sizeP= mxGetM(in[0]);
    int sizeQ= mxGetM(in[1]);
    int sizeC= mxGetM(in[2]);
    
    if(sizeP==0 || sizeQ==0) {
        mexErrMsgTxt("P and Q can not be empty!\n");
    }
    if(1!=mxGetN(in[0]) || 1!=mxGetN(in[1])) {
        mexErrMsgTxt("P and Q should be column vectors!\n");
    }
    
    if (sizeP!=sizeQ||
        sizeQ!=sizeC||
        sizeC!=static_cast<int>(mxGetN(in[2]))) {
        mexErrMsgTxt("P and Q and C should have the same corresponding size!\n");
    }
    unsigned int N= static_cast<unsigned int>(sizeP);
    
    const NUM_T* P= static_cast<const NUM_T*>( mxGetData(in[0]) );
    const NUM_T* Q= static_cast<const NUM_T*>( mxGetData(in[1]) );
    const NUM_T* C= static_cast<const NUM_T*>( mxGetData(in[2]) );
    
    // Check that C is symmetric and all costs are non-negative
    // and main diagonal should be zeros
    for (unsigned int i=0; i<N; ++i) {
        for (unsigned int j=0; j<N; ++j) {
            if ( C[i*N+j]!=C[j*N+i] || C[i*N+j]<0) {
                mexErrMsgTxt("C is not symmetric or there is a negative cost edge");
            }
        }
    }
    //-------------------------------------------------------
    
    Pv.insert(Pv.end(),P,P+N);
    Qv.insert(Qv.end(),Q,Q+N);
    Cv= std::vector< std::vector<int> >( N,std::vector<int>(N) );
    {for (unsigned int i=0; i<N; ++i) {
        {for (unsigned int j=0; j<N; ++j) {
            Cv[i][j]= C[i*N+j];
        }}
    }}
    
    extra_mass_penalty= -1;
    if (nin==4) {
        const NUM_T* extra_mass_penalty_ptr= static_cast<const NUM_T*>( mxGetData(in[3]) );
        extra_mass_penalty= *extra_mass_penalty_ptr;
    }
    
} // end emd_hat_check_and_extract_mex

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
