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
    public static inline var STARTING_GRENADE_DROPS = 3;
    public static inline var STARTING_JUMPS = 2;
    public static inline var CYCLE_0_END_HOP = 3.5;
    public static inline var GRAVITY = 0.16;
    public static inline var TIME_BETWEEN_JUMPS = 3;
    public static inline var JUMP_VEL_X = 4;
    public static inline var MAX_JUMP_VEL_X = 7;
    public static inline var JUMP_VEL_Y = 6.3;
    public static inline var ARROW_DEFLECT_FACTOR = 1;
    public static inline var HEALTH = 1;

    public var weakPoint(default, null):BossWeakPoint;
    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
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
        MemoryEntity.loadSfx([
            "turretshoot", "bossdeath", "bosslift", "bossjump", "bossland",
            "bossrise", "bosshover", "bosshit1", "bosshit2", "bosshit3"
        ]);
        startX = x;
        startY = y;
        type = "boss";
        sprite = new Spritemap("graphics/boss.png", 100, 100);
        sprite.add("idle", [0]);
        sprite.add("stomp", [1]);
        sprite.add("hit", [2]);
        sprite.play("idle");
        lightning = new Spritemap("graphics/boss.png", 100, 100);
        lightning.add("idle", [3, 4], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        velocity = new Vector2(0, 0);
        setHitbox(100, 100);
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
                MemoryEntity.allSfx['bossrise'].play();
                advanceCycle();
            }
            else {
                jumpTimer.start();
                MemoryEntity.allSfx['bossjump'].play();
            }
            jump();
        });
        addTween(jumpTimer);

        wasOnGround = false;
        weakPoint = new BossWeakPoint(this);
        MemoryEntity.allSfx['bosshover'].volume = 0;
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
    }

    private function advanceCycle() {
        if(cycle == 0) {
            velocity.x = 0;
            var stompTimer = new Alarm(3, TweenType.OneShot);
            stompTimer.onComplete.bind(function() {
                cycle++;
                velocity.y = -CYCLE_0_END_HOP;
                MemoryEntity.allSfx['bosshover'].stop();
                MemoryEntity.allSfx['bosslift'].play();
                jumpCount = 0;
            });
            addTween(stompTimer, true);
        }
        else if(cycle == 1) {
            cycle++;
            var floatUp = new VarTween(TweenType.OneShot);
            floatUp.onComplete.bind(function() {
                grenadeDropCount = 0;
                grenadeTimer.start();
                cycle = 0;
                MemoryEntity.allSfx['bosshover'].loop();
            });
            floatUp.tween(this, "y", startY, 3);
            addTween(floatUp, true);
        }
    }

    override public function stopSound() {
        MemoryEntity.allSfx['bosshover'].stop();
    }

    private function dropGrenade() {
        var grenade = new Grenade(centerX, bottom, new Vector2(0, 0));
        grenade.x -= grenade.width/2;
        scene.add(grenade);
        MemoryEntity.allSfx['turretshoot'].play();
    }

    override public function update() {
        var player = scene.getInstance("player");
        if(cycle == 0) {
            if(!MemoryEntity.allSfx['bosshover'].playing) {
                MemoryEntity.allSfx['bosshover'].loop();
            }
            MemoryEntity.allSfx['bosshover'].volume = (
                Math.abs(velocity.x) / MAX_SPEED_GRENADE_PHASE
            );
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

        if(!wasOnGround && isOnGround()) {
            MemoryEntity.allSfx["bossland"].play();
        }

        wasOnGround = isOnGround();
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls"]
        );
        animation();

        var _arrow = collide("arrow", x, y);
        if(_arrow != null && !cast(_arrow, Arrow).landed) {
            var arrow = cast(_arrow, Arrow);
            arrow.velocity.inverse();
            arrow.velocity.scale(ARROW_DEFLECT_FACTOR);
            if(!arrow.silent) {
                MemoryEntity.allSfx['arrowhit${HXP.choose(1, 2, 3)}'].play(1);
                arrow.silence();
            }
        }

        weakPoint.positionOnBoss();

        super.update();
    }

    public override function moveCollideX(e:Entity) {
        if(cycle == 0) {
            velocity.x = 0;
        }
        return true;
    }

    override private function die() {
        scene.remove(this);
        var arrows = detachArrows();
        for(arrow in arrows) {
            cast(arrow, Arrow).setVelocity(
                new Vector2(Math.random() * -5, Math.random() * -5)
            );
        }
        explode(100, 1, false, true);
        MemoryEntity.allSfx['bossdeath'].play();
#if desktop
        Sys.sleep(0.03);
#end
        stopSound();
    }

    private function animation() {
        if(stopFlasher.active) {
            sprite.play("hit");
        }
        else if(isOnGround()) {
            sprite.play("stomp");
        }
        else {
            sprite.play("idle");
        }
        lightning.visible = stopFlasher.active;
    }

    override public function takeHit(arrow:Arrow) {
        if(!arrow.isScattered) {
            MemoryEntity.allSfx['bosshit${HXP.choose(1, 2, 3)}'].play();
        }
        visible = false;
        isFlashing = true;
        stopFlasher.start();
    }
}

