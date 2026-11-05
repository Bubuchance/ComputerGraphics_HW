public class GameObject {
    Transform transform;
    Mesh mesh;
    String name;
    Material material;
    MaterialEnum me;

    GameObject() {
        transform = new Transform();
    }

    GameObject(String fname) {
        transform = new Transform();
        setMesh(fname);
        // 修正：原本只用 Windows 的反斜線切路徑，Mac / Linux 上名稱會變成完整路徑
        String[] sn = fname.split("[\\\\/]");
        name = sn[sn.length - 1].substring(0, sn[sn.length - 1].length() - 4);
        material = new PhongMaterial();
        me = MaterialEnum.PM;

    }

    void reset() {
        transform.position.setZero();
        transform.rotation.setZero();
        transform.scale.setOnes();
    }

    void setMesh(String fname) {
        mesh = new Mesh(fname);
    }

    void Draw() {
       
        if(mesh==null) return;
        for (int i=0; i<mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] position = triangle.verts;
            Vector4[][] result = material.vertexShader(triangle,localToWorld());
            
            Vector4[] gl_Position = result[0];
            // 有頂點在相機後面（w <= 0）時直接略過，避免除以 w 後翻到畫面前方
            if (gl_Position[0].w <= 0 || gl_Position[1].w <= 0 || gl_Position[2].w <= 0) continue;
            Vector3[] s_Position = new Vector3[3];
            for (int j = 0; j<gl_Position.length; j++) {
                s_Position[j] = gl_Position[j].homogenized();
            }
            Vector3[] boundbox = findBoundBox(s_Position);
            float minX = map(min( max(boundbox[0].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
            float maxX = map(min( max(boundbox[1].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
            float minY = map(min( max(boundbox[0].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
            float maxY = map(min( max(boundbox[1].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
            
            for (int y = int(minY); y < maxY; y++) {
                for (int x = int(minX); x < maxX; x++) {
                    float rx=map(x, 0.0 , renderer_size.z - renderer_size.x, -1, 1);
                    float ry=map(y, 0.0, renderer_size.w - renderer_size.y, -1, 1);
                    if (!pnpoly(rx, ry, s_Position)) continue;
                    int index = int((renderer_size.w - renderer_size.y) - y - 1) * int(renderer_size.z - renderer_size.x) + x;
                    float[] abg = barycentric(new Vector3(rx,ry,0.0) , gl_Position);
                    Vector4[] varing = new Vector4[result.length -1];
                    
                    for(int m=0;m<varing.length;m++){
                         varing[m] = interpolation(abg , result[m+1]);
                    }
                    
                    float z = interpolation(abg,s_Position).z;
                    Vector4 c = material.fragmentShader(new Vector3(rx,ry,z),varing);
                    
                    if (GH_DEPTH[index] > z) {
                        GH_DEPTH[index] = z;
                        renderBuffer.pixels[index] = color(c.x * 255, c.y*255, c.z*255);
                    }
                }
            }
        }        
        update();
    }

    void update() {
    }

    void debugDraw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        if (mesh == null)
            return;
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] img_pos = new Vector3[3];
            for (int j = 0; j < 3; j++) {
                img_pos[j] = MVP.mult(triangle.verts[j].getVector4(1.0)).homogenized();
            }

            for (int j = 0; j < img_pos.length; j++) {
                img_pos[j] = new Vector3(map(img_pos[j].x, -1, 1, renderer_size.x, renderer_size.z),
                        map(img_pos[j].y, 1, -1, renderer_size.y, renderer_size.w), img_pos[j].z);
            }

            CGLine(img_pos[0].x, img_pos[0].y, img_pos[1].x, img_pos[1].y);
            CGLine(img_pos[1].x, img_pos[1].y, img_pos[2].x, img_pos[2].y);
            CGLine(img_pos[2].x, img_pos[2].y, img_pos[0].x, img_pos[0].y);
        }
    }

    String getGameObjectName() {
        return name;
    }

    Matrix4 localToWorld() {
        // TODO HW3
        // You need to calculate the model Matrix here.
        // Model 矩陣：先縮放、再旋轉（z → x → y）、最後平移。
        // 順序和框架提供的 worldToLocal() 剛好相反，兩者互為反矩陣
        return Matrix4.Trans(transform.position)
                .mult(Matrix4.RotY(transform.rotation.y))
                .mult(Matrix4.RotX(transform.rotation.x))
                .mult(Matrix4.RotZ(transform.rotation.z))
                .mult(Matrix4.Scale(transform.scale));
    }

    Matrix4 worldToLocal() {
        return Matrix4.Scale(transform.scale.inv()).mult(Matrix4.RotZ(-transform.rotation.z))
                .mult(Matrix4.RotX(-transform.rotation.x)).mult(Matrix4.RotY(-transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    Vector3 forward() {
        return (Matrix4.RotZ(transform.rotation.z).mult(Matrix4.RotX(transform.rotation.y))
                .mult(Matrix4.RotY(transform.rotation.x)).zAxis()).mult(-1);
    }
}
