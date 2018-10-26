package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Follower extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var MAX_SPEED = 2;
    public static inline var BOUNCE_FACTOR = 0.85;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var ACTIVATE_DISTANCE = 150;

    var sprite:Spritemap;
    var lightning:Spritemap;
    var velocity:Vector2;
    var isActive:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("idle", [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ], 24);
        sprite.add("chasing", [3]);
        sprite.add("hit", [4]);
        sprite.play("idle");
        lightning = new Spritemap("graphics/follower.png", 24, 24);
        lightning.add("idle", [5, 6, 7], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        velocity = new Vector2(0, 0);
        setHitbox(23, 23, -1, -1);
        isActive = false;
    }

    override public function update() {
        var player = scene.getInstance("player");
        if(distanceFrom(player, true) < ACTIVATE_DISTANCE) {
            isActive = true;
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
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        if(isActive) {
            moveBy(
                velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
                ["walls", "enemy"]
            );
        }
        animation();
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
        lightning.visible = stopFlasher.active;
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
        isActive = true;
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}
