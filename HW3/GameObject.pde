public class GameObject {
    Transform transform;
    Mesh mesh;
    String name;
    Shader shader;

    GameObject() {
        transform = new Transform();
    }

    GameObject(String fname) {
        transform = new Transform();
        setMesh(fname);
        String[] sn = fname.split("\\\\");
        name = sn[sn.length - 1].substring(0, sn[sn.length - 1].length() - 4);
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
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
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        for (int i=0; i<mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] position = triangle.verts;
            Vector4[] gl_Position = shader.vertex.main(new Object[]{position}, new Object[]{MVP});
            // 有頂點在相機後面（w <= 0）時，除以 w 會把它翻到前面，直接略過這個三角形
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
                    // NDC 的 y 往上是正的，影像的列往下，所以上下翻轉（和 Lab 4 框架相同）
                    int index = int((renderer_size.w - renderer_size.y) - y - 1) * int(renderer_size.z - renderer_size.x) + x;
                    
                    float z = getDepth(rx, ry, s_Position );
                    Vector4 c = shader.fragment.main(new Object[]{new Vector3(rx, ry, z)});
                    
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
        Matrix4 M = localToWorld();
        Matrix4 MVP = main_camera.Matrix().mult(M);
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);

            // ---- Backculling ----
            // 在世界座標算出面的法向量（頂點逆時針排列時朝外），
            // 法向量和「相機 → 面」的方向同向，代表這個面背對相機，跳過不畫
            Vector3 w0 = M.mult(triangle.verts[0].getVector4(1.0)).xyz();
            Vector3 w1 = M.mult(triangle.verts[1].getVector4(1.0)).xyz();
            Vector3 w2 = M.mult(triangle.verts[2].getVector4(1.0)).xyz();
            Vector3 faceNormal = Vector3.cross(w1.sub(w0), w2.sub(w0));
            if (Vector3.dot(faceNormal, w0.sub(cam_position)) >= 0) continue;

            // ---- 3D Clipping（Bonus）----
            // 在裁剪空間（除以 w 之前）把每條邊裁到 -w <= x, y, z <= w 的範圍內
            Vector4[] clip = new Vector4[3];
            for (int j = 0; j < 3; j++) {
                clip[j] = MVP.mult(triangle.verts[j].getVector4(1.0));
            }
            for (int j = 0; j < 3; j++) {
                drawClippedLine(clip[j], clip[(j + 1) % 3]);
            }
        }
    }

    // 把裁剪空間中的線段 a→b 裁到視體內，再投影到螢幕畫出來
    void drawClippedLine(Vector4 a, Vector4 b) {
        float tEnter = 0, tLeave = 1;
        // 六個平面：w+x、w-x、w+y、w-y、w+z、w-z 都要 >= 0
        float[] da = { a.w + a.x, a.w - a.x, a.w + a.y, a.w - a.y, a.w + a.z, a.w - a.z };
        float[] db = { b.w + b.x, b.w - b.x, b.w + b.y, b.w - b.y, b.w + b.z, b.w - b.z };
        for (int k = 0; k < 6; k++) {
            if (da[k] < 0 && db[k] < 0) return;         // 兩端都在這個平面外：整條丟掉
            if (da[k] < 0 || db[k] < 0) {
                float t = da[k] / (da[k] - db[k]);       // 和平面的交點
                if (da[k] < 0) tEnter = max(tEnter, t);  // 從外面進來
                else tLeave = min(tLeave, t);            // 從裡面出去
            }
        }
        if (tEnter > tLeave) return;
        Vector3 p = lerpClip(a, b, tEnter).homogenized();
        Vector3 q = lerpClip(a, b, tLeave).homogenized();
        CGLine(map(p.x, -1, 1, renderer_size.x, renderer_size.z), map(p.y, 1, -1, renderer_size.y, renderer_size.w),
               map(q.x, -1, 1, renderer_size.x, renderer_size.z), map(q.y, 1, -1, renderer_size.y, renderer_size.w));
    }

    Vector4 lerpClip(Vector4 a, Vector4 b, float t) {
        return new Vector4(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t);
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
