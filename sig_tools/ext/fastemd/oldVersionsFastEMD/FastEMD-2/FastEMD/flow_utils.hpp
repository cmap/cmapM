#ifndef FLOW_UTILS_HPP
#define FLOW_UTILS_HPP

#include "EMD_DEFS.hpp"
#include <vector>
#include <cassert>

enum FLOW_TYPE_T {
    NO_FLOW= 0,
    WITHOUT_TRANSHIPMENT_FLOW,
    WITHOUT_EXTRA_MASS_FLOW
};

/// returns the flow from/to transhipment vertex given flow F which was computed using
/// FLOW_TYPE_T of kind WITHOUT_TRANSHIPMENT_FLOW.
template<typename NUM_T>
void return_flow_from_to_transhipment_vertex(const std::vector< std::vector<NUM_T> >& F,
                                             const std::vector<NUM_T>& P,
                                             const std::vector<NUM_T>& Q,
                                             std::vector<NUM_T>& flow_from_P_to_transhipment,
                                             std::vector<NUM_T>& flow_from_transhipment_to_Q) {

    flow_from_P_to_transhipment= P;
    flow_from_transhipment_to_Q= Q;
    for (NODE_T i= 0; i<P.size(); ++i) {
        for (NODE_T j= 0; j<P.size(); ++j) {
            flow_from_P_to_transhipment[i]-= F[i][j];
            flow_from_transhipment_to_Q[j]-= F[i][j];
        }
    }

} // return_flow_from_to_transhipment_vertex


/// Transforms the given flow F which was computed using FLOW_TYPE_T of kind WITHOUT_TRANSHIPMENT_FLOW,
/// to a flow which can be computed using WITHOUT_EXTRA_MASS_FLOW. If you want the flow to the extra mass,
/// you can use return_flow_from_to_transhipment_vertex on the returned F.
template<typename NUM_T>
void transform_flow_to_regular(std::vector< std::vector<NUM_T> >& F,
                               const std::vector<NUM_T>& P,
                               const std::vector<NUM_T>& Q) {

    const NODE_T N= P.size();
    std::vector<NUM_T> flow_from_P_to_transhipment(N);
    std::vector<NUM_T> flow_from_transhipment_to_Q(N);
    return_flow_from_to_transhipment_vertex(F,P,Q,
                                            flow_from_P_to_transhipment,
                                            flow_from_transhipment_to_Q);
    
    NODE_T i= 0;
    NODE_T j= 0;
    while( true ) {

        while (i<N&&flow_from_P_to_transhipment[i]==0) ++i;
        while (j<N&&flow_from_transhipment_to_Q[j]==0) ++j;
        if (i==N||j==N) break;
        
        if (flow_from_P_to_transhipment[i]<flow_from_transhipment_to_Q[j]) {
            F[i][j]+= flow_from_P_to_transhipment[i];
            flow_from_transhipment_to_Q[j]-= flow_from_P_to_transhipment[i];
            flow_from_P_to_transhipment[i]= 0;
        } else {
            F[i][j]+= flow_from_transhipment_to_Q[j];
            flow_from_P_to_transhipment[i]-= flow_from_transhipment_to_Q[j];
            flow_from_transhipment_to_Q[j]= 0;
        }

    }

} // transform_flow_to_regular



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
