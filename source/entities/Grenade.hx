package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Grenade extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var BOUNCE_FACTOR = 0.75;
    public static inline var GRAVITY = 0.2;
    public static inline var MAX_FALL_VELOCITY = 6;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var bounceCount:Int;
    private var explodeTimer:Alarm;

    public function new(x:Float, y:Float, velocity:Vector2) {
        super(x, y);
        this.velocity = velocity;
        type = "grenade";
        layer = 10;
        sprite = new Spritemap("graphics/grenade.png", 12, 12);
        setHitbox(4, 4, -4, -4);
        sprite.add("idle", [0, 1], 5);
        sprite.play("idle");
        setGraphic(sprite);
        bounceCount = 0;
        explodeTimer = new Alarm(1, TweenType.OneShot);
        explodeTimer.onComplete.bind(function() {
            scene.remove(this);
            scene.add(new Explosion(centerX - 72, centerY - 72));
        });
        addTween(explodeTimer, true);
    }

    override public function update() {
        var gravity = GRAVITY * Main.getDelta();
        velocity.y += gravity;
        velocity.y = Math.min(velocity.y, MAX_FALL_VELOCITY);
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(), "walls"
        );
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        bounceCount++;
        velocity.x = -velocity.x * BOUNCE_FACTOR;
        return true;
    }

    public override function moveCollideY(e:Entity) {
        bounceCount++;
        velocity.y = -velocity.y * BOUNCE_FACTOR;
        return true;
    }
}
