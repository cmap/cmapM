#include "EMD_DEFS.hpp"
#include "emd_hat_signatures_interface.hpp"
#include "emd_hat.hpp"

NUM_T emd_hat_signature_interface(signature_tt* Signature1, signature_tt* Signature2,
                                  NUM_T (*func)(feature_tt*, feature_tt*),
                                  NUM_T extra_mass_penalty) {
    
    std::vector<NUM_T> P(Signature1->n + Signature2->n , 0);
    std::vector<NUM_T> Q(Signature1->n + Signature2->n , 0); 
    for (int i=0; i<Signature1->n; ++i) {
        P[i]= Signature1->Weights[i];
    }
    for (int j=0; j<Signature2->n; ++j) {
        Q[j+Signature1->n]= Signature2->Weights[j];
    }
    
    std::vector< std::vector<NUM_T> > C(P.size(), std::vector<NUM_T>(P.size(), 0) );
    for (int i=0; i<Signature1->n; ++i) {
        for (int j=0; j<Signature2->n; ++j) {
            NUM_T dist= func( (Signature1->Features+i) , (Signature2->Features+j) );
            assert(dist>=0);
            C[i][j+Signature1->n]= dist;
        }
    }

    return emd_hat(P,Q,C, extra_mass_penalty);

} // emd_hat_signature_interface

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
