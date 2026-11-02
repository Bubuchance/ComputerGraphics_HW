public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW1
    // You need to implement the "line algorithm" in this section.
    // You can use the function line(x1, y1, x2, y2); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).
    // For instance: drawPoint(114, 514, color(255, 0, 0)); signifies drawing a red
    // point at (114, 514).

    // Bresenham 直線演算法：只用整數加減，決定每一步往 x、往 y 或兩個都走
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

public void CGCircle(float x, float y, float r) {
    // TODO HW1
    // You need to implement the "circle algorithm" in this section.
    // You can use the function circle(x, y, r); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    // 中點畫圓演算法：算 1/8 個圓，再鏡射成 8 份
    int cx = round(x), cy = round(y), radius = round(r);
    int px = 0, py = radius;
    int d = 1 - radius;
    color c = color(0);

    while (px <= py) {
        plotCirclePoints(cx, cy, px, py, c);
        if (d < 0) {
            d += 2 * px + 3;             // 中點在圓內：往右
        } else {
            d += 2 * (px - py) + 5;      // 中點在圓外：往右下
            py--;
        }
        px++;
    }
}

public void CGEllipse(float x, float y, float r1, float r2) {
    // TODO HW1
    // You need to implement the "ellipse algorithm" in this section.
    // You can use the function ellipse(x, y, r1,r2); to verify the correct answer.
    // However, remember to comment out the function before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    // 中點橢圓演算法：算 1/4 個橢圓，分成平緩、陡峭兩個區域
    int cx = round(x), cy = round(y);
    int rx = round(r1), ry = round(r2);
    float rx2 = rx * rx, ry2 = ry * ry;
    color c = color(0);

    int px = 0, py = ry;
    float dx = 0;                // 2 * ry^2 * px
    float dy = 2 * rx2 * py;     // 2 * rx^2 * py

    // 區域 1：斜率絕對值 < 1，x 每次 +1
    float d1 = ry2 - rx2 * ry + 0.25 * rx2;
    while (dx < dy) {
        plotEllipsePoints(cx, cy, px, py, c);
        px++;
        dx += 2 * ry2;
        if (d1 < 0) {
            d1 += dx + ry2;
        } else {
            py--;
            dy -= 2 * rx2;
            d1 += dx - dy + ry2;
        }
    }

    // 區域 2：斜率絕對值 >= 1，y 每次 -1
    float d2 = ry2 * (px + 0.5) * (px + 0.5) + rx2 * (py - 1) * (py - 1) - rx2 * ry2;
    while (py >= 0) {
        plotEllipsePoints(cx, cy, px, py, c);
        py--;
        dy -= 2 * rx2;
        if (d2 > 0) {
            d2 += rx2 - dy;
        } else {
            px++;
            dx += 2 * ry2;
            d2 += dx - dy + rx2;
        }
    }

    // 很扁的橢圓會在還沒走到 rx 前就碰到 y = 0，把剩下的兩端補齊
    for (int i = px; i <= rx; i++) {
        plotEllipsePoints(cx, cy, i, 0, c);
    }
}

public void CGCurve(Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4) {
    // TODO HW1
    // You need to implement the "bezier curve algorithm" in this section.
    // You can use the function bezier(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x,
    // p4.y); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    // 三次貝茲曲線：用 Bernstein 多項式算出曲線上的點，再用 CGLine 把相鄰的點連起來
    int steps = 100;
    float prevX = p1.x, prevY = p1.y;

    for (int i = 1; i <= steps; i++) {
        float t = (float) i / steps;
        float u = 1 - t;
        float bx = u*u*u * p1.x + 3*u*u*t * p2.x + 3*u*t*t * p3.x + t*t*t * p4.x;
        float by = u*u*u * p1.y + 3*u*u*t * p2.y + 3*u*t*t * p3.y + t*t*t * p4.y;
        CGLine(prevX, prevY, bx, by);
        prevX = bx;
        prevY = by;
    }
}

public void CGEraser(Vector3 p1, Vector3 p2) {
    // TODO HW1
    // You need to erase the scene in the area defined by points p1 and p2 in this
    // section.
    // p1 ------
    // |       |
    // |       |
    // ------ p2
    // The background color is color(250);
    // You can use the mouse wheel to change the eraser range.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    // 把 p1、p2 圍成的方框裡每一點塗回背景色
    int left   = int(min(p1.x, p2.x));
    int right  = int(max(p1.x, p2.x));
    int top    = int(min(p1.y, p2.y));
    int bottom = int(max(p1.y, p2.y));

    for (int x = left; x <= right; x++) {
        for (int y = top; y <= bottom; y++) {
            drawPoint(x, y, color(250));
        }
    }
}

public void drawPoint(float x, float y, color c) {
    stroke(c);
    point(x, y);
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

// 圓的 8 方向對稱點
public void plotCirclePoints(int cx, int cy, int px, int py, color c) {
    drawPoint(cx + px, cy + py, c);
    drawPoint(cx - px, cy + py, c);
    drawPoint(cx + px, cy - py, c);
    drawPoint(cx - px, cy - py, c);
    drawPoint(cx + py, cy + px, c);
    drawPoint(cx - py, cy + px, c);
    drawPoint(cx + py, cy - px, c);
    drawPoint(cx - py, cy - px, c);
}

// 橢圓的 4 方向對稱點
public void plotEllipsePoints(int cx, int cy, int px, int py, color c) {
    drawPoint(cx + px, cy + py, c);
    drawPoint(cx - px, cy + py, c);
    drawPoint(cx + px, cy - py, c);
    drawPoint(cx - px, cy - py, c);
}
