package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Roombad extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var MAX_SPEED = 5;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var TIME_BETWEEN_LOBS = 1;
    public static inline var LOB_ACTIVATION_DISTANCE = 180;
    public static inline var LOB_POWER = 5;

    private var sprite:Spritemap;
    private var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/roombad.png", 24, 10);
        sprite.add("idle", [1]);
        sprite.play("idle");
        setGraphic(sprite);
        velocity = new Vector2(0, 0);
        setHitbox(24, 10);
    }

    //private function lob() {
        //var player = scene.getInstance("player");
        //if(!turretMode) {
            //return;
        //}
        //var towardsPlayer = new Vector2(0, 0);
        //towardsPlayer.x = (distanceFrom(player, true) / LOB_ACTIVATION_DISTANCE) * LOB_POWER;
        //if(x > player.x) {
            //towardsPlayer.x *= -1;
        //}
        //towardsPlayer.y = -LOB_POWER;
        //if(y <= player.y) {
            //towardsPlayer.y /= 2;
        //}
        //var grenade = new Grenade(centerX, top, towardsPlayer);
        //scene.add(grenade);
    //}

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        if(bottom == player.bottom && player.isOnGround()) {
            if(x < player.x) {
                velocity.x = MAX_SPEED;
            }
            else {
                velocity.x = -MAX_SPEED;
            }
        }
        else {
            velocity.x = 0;
        }

        x += velocity.x * Main.getDelta();
        var willGoOffEdge = false;
        if(velocity.x < 0) {
            if(!isBottomLeftCornerOnGround()) {
                willGoOffEdge = true;
            }
        }
        else if(velocity.x > 0) {
            if(!isBottomRightCornerOnGround()) {
                willGoOffEdge = true;
            }
        }
        x -= velocity.x * Main.getDelta();

        if(willGoOffEdge) {
            velocity.x = 0;
        }

        moveBy(velocity.x * Main.getDelta(), 0, ["walls", "enemy"]);
        super.update();
    }

    override public function takeHit(arrow:Arrow) {
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}
