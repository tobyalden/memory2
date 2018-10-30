package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Hopper extends MemoryEntity {
    public static inline var ACTIVE_RANGE = 250;
    public static inline var JUMP_VEL_X = 3;
    public static inline var JUMP_VEL_Y = 3.8;
    public static inline var GRAVITY = 0.16;
    public static inline var TIME_BETWEEN_JUMPS = 1.5;
    public static inline var HIT_KNOCKBACK = 5;

    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var jumpTimer:Alarm;
    private var wasOnGround:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["hopperjump", "hopperland"]);
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
        setHitbox(24, 23, 0, -1);
        if(GameScene.easyMode) {
            health = 1;
        }
        else {
            health = 2;
        }
        velocity = new Vector2(0, 0);
        jumpTimer = new Alarm(TIME_BETWEEN_JUMPS, TweenType.Looping);
        jumpTimer.onComplete.bind(function() {
            jump();
        });
        addTween(jumpTimer);
        var jumpTimerDelay = new Alarm(Math.random(), TweenType.OneShot);
        jumpTimerDelay.onComplete.bind(function() {
            jumpTimer.start();
        });
        addTween(jumpTimerDelay, true);
        wasOnGround = false;
    }

    public override function update() {
        if(isOnGround()) {
            if(!wasOnGround) {
                if(isOnScreen()) {
                    MemoryEntity.allSfx["hopperland"].play();
                }
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
        else if(isOnGround()) {
            sprite.play("idle");
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
        if(isOnScreen()) {
            MemoryEntity.allSfx["hopperjump"].play();
        }
    }

    public override function moveCollideX(e:Entity) {
        if(!isOnGround()) {
            velocity.x = velocity.x / 2;
        }
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = velocity.y / 2;
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        if(!isOnGround()) {
            var knockback = arrow.velocity.clone();
            knockback.normalize(HIT_KNOCKBACK);
            velocity.add(knockback);
        }
        super.takeHit(arrow);
    }
}

