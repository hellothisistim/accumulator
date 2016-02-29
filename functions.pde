

void initializeAccumulators() {
  // initialize accumulator arrays
  numFrames = 0;
  mostSat = 0;
  for (int i = 0; i < accNumPixels; i++) {
    accumBright[i] = 0;
    colorVectorX[i] = 0;
    colorVectorY[i] = 0;
  }
  test("arrays initialized.");
}













//___________________________________________________________________________________
// we're examining the video input for sudden changes
//
void look() {

  if ( frameAvail() ) {

    // save previous frame  
    prevFrame.copy(inFrame, 0, 0, inFrame.width, inFrame.height, 0, 0, prevFrame.width, prevFrame.height);

    // read new frame
    getOne();

    difference();

    // switch modes if we're over threshold
    if ( diff >= threshold ) {      
      test("difference [ " + diff + " ] is over threshold [ " + threshold + " ]." );
      looking = false;
      accumulating = true;
      viewing = false;
    }

  }

}















//___________________________________________________________________________
// all hail the magic accumulators
// just like film, but digital
// ...or something.

void accumulate() {

  if ( numFrames < frameLimit ) {
    if ( frameAvail() ) {
      // read new frame
      getOne();
      inFrame.loadPixels();
      // cycle through this frame's pixels and add them to the totals
      for (int i = 0; i < accNumPixels; i++) {
        // add pixel brightness to brightness accumulator
        accumBright[i] += brightness(inFrame.pixels[i]);
        // add color vector to accumulator
        float angle = hue(inFrame.pixels[i]) * TWO_PI;          // hue angle in radians
        float sat = saturation(inFrame.pixels[i]);
        colorVectorX[i] += cos(angle) * sat;
        colorVectorY[i] += sin(angle) * sat;
      }

      numFrames++;
    }

  } 
  else {
    test("accumulate finished. " + numFrames + " frames.");
    accumulating = false;
    normalizing = true;
  }
}














// _____________________________________________________________________________
// called when  it's time to 
// normalize the accumulated pixels for display.
//
void normalize() {

  viewing = false;
  // normalize/average every pixel
  for (int i = 0; i < accNumPixels; i++) {     
    // average brightness
    pixBright[i] = accumBright[i] / numFrames;
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
    pixSat[i] = dist(0, 0, colorVectorX[i], colorVectorY[i]) / numFrames;
    // remember highest saturation value
    if ( mostSat < pixSat[i] ) {
      mostSat = pixSat[i];
    }
  }

  whitePoint = brightest;
  blackPoint = blackest;

  // turn color display off if there isn't any in the source
  if ( mostSat <= 0 ) {
    test("turning color off.");
    colorOn = false;
  }
  else {
    satFactor =  1 / mostSat * garishness ;
    colorOn = true;
  }

  test("normalize finished. BP: " + blackPoint + " WP: " + whitePoint + " SAT: " + satFactor);
  normalizing = false;
  looking = true;
  viewing = true;

  initializeAccumulators();

}
















//______________________________________________________________________________
// this is the chunk that displays the averaged values
//
void view() {
  if ( viewing ) {
    displayImage.loadPixels();
    for ( int i=0; i < displayImage.pixels.length; i++) {
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
      displayImage.pixels[i] = color(pixHue[i], s, b) ;
    }
    displayImage.updatePixels();
    image(displayImage, 0, 0, displayImage.width, displayImage.height);

    viewing = false;

    if ( showWork ) {    
      controls(); 
    }
    
  }
}











// ______________________________________________________________________
// this chunk decides what needs to be done with the BP & WP and does it
//
void viewMaster() {


  loadPixels();

  // load on-screen image into sortBuffer[]
  for ( int i=0; i<accNumPixels; i++ ) {
    sortBuffer[i] = brightness(pixels[i]);
  }

  // sort values in prevFrame
  sortBuffer = sort( sortBuffer );

  // display sorted values
  //    for ( int i=0; i<accNumPixels; i++ ) {      
  //     pixels[i] = color(sortBuffer[i]);
  //   }
  //  updatePixels();

  step = whitePoint - blackPoint;
  step = step / 3;
  // look at the shadow and hilight values
  int h =  int( accNumPixels * 0.75);
  int s = int(accNumPixels * 0.40);
  float high = sortBuffer[ h ] ;
  float shad = sortBuffer[ s ] ;

  // evaluate image and figure out what to do with WP & BP
  float adj = ( 0.85 - high ) * step;  
  whitePoint -= adj / 4;

  adj = ( 0.15 - shad ) * step;  
  blackPoint -= adj;


  viewing = true;

}









