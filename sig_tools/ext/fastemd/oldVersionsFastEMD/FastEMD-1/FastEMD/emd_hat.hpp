#ifndef EMD_HAT_HXX
#define EMD_HAT_HXX

#include <vector>
#include "EMD_DEFS.hpp"
#include "min_cost_flow.hpp"

/// Fastest version of EMD. Also, in my experience metric ground distance and setting extra_mass_penalty to
/// the appropriate value yields better performance.
/// P,Q - two histograms of size N
/// C - The NxN matrix of the ground distance between bins of P and Q. Should be a metric.
/// extra_mass_penalty - the penalty for extra mass - should be at least half the diameter
///                      of the space (maximum possible distance between any two points).
///                      Default value is -1 which means 1*max_element_in_C
NUM_T emd_hat_metric(const std::vector<NUM_T>& P, const std::vector<NUM_T>& Q, const std::vector< std::vector<NUM_T> >& C,
                     NUM_T extra_mass_penalty= -1);

/// Same as emd_hat, but does not assume metric property for the ground distance (C).
/// Also, extra_mass_penalty can be any non-negative number.
/// Note that C should still be symmetric !
NUM_T emd_hat(const std::vector<NUM_T>& P, const std::vector<NUM_T>& Q, const std::vector< std::vector<NUM_T> >& C,
              NUM_T extra_mass_penalty= -1);

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
