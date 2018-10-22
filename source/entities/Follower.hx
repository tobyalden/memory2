package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Follower extends MemoryEntity {
    public static inline var ACCEL = 0.1;
    public static inline var MAX_SPEED = 3;
    public static inline var BOUNCE_FACTOR = 0.85;
    public static inline var HIT_KNOCKBACK = 5;

    var sprite:Spritemap;
    var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("idle", [0]);
        setGraphic(sprite);
        velocity = new Vector2(0, 0);
        setHitbox(24, 24);
    }

    override public function update() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel = ACCEL;
        if(distanceFrom(player, true) < 50) {
            accel *= 2;
        }
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(), "walls"
        );
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x * BOUNCE_FACTOR;
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y * BOUNCE_FACTOR;
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}
