Engine engine;

void setup() {
    size(1000, 600);
    engine = new Engine();
}

void draw() {
    background(255);

    engine.run();

}
