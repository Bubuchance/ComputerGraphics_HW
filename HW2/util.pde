public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW1
    // Please paste your code from HW1 CGLine.

    // Bresenham 直線演算法（沿用 HW1）
    int x = round(x1), y = round(y1);
    int xEnd = round(x2), yEnd = round(y2);
    int dx = abs(xEnd - x);
    int dy = -abs(yEnd - y);
    int sx = (x < xEnd) ? 1 : -1;
    int sy = (y < yEnd) ? 1 : -1;
    int err = dx + dy;
    color c = color(0);

    while (true) {
        drawPoint(x, y, c);
        if (x == xEnd && y == yEnd) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x += sx; }
        if (e2 <= dx) { err += dx; y += sy; }
    }
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
    // You need to check the coordinate p(x,v) if inside the vertices. 
    // If yes return true, vice versa.

    // 射線法（Ray Casting）：從 p 往右射一條水平線，
    // 數它穿過多邊形幾條邊。奇數次在裡面，偶數次在外面。
    int n = vertexes.length;
    if (n < 3) return false;

    boolean inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        Vector3 a = vertexes[i];
        Vector3 b = vertexes[j];
        // 這條邊有跨過 p 所在的水平線（一端在上、一端在下）
        if ((a.y > y) != (b.y > y)) {
            // 算出邊和水平線交點的 x，交點在 p 右邊才算穿過
            float crossX = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y);
            if (x < crossX) inside = !inside;
        }
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    
    
    // TODO HW2 
    // You need to find the bounding box of the vertices v.
    // r1 -------
    //   |   /\  |
    //   |  /  \ |
    //   | /____\|
    //    ------- r2

    // 沒有頂點（例如整個圖形被裁掉）時，回傳 min > max，讓外面的迴圈不會跑
    if (v.length == 0) {
        Vector3[] empty = { new Vector3(0), new Vector3(-1) };
        return empty;
    }

    // 掃過所有頂點，記下 x、y、z 各自的最小值和最大值
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

    // TODO HW2
    // You need to implement the Sutherland Hodgman Algorithm in this section.
    // The function you pass 2 parameter. One is the vertexes of the shape "points".
    // And the other is the vertices of the "boundary".
    // The output is the vertices of the polygon.

    // 裁剪框的方向（順時針或逆時針），用來判斷點在每條邊的「內側」還是「外側」
    float orientation = 0;
    for (int i = 0; i < boundary.length; i++) {
        Vector3 a = boundary[i];
        Vector3 b = boundary[(i + 1) % boundary.length];
        orientation += a.x * b.y - b.x * a.y;
    }

    // 用裁剪框的每一條邊，輪流把多邊形切一刀
    for (int e = 0; e < boundary.length; e++) {
        if (input.size() == 0) break;   // 已經整個被裁掉了
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
                if (!prevIn) output.add(intersection(prev, cur, prevSide, curSide));  // 外 → 內：加交點
                output.add(cur);                                                       // 內：保留這個點
            } else if (prevIn) {
                output.add(intersection(prev, cur, prevSide, curSide));                // 內 → 外：只加交點
            }
            // 外 → 外：什麼都不加
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

// 點 p 在邊 a→b 的哪一側：用外積判斷，正負號代表左右兩側，0 代表剛好在線上
float sideOfEdge(Vector3 a, Vector3 b, Vector3 p) {
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

// 線段 p→q 和裁剪邊的交點。sideP、sideQ 是兩端點到邊的「有號距離」，
// 交點在兩者比例的位置：t = sideP / (sideP - sideQ)
Vector3 intersection(Vector3 p, Vector3 q, float sideP, float sideQ) {
    float t = sideP / (sideP - sideQ);
    return new Vector3(p.x + t * (q.x - p.x), p.y + t * (q.y - p.y), p.z + t * (q.z - p.z));
}
