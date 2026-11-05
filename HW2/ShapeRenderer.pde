public class ShapeRenderer {
    private Box box;
    private ArrayList<Shape> shapes;

    public ShapeRenderer() {
        box = new Box(20, 50, 500, height - 100);
        box.setBoxColor(250);
        shapes = new ArrayList<Shape>();
    }

    public void run() {
        box.show();
        shapes.forEach(Shape::drawShape);

    }

    public void addShape(Shape s) {
        shapes.add(s);
        engine.hierarchy.addButton(s);
    }

    public boolean checkInBox(Vector3 v) {
        return box.checkInSide(v);
    }

    public void popShape() {
        if (shapes.size() <= 0)
            return;
        shapes.remove(shapes.size() - 1);
    }

    public void clear() {
        shapes.clear();
    }
}

public class Hierarchy {
    private Box box;
    ArrayList<Shape> shapes;
    ArrayList<HierarchyButton> buttons;

    public Hierarchy(ArrayList<Shape> s) {
        box = new Box(500 + 40, 50, 200, height - 100);
        box.setBoxColor(250);
        shapes = s;
        buttons = new ArrayList<HierarchyButton>();
    }

    public void addButton(Shape s) {
        float y = buttons.size() * 30;
        HierarchyButton hb = new HierarchyButton(box.pos.x, box.pos.y + y, 200, 30);
        hb.name = s.getShapeName();
        hb.setBoxAndClickColor(color(250), color(150));
        hb.shape = s;
        buttons.add(hb);
    }

    public void run() {
        textAlign(LEFT, CENTER);
        textSize(18);
        fill(0);
        text("Hierarchy", box.pos.x, box.pos.y - 10);
        box.show();

        for (HierarchyButton hb : buttons) {
            hb.run(() -> {
                engine.inspector.setShape(hb.shape);
            });
        }
    }
}

public class Inspector {
    private Box box;
    Shape shape;
    Slider[] position_slider = new Slider[3];
    Slider[] rotation_slider = new Slider[3];
    Slider[] scale_slider = new Slider[3];
    String inspectName = "xyz";

    public Inspector() {

        box = new Box(740 + 20, 50, 200, height - 100);
        box.setBoxColor(250);
    }

    public void setShape(Shape s) {
        shape = s;
        for (int i = 0; i < position_slider.length; i++) {
            position_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(-1, 1, 0), true);
        }
        position_slider[0].setValue(shape.transform.position.x);
        position_slider[1].setValue(shape.transform.position.y);
        position_slider[2].setValue(shape.transform.position.z);

        for (int i = 0; i < rotation_slider.length; i++) {
            rotation_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 100, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0, 6.28, 0), true);
        }
        rotation_slider[0].setValue(shape.transform.rotation.x);
        rotation_slider[1].setValue(shape.transform.rotation.y);
        rotation_slider[2].setValue(shape.transform.rotation.z);

        for (int i = 0; i < scale_slider.length; i++) {
            scale_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 200, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0.1, 3, 0), true);
        }
        scale_slider[0].setValue(shape.transform.scale.x);
        scale_slider[1].setValue(shape.transform.scale.y);
        scale_slider[2].setValue(shape.transform.scale.z);

    }

    public void run() {
        textAlign(LEFT, CENTER);
        textSize(18);
        fill(0);
        text("Inspector", box.pos.x, box.pos.y - 10);
        box.show();
        if (shape != null) {
            textAlign(LEFT, CENTER);
            textSize(15);
            fill(0);
            text("position", box.pos.x, box.pos.y + 15);
            for (int i = 0; i < position_slider.length; i++) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text(inspectName.charAt(i), box.pos.x, position_slider[i].pos.y + 5);
                text(position_slider[i].value(), box.pos.x + 170, position_slider[i].pos.y + 5);
                position_slider[i].show();
                position_slider[i].click();
            }
            shape.transform.position = new Vector3(position_slider[0].value(), position_slider[1].value(),
                    position_slider[2].value());

            textAlign(LEFT, CENTER);
            textSize(15);
            fill(0);
            text("rotation", box.pos.x, box.pos.y + 15 + 100);
            for (int i = 0; i < rotation_slider.length; i++) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text(inspectName.charAt(i), box.pos.x, rotation_slider[i].pos.y + 5);
                text(rotation_slider[i].value(), box.pos.x + 170, rotation_slider[i].pos.y + 5);
                rotation_slider[i].show();
                rotation_slider[i].click();
            }
            shape.transform.rotation = new Vector3(rotation_slider[0].value(), rotation_slider[1].value(),
                    rotation_slider[2].value());

            textAlign(LEFT, CENTER);
            textSize(15);
            fill(0);
            text("scale", box.pos.x, box.pos.y + 15 + 200);
            for (int i = 0; i < scale_slider.length; i++) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text(inspectName.charAt(i), box.pos.x, scale_slider[i].pos.y + 5);
                text(scale_slider[i].value(), box.pos.x + 170, scale_slider[i].pos.y + 5);
                scale_slider[i].show();
                scale_slider[i].click();
            }
            shape.transform.scale = new Vector3(scale_slider[0].value(), scale_slider[1].value(),
                    scale_slider[2].value());

        }
    }
}
