// Mount Plate Module
//
// Author: Steven Nemetz
//
// Current version: https://github.com/snemetz/OpenSCAD-Modules/tree/master/pcb-mount-plate
// TODO: Customizable: http://www.thingiverse.com/thing:
/*
	REVISION HISTORY
	v0.1 Initial working version
*/
// TODO: Future Feature Ideas
//	add more designs
//  improve current designs
//  none of board data works. Figure out how to store in module
//  plate may need some changes as case for it to mount into is designed
//  add text to plate between posts and end of plate

//CUSTOMIZER VARIABLES

//CUSTOMIZER VARIABLES END

/* [Hidden] */

use <../standoffs/StandoffGenerator.scad>;
use <designs.scad>;

// If standoffs are hollow, plate needs holes
//	Parameters
//		locations: vector of x,y vectors of hole locations
//    diameter: size of the holes
//		depth: the depth of the holes in mm
// TODO: fix # of circle fragments
module mountHoles(locations, diameter = 2.8, depth = 5) {
  for(holePos = locations) {
    translate([holePos[0], holePos[1], -depth/2+0.1]) cylinder(d=diameter, h=depth);
  }
}

// Create and place standoffs
//	Parameters
//		locations: vector of x,y vectors of post locations
//		boardThick: thickness of the mount plate board
//		postBase: [shape, baseHeight, baseDiameter]
//    postTop: [style, topHeight, topDiameter]
module mountPosts(locations, boardThick, postBase, postTop) {
  for (postPos = locations) {
    translate([postPos[0], postPos[1], boardThick])
      standoff(postBase[0], postBase[1], postBase[2], postTop[0], postTop[1], postTop[2]);
  }
}

// Get design
//	Parameters
//    image: name of design to get
module design(image) {
  // no match = [[]] - len(search)[0] == 0
  // match = undef
  // len(search([image], )[0]) != 0
  if (image == "Pine64") {design_pine64();
  } else if (len(search([image], ["BPi", "BPiM1","BPiM2+"])[0]) != 0)
   {design_bpi();
  } else if (image == "odroid")
   {design_odroid();
  } else if (len(search([image], ["OPi","OPiOne","OPiPC","OPiPlus","OPi2","OPiPlus2"])[0]) != 0)
   {design_opi();
  } else if (len(search([image], ["RPi","RPi1B","RPi1B+","RPiZero","RPi1A+"])[0]) != 0)
   {design_rpi();
  } else if (image == "parallella") {design_parallella();};
}

// Setup design to merge into plate
//	Parameters
//    image: design name to place
//    locations: vector of x,y vectors of post locations
//    boardThick: thickness of the mount plate board
//    postDia: post diameter
//    z: z offset
// FIX: is max to furthest points instead of min
module design_placed(image, locations, boardThick, postDia, z) {
  shrinkage = postDia/2;
  len_x = max_x(locations)-min_x(locations);
  len_y = max_y(locations)-min_y(locations);
  translate([len_x/2+shrinkage,len_y/2+shrinkage,z])
  resize([len_x-shrinkage,len_y-shrinkage,boardThick+1])
    rotate([0,0,90]) design(image);
}

// Create mount board
//	Parameters
//    dimensions: board dimensions
//		locations: vector of x,y vectors of post locations
//		postBase: [shape, baseHeight, baseDiameter]
//    postTop: [style, topHeight, topDiameter]
module board(dimensions, locations, postBase, postTop) {
  if (postTop[0] == 5) { // hollow post - need holes in board
    difference() {
      union() {
        cube(dimensions, center=false);
        mountPosts(locations, dimensions[2], postBase, postTop);
      };
      mountHoles(locations, postTop[2], dimensions[2]*2);
    }
  } else {
    union() {
      cube(dimensions, center=false);
      mountPosts(locations, dimensions[2], postBase, postTop);
    }
  }
}

// Create mount plate
//	Parameters
//    plateDim: plate dimensions
//    boardDim: board dimensions
//		mountLocs: vector of x,y vectors of post locations
//    image: design to put in plate
//		postBase: [shape, baseHeight, baseDiameter]
//    postTop: [style, topHeight, topDiameter]
module pcbMountPlate(plateDim, boardDim, mountLocs, image, postBase, postTop) {
  diff = plateDim[2] - boardDim[2];
  difference () {
    union() {
      translate ([-(plateDim[0] - boardDim[0])/2,-(plateDim[1]-boardDim[1])/2,-diff])
        cube(plateDim);
      board(boardDim,mountLocs, postBase, postTop);
    };
    design_placed(image, mountLocs, plateDim[2]*2, postBase[1], -diff-0.1);
    if (postTop[0] == 5) { // hollow
      mountHoles(mountLocs, postTop[2], plateDim[2]*2);
    };
  };

}


