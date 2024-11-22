import Media.Picture;
import Media.Turtle;
import Media.TurtleDisplayer;

import java.awt.Color;
import java.awt.Color;

public class FloorPlanGenerator {

    private static final int WIDTH = 500;
    private static final int HEIGHT = 500;
    private static final Color WALL_COLOR = Color.BLACK;
    private static final Color DOOR_COLOR = Color.YELLOW;

    public static void main(String[] args) {
        FloorPlanGenerator generator = new FloorPlanGenerator();
        generator.generateFloorPlan();
    }

    public void generateFloorPlan() {
        // Create a Turtle instance
        Turtle turtle = new Turtle(WIDTH / 2, HEIGHT / 2, WALL_COLOR);
        turtle.penDown();

        // Draw the outer walls
        drawOuterWalls(turtle);

        // Add rooms and doors
        addRooms(turtle);
        addDoors(turtle);

        // Display the generated floor plan
        Picture picture = turtle.getPcolor();
        picture.show();
    }

    private void drawOuterWalls(Turtle turtle) {
        turtle.turn(0);  // Face east
        turtle.forward(400);
        turtle.turn(90);
        turtle.forward(400);
        turtle.turn(90);
        turtle.forward(400);
        turtle.turn(90);
        turtle.forward(400);
        turtle.turn(90);
    }

    private void addRooms(Turtle turtle) {
        // Define the dimensions of rooms and their positions
        addRoom(turtle, 50, 50, 100, 150); // Room 1
        addRoom(turtle, 200, 50, 100, 150); // Room 2
        addRoom(turtle, 50, 200, 100, 150); // Room 3
        addRoom(turtle, 200, 200, 100, 150); // Room 4
    }

    private void addRoom(Turtle turtle, int startX, int startY, int width, int height) {
        // Move turtle to the starting point for a room
        turtle.penUp();
        turtle.forward(startX - turtle.getX());
        turtle.turn(90);
        turtle.forward(startY - turtle.getY());
        turtle.turn(270);
        turtle.penDown();

        // Draw a rectangle for the room
        turtle.forward(width);
        turtle.turn(90);
        turtle.forward(height);
        turtle.turn(90);
        turtle.forward(width);
        turtle.turn(90);
        turtle.forward(height);
        turtle.turn(90);
    }

    private void addDoors(Turtle turtle) {
        // Add doors by drawing small lines in the walls
        addDoor(turtle, 150, 50, 30);  // Door 1
        addDoor(turtle, 150, 200, 30); // Door 2
    }

    private void addDoor(Turtle turtle, int x, int y, int width) {
        turtle.penUp();
        turtle.forward(x - turtle.getX());
        turtle.turn(90);
        turtle.forward(y - turtle.getY());
        turtle.turn(270);
        turtle.penDown();

        turtle.forward(width); // Draw door
    }
}

