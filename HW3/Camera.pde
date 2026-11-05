public class Camera {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;
    Transform transform;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform = new Transform();
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {
        wid = w;
        hei = h;
        near = n;
        far = f;
        // 透視投影矩陣：
        // x、y 依照視角（FOV）和長寬比縮放，z 從 [near, far] 映射到 [-1, 1]，
        // 最後一列讓 w = 觀察空間的 z，之後除以 w 就產生「越遠越小」的效果
        float aspect = (float) w / h;
        float fy = 1.0 / tan(radians(GH_FOV) / 2.0);
        projection = Matrix4.Zero();
        projection.m[0]  = fy / aspect;
        projection.m[5]  = fy;
        projection.m[10] = (f + n) / (f - n);
        projection.m[11] = -2.0 * f * n / (f - n);
        projection.m[14] = 1.0;
    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {

    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
        // TODO HW3
        // This function takes two parameters, which are the position of the camera and
        // the point the camera is looking at.
        // We uses topVector = (0,1,0) to calculate the eye matrix.
        // Finally, pass the result into worldView matrix.
        // View 矩陣：建立相機自己的座標軸（右、上、前），
        // 再把世界座標轉到以相機為原點、看向 +z 的座標系
        Vector3 forward = lookat.sub(pos);
        if (forward.norm() < 1e-6) forward = new Vector3(0, 0, 1);
        forward = forward.unit_vector();
        Vector3 up = new Vector3(0, 1, 0);
        Vector3 right = Vector3.cross(up, forward);
        if (right.norm() < 1e-6) right = Vector3.cross(new Vector3(0, 0, 1), forward);  // 正上方或正下方看時換一個 up
        right = right.unit_vector();
        Vector3 camUp = Vector3.cross(forward, right);

        worldView = Matrix4.Identity();
        worldView.m[0] = right.x;    worldView.m[1] = right.y;    worldView.m[2]  = right.z;    worldView.m[3]  = -Vector3.dot(right, pos);
        worldView.m[4] = camUp.x;    worldView.m[5] = camUp.y;    worldView.m[6]  = camUp.z;    worldView.m[7]  = -Vector3.dot(camUp, pos);
        worldView.m[8] = forward.x;  worldView.m[9] = forward.y;  worldView.m[10] = forward.z;  worldView.m[11] = -Vector3.dot(forward, pos);
    }
}
