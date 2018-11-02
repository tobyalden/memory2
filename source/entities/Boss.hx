package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import scenes.*;

class Boss extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var MAX_SPEED = 2;

    private var sprite:Spritemap;
    //private var lightning:Spritemap;
    private var velocity:Vector2;
    //private var bounceSfx:Sfx;

    public function new(x:Float, y:Float) {
        super(x, y);
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
        health = 10;
    }

    override public function stopSound() {
        //hum.stop();
    }

    override public function update() {
        var player = scene.getInstance("player");
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls"]
        );
        animation();
        super.update();
    }

    private function animation() {
        sprite.play("idle");
        //lightning.visible = stopFlasher.active;
    }

    override public function takeHit(arrow:Arrow) {
        super.takeHit(arrow);
    }
}

