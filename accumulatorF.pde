/**
 * accumulatorE
 * 
 * Tim Bowman 2007.12.20 
 *
 * Create a high dynamic range image by adding succesive
 * frames from a Quicktime movie together, then display
 * the result with controls for blackpoint and whitepoint.
 * 
 * Functionality in version E:
 * This version computes color by accumulating color
 * vectors (calculated from hue and saturation) which will
 * be normalized after capture.
 *
 * Version F adjusts whitepoint and blackpoint automaticaly and
 * adds keyboard controls. it is also smarter about how
 * many frames it tries to accumulate.
 * 
 * keys:
 * o - output, saves screen as jpeg
 * c - toggles color display
 * r - resets white point, bkackpoint and saturation
 *
 */

import processing.video.*;


Movie myMovie;
// declaring details about the source movie
String movieName = "300.mov";  
int captureWidth = 480;
int captureHeight = 270;
float movieFPS = 23.98;

int numPixels = captureWidth * captureHeight;
float movieFrameTime = 1.0/movieFPS;
int hueRange;
int numFrames = 0;          // counts each frame as it it recorded

float[] colorVectorX; 
float[] colorVectorY;
float[] pixHue;
float[] pixSat;
float[] pixBright;        // used to total each pixel's brightness and later store normalized brightness
float brightest = 0;      // finds brightest accumulated value in pixBright
float blackest = 1;      // finds darkest accumulated value in pixBright
float mostSat = 0;        // finds highest saturation value
float whitePoint = 1.0;
float blackPoint = 0.0;
float satFactor = 1.0;    // used during display to adjust saturation

float garishness = 1.0;   // sets the level of gain for saturation 1 is pretty garish and 0 is monochrome

boolean captureDone = false; 
boolean averageDone = false;
boolean colorOn = true;
boolean writeFile = false;
boolean testMode = true;     // toggles the verbose test mode.
boolean refresh = true;      // set to true to write updated picture


void setup() {
  size(captureWidth, captureHeight);
  colorMode(HSB,1.0);
  background(0.5);

  pixHue = new float[numPixels];
  pixSat = new float[numPixels];
  pixBright = new float[numPixels];
  colorVectorX = new float[numPixels];
  colorVectorY = new float[numPixels];

  myMovie = new Movie(this, movieName);
  myMovie.loop();
  myMovie.speed(0);

  // if movie duration and framerate are such that we
  // will capture more than 300 frames, readjust framerate
  // to only capture 300 frames
  int fr = int( myMovie.duration() * movieFPS );
  if ( fr > 300 ) {
    movieFrameTime = myMovie.duration() / 300;
    movieFPS = 1.0 / movieFrameTime;
  }

  // initialize arrays
  for (int i = 0; i < numPixels; i++) {
    colorVectorX[i] = 0;
    colorVectorY[i] = 0;
    pixBright[i] = 0;
  }

  test("arrays initialized.");

  myMovie.play();

  test("stepping through movie at " + movieFPS + " frames per second");


  // this is the capture chunk
  // here, we load in each frame of the quicktime
  for (float time = 0;time <= myMovie.duration(); time += movieFrameTime) {
    myMovie.jump(time);
    myMovie.read();
    image(myMovie, 0, 0);
    loadPixels();

    // add this frame's pixels to the totals
    for (int i = 0; i < numPixels; i++) {
      // add pixel brightness to brightness accumulator
      pixBright[i] += brightness(pixels[i]);
      // add color vector to accumulator
      float angle = hue(pixels[i]) * TWO_PI;          // hue angle in radians
      float sat = saturation(pixels[i]);
      //  float sat = saturation(pixels[i]) - (1 - brightness(pixels[i]));
      colorVectorX[i] += sin(angle) * saturation(pixels[i]);
      colorVectorY[i] += cos(angle) * saturation(pixels[i]);
    }
    numFrames++;
  }
  captureDone = true;

  myMovie.stop();

  test("capture done."); 
  test("stopping movie.");
  test("number of frames captured: " + numFrames);

  // normalize/average every pixel
  if ( captureDone && (!averageDone) ) {

    test("averaging started.");

    for (int i = 0; i < numPixels; i++) {     

      // average brightness
      pixBright[i] = pixBright[i] / numFrames;
      // remember highest brightness value
      if ( brightest < pixBright[i] ) {
        brightest = pixBright[i];
      }
      // remember darkest brightness value
      if ( blackest > pixBright[i] ) {
        blackest = pixBright[i];
      }

      // convert color vector back into hue angle
      float angle = atan2(colorVectorY[i], colorVectorX[i]);
      // convert radians to float1.0 hue
      angle = degrees(angle) / 360;    
      // correct negative hue values      
      while (angle < 0) { 
        angle++; 
      }
      pixHue[i] = angle;

      // reclaim saturation from color vector
      pixSat[i] = dist(0, 0, colorVectorX[i], colorVectorY[i]) / numFrames * satFactor;
      // remember highest saturation value
      if ( mostSat < pixSat[i] ) {
        mostSat = pixSat[i];
      }


    }
    whitePoint = brightest;
    if ( mostSat <= 0 ) {
      colorOn = false;
    } 
    else {
      satFactor = satFactor * ( 1 / mostSat * garishness );
    }
    averageDone = true;
    test("averaging finished.");
  }


}


