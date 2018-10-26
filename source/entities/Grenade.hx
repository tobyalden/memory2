package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Grenade extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var BOUNCE_FACTOR = 0.5;
    public static inline var GRAVITY = 0.2;
    public static inline var MAX_FALL_VELOCITY = 6;

    private var sprite:Spritemap;
    private var velocity:Vector2;

    public function new(x:Float, y:Float, velocity:Vector2) {
        super(x, y);
        this.velocity = velocity;
        sprite = new Spritemap("graphics/grenade.png", 10, 10);
        setHitbox(10, 10);
        sprite.add("idle", [0]);
        sprite.play("idle");
        setGraphic(sprite);
    }

    override public function update() {
        var gravity = GRAVITY * Main.getDelta();
        velocity.y += gravity;
        velocity.y = Math.min(velocity.y, MAX_FALL_VELOCITY);
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            "walls"
        );
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        //velocity.x = -velocity.x * BOUNCE_FACTOR;
        scene.remove(this);
        explode(2, 0.1);
        return true;
    }

    public override function moveCollideY(e:Entity) {
        //velocity.y = -velocity.y * BOUNCE_FACTOR;
        scene.remove(this);
        explode(2, 0.1);
        return true;
    }
}
