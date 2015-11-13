/*
created with obj2opengl.pl

source file    : /Users/kirill/Desktop/PanoramaView/PanoramaView.obj
vertices       : 4
faces          : 2
normals        : 1
texture coords : 4


// include generated arrays
#import "/Users/kirill/Desktop/PanoramaView/PanoramaView.h"

// set input data to arrays
glVertexPointer(3, GL_FLOAT, 0, PanoramaViewVerts);
glNormalPointer(GL_FLOAT, 0, PanoramaViewNormals);
glTexCoordPointer(2, GL_FLOAT, 0, PanoramaViewTexCoords);

// draw data
glDrawArrays(GL_TRIANGLES, 0, PanoramaViewNumVerts);
*/

unsigned int PanoramaViewNumVerts = 6;

float PanoramaViewVerts [] = {
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  -0.5, 0.28169014084507, 0,
  0.5, 0.28169014084507, 0,
  0.5, -0.28169014084507, 0,
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  -0.5, 0.28169014084507, 0,
  -0.5, -0.28169014084507, 0,
  0.5, -0.28169014084507, 0,
};

float PanoramaViewNormals [] = {
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  0, 0, -1,
  0, 0, -1,
  0, 0, -1,
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  0, 0, -1,
  0, 0, -1,
  0, 0, -1,
};

float PanoramaViewTexCoords [] = {
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  0.000100, 0.9999,
  0.999900, 0.9999,
  0.999900, 9.9999999999989e-05,
  // f 1/1/1 2/2/1 4/3/1 3/4/1
  0.000100, 0.9999,
  0.000100, 9.9999999999989e-05,
  0.999900, 9.9999999999989e-05,
};
