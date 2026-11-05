public void CGLine(float x1, float y1, float x2, float y2) {
    stroke(0);
    line(x1, y1, x2, y2);
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
    // TODO HW2
    // You need to check the coordinate p(x,v) if inside the vertexes. 
    // 射線法：從 (x, y) 往右射一條水平線，穿過奇數條邊就在多邊形裡面
    int n = vertexes.length;
    if (n < 3) return false;
    boolean inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        Vector3 a = vertexes[i];
        Vector3 b = vertexes[j];
        if ((a.y > y) != (b.y > y)) {
            float crossX = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y);
            if (x < crossX) inside = !inside;
        }
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    // 掃過所有頂點，記下 x、y、z 的最小值和最大值
    if (v.length == 0) {
        Vector3[] empty = { new Vector3(0), new Vector3(-1) };
        return empty;
    }
    Vector3 recordminV = new Vector3(v[0].x, v[0].y, v[0].z);
    Vector3 recordmaxV = new Vector3(v[0].x, v[0].y, v[0].z);
    for (int i = 1; i < v.length; i++) {
        recordminV.x = min(recordminV.x, v[i].x);
        recordminV.y = min(recordminV.y, v[i].y);
        recordminV.z = min(recordminV.z, v[i].z);
        recordmaxV.x = max(recordmaxV.x, v[i].x);
        recordmaxV.y = max(recordmaxV.y, v[i].y);
        recordmaxV.z = max(recordmaxV.z, v[i].z);
    }
    Vector3[] result = { recordminV, recordmaxV };
    return result;
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i += 1) {
        input.add(points[i]);
    }

    // Sutherland-Hodgman：用裁剪框的每一條邊輪流把多邊形切一刀
    float orientation = 0;
    for (int i = 0; i < boundary.length; i++) {
        Vector3 a = boundary[i];
        Vector3 b = boundary[(i + 1) % boundary.length];
        orientation += a.x * b.y - b.x * a.y;
    }
    for (int e = 0; e < boundary.length; e++) {
        if (input.size() == 0) break;
        Vector3 edgeStart = boundary[e];
        Vector3 edgeEnd = boundary[(e + 1) % boundary.length];
        output = new ArrayList<Vector3>();
        for (int i = 0; i < input.size(); i++) {
            Vector3 cur = input.get(i);
            Vector3 prev = input.get((i + input.size() - 1) % input.size());
            float curSide = sideOfEdge(edgeStart, edgeEnd, cur);
            float prevSide = sideOfEdge(edgeStart, edgeEnd, prev);
            boolean curIn = curSide * orientation >= 0;
            boolean prevIn = prevSide * orientation >= 0;
            if (curIn) {
                if (!prevIn) output.add(intersection(prev, cur, prevSide, curSide));
                output.add(cur);
            } else if (prevIn) {
                output.add(intersection(prev, cur, prevSide, curSide));
            }
        }
        input = output;
    }
    output = input;

    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i += 1) {
        result[i] = output.get(i);
    }
    return result;
}

public float getDepth(float x, float y, Vector3[] vertex) {
    // TODO HW3
    // You need to calculate the depth (z) in the triangle (vertex) based on the
    // positions x and y. and return the z value;
    // 三角形投影到螢幕後仍然是平面，NDC 的 z 在螢幕上是線性的，
    // 所以用 2D 重心座標把三個頂點的 z 加權平均，就是 (x, y) 的深度
    float[] w = screenBarycentric(x, y, vertex[0], vertex[1], vertex[2]);
    return w[0] * vertex[0].z + w[1] * vertex[1].z + w[2] * vertex[2].z;
}

float[] barycentric(Vector3 P, Vector4[] verts) {

    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    Vector4 AW = verts[0];
    Vector4 BW = verts[1];
    Vector4 CW = verts[2];

    // TODO HW4
    // Calculate the barycentric coordinates of point P in the triangle verts using
    // the barycentric coordinate system.
    // Please notice that you should use Perspective-Correct Interpolation otherwise
    // you will get wrong answer.

    // 1. 先在螢幕空間（除以 w 之後）算出 2D 重心座標
    float[] s = screenBarycentric(P.x, P.y, A, B, C);

    // 2. 透視校正：螢幕上的線性內插不等於 3D 空間的線性內插，
    //    要先把權重除以各頂點的 w（深度），再重新正規化讓總和為 1
    float a = s[0] / AW.w;
    float b = s[1] / BW.w;
    float c = s[2] / CW.w;
    float sum = a + b + c;
    if (abs(sum) < 1e-12) return s;

    float[] result = { a / sum, b / sum, c / sum };
    return result;
}

Vector3 interpolation(float[] abg, Vector3[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

Vector4 interpolation(float[] abg, Vector4[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

float interpolation(float[] abg, float[] v) {
    return v[0] * abg[0] + v[1] * abg[1] + v[2] * abg[2];
}

// 點 p 在邊 a→b 的哪一側（外積的正負號）
float sideOfEdge(Vector3 a, Vector3 b, Vector3 p) {
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

// 線段 p→q 和裁剪邊的交點
Vector3 intersection(Vector3 p, Vector3 q, float sideP, float sideQ) {
    float t = sideP / (sideP - sideQ);
    return new Vector3(p.x + t * (q.x - p.x), p.y + t * (q.y - p.y), p.z + t * (q.z - p.z));
}

// 點 (x, y) 在三角形 a、b、c 上的 2D 重心座標（只看 x、y）
float[] screenBarycentric(float x, float y, Vector3 a, Vector3 b, Vector3 c) {
    float area = (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
    if (abs(area) < 1e-12) {
        float[] degenerate = { 1.0, 0.0, 0.0 };
        return degenerate;
    }
    float alpha = ((b.x - x) * (c.y - y) - (c.x - x) * (b.y - y)) / area;
    float beta  = ((c.x - x) * (a.y - y) - (a.x - x) * (c.y - y)) / area;
    float gamma = 1.0 - alpha - beta;
    float[] result = { alpha, beta, gamma };
    return result;
}
