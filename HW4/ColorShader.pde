public class PhongVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Matrix4 N = (Matrix4) uniform[2];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            // 原本用 M 轉換法向量，非等比例縮放時會歪掉，改用反轉置矩陣
            w_normal[i] = N.mult(aVertexNormal[i].getVector4(0.0));
        }

        Vector4[][] result = { gl_Position, w_position, w_normal };

        return result;
    }
}

public class PhongFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 albedo = (Vector3) varying[3];
        Vector3 kdksm = (Vector3) varying[4];
        Vector3 Ka = (Vector3) varying[5];

        // Phong shading：每個像素都用「內插後的法向量」重新算一次光照
        Vector3 c = phongLighting(w_position, w_normal, albedo, Ka, kdksm.x, kdksm.y, kdksm.z);
        return new Vector4(c.x, c.y, c.z, 1.0);
    }
}

public class FlatVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Matrix4 N = (Matrix4) uniform[2];
        Vector3 albedo = (Vector3) uniform[3];
        Vector3 Ka = (Vector3) uniform[4];
        Vector3 kdksm = (Vector3) uniform[5];
        Vector4[] gl_Position = new Vector4[3];
        Vector3[] w_position = new Vector3[3];

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0)).xyz();
        }

        // Flat shading：整個三角形只算一次光照
        // 面法向量 = 兩條邊的外積，並讓它和頂點法向量的平均方向一致（避免朝內）
        Vector3 faceNormal = Vector3.cross(w_position[1].sub(w_position[0]), w_position[2].sub(w_position[0]));
        Vector3 avgNormal = new Vector3(0, 0, 0);
        for (int i = 0; i < 3; i++) {
            avgNormal = avgNormal.add(N.mult(aVertexNormal[i].getVector4(0.0)).xyz());
        }
        if (Vector3.dot(faceNormal, avgNormal) < 0) faceNormal = faceNormal.mult(-1);

        // 在三角形中心點算光照
        Vector3 center = w_position[0].add(w_position[1]).add(w_position[2]).mult(1.0 / 3.0);
        Vector3 c = phongLighting(center, faceNormal, albedo, Ka, kdksm.x, kdksm.y, kdksm.z);

        // 三個頂點傳一樣的顏色，內插後整個面都是同一個顏色
        Vector4 faceColor = new Vector4(c.x, c.y, c.z, 1.0);
        Vector4[] colors = { faceColor, faceColor, faceColor };
        Vector4[][] result = { gl_Position, colors };
        return result;
    }
}

public class FlatFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 faceColor = (Vector3) varying[1];
        return new Vector4(faceColor.x, faceColor.y, faceColor.z, 1.0);
    }
}

public class GouraudVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Matrix4 N = (Matrix4) uniform[2];
        Vector3 albedo = (Vector3) uniform[3];
        Vector3 Ka = (Vector3) uniform[4];
        Vector3 kdksm = (Vector3) uniform[5];

        Vector4[] gl_Position = new Vector4[3];
        Vector4[] colors = new Vector4[3];

        // Gouraud shading：在每個「頂點」算光照，顏色再交給 GameObject 內插到整個三角形
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            Vector3 w_position = M.mult(aVertexPosition[i].getVector4(1.0)).xyz();
            Vector3 w_normal = N.mult(aVertexNormal[i].getVector4(0.0)).xyz();
            Vector3 c = phongLighting(w_position, w_normal, albedo, Ka, kdksm.x, kdksm.y, kdksm.z);
            colors[i] = new Vector4(c.x, c.y, c.z, 1.0);
        }

        Vector4[][] result = { gl_Position, colors };
        return result;
    }
}

public class GouraudFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 color = (Vector3) varying[1];
        return new Vector4(color.x, color.y, color.z, 1.0);
    }
}

// Bonus：貼圖著色器
public class TextureVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Vector3[] aVertexUV = (Vector3[]) attribute[2];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Matrix4 N = (Matrix4) uniform[2];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];
        Vector4[] uv = new Vector4[3];

        for (int i = 0; i < 3; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            w_normal[i] = N.mult(aVertexNormal[i].getVector4(0.0));
            // 沒有 UV 的模型，w = 0 當作「沒有貼圖座標」的標記
            uv[i] = aVertexUV[i] == null ? new Vector4(0, 0, 0, 0) : new Vector4(aVertexUV[i].x, aVertexUV[i].y, 0, 1);
        }
        Vector4[][] result = { gl_Position, w_position, w_normal, uv };
        return result;
    }
}

public class TextureFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector4 uv = (Vector4) varying[3];
        PImage tex = (PImage) varying[4];
        Vector3 albedo = (Vector3) varying[5];
        Vector3 Ka = (Vector3) varying[6];
        Vector3 kdksm = (Vector3) varying[7];

        Vector3 baseColor = albedo;
        if (uv.w > 0 && tex != null) {
            // UV 超出 [0, 1] 時重複貼圖；圖片的 y 軸往下，所以 v 要上下翻轉
            float u = uv.x - floor(uv.x);
            float v = uv.y - floor(uv.y);
            int px = constrain(int(u * (tex.width - 1)), 0, tex.width - 1);
            int py = constrain(int((1 - v) * (tex.height - 1)), 0, tex.height - 1);
            color texel = tex.pixels[py * tex.width + px];
            baseColor = multiplyRGB(new Vector3(red(texel) / 255.0, green(texel) / 255.0, blue(texel) / 255.0), albedo);
        }
        Vector3 c = phongLighting(w_position, w_normal, baseColor, Ka, kdksm.x, kdksm.y, kdksm.z);
        return new Vector4(c.x, c.y, c.z, 1.0);
    }
}

// 三種著色方式共用的 Phong 光照模型：
//   顏色 = 環境光 + 漫反射 + 鏡面反射
//   環境光   = Ka × albedo
//   漫反射   = Kd × max(N·L, 0) × 光的顏色 × 強度 × albedo
//   鏡面反射 = Ks × max(R·V, 0)^m × 光的顏色 × 強度
Vector3 phongLighting(Vector3 w_position, Vector3 w_normal, Vector3 albedo, Vector3 Ka, float Kd, float Ks, float shininess) {
    Light light = basic_light;
    Camera cam = main_camera;

    Vector3 lightColor = light.light_color.mult(light.intensity);
    Vector3 ambient = multiplyRGB(Ka, albedo);
    if (w_normal.norm() < 1e-8) return clampRGB(ambient);

    Vector3 N = w_normal.unit_vector();                                 // 表面法向量
    Vector3 L = light.transform.position.sub(w_position).unit_vector(); // 指向光源
    Vector3 V = cam.transform.position.sub(w_position).unit_vector();   // 指向相機

    float NdotL = Vector3.dot(N, L);
    Vector3 diffuse = multiplyRGB(lightColor, albedo).mult(Kd * max(NdotL, 0));

    Vector3 specular = new Vector3(0, 0, 0);
    if (NdotL > 0) {
        Vector3 R = N.mult(2 * NdotL).sub(L);                           // L 對法向量的反射方向
        float RdotV = max(Vector3.dot(R, V), 0);
        specular = lightColor.mult(Ks * pow(RdotV, shininess));
    }
    return clampRGB(ambient.add(diffuse).add(specular));
}

Vector3 multiplyRGB(Vector3 a, Vector3 b) {
    return new Vector3(a.x * b.x, a.y * b.y, a.z * b.z);
}

Vector3 clampRGB(Vector3 c) {
    return new Vector3(constrain(c.x, 0, 1), constrain(c.y, 0, 1), constrain(c.z, 0, 1));
}
