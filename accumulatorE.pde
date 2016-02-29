/**
 * accumulatorE
 * 
 * Tim Bowman 2007.12.10 
 *
 * Create a high dynamic range image by adding succesive
 * frames from a Quicktime movie together, then display
 * the result with controls for blackpoint and whitepoint.
 * 
 * This version computes color by accumulating color
 * vectors (calculated from hue and saturation) which will
 * be normalized after capture.
 *
 */

import processing.video.*;


Movie myMovie;
int captureWidth = 640;     // width of source movie
int captureHeight = 480;    // height of source movie
float movieFPS = 29.97;     // frames per second of source movie

int numPixels = captureWidth * captureHeight;
float movieFrameTime = 1.0/movieFPS;
int hueRange;
int numFrames = 0;          // counts each frame as it it recorded

float[] colorVectorX; 
float[] colorVectorY;
float[] pixHue;
float[] pixSat;
float[] pixBright;        // used to total each pixel's brightness and later store normalized brightness
float whitePoint = 1.0;
float blackPoint = 0.0;
float satFactor = 1.0;    // used during display to adjust saturation

boolean captureDone = false; 
boolean averageDone = false;
boolean colorOn = true;


void setup() {
  size(captureWidth, captureHeight);
  colorMode(HSB,1.0);
  background(0.5);

  pixHue = new float[numPixels];
  pixSat = new float[numPixels];
  pixBright = new float[numPixels];
  colorVectorX = new float[numPixels];
  colorVectorY = new float[numPixels];

  myMovie = new Movie(this, "sample.mov");
  myMovie.loop();
  myMovie.speed(0);

  // initialize arrays
  for (int i = 0; i < numPixels; i++) {
    colorVectorX[i] = 0;
    colorVectorY[i] = 0;
    pixBright[i] = 0;
  }
  println("arrays initialized.");

  myMovie.play();
  println("playing movie.");

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
  println("capture done."); 
  println("stopping movie.");
  myMovie.stop();
  println("number of frames captured: " + numFrames);

  // normalize/average every pixel
  if ( captureDone && (!averageDone) ) {
    println("averaging started.");
    for (int i = 0; i < numPixels; i++) {     
      // average brightness
      pixBright[i] = pixBright[i] / numFrames;
      float angle = atan2(colorVectorY[i], colorVectorX[i]);
      // convert radians to float1.0 hue
      angle = degrees(angle) / 360;    
      // correct negative hue values      
      while (angle < 0) { 
        angle++; 
      }
      pixHue[i] = angle;
      pixSat[i] = dist(0, 0, colorVectorX[i], colorVectorY[i]) / numFrames * satFactor;

    }
    averageDone = true;
    println("averaging finished.");
  }


}


void draw()  {

  background(0.3);



  //this is the chunk that displays the averaged values
  if ( captureDone && averageDone ) {
    loadPixels();
    for ( int i=0; i< numPixels; i++) {
      float b = norm(pixBright[i], blackPoint, whitePoint);
      b = constrain(b, 0, 1);
      float s = pixSat[i] * satFactor;
      // this bit is supposed to roll off saturation for bright pixels
      s = s * sin(b * PI);
      pixels[i] = color(pixHue[i], s, b);
    }
    updatePixels();

    // draw blackpoint indicator
    stroke(0.1, 1, 0.8);
    line(0, height-(height*blackPoint), width * 0.1, height-(height*blackPoint) );
    // draw whitepoint indicator
    stroke(0.1, 1, .8);
    line(width * 0.9, height-(height*whitePoint), width, height-(height*whitePoint) );
    // draw sat indicator
    stroke(0.8);
    line(width * 0.4, height-(height*(satFactor-1)), width * 0.6, height-(height*(satFactor-1)) );


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


}

void mousePressed() {
  if (!captureDone) {
    captureDone = true;
    myMovie.stop();
  }
}

void keyPressed() {
  println("blackpoint: " + blackPoint + " whitepoint: " + whitePoint + " resetting values.");
  blackPoint=0;
  whitePoint=1;
}
