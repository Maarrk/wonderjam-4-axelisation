const rl = @import("raylib");
const game = @import("game.zig");

pub fn main() !void {
    rl.InitWindow(800, 450, "Axelisation");
    rl.SetWindowState(@enumToInt(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE));
    rl.SetTargetFPS(60);
    defer rl.CloseWindow();

    var model = game.Model{};

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        const input_actions = game.input();
        defer input_actions.deinit();

        model = game.update(model, input_actions);

        try game.view(model);

        rl.DrawFPS(10, 10);
    }
}
