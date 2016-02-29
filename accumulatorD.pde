/**
 * accumulatorD
 * 
 * Tim Bowman 2007.12.06 
 *
 * Create a high dynamic range image by adding succesive
 * frames from a Quicktime movie together, then display
 * the result with controls for blackpoint and whitepoint.
 * 
 * This version computes color by chopping the hue circle
 * into x number of hue ranges and finding the most 
 * frequently occupied range saturation is calculated by 
 * dividing accumulated sat values by hue range frequency.
 *
 */

import processing.video.*;


Movie myMovie;
int captureWidth = 640;     // width of source movie
int captureHeight = 480;    // height of source movie
float movieFPS = 29.97;     // frames per second of source movie
int numHueRanges = 12;       // this is how many subdivisions we make in the hue circle

int numPixels = captureWidth * captureHeight;
float movieFrameTime = 1.0/movieFPS;
int hueRange;
int numFrames = 0;          // counts each frame as it it recorded
int[][] pixelHueRange;      // [hue angle range] [pixel number] contains number of pixels in each hue range
float[][] pixelSatCume; // [hue angle range] [pixel number] accumulates saturation value for each hue range
float[] pixelHue; 
float[] pixelSat;
float[] pixelBright;        // used to total each pixel's brightness and later store normalized brightness
float whitePoint = 1.0;
float blackPoint = 0.0;
float newValue = 0.0;
float brightestPixel = 0;
float h, s, b;
color pixelColor;

boolean captureDone = false; 
boolean averageDone = false; // set true when average vales have been calculated into hdrPixels[]
boolean colorOn = true;


void setup() {
  size(captureWidth, captureHeight);
  colorMode(HSB,1.0);
  background(0.5);

  pixelHueRange = new int[numHueRanges][numPixels];
  pixelSatCume = new float[numHueRanges][numPixels];
  pixelHue = new float[numPixels];
  pixelSat = new float[numPixels];
  pixelBright = new float[numPixels];

  myMovie = new Movie(this, "sample.mov");
  myMovie.loop();
  myMovie.speed(0);

  // initialize arrays
  for (int i = 0; i < numPixels; i++) {
    pixelHue[i] = 0;
    pixelSat[i] = 0;
    pixelBright[i] = 0;
    for (int j = 0; j < numHueRanges; j++){
      pixelHueRange[j][i] = 0;
      pixelSatCume[j][i] = 0.0;
    }
  }
  println("arrays initialized.");

  myMovie.play();
  println("playing movie.");
}



void draw()  {

  background(0.3);

  //this is the capture chunk

  if ( !captureDone ) {

    // load in each frame of the quicktime
    for (float time = 0;time <= myMovie.duration(); time += movieFrameTime) {
      myMovie.jump(time);
      myMovie.read();
      image(myMovie, 0, 0);
      loadPixels();

      // add this frame's pixels to the totals
      for (int i = 0; i < numPixels; i++) {
        // add pixel brightness to brightness accumulator
        pixelBright[i] += brightness(pixels[i]);
        // calculate which hue range this pixel falls into
        hueRange = floor(hue(pixels[i]) * numHueRanges);
        if (hueRange == numHueRanges) {
          println("hueRange over range. [" + hueRange + "] decrementing.");
          hueRange--;
        }
        // increment appropriate hue range counter for this pixel
        pixelHueRange[hueRange][i]++;
        // add pixel's saturation to the appropriate hue range 
        pixelSatCume[hueRange][i] += 1 - saturation(pixels[i]);
      }
      numFrames++;
    }

    // this chunk will execute once all pixels in all frames have been accumulated.
    captureDone = true;
    println("capture done."); 
    println("stopping movie.");
    myMovie.stop();
    println("number of frames captured: " + numFrames);

  }


  // when capture is completed, normalize/average every pixel
  if ( captureDone && (!averageDone) ) {
    println("averaging started.");
    for (int i = 0; i < numPixels; i++) {
      // find the hue range with the highest number of pixels
      int highScore = 0;
      for (int range = 0; range < numHueRanges; range++){
        if (pixelHueRange[range][i] > highScore) {
          highScore = pixelHueRange[range][i];
          hueRange = range;
        }
      }
      // println("range for pixel " + i + " is:  " + hueRange);

      // assign middle value for the most frequent hue range to pixelHue
      pixelHue[i] = float(hueRange) / numHueRanges;
      pixelHue[i] += 0.5 / numHueRanges;    
      println();
      // calculate saturation for that hue range
      // divide the accumulated saturation for selected range by the number of pixels in selected range
      pixelSat[i] = pixelSatCume[hueRange][i] / pixelHueRange[hueRange][i];
      // average brightness
      pixelBright[i] = pixelBright[i] / numFrames;
      // println("pixel " + i + " :  H" + pixelHue[i] + " S" + pixelSat[i] + " B" + pixelBright[i] + " range: " + hueRange);

    }
    averageDone = true;
    println("averaging finished.");
  }


  //this is the chunk that displays the averaged values
  if ( captureDone && averageDone ) {
    loadPixels();
    for ( int i=0; i< numPixels; i++) {
      float b = norm(pixelBright[i], blackPoint, whitePoint);
      pixels[i] = color(pixelHue[i], pixelSat[i], b);
    }
    updatePixels();

    // draw blackpoint indicator
    stroke(0.1, 1, 0.8);
    line(0, height-(height*blackPoint), width * 0.1, height-(height*blackPoint) );
    // draw whitepoint indicator
    stroke(0.1, 1, .8);
    line(width * 0.9, height-(height*whitePoint), width, height-(height*whitePoint) );

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
  if (!captureDone) {
    captureDone = true;
    myMovie.stop();
  }
}

void keyPressed() {
  //  println("blackpoint: " + blackPoint + " whitepoint: " + whitePoint + " resetting values.");
  //  blackPoint=0;
  //  whitePoint=1;
}
