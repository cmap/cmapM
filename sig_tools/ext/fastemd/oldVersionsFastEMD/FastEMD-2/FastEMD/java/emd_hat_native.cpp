#include "emd_hat_native.hpp"
#include <vector>
#include "emd_hat.hpp"

JNIEXPORT jdouble JNICALL Java_emd_1hat_native_1dist_1compute
(JNIEnv *env, jclass jc,
 jdoubleArray P_j, jdoubleArray Q_j, jdoubleArray Cv_j, jdouble extra_mass_penalty_j,
 jdoubleArray Fv_j,
 jint N_j, jint gd_metric_j, jint Fv_j_is_null_j) {

    int N= N_j;
    int gd_metric= gd_metric_j;
    int Fv_j_is_null= Fv_j_is_null_j;

    
    
    
    jdouble* P_j_e= env->GetDoubleArrayElements(P_j,NULL);
    std::vector<double> P(P_j_e,P_j_e+N);
    env->ReleaseDoubleArrayElements(P_j, P_j_e, JNI_ABORT);

    jdouble* Q_j_e= env->GetDoubleArrayElements(Q_j,NULL);
    std::vector<double> Q(Q_j_e,Q_j_e+N);
    env->ReleaseDoubleArrayElements(Q_j, Q_j_e, JNI_ABORT);

    jdouble* C_j_e= env->GetDoubleArrayElements(Cv_j,NULL);
    std::vector<double> Cvector(C_j_e,C_j_e+N*N);
    env->ReleaseDoubleArrayElements(Cv_j, C_j_e, JNI_ABORT);
        
    std::vector< std::vector<double> > C(N, std::vector<double>(N));
    int Cvector_i= 0;
    for (int i= 0; i<N; ++i) {
        for (int j= 0; j<N; ++j) {
            C[i][j]= Cvector[Cvector_i];
            ++Cvector_i;
        }
    }
        
    double extra_mass_penalty= extra_mass_penalty_j;
    
    std::vector< std::vector<double> >* Fp= NULL;
    if (!Fv_j_is_null) Fp= new std::vector< std::vector<double> >(N, std::vector<double>(N));

    double dist= -1;
    if (gd_metric) {
        if (Fp) {
            dist= emd_hat_gd_metric<double,WITHOUT_EXTRA_MASS_FLOW>()(P,Q,C,extra_mass_penalty,Fp);
        } else {
            dist= emd_hat_gd_metric<double,NO_FLOW>()(P,Q,C,extra_mass_penalty,Fp);
        }
    } else {
        if (Fp) {
            dist= emd_hat<double,WITHOUT_EXTRA_MASS_FLOW>()(P,Q,C,extra_mass_penalty,Fp);
        } else {
            dist= emd_hat<double,NO_FLOW>()(P,Q,C,extra_mass_penalty,Fp);
        }
    }
    assert(dist!=-1);
        
    // convert Fp to regular F
    if (Fp) {
        jboolean isCopy = JNI_FALSE;
        jdouble *Fv_j_e = env->GetDoubleArrayElements(Fv_j, &isCopy);
        int Fv_j_e_i= 0;
        for (int i= 0; i<N; ++i) {
            for (int j= 0; j<N; ++j) {
                Fv_j_e[Fv_j_e_i]= (*Fp)[i][j];
                ++Fv_j_e_i;
            }
        }
        // The third argument here should be 0, so that content will change
        // on original array.
        env->ReleaseDoubleArrayElements(Fv_j, Fv_j_e, 0);
    }

    return dist;
    
    delete Fp;
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
