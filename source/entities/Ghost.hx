package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Ghost extends MemoryEntity {
    public static inline var ACCEL = 0.03;
    public static inline var MAX_SPEED = 1.8;
    public static inline var MAX_SPEED_PHASED = 0.9;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var ACTIVATE_DISTANCE = 200;
    public static inline var HUM_DISTANCE = 200;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var isActive:Bool;
    private var hum:Sfx;
    private var hitSfx:Sfx;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["ghosthit1", "ghosthit2", "ghosthit3"]);
        type = "enemy";
        sprite = new Spritemap("graphics/ghost.png", 30, 30);
        sprite.add("idle", [0, 1], 6);
        sprite.play("idle");
        setGraphic(sprite);
        velocity = new Vector2(0, 0);
        setHitbox(30, 30);
        isActive = false;
        hum = new Sfx("audio/ghost.wav");
        hum.volume = 0;
        health = 1;
    }

    override public function stopSound() {
        hum.stop();
    }

    override public function update() {
        var player = scene.getInstance("player");
        var wasActive = isActive;
        if(distanceFrom(player, true) < ACTIVATE_DISTANCE) {
            isActive = true;
        }
        if(isActive && !wasActive) {
            hum.loop();
        }
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel = ACCEL;
        if(distanceFrom(player, true) < 50) {
            accel *= 2;
        }
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);

        collidable = true;
        if(collide("walls", x, y) != null) {
            collidable = false;
        }
        sprite.alpha = collidable ? 1 : 0.5;

        var maxSpeed = collidable ? MAX_SPEED : MAX_SPEED_PHASED;
        if(velocity.length > maxSpeed) {
            velocity.normalize(maxSpeed);
        }
        if(isActive) {
            moveBy(velocity.x * Main.getDelta(), velocity.y * Main.getDelta());
        }
        animation();


        if(isActive) {
            hum.volume = 1 - Math.min(
                distanceFrom(player, true), HUM_DISTANCE
            ) / HUM_DISTANCE;
        }
        else {
            hum.volume = 0;
        }

        super.update();
    }

    private function animation() {
        var player = scene.getInstance("player");
        sprite.flipX = centerX < player.centerX;
        if(stopFlasher.active) {
            sprite.play("hit");
        }
        else if(isActive) {
            sprite.play("chasing");
        }
        else {
            sprite.play("idle");
        }
    }

    override public function takeHit(arrow:Arrow) {
        scene.remove(this);
        var arrows = detachArrows();
        explode();
        MemoryEntity.allSfx['ghosthit${HXP.choose(1, 2, 3)}'].play();
#if desktop
        Sys.sleep(0.02);
#end
        stopSound();
    }
}

