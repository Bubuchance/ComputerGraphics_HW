public abstract class Material {
    Vector3 albedo = new Vector3(0.9, 0.9, 0.9);
    // 所有材質共用的光照係數：環境光、漫反射、鏡面反射強度、光澤度
    Vector3 Ka = new Vector3(0.3, 0.3, 0.3);
    float Kd = 0.5;
    float Ks = 0.5;
    float m = 20;
    Shader shader;

    Material() {
        // TODO HW4
        // In the Material, pass the relevant attribute variables and uniform variables
        // you need.
        // In the attribute variables, include relevant variables about vertices,
        // and in the uniform, pass other necessary variables.
        // Please note that a Material will be bound to the corresponding Shader.
    }

    abstract Vector4[][] vertexShader(Triangle triangle, Matrix4 M);

    abstract Vector4 fragmentShader(Vector3 position, Vector4[] varing);

    void attachShader(Shader s) {
        shader = s;
    }
}

public class DepthMaterial extends Material {
    DepthMaterial() {
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector4[][] r = shader.vertex.main(new Object[] { position }, new Object[] { MVP });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position });
    }
}

public class PhongMaterial extends Material {

    PhongMaterial() {
        shader = new Shader(new PhongVertexShader(), new PhongFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;
        Vector4[][] r = shader.vertex.main(new Object[] { position, normal }, new Object[] { MVP, M, normalMatrix(M) });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // 多傳一個 Ka 給 fragment shader 算環境光
        return shader.fragment
                .main(new Object[] { position, varing[0].xyz(), varing[1].xyz(), albedo, new Vector3(Kd, Ks, m), Ka });
    }

}

public class FlatMaterial extends Material {
    FlatMaterial() {
        shader = new Shader(new FlatVertexShader(), new FlatFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;

        // TODO HW4
        // pass the uniform you need into the shader.
        // attribute：頂點位置、頂點法向量（用來判斷面法向量的朝向）
        // uniform：MVP、Model 矩陣、法向量矩陣、顏色與光照係數
        Vector3[] normal = triangle.normal;
        Vector4[][] r = shader.vertex.main(new Object[] { position, normal },
                new Object[] { MVP, M, normalMatrix(M), albedo, Ka, new Vector3(Kd, Ks, m) });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // varing[0] 是 vertex shader 算好的整個面的顏色
        return shader.fragment.main(new Object[] { position, varing[0].xyz() });
    }
}

public class GouraudMaterial extends Material {
    GouraudMaterial() {
        shader = new Shader(new GouraudVertexShader(), new GouraudFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        
        // TODO HW4
        // pass the uniform you need into the shader.
        Vector3[] normal = triangle.normal;
        Vector4[][] r = shader.vertex.main(new Object[] { position, normal },
                new Object[] { MVP, M, normalMatrix(M), albedo, Ka, new Vector3(Kd, Ks, m) });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // varing[0] 是三個頂點的顏色經過重心座標內插後的結果
        return shader.fragment.main(new Object[] { position, varing[0].xyz() });
    }
}

// Bonus：貼圖材質。用模型的 UV 座標到貼圖上取顏色，再套用 Phong 光照
public class TextureMaterial extends Material {
    PImage texture;

    TextureMaterial(String objectName) {
        shader = new Shader(new TextureVertexShader(), new TextureFragmentShader());
        texture = loadTextureFor(objectName);
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector4[][] r = shader.vertex.main(new Object[] { triangle.verts, triangle.normal, triangle.uvs },
                new Object[] { MVP, M, normalMatrix(M) });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position, varing[0].xyz(), varing[1].xyz(), varing[2],
                texture, albedo, Ka, new Vector3(Kd, Ks, m) });
    }
}

// 法向量要用 Model 矩陣的「反轉置矩陣」轉換，物體非等比例縮放時法向量才會保持垂直於表面
Matrix4 normalMatrix(Matrix4 M) {
    return M.Inverse().transposed();
}

// 依照模型名稱到 data/Textures 找同名的貼圖（例如 cat.obj → cat.jpg），找不到就用棋盤格
HashMap<String, PImage> textureCache = new HashMap<String, PImage>();
PImage loadTextureFor(String objectName) {
    String file = "Checkerboard.png";
    File[] files = new File(dataPath("Textures")).listFiles();
    if (files != null && objectName != null) {
        for (File f : files) {
            String n = f.getName();
            int dot = n.lastIndexOf('.');
            if (dot > 0 && n.substring(0, dot).equalsIgnoreCase(objectName)) file = n;
        }
    }
    if (!textureCache.containsKey(file)) {
        PImage img = loadImage("Textures/" + file);
        img.loadPixels();
        textureCache.put(file, img);
    }
    return textureCache.get(file);
}

public enum MaterialEnum {
    DM, FM, GM, PM, TM;
}
