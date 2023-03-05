const rl = @import("raylib");
const game = @import("game.zig");

pub fn main() !void {
    const width = 800;
    const height = 450;
    rl.InitWindow(width, height, "Axelisation");
    const screen_size = rl.Vector2{ .x = width, .y = height };
    rl.SetWindowState(@enumToInt(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE));
    rl.SetTargetFPS(60);
    defer rl.CloseWindow();

    var model = game.Model{};
    var previous_time: f64 = rl.GetTime();

    while (!rl.WindowShouldClose()) {
        const current_time: f64 = rl.GetTime();
        const delta_time = current_time - previous_time;

        rl.BeginDrawing();
        defer rl.EndDrawing();

        const input_actions = game.input();

        model = game.update(model, input_actions, delta_time);

        try game.view(model, screen_size);

        rl.DrawFPS(10, 10);
        previous_time = current_time;
    }
}
