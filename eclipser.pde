//import com.hamoid.*;
//VideoExport videoExport;
//String VIDEO_FILE_NAME = "g.mp4";

int frames = 0;
int speed = 1;
int FRAME_LENGTH = 1800;
color bg = color(150,200,255);
color SHADOW = color(100,133,170);

float SHADOW_LEN = 1000;

float cX = 960;
float cY = 540;

JSONObject json;
JSONArray objectInfo;

int OBJECT_COUNT;
double[][] coords;
float[][] screens;
int zoom = 0;
int vantage_from = 0;
int vantage_to = -1;

boolean pan = true;

void setup(){
  size(1920,1080,P3D);
  /*videoExport = new VideoExport(this, VIDEO_FILE_NAME);
  videoExport.setFrameRate(30);
  videoExport.startMovie();*/
  
  json = loadJSONObject("info.json");
  objectInfo = json.getJSONArray("info");
  OBJECT_COUNT = objectInfo.size();
  coords = new double[OBJECT_COUNT][3];
  screens = new float[OBJECT_COUNT][2];
  strokeWeight(2);
}
void draw(){
  
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  float fovy = (vantage_to >= 0) ? PI/3.0+0.09*zoom : PI/3.0;
  perspective(fovy, ((float)width/height), cameraZ/1000.0, cameraZ*10.0);
  
  
  lights();
  noStroke();
  background(bg);
  
  for(int i = 0; i < OBJECT_COUNT; i++){
     JSONObject object = objectInfo.getJSONObject(i);
     int parent = object.getInt("parent");
     int dist = object.getInt("dist");
     double period = object.getDouble("period");
     double period_offset = object.getDouble("period_offset");
     double inclination = object.getDouble("inclination")*2*PI/360.0;
     double precession = object.getDouble("precession")*2*PI/360.0;
     
     if(parent == -1){
       coords[i][0] = cX;
       coords[i][1] = cY;
       coords[i][2] = 0;
     }else{
       double prog = ((frames%period)/period+period_offset)%1.0;
       double dRot = Math.cos(prog*2*PI)*dist;
       
       double d_updown = dRot*Math.cos(inclination);
       double d_flat = -Math.sin(prog*2*PI)*dist;
       double d_angle = Math.atan2(d_flat,d_updown)+precession;
       double d_dist = ddist(0,0,d_flat,d_updown);
       double dX = Math.cos(d_angle)*d_dist;
       double dY = Math.sin(d_angle)*d_dist;
       double dZ = -dRot*Math.sin(inclination);
  
       coords[i][0] = coords[parent][0]+dX;
       coords[i][1] = coords[parent][1]+dY;
       coords[i][2] = coords[parent][2]+dZ;
     }
  }
  float dis = pow(1.1, zoom) * (height/2.0) / tan(PI*30.0 / 180.0);
  float centerX = (float)coords[vantage_from][0];
  float centerY = (float)coords[vantage_from][1];
  float centerZ = (float)coords[vantage_from][2];
  
  if(vantage_to == -1){
    float Yang = pan ? (mouseY-height/2.0)/(height/2.0)*PI/2 : 0;
    float Xang = pan ? (mouseX-width/2.0)/(width/2.0)*PI : 0;
    camera(centerX,centerY+dis*sin(Yang),
    centerZ+dis*cos(Yang),
    centerX,centerY,centerZ, 0, 1, 0);
    translate(centerX,centerY,centerZ);
    rotateZ(-Xang);
    translate(-centerX,-centerY,-centerZ);
  }else{
    camera((float)coords[vantage_from][0],(float)coords[vantage_from][1],(float)coords[vantage_from][2],
    (float)coords[vantage_to][0],(float)coords[vantage_to][1],(float)coords[vantage_to][2], 0, 0, -1);
  }
  
  
  
  for(int i = 0; i < OBJECT_COUNT; i++){
    JSONObject object = objectInfo.getJSONObject(i);
     int parent = object.getInt("parent");
     int dist = object.getInt("dist");
     float period = object.getInt("period");
     float inclination = object.getInt("inclination")*2*PI/360.0;
     JSONObject coljson = object.getJSONObject("color");
     color col = color(coljson.getInt("r"),coljson.getInt("g"),coljson.getInt("b"));
     int radius = object.getInt("radius");
     int ray_len = object.getInt("ray_len");
     int tickmarks = object.getInt("tickmarks");
     int acrosses = object.getInt("acrosses");
     int lighter = object.getInt("lighter");
     float precession = object.getInt("precession")*2*PI/360.0;
     if(!(vantage_to >= 0 && vantage_from == i)){
       drawSphere(coords[i],radius,col);
       if(lighter >= 0){
         drawShadow(coords[i],coords[lighter],radius);
       }
     }
     if(parent >= 0){
       pushMatrix();
       translate((float)coords[parent][0],(float)coords[parent][1],(float)coords[parent][2]);
       rotateZ(precession);
       rotateY(inclination);
       drawOrbit(dist,tickmarks,acrosses);
       popMatrix();
     }
     if(ray_len > 0){
       fill(255,128,0);
       pushMatrix();
       translate((float)coords[i][0],(float)coords[i][1],(float)coords[i][2]);
       if(vantage_to >= 0){ // if we're looking from one object to another, rotate the sun rays so we can see them
         rotateX(PI/2);
       }
       for(int r = 0; r < 16; r++){
         beginShape();
         float ang1 = r/16.0*2*PI;
         float ang2 = (r+0.5)/16.0*2*PI;
         float ang3 = (r+1.0)/16.0*2*PI;
         float f = 0.5+0.5*((((sin(r)+1)*1000.0)%1000.0)/1000.0);
         vertex(radius*cos(ang1),radius*sin(ang1),0);
         vertex((radius+ray_len*f)*cos(ang2),(radius+ray_len*f)*sin(ang2),0);
         vertex(radius*cos(ang3),radius*sin(ang3),0);
         endShape();
       }
       popMatrix();
     }
  }
  
  for(int i = 0; i < OBJECT_COUNT; i++){
     screens[i][0] = screenX((float)coords[i][0],(float)coords[i][1],(float)coords[i][2]);
     screens[i][1] = screenY((float)coords[i][0],(float)coords[i][1],(float)coords[i][2]);
  }
  
  /*videoExport.saveFrame();
  
  if(frames >= FRAME_LENGTH){
    videoExport.endMovie();
    exit();
  }*/
  frames += speed;
}
void drawSphere(double[] coords, float r, color c){
  float x = (float)coords[0];
  float y = (float)coords[1];
  float z = (float)coords[2];
  fill(c);
  pushMatrix();
  translate(x,y,z);
  scale(r/100,r/100,r/100);
  sphere(100);
  popMatrix();
}

