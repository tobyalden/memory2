package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Hopper extends MemoryEntity {
    public static inline var ACTIVE_RANGE = 250;
    public static inline var JUMP_VEL_X = 3.3;
    public static inline var JUMP_VEL_Y = 3.3;
    public static inline var GRAVITY = 0.18;
    public static inline var TIME_BETWEEN_JUMPS = 1.5;

    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var jumpTimer:Alarm;
    private var wasOnGround:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/hopper.png", 24, 24);
        sprite.add("idle", [0, 1], 5);
        sprite.add("jump", [3, 2], 6, false);
        sprite.add("hit", [4], 6);
        sprite.play("idle");
        lightning = new Spritemap("graphics/lightning.png", 24, 24);
        lightning.add("idle", [0, 1, 2], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        setHitbox(24, 24);
        health = 2;
        velocity = new Vector2(0, 0);
        jumpTimer = new Alarm(TIME_BETWEEN_JUMPS, TweenType.Looping);
        jumpTimer.onComplete.bind(function() {
            jump();
        });
        addTween(jumpTimer, true);
        wasOnGround = false;
    }

    public override function update() {
        if(isOnGround()) {
            if(!wasOnGround) {
                sprite.play("idle");
                velocity.x = 0;
                velocity.y = 0;
            }
        }
        else {
            velocity.y += Main.getDelta() * GRAVITY;
        }
        wasOnGround = isOnGround();
        moveBy(
            Main.getDelta() * velocity.x, Main.getDelta() * velocity.y,
            ["walls", "enemy"]
        );
        lightning.visible = stopFlasher.active;
        if(stopFlasher.active) {
            sprite.play("hit");
        }
        super.update();
    }

    private function jump() {
        var player = scene.getInstance("player");
        if(distanceFrom(player, true) > ACTIVE_RANGE || !isOnGround()) {
            return;
        }
        if(centerX < player.centerX) {
            velocity.x = JUMP_VEL_X;
        }
        else {
            velocity.x = -JUMP_VEL_X;
        }
        velocity.y = -JUMP_VEL_Y;
        sprite.play("jump");
    }
}

