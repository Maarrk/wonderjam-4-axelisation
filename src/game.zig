const std = @import("std");

const rl = @import("raylib");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Vector2 = rl.Vector2;
const Axis = rl.GamepadAxis;
const Key = rl.KeyboardKey;

pub const Model = struct {
    player_position: Vector2 = Vector2.zero(),
    camera_position: Vector2 = Vector2.zero(),
};

const InputTrigger = enum {
    none,
    press,
    hold,
    release,
};

pub const InputActions = struct {
    move_right: f32 = 0.0,
    move_down: f32 = 0.0,
    use: InputTrigger = InputTrigger.none,
};

pub fn input() InputActions {
    var actions = InputActions{};

    // Player movement
    if (rl.IsGamepadAvailable(0)) {
        const deadzone = 0.3;

        const x_axis = rl.GetGamepadAxisMovement(0, Axis.GAMEPAD_AXIS_LEFT_X);
        if (@fabs(x_axis) > deadzone) actions.move_right = x_axis;

        const y_axis = rl.GetGamepadAxisMovement(0, Axis.GAMEPAD_AXIS_LEFT_Y);
        if (@fabs(y_axis) > deadzone) actions.move_down = y_axis;
    }
    if (rl.IsKeyDown(Key.KEY_RIGHT)) {
        actions.move_right += 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_LEFT)) {
        actions.move_right -= 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_DOWN)) {
        actions.move_down += 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_UP)) {
        actions.move_down -= 1.0;
    }
    actions.move_right = rl.Clamp(actions.move_right, -1.0, 1.0);
    actions.move_down = rl.Clamp(actions.move_down, -1.0, 1.0);

    // Button presses
    actions.use = keyState(Key.KEY_SPACE);

    return actions;
}

fn keyState(key: Key) InputTrigger {
    if (rl.IsKeyPressed(key)) return InputTrigger.press;
    if (rl.IsKeyReleased(key)) return InputTrigger.release;
    if (rl.IsKeyDown(key)) return InputTrigger.hold;
    return InputTrigger.none;
}

pub fn update(model: Model, input_actions: InputActions, delta_time: f64) Model {
    var m = model;
    const dt = @floatCast(f32, delta_time);

    const player_velocity = 3.0;
    m.player_position.x += input_actions.move_right * player_velocity * dt;
    m.player_position.y += input_actions.move_down * player_velocity * dt;

    return m;
}

pub fn view(model: Model, screen_size: Vector2) !void {
    rl.ClearBackground(rl.BLACK);

    var camera: rl.Camera2D = rl.Camera2D{ .target = model.camera_position };
    camera.offset = Vector2{ .x = screen_size.x / 2.0, .y = screen_size.y / 2.0 };
    camera.zoom = 64.0;

    {
        rl.BeginMode2D(camera);
        defer rl.EndMode2D();

        rl.DrawCircleV(model.player_position, 0.5, rl.RED);
    }

    const status_text = try std.fmt.allocPrint(allocator, "Player position: x:{d:.3} y:{d:.3}\x00", .{ model.player_position.x, model.player_position.y });
    defer allocator.free(status_text);

    rl.DrawText(@ptrCast([*:0]const u8, status_text), 120, 10, 20, rl.YELLOW);
}