module knownBoard(name, postBase, postTop, design=true) {
  // Get vector index for a board
  // will return empty vector if not found
  function findBoard(name,boards=boards) =
   (len(boards[search([name], boards)[0]]) == 2) ?
    search([boards[search([name], boards)[0]][1]], boards)[0] :
     search([name], boards)[0];
  // for generating selection list for customizer
  function getBoards(boards=boards) = [ for (board = boards) board[0] ];
  // known boards specs
  boards = [
    // [Name , [dim], [mount holePos]]
    // [Alias, Name]
    // ["name", [x,y,z],[[x,y],[x,y],[x,y],[x,y]]],
    // ["name2", [x,y,z],[[x,y],[x,y],[x,y],[x,y]]],
    // Ardunio
    // Banana Pi
    // Holes: Internal
    // [91.5,60,],[[3,3],[3,57],[89,3],[89,52]]
    ["BPiM1",  [92, 60, 1.25],[[3,3],[3,57],[89,3],[89,52]]],
    ["BPiM1+", "BPiM1"],
    ["BPiM2",  "BPiM1"],
    ["BPiM3",  "BPiM1"],
    ["BPiM2+", [65, 65, 1.25],[]],
    // Beaglebone
    // Jaguar boards
    ["JaguarOne", [101.9, 64.5, 1.6],[]],
    // ODROID
    //OdroidC0
    //["OdroidC1+", [85, 56, 1.25],[]], // same as C2
  	["OdroidC2",  [85, 56, 1.25],[]],
  	["OdroidXU4", [82, 58, 1.25],[]],
    // Orange Pi
    // Thick 1.5 ?
    // Holes: Internal 3
    ["OPiOne",   [69, 48, 1.25],[]],
    ["OPiPC",    [85, 55, 1.25],[]],
    ["OPiPlus",  [108, 60, 1.25],[]],
    ["OPi2",     [93, 60, 1.25],[]],
    ["OPiMini2","OPi2"],
    ["OPiPlus2", [108, 67, 1.25],[]],
    // Parallella
    // https://github.com/parallella/parallella-hw
    // Holes: Internal 0.125"
    // 3.4" x 2.15" x .62" ?
    //["Parallella", [],[]],
    // Pine
    // Holes: Internal 3
    ["Pine64", [127, 79, 1.2],[[4.3,4.3],[4.3,75.2],[122.7,4.3],[122.7,75.2]]],
    // Raspberry Pi
    ["RPi1B",  	[85, 56, 1.25],[[80, 43.5], [25, 17.5]]],
    // Holes: M2.5 - Internal 2.75, external 6.2
    ["RPi1B+",  [85, 56, 1.25],[[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]]],
    ["RPi2B", "RPi1B+"],
    ["RPi3B", "RPi1B+"],
    ["RPiZero", [65, 30, 1.25],[[3.5, 3.5], [61.5, 3.5], [3.5, 26.5], [61.5, 26.5]]],
    ["RPi1A+",  [65, 56, 1.25],[[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]]]
  ];

  // generate mount plate
  boardIndex = findBoard(name);
  translate([-boards[boardIndex][1][0]/2,-boards[boardIndex][1][1]/2,0]) // this should be outside, but dim only known here
  pcbMountPlate(plate, boards[boardIndex][1], boards[boardIndex][2],
    (design) ? boards[boardIndex][0] : "", postBase, postTop);

  // testing
  echo("Func=:",findBoard(name));
  echo(boards[boardIndex]);
  echo("0 name=",boards[boardIndex][0]);
  echo("1 dim =",boards[boardIndex][1]); // ok
  echo("2 locs=",boards[boardIndex][2]); // ok
}

// Create an array of post mount (post) locations (for customizer)
//	Parameters
//    row_data: [rows, x_origin, x_offset]
//    column_data: [columns, y_origin, y_offset]
function mountPoints(row_data, column_data) = [
  for (j = [1 : row_data[0]])
    for( i = [1 : column_data[0]])
      [(j-1) * row_data[2] + row_data[1], (i-1) * column_data[2] + column_data[1]]
];

// Testing
// Create sample STLs:
//  many posts - w/ & w/o design
//  without design

// do lots posts
//mountLocs = [[3.5, 3.5], [3.5, 12.5], [3.5, 22.5], [3.5, 32.5], [3.5, 42.5], [21.5, 3.5], [41.5, 3.5], [61.5, 3.5], [3.5, 52.5], [21.5, 52.5], [41.5, 52.5], [61.5, 52.5]];
//mountLocs = [[3.5, 3.5], [3.5, 12.5], [3.5, 22.5], [3.5, 32.5],[3.5, 42.5], [21.5, 3.5], [41.5, 3.5], [61.5, 3.5], [3.5, 52.5], [21.5, 52.5], [41.5, 52.5], [61.5, 52.5], [13.5, 22.5], [23.5, 22.5], [33.5, 22.5], [43.5, 22.5],  [50,5],[50,15],[50,30],[50,45]];

//mountLocs = mountPoints([9, 3.5, 13], [8, 3.5, 10]);
//boardDim = [110, 78, 1.25];
//plate = [112, 80, 1.5];

// RPi
mountLocs = [[3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]];
boardDim = [92, 60, 1.25];
plate = [112, 80, 1.5];
// image = "Rpi";
// image = "opi";
// image = "bpi";
// image = "odroid";
// image = "parallella";
image = "Pine64";
board = "Pine64";
postBase = [1, 8, 5];
postTop = [5, 5, 2];
//translate([-boardDim[0]/2,-boardDim[1]/2,0])
//pcbMountPlate(plate, boardDim, mountLocs, image, postBase, postTop);

knownBoard(board, postBase, postTop, design=true);

// END

/*function flatten(l) = [ for (a = l) for (b = a) b ];
function dim (name="RPi3B") = [ // use search instead ?? yes
  // Can't have any {} or =
  for (board = boards)
    (board[0] == name) ? board[1] : []
]; */
