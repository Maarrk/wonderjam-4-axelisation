const std = @import("std");
const rl = @import("raylib");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const Model = struct {
    player_position: rl.Vector2 = rl.Vector2{
        .x = 1.0,
        .y = 2.0,
    },
};

pub const InputAction = union {
    move_up: f32,
    move_right: f32,
    use: void,
};

pub fn input() std.ArrayList(InputAction) {
    var list = std.ArrayList(InputAction).init(allocator);
    return list;
}

pub fn update(model: Model, input_actions: std.ArrayList(InputAction)) Model {
    _ = input_actions;
    return model;
}

pub fn view(model: Model) !void {
    rl.ClearBackground(rl.BLACK);

    const status_text = try std.fmt.allocPrint(allocator, "Player position: x:{d:.3} y:{d:.3}\x00", .{ model.player_position.x, model.player_position.y });
    defer allocator.free(status_text);

    rl.DrawText(@ptrCast([*:0]const u8, status_text), 100, 100, 20, rl.YELLOW);
}
