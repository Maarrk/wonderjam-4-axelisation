const rl = @import("raylib");

pub fn main() void {
    rl.InitWindow(800, 450, "Axelisation");
    rl.SetTargetFPS(60);
    defer rl.CloseWindow();

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);
        rl.DrawFPS(10, 10);

        rl.DrawText("Hello, world!", 100, 100, 20, rl.YELLOW);
    }
}