double ddist(double x1, double y1, double x2, double y2){
  double dx2 = Math.pow(x2-x1,2);
  double dy2 = Math.pow(y2-y1,2);
  return Math.sqrt(dx2+dy2);
}

void drawShadow(double[] coords, double[] lcoords, float r){
  
  float x = (float)coords[0];
  float y = (float)coords[1];
  float z = (float)coords[2];
  
  float lx = (float)lcoords[0];
  float ly = (float)lcoords[1];
  float lz = (float)lcoords[2];
  
  noLights();
  fill(SHADOW);
  if(lx != -9999){
    float d = dist(x,y,z,lx,ly,lz);
    float shadowX = x+(x-lx)/d*SHADOW_LEN;
    float shadowY = y+(y-ly)/d*SHADOW_LEN;
    float shadowZ = z+(z-lz)/d*SHADOW_LEN;
    
    float shadowAngleXY = atan2(y-ly,x-lx);
    for(int i = 0; i < 2; i++){
      int j = 1-i;
      float x1 = x+j*sin(shadowAngleXY)*r;
      float y1 = y-j*cos(shadowAngleXY)*r;
      float z1 = z+i*r;
      float x2 = x-j*sin(shadowAngleXY)*r;
      float y2 = y+j*cos(shadowAngleXY)*r;
      float z2 = z-i*r;
      float x3 = shadowX+j*sin(shadowAngleXY)*r;
      float y3 = shadowY-j*cos(shadowAngleXY)*r;
      float z3 = shadowZ+i*r;
      float x4 = shadowX-j*sin(shadowAngleXY)*r;
      float y4 = shadowY+j*cos(shadowAngleXY)*r;
      float z4 = shadowZ-i*r;
      beginShape();
      vertex(x1,y1,z1);
      vertex(x2,y2,z2);
      vertex(x4,y4,z4);
      vertex(x3,y3,z3);
      endShape();
    }
  }
  lights();
}

void drawOrbit(float d, int tickmarks, int acrosses){
  stroke(0);
  noFill();
  ellipseMode(RADIUS);
  ellipse(0,0,d,d);
  for(int i = 0; i < tickmarks; i++){
    float ang = ((float)i)/tickmarks*2*PI;
    float x1 = cos(ang)*d*0.93;
    float y1 = sin(ang)*d*0.93;
    float x2 = cos(ang)*d*1.07;
    float y2 = sin(ang)*d*1.07;
    line(x1,y1,0,x2,y2,0);
  }
  for(int i = 0; i < acrosses; i++){
    float ang = ((float)i)/tickmarks*PI+PI/2;
    float x1 = cos(ang)*d;
    float y1 = sin(ang)*d;
    float x2 = -cos(ang)*d;
    float y2 = -sin(ang)*d;
    line(x1,y1,0,x2,y2,0);
  }
  noStroke();
}
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom += e;
}
void keyPressed() {
  if (key == ' ') {
    pan = !pan;
  }
}
void mousePressed() {
  vantage_to = -1;
  if(mouseButton == LEFT){
    for(int i = 0; i < OBJECT_COUNT; i++){
      float dist = dist(mouseX,mouseY,screens[i][0],screens[i][1]);
      if(dist < 50){
        vantage_from = i;
        break;
      }
    }
  }else if(mouseButton == RIGHT){
    vantage_to = -1;
    for(int i = 0; i < OBJECT_COUNT; i++){
      float dist = dist(mouseX,mouseY,screens[i][0],screens[i][1]);
      if(dist < 50 && i != vantage_from){ // YOu can't be looking at yourself FROM youreslf
        vantage_to = i;
      }
    }
  }
}
