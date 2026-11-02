public class ShapeRenderer{
    private Box box;
    public Renderer renderer;
    private ArrayList<Shape> shapes;
    public ShapeRenderer(){
      box = new Box(20,50,width-40,height-100);
      box.setBoxColor(250);
      shapes = new ArrayList<Shape>();
    }
    
    public void run(){      
      
      shapes.forEach(Shape::drawShape);
      if(renderer!=null) renderer.render();
    }
    
    public void setRenderer(Renderer r){
        renderer = r;
    }
    
    public void addShape(Shape s){
      shapes.add(s);
    }   
    
    public boolean checkInBox(Vector3 v){
      return box.checkInSide(v);
    }
    
    public void popShape(){
        if(shapes.size()<=0) return;
        shapes.remove(shapes.size()-1);
    }
    public void clear(){
        shapes.clear();
    }
}


public interface Renderer{
    void render();
}

public class PencilRenderer implements Renderer{
    
    private ArrayList<Vector3> points = new ArrayList<Vector3>();
    private boolean once;
    @Override 
    public void render(){
        if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
        if(mousePressed){
            once = false;
            points.add(new Vector3(mouseX,mouseY,0));
        }else{
            if(!once){
                once = true;
                shapeRenderer.addShape(new Point(points)); 
                points = new ArrayList<Vector3>();
            }
        }
        if(points.size()<=1) return;  
        for(int i=0;i<points.size()-1;i++){
            Vector3 p1 = points.get(i);
            Vector3 p2 = points.get(i+1);
            CGLine(p1.x,p1.y,p2.x,p2.y);
        }
        
    }

}

public class LineRenderer implements Renderer{
    private boolean once;
    private boolean first_click;
    private Vector3 first_point;
    private Vector3 second_point;
    
    @Override
    public void render(){
        if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
        if(mousePressed&& mouseButton == LEFT){
            if(!once){
                if(!first_click) first_point = new Vector3(mouseX,mouseY,0);
                if(first_click) second_point = new Vector3(mouseX,mouseY,0);             
                if(first_click){
                    shapeRenderer.addShape(new Line(first_point,second_point));
                    first_point = null;
                    second_point = null;
                }
                first_click = !first_click;
                once = true;
            }
        }else if(mousePressed&& mouseButton == RIGHT){
            first_click = false;          
            first_point = null;
            second_point = null;
        }
        else{
            once = false;
        }     
        if(first_click && first_point!=null) CGLine(first_point.x,first_point.y,mouseX,mouseY);      
    }
}

public class CircleRenderer implements Renderer{
  
    private boolean once;
    private boolean first_click;
    private Vector3 first_point;
    private Vector3 second_point;
    
    @Override
    public void render(){
        if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
        if(mousePressed&& mouseButton == LEFT){
              if(!once){
                  if(!first_click) first_point = new Vector3(mouseX,mouseY,0);
                  if(first_click) second_point = new Vector3(mouseX,mouseY,0);             
                  if(first_click){
                      shapeRenderer.addShape(new Circle(first_point,distance(first_point,second_point)));
                      first_point = null;
                      second_point = null;
                  }
                  first_click = !first_click;
                  once = true;
              }
          }else if(mousePressed&& mouseButton == RIGHT){
              first_click = false;          
              first_point = null;
              second_point = null;
          }
          else{
              once = false;
          }           
          if(first_click && first_point!=null) CGCircle(first_point.x,first_point.y,distance(first_point,new Vector3(mouseX,mouseY,0)));
    }
}

public class PolygonRenderer implements Renderer{
  
    private boolean once;
    private ArrayList<Vector3> verties = new ArrayList<Vector3>();
  
    @Override
    public void render(){
        if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
        if(mousePressed&& mouseButton == LEFT){
            if(!once){
                verties.add(new Vector3(mouseX,mouseY,0));
                once = true;
            }
        }else if(mousePressed&& mouseButton == RIGHT){
            if(!once){
              shapeRenderer.addShape(new Polygon(verties));
              verties = new ArrayList<Vector3>();
              once = true;
            }
        }
        else{
            once = false;
        }
        if(verties.size()>0){
            for(int i=0;i<verties.size()-1;i++){
                Vector3 p1 = verties.get(i);
                Vector3 p2 = verties.get(i+1);
                CGLine(p1.x,p1.y,p2.x,p2.y);
            }
            Vector3 p = verties.get(verties.size()-1);
            CGLine(p.x,p.y,mouseX,mouseY);
        }     
    }
} 

public class EllipseRenderer implements Renderer{
  private boolean once;
  private int times;
  private Vector3 center;
  private float radius1 = 0;
  private float radius2 = 0;
  
  @Override
  public void render(){
      if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
        if(mousePressed&& mouseButton == LEFT){
            if(!once){
                if(times==0) center = new Vector3(mouseX,mouseY,0);
                if(times==1){
                    float dist = abs(center.x - mouseX);
                    radius1 = dist;
                    radius2 = dist;
                }
                if(times==2){
                    float dist = abs(center.y - mouseY);                  
                    radius2 = dist;
                    shapeRenderer.addShape(new Ellipse(center,radius1,radius2));
                }
                times += 1;
                times %=3;
                once = true;
            }
        }else if(mousePressed&& mouseButton == RIGHT){
            times = 0;
            center = null;
        }
        else{
            once = false;
        }
        if(times==0) return;
        if(times==1) {
          float dist = abs(center.x - mouseX);
          CGEllipse(center.x,center.y,dist,dist);
        }
        if(times==2){
          float dist = abs(center.y - mouseY);
          CGEllipse(center.x,center.y,radius1,dist);
        }

  }

}

class EraserRenderer implements Renderer{

  @Override
  public void render(){
      if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
     // loadPixels();
      noFill();
      stroke(0);
      rect(mouseX - eraserSize/2,mouseY - eraserSize/2,eraserSize,eraserSize);
      if(mousePressed&& mouseButton == LEFT){
          shapeRenderer.addShape(new EraseArea(new Vector3(mouseX - eraserSize/2,mouseY - eraserSize/2,0),new Vector3(mouseX + eraserSize/2,mouseY + eraserSize/2,0)));
          
      }
      //updatePixels();
     
  }

}

class CurveRenderer implements Renderer{
  private boolean once;
  private int times;
  private Vector3 cp1;
  private Vector3 cp2;
  private Vector3 cp3;
  private Vector3 cp4;
  
  @Override
  public void render(){
      if(!shapeRenderer.checkInBox(new Vector3(mouseX,mouseY,0))) return;
      if(mousePressed&& mouseButton == LEFT){
          if(!once){   
              switch(times){
                case 0:
                  cp1 = new Vector3(mouseX,mouseY,0);
                  break;
                case 1:
                  cp2 = new Vector3(mouseX,mouseY,0);
                  break;
                case 2:
                  cp3 = new Vector3(mouseX,mouseY,0);
                  break;
                case 3:
                  cp4 = new Vector3(mouseX,mouseY,0);
                  shapeRenderer.addShape(new Curve(cp1,cp3,cp4,cp2));
                 
                  break;
              }
              times += 1;
              times %=4;
              once = true;
          }
      }else if(mousePressed&& mouseButton == RIGHT){
          times = 0;          
      }
      else{
          once = false;
      }
      Vector3 cp = new Vector3(mouseX,mouseY,0);
      if(times==0) return;
      if(times==1) CGCurve(cp1,cp1,cp ,cp);
      if(times==2) CGCurve(cp1,cp,cp2 ,cp2);
      if(times==3) CGCurve(cp1,cp3,cp ,cp2);
      
  }
}
