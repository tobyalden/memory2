package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Boss extends MemoryEntity {
    public static inline var ACCEL = 1;
    public static inline var MAX_SPEED_GRENADE_PHASE = 3;
    public static inline var STARTING_GRENADE_DROPS = 1;
    public static inline var STARTING_JUMPS = 2;
    public static inline var CYCLE_0_END_HOP = 3.5;
    public static inline var GRAVITY = 0.16;
    public static inline var TIME_BETWEEN_JUMPS = 3;
    public static inline var JUMP_VEL_X = 4;
    public static inline var MAX_JUMP_VEL_X = 7;
    public static inline var JUMP_VEL_Y = 6.3;

    private var sprite:Spritemap;
    //private var lightning:Spritemap;
    private var velocity:Vector2;
    //private var bounceSfx:Sfx;
    private var cycle:Int;
    private var grenadeTimer:Alarm;
    private var grenadeDropCount:Int;
    private var jumpTimer:Alarm;
    private var jumpCount:Int;
    private var wasOnGround:Bool;
    private var startX:Float;
    private var startY:Float;

    public function new(x:Float, y:Float) {
        super(x, y);
        startX = x;
        startY = y;
        type = "enemy";
        sprite = new Spritemap("graphics/boss.png", 100, 100);
        sprite.add("idle", [0]);
        sprite.play("idle");
        //lightning = new Spritemap("graphics/follower.png", 24, 24);
        //lightning.add("idle", [5, 6, 7], 24);
        //lightning.play("idle");
        setGraphic(sprite);
        //addGraphic(lightning);
        //lightning.visible = false;
        velocity = new Vector2(0, 0);
        setHitbox(100, 100);
        //bounceSfx = new Sfx("audio/bounce.wav");
        health = 999;
        cycle = 0;

        grenadeDropCount = 0;
        grenadeTimer = new Alarm(2, TweenType.Persist);
        grenadeTimer.onComplete.bind(function() {
            dropGrenade();
            grenadeDropCount++;
            if(grenadeDropCount >= STARTING_GRENADE_DROPS) {
                advanceCycle();
            }
            else {
                grenadeTimer.start();
            }
        });
        addTween(grenadeTimer, true);

        jumpCount = 0;
        jumpTimer = new Alarm(TIME_BETWEEN_JUMPS, TweenType.Persist);
        jumpTimer.onComplete.bind(function() {
            if(jumpCount >= STARTING_JUMPS) {
                advanceCycle();
            }
            else {
                jumpTimer.start();
            }
            jump();
        });
        addTween(jumpTimer);

        wasOnGround = false;
    }

    private function jump() {
        if(!isOnGround()) {
            return;
        }
        jumpCount++;
        var player = scene.getInstance("player");
        if(centerX < player.centerX) {
            velocity.x = JUMP_VEL_X * (distanceFrom(player, true) / 200);
            velocity.x = Math.min(velocity.x, MAX_JUMP_VEL_X);
        }
        else {
            velocity.x = -JUMP_VEL_X * (distanceFrom(player, true) / 200);
            velocity.x = Math.max(velocity.x, -MAX_JUMP_VEL_X);
        }
        velocity.y = -JUMP_VEL_Y;
        //MemoryEntity.allSfx["hopperjump"].play();
    }

    private function advanceCycle() {
        if(cycle == 0) {
            velocity.x = 0;
            var stompTimer = new Alarm(3, TweenType.OneShot);
            stompTimer.onComplete.bind(function() {
                cycle++;
                velocity.y = -CYCLE_0_END_HOP;
                jumpCount = 0;
            });
            addTween(stompTimer, true);
        }
        else if(cycle == 1) {
            cycle++;
            var floatUp = new VarTween(TweenType.OneShot);
            floatUp.onComplete.bind(function() {
                grenadeTimer.start();
                cycle = 0;
            });
            floatUp.tween(this, "y", startY, 3);
            addTween(floatUp, true);
        }
    }

    override public function stopSound() {
        //hum.stop();
    }

    private function dropGrenade() {
        var grenade = new Grenade(centerX, bottom, new Vector2(0, 0));
        grenade.x -= grenade.width/2;
        scene.add(grenade);
    }

    override public function update() {
        var player = scene.getInstance("player");
        if(cycle == 0) {
            if(Math.abs(centerX - player.centerX) < 25) {
                velocity.scale(0.95);
            }
            else {
                var towardsPlayer = new Vector2(player.centerX - centerX, 0);
                var accel = ACCEL;
                towardsPlayer.normalize(accel * Main.getDelta());
                velocity.add(towardsPlayer);
                var maxSpeed = MAX_SPEED_GRENADE_PHASE;
                if(Math.abs(velocity.x) > maxSpeed) {
                    velocity.x = Math.min(velocity.x, maxSpeed);
                    velocity.x = Math.max(velocity.x, -maxSpeed);
                }
            }
        }
        else if(cycle == 1) {
            if(isOnGround()) {
                if(!jumpTimer.active) {
                    jumpTimer.start();
                }
                if(!wasOnGround) {
                    velocity.x = 0;
                    velocity.y = 0;
                }
            }
            else {
                velocity.y += Main.getDelta() * GRAVITY;
            }
        }
        else if(cycle == 2) {
            velocity.x = 0;
            velocity.y = 0;
        }
        wasOnGround = isOnGround();
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls"]
        );
        animation();
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        if(cycle == 0) {
            velocity.x = 0;
        }
        return true;
    }

    private function animation() {
        sprite.play("idle");
        //lightning.visible = stopFlasher.active;
    }

    override public function takeHit(arrow:Arrow) {
        super.takeHit(arrow);
    }
}

