public class Engine {
    ShapeRenderer shapeRenderer;
    Inspector inspector;
    Hierarchy hierarchy;

    Vector3[] boundary = { new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0), new Vector3(1, -1, 0) };

    ArrayList<ShapeButton> shapeButton = new ArrayList<ShapeButton>();
    ShapeButton rectangleButton;
    ShapeButton starButton;

    public Engine() {
        shapeRenderer = new ShapeRenderer();
        inspector = new Inspector();
        hierarchy = new Hierarchy(shapeRenderer.shapes);

        initButton();

    }

    public void initButton() {
        rectangleButton = new ShapeButton(20, 10, 30, 30) {
            @Override
            public void show() {
                super.show();
                stroke(0);
                line(pos.x + 2, pos.y + 2, pos.x + size.x - 2, pos.y + 2);
                line(pos.x + 2, pos.y + size.y - 2, pos.x + size.x - 2, pos.y + size.y - 2);
                line(pos.x + size.x - 2, pos.y + 2, pos.x + size.x - 2, pos.y + size.y - 2);
                line(pos.x + 2, pos.y + 2, pos.x + 2, pos.y + size.y - 2);
            }

            @Override
            public Shape renderShape() {
                return new Rectangle();
            }
        };

        rectangleButton.setBoxAndClickColor(color(250), color(150));
        shapeButton.add(rectangleButton);

        starButton = new ShapeButton(60, 10, 30, 30) {
            @Override
            public void show() {
                super.show();
            }

            @Override
            public Shape renderShape() {
                return new Star();
            }
        };

        starButton.setImage(loadImage("star.png"));
        starButton.setBoxAndClickColor(color(250), color(150));
        shapeButton.add(starButton);
    }

    void run() {
        shapeRenderer.run();
        inspector.run();
        hierarchy.run();

        for (ShapeButton sb : shapeButton) {
            sb.run(() -> {
                shapeRenderer.addShape(sb.renderShape());
            });
        }

    }

}
