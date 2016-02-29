/**
 * wideTimeDHR  
 * (c) 2007 Tim Bowman. 
 * 
 * Create a high dynamic range image by adding succesive
 * frames from a Quicktime movie together, then display
 * the result with controls for blackpoint and whitepoint.
 *
 */

import processing.video.*;


Movie myMovie;
int numFrames = 0;          // counts each frame as it it recorded
int captureWidth = 640;
int captureHeight = 480;
float[] allPixels;          // contains the cumulative sum of each frame's value
float[] hdrPixels;          // contains allPixels scaled to fit from 0 to 1
float whitePoint = 1.0;
float blackPoint = 0.0;
float newValue = 0.0;
boolean capturing = true; 
boolean averageDone = false; // set true when average vales have been calculated into hdrPixels[]


void setup() {
  size(captureWidth, captureHeight);
  colorMode(HSB,1.0);
  background(0.5);

  int numPixels = captureWidth * captureHeight;
  allPixels = new float[numPixels];
  hdrPixels = new float[numPixels];

  myMovie = new Movie(this, "sample.mov");
  myMovie.noLoop();
  myMovie.speed(0.1);

  // initialize allPixels[]
  for (int i = 0; i < numPixels; i++) {
    allPixels[i] = 0.0;
  }
    println("allPixels initialized.");

  myMovie.play();
  println("playing movie.");
}



void draw()  {

  background(0.3);

  //this is the capture chunk
  if ( capturing ) {

    if(myMovie.available()) {
      myMovie.read();
      image(myMovie, 0, 0);
      loadPixels();
      for (int i = 0; i < captureWidth*captureHeight; i++) {
        allPixels[i] = allPixels[i] + brightness(pixels[i]);
      }

    }
    numFrames++;
  }


  // if movie has finished playing, stop movie and signal capture end.
  float md = myMovie.duration();
  float mt = myMovie.time();
  if ( (mt >= md) && capturing ) {
    //   println("stopping movie.");
    myMovie.stop();
    capturing = false;
    println("number of frames captured: " + numFrames);
  }


  // when capture is finish, calculate hdrPixels
  if ( (!capturing) && (!averageDone) ) {
    println("averaging started.");

    for (int i = 0; i < captureWidth*captureHeight; i++) {
      hdrPixels[i] = allPixels[i] / numFrames;
      if ( hdrPixels[i] > 1) {
        println(  "pixel " + i + " has value: " + hdrPixels[i]);
      }
    }
    averageDone = true;
    //   println("averaging finished.");
  }


  //this is the chunk that displays the averaged values
  if ( (!capturing) && averageDone ) {
    loadPixels();
    for ( int i=0; i< captureWidth*captureHeight; i++) {
      pixels[i] = color(norm(hdrPixels[i], blackPoint, whitePoint));
      // pixels[i] = color( hdrPixels[i] );
    }
    updatePixels();

    //blackpoint indicator
    stroke(0.2);
    line(0, height-(height*blackPoint), width * 0.1, height-(height*blackPoint) );
    //whitepoint indicator
    stroke(1);
    line(width * 0.95, height-(height*whitePoint), width, height-(height*whitePoint) );

  }


}


void mouseDragged() {

  newValue = 1 - float(mouseY) / float(height);

  //  println("new value: " + newValue);

  if ( mouseX < (width/4) ) {
    blackPoint = newValue;
    //    println(" set new blackpoint value.");
  }

  if ( mouseX > width-(width/4) ) {
    whitePoint = newValue;
    //    println(" set new whitepoint value.");
  }
}

void mousePressed() {
  if (capturing) {
    capturing = false;
    myMovie.stop();
  }
}

void keyPressed() {
  println("blackpoint: " + blackPoint + " whitepoint: " + whitePoint + " resetting values.");
  blackPoint=0;
  whitePoint=1;
}
