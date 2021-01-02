namespace grid{
namespace rect{


/* (Autoinserted by mtoc++)
 * This source code has been filtered by the mtoc++ executable,
 * which generates code that can be processed by the doxygen documentation tool.
 *
 * On the other hand, it can neither be interpreted by MATLAB, nor can it be compiled with a C++ compiler.
 * Except for the comments, the function bodies of your M-file functions are untouched.
 * Consequently, the FILTER_SOURCE_FILES doxygen switch (default in our Doxyfile.template) will produce
 * attached source files that are highly readable by humans.
 *
 * Additionally, links in the doxygen generated documentation to the source code of functions and class members refer to
 * the correct locations in the source code browser.
 * However, the line numbers most likely do not correspond to the line numbers in the original MATLAB source files.
 */

class rectgrid {
/** @class "grid::rect::rectgrid"
  * @ingroup test
  * @brief  help for rectgrid is a class for a rectangular grid in 2 dimensions
  *
  *
  *  rectgrid is a class for a rectangular grid in 2 dimensions
  *
 */


  public:


    rectgrid(matlabtypesubstitute varargin) {


    /*  Bernard Haasdonk 9.5.2007 */

    
    addRequired(p, 'xnumintervals');
    p.addRequired('xnumintervals2');
    addOptional(p, 'ynumintervals', 100);
    p.addOptional('ynumintervals2', 100);
    addParamValue(p, 'bnd_rect_corner1', [-inf,-inf]);
    p.addParamValue('bnd_rect_corner21', [-inf,-inf]);
    addParamValue(p, 'bnd_rect_corner2', [+inf,+inf]);
    p.addParamValue('bnd_rect_corner22', [+inf,+inf], @isnumeric);

    /* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     * copy constructor */
    if (nargin>0) & ...
          isa(varargin[1]," rectgrid ")
      grid= varargin[1];
    else
      /* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       * default constructor: unit square */
      if (nargin==0)
        params.xnumintervals= 2;
        params.ynumintervals= 2;
        params.xrange= [0,1];
        params.yrange= [0,1];
        /*  mark element in rectangle from [-1,-1] to [+2,+2] with index -1 */
        params.bnd_rect_corner1= [-1,-1]^t;
        params.bnd_rect_corner2= [2 2]^t;
        params.bnd_rect_index= [-1];
        params.verbose= 0;
      else
        params = varargin[1];
      end;

      /* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       * construct from params */

      grid = [];

    /*   if ~isfield(params,'verbose')
     *    params.verbose = 0;
     *  end; */

      nx = params.xnumintervals;
      ny = params.ynumintervals;

      grid.nelements=nx*ny;
      grid.nvertices=(nx+1)*(ny+1);

      /*  get areas of grid-cells */
      dx = (params.xrange(2)-params.xrange(1))/nx;
      dy = (params.yrange(2)-params.yrange(1))/ny;
      grid.A= dx*dy*ones(nx*ny,1);
      grid.Ainv= grid.A.^(-1);

      /*  set vertex coordinates */
      vind = (1:(nx+1)*(ny+1))^t;
      grid.X= mod(vind-1,nx+1) * dx + params.xrange(1);
      grid.Y= floor((vind-1)/(nx+1))*dy  + params.yrange(1);

      /*  set element vertex indices: numbering starting right lower corner
       * counterclockwise, i.e. edge j connects vertex j and j+1
       * nx+2--nx+3-- ...
       *  |     |
       *  |  1  | 2 ...
       *  |     |
       *  1-----2---- ...
       *  =>  grid.VI = [ 2 nx+3 nx+2 1]; */

      el_ind = 1:length(grid.A);
      col_ind = transpose(mod((el_ind-1),nx)+1);
      row_ind = transpose(floor((el_ind-1)/nx)+1);
      VI = zeros(length(grid.A),4);
      VI(:,1) = (row_ind-1)*(nx+1)+1 +col_ind;
      VI(:,2) = (row_ind  )*(nx+1)+1 +col_ind;
      VI(:,3) = (row_ind  )*(nx+1)   +col_ind;
      VI(:,4) = (row_ind-1)*(nx+1)   +col_ind;
      grid.VI= VI;

      /*  midpoint coordinates of grid-cells */
      CX = (0:(nx-1))*(params.xrange(2)-params.xrange(1))/ ...
           nx+dx/2+params.xrange(1);
      CX = CX(:);
      grid.CX= repmat(CX,ny,1);
      CY = (0:(ny-1))*(params.yrange(2)-params.yrange(1))/ ...
           ny+dy/2+ params.yrange(1);
      CY = repmat(CY,nx,1);
      grid.CY= CY(:);
      disp(" stopping after COG computation ");
      /* keyboard; */

      /*  check consistency: grid-midpoints and vertices */
      xdiff1 = max(abs(grid.CX + dx/2 -grid.X(grid.VI(:,1))));
      xdiff2 = max(abs(grid.CX + dx/2 -grid.X(grid.VI(:,2))));
      xdiff3 = max(abs(grid.CX - dx/2 -grid.X(grid.VI(:,3))));
      xdiff4 = max(abs(grid.CX - dx/2 -grid.X(grid.VI(:,4))));
      ydiff1 = max(abs(grid.CY - dy/2 -grid.Y(grid.VI(:,1))));
      ydiff2 = max(abs(grid.CY + dy/2 -grid.Y(grid.VI(:,2))));
      ydiff3 = max(abs(grid.CY + dy/2 -grid.Y(grid.VI(:,3))));
      ydiff4 = max(abs(grid.CY - dy/2 -grid.Y(grid.VI(:,4))));

      if params.verbose>=10
        disp([xdiff1,xdiff2,xdiff3,xdiff4, ...
    	  ydiff1,ydiff2,ydiff3,ydiff4]);

        if max([xdiff1,xdiff2,xdiff3,xdiff4, ...
    	    ydiff1,ydiff2,ydiff3,ydiff4] > eps)
          error(" vertex coordinate and element midpoint consistency!! ");
        end;
      end;

      /*  matrix with edge-lengths */
      grid.EL= repmat([dy, dx, dy, dx ],size(grid.CX,1),1);

      /*  matrix with midpoint-distances */
      grid.DC= repmat([dx, dy, dx, dy],size(grid.CX,1),1);

      /*  matrix with (unit) normal components */
      grid.NX= repmat([1,0,-1,0],size(grid.CX,1),1);
      grid.NY= repmat([0,1,0,-1],size(grid.CX,1),1);

      /*  matrix with edge-midpoint-coordinates
       * this computation yields epsilon-differing edge-midpoints on
       * neighbouring elements. This is adjusted at end of this routine */
      grid.ECX= [grid.CX + dx/2,grid.CX,grid.CX-dx/2,grid.CX];
      grid.ECY= [grid.CY, grid.CY + dy/2,grid.CY,grid.CY-dy/2];

      /* %% determine indices of neighbouring elements, */
      NBI = repmat((1:nx*ny)^t,1,4);
      /*  first column: +x direction: cyclical shift +1 of indices */
      NBI(:,1) = NBI(:,1)+1;
      /*  second column: +y direction */
      NBI(:,2) = NBI(:,2)+nx;
      /*  third column: -x direction */
      NBI(:,3) = NBI(:,3)-1;
      /*  fourth column: -y direction */
      NBI(:,4) = NBI(:,4)-nx;

      /*  correct boundary elements neighbour-indices: */
      bnd_i1 = (1:ny)*nx; /*  indices of right-column elements */
      bnd_i2 = (1:nx)+ nx*(ny-1); /*  indices of upper el */
      bnd_i3 = (1:ny)*nx-nx+1; /*  indices of left-column */
      bnd_i4 = 1:nx; /*  indices of lower row elements */
      SX = [grid.ECX(bnd_i1,1); grid.ECX(bnd_i2,2); grid.ECX(bnd_i3,3); grid.ECX(bnd_i4, 4)];
      SY = [grid.ECY(bnd_i1,1); grid.ECY(bnd_i2,2); grid.ECY(bnd_i3,3); grid.ECY(bnd_i4, 4)];

      /*  formerly default: Dirichlet :
       * bnd_ind = -1 * ones(1,length(SX));
       * now: set default to "symmetric", i.e. rectangle is a torus */

      bnd_ind = [NBI(bnd_i1,1)" -nx, NBI(bnd_i2,2) "-nx*ny, ...
    	     NBI(bnd_i3,3)" +nx, NBI(bnd_i4,4) "+nx*ny];

    /*   disp('halt 1');
     *  keyboard; */

      if ~isfield(params, " bnd_rect_index ")
        params.bnd_rect_index= [];
      end

      if ~isempty(params.bnd_rect_index)
    /*     keyboard; */
        if (max(params.bnd_rect_index)>0)
          error(" boundary indices must be negative! ");
        end;
        if size(params.bnd_rect_corner1,1) == 1
          params.bnd_rect_corner1= params.bnd_rect_corner1^t;
        end;
        if size(params.bnd_rect_corner2,1) == 1
          params.bnd_rect_corner2= params.bnd_rect_corner2^t;
        end;
        for i = 1:length(params.bnd_rect_index)
          indx = (SX > params.bnd_rect_corner1(1,i)) & ...
    	     (SX < params.bnd_rect_corner2(1,i)) & ...
    	     (SY > params.bnd_rect_corner1(2,i)) & ...
    	     (SY < params.bnd_rect_corner2(2,i));
          bnd_ind(indx) = params.bnd_rect_index(i);
        end;
      end;
    /*   disp('halt 2');
     *  keyboard; */

      iend1 = length(bnd_i1);
      iend2 = iend1 + length(bnd_i2);
      iend3 = iend2 + length(bnd_i3);
      iend4 = iend3 + length(bnd_i4);
      NBI(bnd_i1,1) = bnd_ind(1:iend1)^t; /*  set right border-neigbours to boundary */
      NBI(bnd_i2,2) = bnd_ind((iend1+1):iend2)^t; /*  set neighbours to boundary */
      NBI(bnd_i3,3) = bnd_ind((iend2+1):iend3)^t; /*  set neigbours to boundary */
      NBI(bnd_i4,4) = bnd_ind((iend3+1):iend4)^t; /*  set neighbours to boundary */

      grid.NBI= NBI;

      /*  INB: INB(i,j) = local edge number in NBI(i,j) leading from element
       *                 NBI(i,j) to element i, i.e. satisfying
       *                 NBI(NBI(i,j), INB(i,j)) = i */
      INB = repmat([3 4 1 2],size(grid.NBI,1),1);
      grid.INB= INB;

      /*  check grid consistency: */
      nonzero = find(NBI>0); /*  vector with vector-indices */
      [i,j] = ind2sub(size(NBI), nonzero); /*  vectors with matrix indices */
      NBIind = NBI(nonzero); /*  vector with global neighbour indices */
      INBind = INB(nonzero);
      i2 = sub2ind(size(NBI),NBIind, INBind);
      i3 = NBI(i2);
      if ~isequal(i3,i)
    /*     plot_element_data(grid,grid.NBI,params); */
        disp(" neighbour indices are not consistent!! ");
        keyboard;
      end;

      grid.hmin= sqrt(dx^2+dy^2); /*  minimal diameter of elements
    			        * CAUTION: this geometry bound is
                                    * adapted to triangles, should be extended
    			        * properly to rectangles */
      alpha1 = dx * dy/(dx^2+dy^2); /*  geometry bound */
      alpha2 = sqrt(dx^2+dy^2)/(2*dx + 2*dy);
      alpha3 = dx / sqrt(dx^2+dy^2);
      grid.alpha= min([alpha1,alpha2,alpha3]);	

      /*  make entries of ECX, ECY exactly identical for neighbouring elements!
       * currently by construction a small eps deviation is possible. */

      /* averaging over all pairs is required */
      nonzero = find(grid.NBI>0); /*  vector with vector-indices */
      [i,j] = ind2sub(size(grid.NBI), nonzero); /*  vectors with matrix indices */
      NBIind = NBI(nonzero); /*  vector with global neighbour indices */
      INBind = INB(nonzero); /*  vector with local edge indices */
      i2 = sub2ind(size(NBI),NBIind, INBind);
      /*  determine maximum difference in edge-midpoints, but exclude
       * symmetry boundaries by relative error < 0.0001 */
      diffx = abs(grid.ECX(nonzero)-grid.ECX(i2));
      diffy = abs(grid.ECY(nonzero)-grid.ECY(i2));
      fi = find ( (diffx/(max(grid.X)-min(grid.X)) < 0.0001) &  ...
    	      (diffy/(max(grid.Y)-min(grid.Y)) < 0.0001) );

      /* disp(max(diffx));
       *disp(max(diffy));
       *  => 0 ! :-)
       * keyboard; */

      grid.ECX(nonzero(fi)) = 0.5*(grid.ECX(nonzero(fi))+ grid.ECX(i2(fi)));
      grid.ECY(nonzero(fi)) = 0.5*(grid.ECY(nonzero(fi))+ grid.ECY(i2(fi)));

      /*  for diffusion discretization: Assumption of points with
       * orthogonal connections to edges. Distances and intersections
       * determined here. In cartesian case identical to centroids */
      grid.SX= grid.CX;
      grid.SY= grid.CY;
      grid.ESX= grid.ECX;
      grid.ESY= grid.ECY;
      grid.DS= grid.DC;
      grid.nneigh= 4;

      grid = class(grid," rectgrid ");

    }
/** @fn rectgrid(matlabtypesubstitute varargin)
  * @brief  constructor of rectgrid
  *
  *
  *  constructor of a cartesian rectangular grid in 2 dimensions with
  *  axis parallel elements. General geometrical information is stored
  *  includng neighbour information. Therefore also boundary neighbour
  *  relations can be specified. The boundary type is set
  * @par  to be symmetric by default. Additionally, "rectangles" can be defined
  *  the edges with midpoints within such a rectangle are marked accordingly.
  *  By this boundary edges can be marked for later special use
  *  Much (partially redundant) information is stored in the grid,
  *  which might be useful in simulations.
  * 
  *  sorting of vertices is always counterclockwise SE,NE,NW,SW
  *  local edge j (1..4) is connecting points j and j+1
  * 
  * @par      optional fields
  *          bnd_rect_corner1: coordinates of lower corner of to be marked
  *                    boundaries
  *          bnd_rect_corner2: coordinates of upper corner of to be marked
  *                    boundaries
  *          bnd_rect_index: integer index to be set on the edges in
  *                  the above  defined
  *                  rectangle. Should not be positive integer in the
  *                  range of the number of elements. use negative
  *                  indices for certain later discrimination.
  * 
  *  for the last three optional boundary settings, also multiple rectangles
  *  can be straightforwardly defined by accepting matrix of columnwise
  *  corners1, corners2 and a vector of indices for the different rectangles.
  * 
  *  perhaps later: constructor by duneDGF-file?
  *  perhaps later: contructor-flag: full vs non-full
  *                  => only compute redundant information if required.
  * 
  * @par  internal fields
  *  nelements: number of elements
  *  nvertices: number of vertices
  *  nneigh: 4
  * 
  *  A  : vector of element area
  *  Ainv  : vector of inverted element area
  *  X  : vector of vertex x-coordinates
  *  Y  : vector of vertex y-coordinates
  *  VI : matrix of vertex indices: VI(i,j) is the global index of j-th
  *       vertex of element i
  *  CX  : vector of centroid x-values
  *  CY  : vector of centroid y-values
  *  NBI: NBI(i,j) = element index of j-th neighbour of element i
  *                  boundary faces are set to -1 or negative values are
  *                  requested by params.boundary_type
  *  INB: INB(i,j) = local edge number in NBI(i,j) leading from element
  *                  NBI(i,j) to element i, i.e. satisfying
  *                  NBI(NBI(i,j), INB(i,j)) = i
  *  EL : EL(i,j) = length of edge from element i to neighbour j
  *  DC : DC(i,j) = distance from centroid of element i to NB j
  *                for boundary elements, this is the distance to the
  *                reflected element (for use in boundary treatment)
  *  NX : NX(i,j) = x-coordinate of unit outer normal of edge from el i to NB j
  *  NY : NY(i,j) = y-coordinate of unit outer normal of edge from el i to NB j
  *  ECX : ECX(i,j) = x-coordinate of midpoint of edge from el i to NB j
  *  ECY : ECY(i,j) = y-coordinate of midpoint of edge from el i to NB j
  * 
  *  for diffusion-discretization with FV-schemes, points S_i must
  *  exist, such that S_i S_j is perpendicular to edge i j the
  * @par  intersection are denoted S_ij
  * 
  *  SX : vector of x-coordinates of point S_i (for rect: identical to centroids)
  *  SY : vector of y-coordinate of point S_j (for rect: identical to centroids)
  *  ESX : ESX(i,j) = x-coordinate of point S_ij on edge el i to NB j
  *  ESY : ESY(i,j) = y-coordinate of point S_ij on edge el i to NB j
  *  DS : DS(i,j) = distance from S_i of element i to S_j of NB j
  *                for boundary elements, this is the distance to the
  *                reflected element (for use in boundary treatment)
  *  hmin : minimal element-diameter
  *  alpha: geometry bound (simultaneously satisfying alpha* h_i^d <= A(T_i),
  *         alpha * circumfere(T_i) <= h_i^(d-1) and
  *         alpha * h_i <= distance(midpoint i to any neigbour) )
  *
  * @param varargin     variable number of constructors. The constructor can be used
  *              as
  *      - rectgrid() : construction of a default rectgrid (2d unit square,
  *                     2x2 elements with -1 as outer neighbour indices)
  *      - rectgrid(rgrid) : copy-constructor
  *      - rectgrid(options) : generate rectgrid with certain options, which
  *      must be one of the following: 
  *      .
  * @code rectgrid ( xrange, yrange, xnumintervals, xnumintervals2,
           [ ynumintervals [, ynumintervals2
           [, "bnd_rect_corner1", bnd_rect_corner1_value ] [, "bnd_rect_corner21", bnd_rect_corner21_value ]
           [, "bnd_rect_corner2", bnd_rect_corner2_value ] [, "bnd_rect_corner22", bnd_rect_corner22_value ] ] ] ) @endcode
  * <i>Required Parameters for varargin:</i>
  * - <span class="paramname"> xrange</span>     interval covered along the x-axes
  * - <span class="paramname"> yrange</span>     interval covered along the y-axes
  * - <span class="paramname"> xnumintervals</span>     number of elements along x directions
  * - <span class="paramname"> xnumintervals2</span>    xnumintervals2
  * .
  * <i>Optional Parameters for varargin:</i>
  * - <span class="paramname"> ynumintervals</span>     number of elements along y directions
  *      ( @b Default: <tt>100</tt> )
  * - <span class="paramname"> ynumintervals2</span>    ynumintervals2
  *      ( @b Default: <tt>100</tt> )
  * .
  * <i>Named Parameters for varargin:</i>
  * - <span class="paramname"> bnd_rect_corner1</span>    bnd rect corner1
  *      ( @b Default: <tt>[-inf,-inf]</tt> )
  * - <span class="paramname"> bnd_rect_corner21</span>    bnd rect corner21
  *      ( @b Default: <tt>[-inf,-inf]</tt> )
  * - <span class="paramname"> bnd_rect_corner2</span>    bnd rect corner2
  *      ( @b Default: <tt>[+inf,+inf]</tt> )
  * - <span class="paramname"> bnd_rect_corner22</span>    bnd rect corner22
  *      ( @b Default: <tt>[+inf,+inf]</tt> )
  * .
  */


    noret::substitute demo();

    noret::substitute display();

    noret::substitute gridpart(matlabtypesubstitute eind);

    mlhsInnerSubst<matlabtypesubstitute,p> plot(::plot_params params);

    noret::substitute set_enbi(matlabtypesubstitute nbind,matlabtypesubstitute values);

  public: /* ( Static ) */

    static mlhsInnerSubst<matlabtypesubstitute,ret> test(::othergrid auto_param,matlabtypesubstitute b,::test c);

};
}
}




