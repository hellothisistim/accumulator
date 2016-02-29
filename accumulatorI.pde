/**
 * accumulatorG
 * 
 * Tim Bowman 2008.01.04
 *
 * Create a high dynamic range image by adding succesive
 * frames from a live inputor a Quicktime movie together,
 * then display the result with auto controls for blackpoint 
 * and whitepoint.
 * 
 * 
 * keys:
 * o - output, saves screen as jpeg
 * c - toggles color display
 * r - resets white point, bkackpoint and saturation
 * w - show Work
 * m - ViewMaster mode
 * d - variable Dump
 * l - Look
 * a - Accumulate
 * n - Normalize
 * v - View
 *
 */

import processing.video.*;
Capture myCam;
Movie myMovie;


// declaring details about the source movie
String movieName = "http://127.0.0.1/mov/Tron_chunk.mov";  

// details about the accumulation size
int accWidth = 320;
int accHeight = 180;
int accNumPixels = accWidth * accHeight;

int hueRange;
int numFrames = 0;          // counts each frame as it it recorded

//framebuffers
PImage inFrame = createImage(accWidth, accHeight, RGB);
PImage prevFrame = createImage(accWidth, accHeight, RGB);
//PImage diffImage = createImage(1,1,RGB);                      // single pixel image to hold the difference value
PImage displayImage = createImage(accWidth, accHeight, RGB);
float time = 0;            // position in quicktime movie (in seconds)

// the accumulator arrays
// these are used in accumulating multiple frames worth of pixel data
float[] accumBright;       //used to total each pixel's brightness
float[] colorVectorX; 
float[] colorVectorY;

// these store the normalized floating point color values for each pixel
float[] pixHue;
float[] pixSat;
float[] pixBright;   

float[] sortBuffer;        // used for BP & WB dialing after normalizing

float brightest = 0;     // finds brightest accumulated value in pixBright
float blackest = 1;      // finds darkest accumulated value in pixBright
float mostSat = 0;       // for finding highest saturation value
float diff;              //  difference between current frame and previous one

float vmSampler = 0.5;           // used to set the sample point in pixels[] during viewMaster()

// variables for setting modifying threshold
float threshold = 0.15;        // value to trigger a new accumulation
float[] diffReadings;
int numReadings = 48;          // number of inter-frame differences to average together
int diffIndex = 0;
float diffTotal = 0;
float smoothDiff;              // this is the smoothed difference value over numReadings of captures
float threshFactor = 4.5;      // how much over the smoothed diff does a diff have to be to trigger?


// target for the length of time (in frames) that we stay looking
// before we accumulate again. we'll modify this in look()
float targetDur = 320;

// number of frames to capture in accumulate
int frameLimit = 80;
int lastNewScene = 0;         // time in frames of the start if current shot 

float whitePoint = 1.0;
float blackPoint = 0.0;
float step;                 // size of adjustment made during viewMaster()
float satFactor = 1.0;    // used during display to adjust saturation
float garishness = 1.0;   // sets the level of gain for saturation 1 is pretty garish and 0 is monochrome

// switches
boolean looking = true;
boolean accumulating = false;
boolean normalizing = false;
boolean viewing = false; 
boolean colorOn = true;
boolean writeFile = false;
boolean testMode = true;     // toggles the verbose test mode.
boolean showWork = false;     // toggles whether we see the input image and difference 
boolean vmMode = true;          // toggles ViewMaster mode
boolean live = false;         // switch input from live camera to quicktime. true=camera false=QT
boolean frameAvail = false; 



void setup() {
  size(320, 180);
  colorMode(HSB,1.0);
  background(0.05);

  pixHue = new float[accNumPixels];
  pixSat = new float[accNumPixels];
  pixBright = new float[accNumPixels];
  colorVectorX = new float[accNumPixels];
  colorVectorY = new float[accNumPixels];
  accumBright = new float[accNumPixels];
  diffReadings = new float[numReadings];
  sortBuffer = new float[accNumPixels];

  if ( live ) {
    // setup live camera input
    myCam = new Capture(this, 320, 240, 30);
  } 
  else {
    // setup QT input
    myMovie = new Movie(this, movieName);
    myMovie.loop();
    myMovie.jump(random(myMovie.duration()));
    //   myMovie.speed(2.5);
  }

  // zero numReadings
  for ( int i = 0; i < numReadings; i++ ) {
    diffReadings[i] = 0;
  }


  strokeWeight(2);

  initializeAccumulators();


}










void draw()  {

  if ( looking ) { 
    look();
  }


  if ( accumulating ) {
    accumulate();
  }


  if ( normalizing ) {
    normalize();
  }


  if ( viewing ) {
    view();

    if ( writeFile ) {
      saveFrame("accumulatorI-####.jpg");
      test("frame saved.");
      println();
      writeFile = false;
    }

    viewMaster();    

  }


  if ( showWork ) {
    work();
  }

}
