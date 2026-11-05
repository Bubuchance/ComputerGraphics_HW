public class Shader {
    VertexShader vertex;
    FragmentShader fragment;

    public Shader(VertexShader v, FragmentShader f) {
        vertex = v;
        fragment = f;
    }
}

public abstract class VertexShader {
    abstract Vector4[][] main(Object[] attribute, Object[] uniform);
}

public abstract class FragmentShader {
    abstract Vector4 main(Object[] varying);
}

public class DepthVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];
        Vector4[] gl_Position = new Vector4[3];
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
        }

        Vector4[][] result = { gl_Position };

        return result;
    }
}

public class DepthFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];

        return new Vector4(position.z, position.z, position.z, 1.0);
    }
}