// ______________________________________________________________________
// this chunk smooths the interframe differences over time
// and uses that to update the threshold value
//
void updateThreshold() {

  // subtract last diff value
  diffTotal -= diffReadings[diffIndex];
  diffReadings[diffIndex] = diff;
  // add new diff value
  diffTotal += diffReadings[diffIndex];

  diffIndex++;
  if ( diffIndex >= numReadings ) {
    diffIndex = 0;
  }

  smoothDiff = diffTotal / numReadings;

  threshold = smoothDiff * threshFactor;


}













// ______________________________________________________________________
// turn the previous image into a difference image
//
void difference() {

  prevFrame.blend(inFrame, 0, 0, inFrame.width, inFrame.height, 0, 0, prevFrame.width, prevFrame.height, SUBTRACT);

  // create the 1-pixel difference image
  smooth();
  image(prevFrame, 0, 0, 1, 1);
  noSmooth();

  loadPixels();
  diff = brightness( pixels[0] );
  // test("diff value" + diff );


}














//_______________________________________________________
// this bit draws the onscreen data feedback
//
void controls() {


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

















// _____________________________________________________________________________________
// if we're in test mode, this baby displays all the messages with 
// the current frame number in from of it.  hurray for debugging.
//
void test(String message) {
  if ( testMode ){
    println( frameCount + ": " + message );
  }
}






// _____________________________________________________________________________________
// grabs a frame from whichever input we're using now
//
void getOne() {
  if ( live ) {
    myCam.read();
    inFrame.copy(myCam, 0, 0, myCam.width, myCam.height, 0, 0, inFrame.width, inFrame.height);
  } 
  else {
    myMovie.read();
    inFrame.copy(myMovie, 0, 0, myMovie.width, myMovie.height, 0, 0, inFrame.width, inFrame.height);
  }
}









// _____________________________________________________________________________________
// check whether there's a frame ready from whichever input we're using now
//
boolean frameAvail() {
  boolean d;
  if ( live ) {
    d = myCam.available();
  } 
  else { 
    d = myMovie.available();
  }
  return d;
}













// _____________________________________________________________________________________
// this bit shows the work of looking and accumulating 
//
void work() {

  if ( looking ) {
    // write input and difference images in lower right
    // make a rectangle to the left of them -- stroke is threshold, fill is current diff value
    stroke(threshold);
    fill(diff);
    rect((width/2) - 40, height * 0.75, 32, 32);
    image(inFrame, width/2, height * 0.75, inFrame.width/4, inFrame.height/4);        // display input 
    image(prevFrame, 3*width/4, height * 0.75, inFrame.width/4, inFrame.height/4);    // display diffImage 
  } 

  if ( accumulating ) {
    image(inFrame, width/2, 0, inFrame.width/2, inFrame.height/2);
  } 



}










// __________________________________________________________________________
// key commands
//
void keyPressed() {

  if ( key == 'r' || key == 'R' ) {
    test("blackpoint: " + blackPoint + " whitepoint: " + whitePoint + " resetting values.");
    blackPoint=0;
    whitePoint=1;
  }

  if ( key == 'o' || key == 'O' ) {
    writeFile = true;
  }

  if ( key == 'c' || key == 'C' ) {
    colorOn = !colorOn;
  }

  if ( key == 'w' || key == 'W' ) {
    showWork = !showWork;
  }

  if ( key == 'm' || key == 'M' ) {
    vmMode = !vmMode;
    if ( vmMode ) { 
      test("viewMaster mode 1."); 
    } 
    else { 
      test("viewMaster mode 2."); 
    }
  }

  if ( key == 'd' || key == 'D' ) {
    // variable dump
    test("----------------------------");

    test("threshold: " + threshold);
    test("diff: " + diff);
    test("smoothDiff: " + smoothDiff);
    test("threshFactor: " + threshFactor);
    test("frameLimit: " + frameLimit);
    test("diffIndex: " + diffIndex);
    test("whitePoint: " + whitePoint);
    test("blackPoint: " + blackPoint);
    test("----------------------------");
    test("looking: " + looking);
    test("accumulating: " + accumulating);
    test("normalizing: " + normalizing);
    test("viewing: " + viewing);
    test("----------------------------");

  }


  if ( key == 'l' || key == 'L' ) {
    //    looking = true;
    //    accumulating = false;
    //    normalizing = false;
    //    viewing = false;

    look();
  }

  if ( key == 'a' || key == 'A' ) {
    accumulate();
  }

  if ( key == 'n' || key == 'N' ) {
    normalize();
  }

  if ( key == 'v' || key == 'V' ) {
    view();
  }


  viewing = true;
}








void mousePressed() {
  looking = false;
  accumulating = true;
  normalizing = false;
  viewing = false; 
}
