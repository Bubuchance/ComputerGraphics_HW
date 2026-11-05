import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public Vector4 renderer_size;
static public float GH_FOV = 45.0f;
static public float GH_NEAR_MIN = 1e-3f;
static public float GH_NEAR_MAX = 1e-1f;
static public float GH_FAR = 1000.0f;

public boolean debug = true;

public float[] GH_DEPTH;
public PImage renderBuffer;

Engine engine;
Camera main_camera;
Vector3 cam_position;
Vector3 lookat;

// 環繞相機的角度和距離
float camYaw = 0;
float camPitch = 0;
float camDistance = 10;

void setup() {
    size(1000, 600);
    renderer_size = new Vector4(20, 50, 520, 550);
    cam_position = new Vector3(0, 0, -10);
    lookat = new Vector3(0, 0, 0);
    setDepthBuffer();
    main_camera = new Camera();
    engine = new Engine();

}

void setDepthBuffer(){
    renderBuffer = new PImage(int(renderer_size.z - renderer_size.x) , int(renderer_size.w - renderer_size.y));
    GH_DEPTH = new float[int(renderer_size.z - renderer_size.x) * int(renderer_size.w - renderer_size.y)];
    for(int i = 0 ; i < GH_DEPTH.length;i++){
        GH_DEPTH[i] = 1.0;
        renderBuffer.pixels[i] = color(1.0*250);
    }
}

void draw() {
    background(255);

    engine.run();
    cameraControl();
}

String selectFile() {
    JFileChooser fileChooser = new JFileChooser();
    fileChooser.setCurrentDirectory(new File("."));
    fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
    FileNameExtensionFilter filter = new FileNameExtensionFilter("Obj Files", "obj");
    fileChooser.setFileFilter(filter);

    int result = fileChooser.showOpenDialog(null);
    if (result == JFileChooser.APPROVE_OPTION) {
        String filePath = fileChooser.getSelectedFile().getAbsolutePath();
        return filePath;
    }
    return "";
}

void cameraControl(){
    // You can write your own camera control function here.
    // Use setPositionOrientation(Vector3 position,Vector3 lookat) to modify the ViewMatrix.
    // Hint : Use keyboard event and mouse click event to change the position of the camera.       
    // 環繞相機（Orbit Camera）：相機永遠看著 lookat，用角度和距離決定位置
    //   鍵盤：A / D 左右繞、W / S 上下繞、Q / E 拉近拉遠
    //   滑鼠：在畫布上拖曳旋轉，滾輪（觸控板兩指上下滑）拉近拉遠
    float rotSpeed = 0.03;
    float zoomSpeed = 0.2;
    if (keyPressed) {
        if (key == 'a' || key == 'A') camYaw -= rotSpeed;
        if (key == 'd' || key == 'D') camYaw += rotSpeed;
        if (key == 'w' || key == 'W') camPitch += rotSpeed;
        if (key == 's' || key == 'S') camPitch -= rotSpeed;
        if (key == 'q' || key == 'Q') camDistance -= zoomSpeed;
        if (key == 'e' || key == 'E') camDistance += zoomSpeed;
    }
    boolean inCanvas = mouseX > renderer_size.x && mouseX < renderer_size.z
                    && mouseY > renderer_size.y && mouseY < renderer_size.w;
    if (mousePressed && mouseButton == LEFT && inCanvas) {
        camYaw += (mouseX - pmouseX) * 0.01;
        camPitch += (mouseY - pmouseY) * 0.01;
    }

    camPitch = constrain(camPitch, -1.5, 1.5);   // 不要轉到正上方或正下方
    camDistance = max(camDistance, 0.5);

    // 球座標 → 直角座標（yaw = pitch = 0 時就是原本的 (0, 0, -10)）
    cam_position = new Vector3(
        lookat.x + camDistance * cos(camPitch) * sin(camYaw),
        lookat.y + camDistance * sin(camPitch),
        lookat.z - camDistance * cos(camPitch) * cos(camYaw));
    main_camera.setPositionOrientation(cam_position, lookat);
}

void mouseWheel(MouseEvent event) {
    camDistance *= 1 + event.getCount() * 0.05;
}
