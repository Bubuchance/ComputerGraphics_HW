import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public Vector4 renderer_size;
static public float GH_FOV = 45.0f;
static public float GH_NEAR_MIN = 1e-3f;
static public float GH_NEAR_MAX = 1e-1f;
static public float GH_FAR = 1000.0f;
static public Vector3 AMBIENT_LIGHT = new Vector3(0.3, 0.3, 0.3);

public boolean debug = false;

public float[] GH_DEPTH;
public PImage renderBuffer;

Engine engine;
Camera main_camera;
Vector3 cam_position;
Vector3 lookat;

Light basic_light;

// 環繞相機的角度和距離（相機一開始在 (0, 0, -50)）
float camYaw = 0;
float camPitch = 0;
float camDistance = 50;
boolean wheelMoved = false;

void setup() {
    size(1000, 600);
    renderer_size = new Vector4(20, 50, 520, 550);

    lookat = new Vector3(0, 0, 0);
    setDepthBuffer();
    main_camera = new Camera();
    engine = new Engine();
    engine.renderer.addGameObject(basic_light);
    engine.renderer.addGameObject(main_camera);

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

void cameraControl() {
    // TODO HW3 (Optional)
    // You can write your own camera control function here.
    // Use setPositionOrientation(Vector3 position,Vector3 lookat) to modify the
    // ViewMatrix.
    // Hint : Use keyboard event and mouse click event to change the position of the
    // camera.
    // 環繞相機：A / D 左右繞、W / S 上下繞、Q / E 拉近拉遠，
    // 也可以在畫布上拖曳滑鼠旋轉、用滾輪（觸控板兩指上下滑）縮放。
    // 這一版的相機是 GameObject，所以改的是相機的 transform，
    // engine 每一幀會用 setPositionOrientation() 套用。
    float rotSpeed = 0.03;
    float zoomSpeed = 0.5;
    boolean moved = false;
    if (keyPressed) {
        if (key == 'a' || key == 'A') { camYaw -= rotSpeed; moved = true; }
        if (key == 'd' || key == 'D') { camYaw += rotSpeed; moved = true; }
        if (key == 'w' || key == 'W') { camPitch += rotSpeed; moved = true; }
        if (key == 's' || key == 'S') { camPitch -= rotSpeed; moved = true; }
        if (key == 'q' || key == 'Q') { camDistance -= zoomSpeed; moved = true; }
        if (key == 'e' || key == 'E') { camDistance += zoomSpeed; moved = true; }
    }
    boolean inCanvas = mouseX > renderer_size.x && mouseX < renderer_size.z
                    && mouseY > renderer_size.y && mouseY < renderer_size.w;
    if (mousePressed && mouseButton == LEFT && inCanvas) {
        camYaw += (mouseX - pmouseX) * 0.01;
        camPitch += (mouseY - pmouseY) * 0.01;
        moved = true;
    }
    if (wheelMoved) { moved = true; wheelMoved = false; }
    if (!moved) return;

    camPitch = constrain(camPitch, -1.5, 1.5);
    camDistance = max(camDistance, 1);

    // 相機 view 矩陣是 RotX(pitch) × RotY(yaw) × Trans(-position)，
    // 要讓相機看向原點，位置就放在「看的方向的反方向」距離 camDistance 處
    main_camera.transform.rotation = new Vector3(camPitch, camYaw, 0);
    main_camera.transform.position = new Vector3(
        camDistance * sin(camYaw) * cos(camPitch),
        -camDistance * sin(camPitch),
        -camDistance * cos(camYaw) * cos(camPitch));
    main_camera.setPositionOrientation();
}

void mouseWheel(MouseEvent event) {
    camDistance *= 1 + event.getCount() * 0.05;
    wheelMoved = true;
}
