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
    private var eye:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["roombadchase"]);
        type = "enemy";
        sprite = new Spritemap("graphics/roombad.png", 24, 10);
        sprite.add("idle", [0]);
        sprite.add("chasing", [0, 1], 30);
        sprite.play("idle");
        lightning = new Spritemap("graphics/roombad.png", 24, 10);
        lightning.add("idle", [3, 4], 24);
        lightning.play("idle");
        lightning.visible = false;
        eye = new Spritemap("graphics/roombad.png", 24, 10);
        eye.add("idle", [2]);
        eye.play("idle");
        eye.visible = false;
        setGraphic(sprite);
        addGraphic(eye);
        addGraphic(lightning);
        velocity = new Vector2(0, 0);
        setHitbox(24, 10);
        health = 2;
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
        trace(velocity);
        animation();
        super.update();
    }

    private function makeDustOnGround() {
        var dust:Dust;
        dust = new Dust(centerX, bottom, "slide");
        scene.add(dust);
    }

    private function animation() {
        if(velocity.x < 0) {
            sprite.play("chasing");
            sprite.flipX = false;
            lightning.flipX = false;
            eye.flipX = false;
        }
        else if(velocity.x > 0) {
            sprite.play("chasing");
            sprite.flipX = true;
            lightning.flipX = true;
            eye.flipX = true;
        }
        else {
            sprite.play("idle");
        }
        eye.visible = velocity.x != 0;
        lightning.visible = stopFlasher.active;

        if(velocity.x != 0) {
            makeDustOnGround();
        }
    }

    override public function takeHit(arrow:Arrow) {
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}