void draw()  {

  if ( !captureDone ) {

    // accumulate a frame of video 



    // we will normalize and display as we accumulate

  }




  //this is the chunk that displays the averaged values
  if ( captureDone && averageDone && refresh ) {
    loadPixels();
    for ( int i=0; i< numPixels; i++) {
      float b = norm(pixBright[i], blackPoint, whitePoint);
      b = constrain(b, 0, 1);

      // set up hue and saturation
      float s = 0;
      float h = 0;

      // set H and S value if color is turned on, otherwise leave them at 0
      if ( colorOn ) {
        s = pixSat[i] * satFactor;
        // this bit will roll off saturation for bright pixels
        s = s * sin(b * PI);
      } 
      pixels[i] = color(pixHue[i], s, b);
    }
    updatePixels();

    if ( writeFile ) {
      saveFrame("accumulatorF-####.jpg");
      test("frame saved.");
      writeFile = false;
    }

    // draw blackpoint indicator
    stroke(0.1, 1, 0.8);
    line(0, height-(height*blackPoint), width * 0.1, height-(height*blackPoint) );
    // draw whitepoint indicator
    stroke(0.1, 1, .8);
    line(width * 0.9, height-(height*whitePoint), width, height-(height*whitePoint) );
    // draw sat indicator
    stroke(0.8);
    line(width * 0.4, height-(height*(satFactor-1)), width * 0.6, height-(height*(satFactor-1)) );

    refresh = false;

  }


}


void mouseDragged() {

  float newValue = 1 - float(mouseY) / float(height);

  //  println("new value: " + newValue);

  if ( mouseX < (width/4) ) {
    blackPoint = newValue;
    //    println(" set new blackpoint value.");
  }

  if ( mouseX > width-(width/4) ) {
    whitePoint = newValue;
    //    println(" set new whitepoint value.");
  }

  if ( (mouseX > (width * 0.4)) && (mouseX < (width * 0.6)) ) {
    satFactor += (newValue - 0.5) * 0.03;
  }

  refresh = true;
}

void mousePressed() {
  if (!captureDone) {
    captureDone = true;
    myMovie.stop();
  }
}

void keyPressed() {

  if ( key == 'r' || key == 'R' ) {
    println("blackpoint: " + blackPoint + " whitepoint: " + whitePoint + " resetting values.");
    blackPoint=0;
    whitePoint=1;
  }

  if ( key == 'o' || key == 'O' ) {
    writeFile = true;
  }

  if ( key == 'c' || key == 'C' ) {
    colorOn = !colorOn;
  }

  refresh = true;
}


void test(String message) {
  if ( testMode ){
    println( message );
  }
}
