const std = @import("std");
const rl = @import("raylib");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Vector2 = rl.Vector2;
const Axis = rl.GamepadAxis;
const Key = rl.KeyboardKey;
const Button = rl.GamepadButton;

const Config = struct {
    player_size: Vector2 = Vector2.one(),
    player_max_velocity: f32 = 3.0,
    player_jump_velocity: f32 = 5.0,
    player_air_acceleration: f32 = 8.0,
    player_air_friction: f32 = 3.0,
    env_items: [2]EnvItem = [_]EnvItem{
        EnvItem{ .rect = rl.Rectangle{ .x = -6, .y = 3, .width = 12, .height = 0.5 }, .blocking = true, .color = rl.GRAY },
        EnvItem{ .rect = rl.Rectangle{ .x = 2, .y = 1, .width = 3, .height = 1 }, .blocking = true, .color = rl.GRAY },
    },
    gravity: f32 = 6.0,
};
const config = Config{};

pub const Model = struct {
    player_position: Vector2 = Vector2.zero(),
    player_velocity: Vector2 = Vector2.zero(),
    camera_position: Vector2 = Vector2.zero(),
};

const EnvItem = struct {
    rect: rl.Rectangle,
    blocking: bool,
    color: rl.Color,
};

const InputTrigger = enum {
    none,
    hold,
    release,
    press,

    fn orInput(self: InputTrigger, other: InputTrigger) InputTrigger {
        return @intToEnum(InputTrigger, std.math.max(@enumToInt(self), @enumToInt(other)));
    }
};

pub const InputActions = struct {
    move: Vector2 = Vector2.zero(),
    jump: InputTrigger = InputTrigger.none,
    sprint: InputTrigger = InputTrigger.none,
};

pub fn input() InputActions {
    var actions = InputActions{};

    // Player movement
    if (rl.IsGamepadAvailable(0)) {
        const deadzone = 0.3;

        const x_axis = rl.GetGamepadAxisMovement(0, Axis.GAMEPAD_AXIS_LEFT_X);
        if (@fabs(x_axis) > deadzone) actions.move.x = x_axis;

        const y_axis = rl.GetGamepadAxisMovement(0, Axis.GAMEPAD_AXIS_LEFT_Y);
        if (@fabs(y_axis) > deadzone) actions.move.y = y_axis;
    }
    if (rl.IsKeyDown(Key.KEY_RIGHT)) {
        actions.move.x += 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_LEFT)) {
        actions.move.x -= 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_DOWN)) {
        actions.move.y += 1.0;
    }
    if (rl.IsKeyDown(Key.KEY_UP)) {
        actions.move.y -= 1.0;
    }
    actions.move.x = rl.Clamp(actions.move.x, -1.0, 1.0);
    actions.move.y = rl.Clamp(actions.move.y, -1.0, 1.0);

    // Button presses
    actions.jump = keyState(Key.KEY_SPACE).orInput(buttonState(Button.GAMEPAD_BUTTON_RIGHT_FACE_DOWN));
    actions.sprint = keyState(Key.KEY_LEFT_SHIFT).orInput(buttonState(Button.GAMEPAD_BUTTON_LEFT_TRIGGER_1));

    return actions;
}

fn keyState(key: Key) InputTrigger {
    if (rl.IsKeyPressed(key)) return InputTrigger.press;
    if (rl.IsKeyReleased(key)) return InputTrigger.release;
    if (rl.IsKeyDown(key)) return InputTrigger.hold;
    return InputTrigger.none;
}

fn buttonState(button: Button) InputTrigger {
    if (rl.IsGamepadAvailable(0)) {
        if (rl.IsGamepadButtonPressed(0, button)) return InputTrigger.press;
        if (rl.IsGamepadButtonReleased(0, button)) return InputTrigger.release;
        if (rl.IsGamepadButtonDown(0, button)) return InputTrigger.press;
    }
    return InputTrigger.none;
}

pub fn update(model: Model, input_actions: InputActions, delta_time: f64) Model {
    var m = model;
    const dt = @floatCast(f32, delta_time);

    const is_grounded = for (config.env_items) |ei| {
        const p = m.player_position;
        if (ei.blocking and
            ei.rect.x <= p.x and
            ei.rect.x + ei.rect.width >= p.x and
            ei.rect.y <= p.y and
            ei.rect.y <= p.y + m.player_velocity.y * dt)
        {
            m.player_position.y = ei.rect.y;
            break true;
        }
    } else false;

    {
        var v = &m.player_velocity;
        const move = input_actions.move;

        if (is_grounded) {
            v.x = config.player_max_velocity * move.x;
            if (input_actions.jump == InputTrigger.press) {
                v.y = -config.player_jump_velocity;
            } else {
                m.player_velocity.y = 0;
            }
        } else {
            const move_dv = config.player_max_velocity * dt;
            if (@fabs(v.x) <= config.player_max_velocity - move_dv or v.x * move.x < 0) {
                v.x += move.x * config.player_air_acceleration * dt;
            }
            if (input_actions.sprint == InputTrigger.press) {
                // Temporary to test above max velocity
                const dash_v = 3.0;
                if (move.x > 0) v.x += dash_v;
                if (move.x < 0) v.x -= dash_v;
            }

            if (!(@fabs(move.x) >= 0.95 and v.x * move.x > 0)) {
                // Keep current velocity if maximal input in direction of travel
                const friction_dv = config.player_air_friction * dt;
                if (@fabs(v.x) <= friction_dv) {
                    v.x = 0.0;
                } else {
                    v.x -= if (v.x > 0) friction_dv else -friction_dv;
                }
            }

            v.y += config.gravity * dt;
        }
    }

    m.player_position = rl.Vector2Add(m.player_position, rl.Vector2Scale(m.player_velocity, dt));

    return m;
}

pub fn view(model: Model, screen_size: Vector2) !void {
    rl.ClearBackground(rl.DARKGRAY);

    var camera: rl.Camera2D = rl.Camera2D{ .target = model.camera_position };
    camera.offset = Vector2{ .x = screen_size.x / 2.0, .y = screen_size.y / 2.0 };
    camera.zoom = 48.0;

    {
        rl.BeginMode2D(camera);
        defer rl.EndMode2D();

        for (config.env_items) |env_item| {
            rl.DrawRectangleRec(env_item.rect, env_item.color);
        }

        const p_rect = rl.Rectangle{
            .x = model.player_position.x - config.player_size.x / 2,
            .y = model.player_position.y - config.player_size.y,
            .width = config.player_size.x,
            .height = config.player_size.y,
        };
        rl.DrawRectangleRec(p_rect, rl.RED);
    }

    const status_text = try std.fmt.allocPrint(allocator, "position: x:{d:.2} y:{d:.2}\nvelocity: x:{d:.2} y:{d:.2}\x00", .{ model.player_position.x, model.player_position.y, model.player_velocity.x, model.player_velocity.y });
    defer allocator.free(status_text);

    rl.DrawText(@ptrCast([*:0]const u8, status_text), 120, 10, 20, rl.YELLOW);
}
