#include "emd_hat.hpp"
#include "min_cost_flow.hpp"
#include <set>
#include <limits>
#include <cassert>
#include <algorithm>
#include <vector>

NUM_T emd_hat_metric(const std::vector<NUM_T>& Pc, const std::vector<NUM_T>& Qc, const std::vector< std::vector<NUM_T> >& C,
                     NUM_T extra_mass_penalty) {

    std::vector<NUM_T> P= Pc;
    std::vector<NUM_T> Q= Qc;
    
    // Assuming metric property we can pre-flow 0-cost edges
    {for (NODE_T i=0; i<P.size(); ++i) {
        if (P[i]<Q[i]) {
            Q[i]-= P[i];
            P[i]= 0;
        } else {
            P[i]-= Q[i];
            Q[i]= 0;
        }
    }}
    
    return emd_hat(P,Q,C,extra_mass_penalty);
        
} // emd_hat_metric
    
NUM_T emd_hat(const std::vector<NUM_T>& Pc, const std::vector<NUM_T>& Qc, const std::vector< std::vector<NUM_T> >& C,
              NUM_T extra_mass_penalty)  {

    //-------------------------------------------------------
    NODE_T N= Pc.size();
    assert(Qc.size()==N);

    // Ensuring that the supplier - P, have more mass.
    // Note that we assume here that C is symmetric
    std::vector<NUM_T> P;
    std::vector<NUM_T> Q;
    NUM_T abs_diff_sum_P_sum_Q;
    NUM_T sum_P= 0;
    NUM_T sum_Q= 0;
    {for (NODE_T i=0; i<N; ++i) sum_P+= Pc[i];}
    {for (NODE_T i=0; i<N; ++i) sum_Q+= Qc[i];}
    if (sum_Q>sum_P) {
        P= Qc;
        Q= Pc;
        abs_diff_sum_P_sum_Q= sum_Q-sum_P;
    } else {
        P= Pc;
        Q= Qc;
        abs_diff_sum_P_sum_Q= sum_P-sum_Q;
    }

    // creating the b vector that contains all vertexes
    std::vector<NUM_T> b(2*N+2);
    const NODE_T THRESHOLD_NODE= 2*N;
    const NODE_T ARTIFICIAL_NODE= 2*N+1; // need to be last !
    {for (NODE_T i=0; i<N; ++i) {
        b[i]= P[i];
    }}
    {for (NODE_T i=N; i<2*N; ++i) {
        b[i]= -(Q[i-N]);
    }}
    
    // remark*) I put here a deficit of the extra mass, as mass that flows to the threshold node
    // can be absorbed from all sources with cost zero (this is in reverse order from the paper,
    // where incoming edges to the threshold node had the cost of the threshold and outgoing
    // edges had the cost of zero)
    // This also makes sum of b zero.
    b[THRESHOLD_NODE]= -abs_diff_sum_P_sum_Q; 
    b[ARTIFICIAL_NODE]= 0;
    //-------------------------------------------------------
    
    //-------------------------------------------------------
    NUM_T maxC= 0;
    {for (NODE_T i=0; i<N; ++i) {
        {for (NODE_T j=0; j<N; ++j) {
            assert(C[i][j]>=0);
            if ( C[i][j]>maxC ) maxC= C[i][j];
        }}
    }}
    if (extra_mass_penalty==-1) extra_mass_penalty= maxC;
    //-------------------------------------------------------
   
    
    //=============================================================
    std::set< NODE_T > sources_that_flow_not_only_to_thresh; 
    std::set< NODE_T > sinks_that_get_flow_not_only_from_thresh; 
    NUM_T THRESH_PRE_FLOW= 0;
    //=============================================================

    //=============================================================
    // regular edges between sinks and sources without threshold edges
    std::vector< std::list< edge > > c(b.size());
    {for (NODE_T i=0; i<N; ++i) {
        if (b[i]==0) continue;
        {for (NODE_T j=0; j<N; ++j) {
            if (b[j+N]==0) continue;
            if (C[i][j]==maxC) continue;
            c[i].push_back( edge(j+N , C[i][j]) );
            sources_that_flow_not_only_to_thresh.insert(i);
            sinks_that_get_flow_not_only_from_thresh.insert(j+N);
        }} // j
    }}// i

    // add edges from/to threshold node,
    // note that costs are reversed to the paper (see also remark* above)
    // It is important that it will be this way because of remark* above.
    {for (NODE_T i=0; i<N; ++i) {
        c[i].push_back( edge(THRESHOLD_NODE, 0) );
    }}
    {for (NODE_T j=0; j<N; ++j) {
        c[THRESHOLD_NODE].push_back( edge(j+N, maxC) );
    }} 
    
    // artificial arcs - Note the restriction that only one edge i,j is artificial so I ignore it...
    {for (NODE_T i=0; i<ARTIFICIAL_NODE; ++i) {
        c[i].push_back( edge(ARTIFICIAL_NODE, maxC + 1 ) );
        c[ARTIFICIAL_NODE].push_back( edge(i, maxC + 1 ) );
    }}
    //=============================================================


    
    //====================================================    
    // remove nodes with supply demand of 0
    // and isolated vertexes
    //====================================================    
    NODE_T current_node_name= 0;
    // Note here it should be vector<int> and not vector<NODE_T>
    // as I'm using -1 as a special flag !!!
    const int REMOVE_NODE_FLAG= -1;
    std::vector<int> nodes_new_names(b.size(),REMOVE_NODE_FLAG);
    {for (NODE_T i=0; i<N*2; ++i) {
        if (b[i]!=0) {
            if (sources_that_flow_not_only_to_thresh.find(i)!=sources_that_flow_not_only_to_thresh.end()|| 
                sinks_that_get_flow_not_only_from_thresh.find(i)!=sinks_that_get_flow_not_only_from_thresh.end()) {
                nodes_new_names[i]= current_node_name;
                ++current_node_name;
            } else {
                if (i>=N) { // sink
                    THRESH_PRE_FLOW-= b[i];
                }
                b[THRESHOLD_NODE]+= b[i]; // add mass(i<N) or deficit (i>=N)
            } 
        }
    }} //i
    nodes_new_names[THRESHOLD_NODE]= current_node_name;
    ++current_node_name;
    nodes_new_names[ARTIFICIAL_NODE]= current_node_name;
    ++current_node_name;
        
    std::vector<int> bb(current_node_name);
    NODE_T j=0;
    {for (NODE_T i=0; i<b.size(); ++i) {
        if (nodes_new_names[i]!=REMOVE_NODE_FLAG) {
            bb[j]= b[i];
            ++j;
        }
    }}
        
    std::vector< std::list< edge > > cc(bb.size());
    {for (NODE_T i=0; i<c.size(); ++i) {
        if (nodes_new_names[i]==REMOVE_NODE_FLAG) continue;
        {for (std::list< edge >::const_iterator it= c[i].begin(); it!=c[i].end(); ++it) {
            if ( nodes_new_names[it->_to]!=REMOVE_NODE_FLAG) {
                cc[ nodes_new_names[i] ].push_back( edge( nodes_new_names[it->_to], it->_cost ) );
            }
        }}
    }}
    //====================================================    

    #ifndef NDEBUG
    NUM_T DEBUG_sum_bb= 0;
    for (unsigned int i=0; i<bb.size(); ++i) DEBUG_sum_bb+= bb[i];
    assert(DEBUG_sum_bb==0);
    #endif

    //-------------------------------------------------------
    min_cost_flow mcf;
        
    NUM_T my_dist;
    
    //tictoc timer;
    //timer.tic();
    //std::cout << bb.size() << std::endl;
    //std::cout << cc.size() << std::endl;
    
    my_dist=
        mcf(bb,cc) +                               // solution of the transportation problem
        (THRESH_PRE_FLOW*maxC) +                   // pre-flowing
        (abs_diff_sum_P_sum_Q*extra_mass_penalty); // emd-hat extra mass penalty
    //timer.toc();
    //std::cout << "min_cost_flow time== " << timer.totalTimeSec() << std::endl;
    return my_dist;
    //-------------------------------------------------------
    
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
