package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Roombad extends MemoryEntity {
    public static inline var IDLE_SPEED = 2;
    public static inline var CHASE_SPEED = 4;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var SFX_DISTANCE = 280;
    //public static inline var TIME_BETWEEN_LOBS = 1;
    //public static inline var LOB_ACTIVATION_DISTANCE = 180;
    //public static inline var LOB_POWER = 5;

    private var sprite:Spritemap;
    private var eye:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var isChasing:Bool;
    private var idleSfx:Sfx;
    private var chaseSfx:Sfx;
    private var soundsStopped:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["roombadchase"]);
        type = "enemy";
        sprite = new Spritemap("graphics/roombad.png", 24, 10);
        sprite.add("idle", [0, 1], 7);
        sprite.add("chasing", [0, 1], 14);
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
        velocity = new Vector2(IDLE_SPEED, 0);
        if(Random.random > 0.5) {
            velocity.x *= -1;
        }
        setHitbox(24, 10);
        if(GameScene.easyMode) {
            health = 1;
        }
        else {
            health = 2;
        }
        isChasing = false;
        idleSfx = new Sfx("audio/roombadidle.wav");
        chaseSfx = new Sfx("audio/roombadchase.wav");
        idleSfx.volume = 0;
        chaseSfx.volume = 0;
        soundsStopped = false;
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
            isChasing = true;
            if(x < player.x) {
                velocity.x = CHASE_SPEED;
            }
            else {
                velocity.x = -CHASE_SPEED;
            }
        }
        else {
            isChasing = false;
            if(velocity.x > 0) {
                velocity.x = IDLE_SPEED;
            }
            else {
                velocity.x = -IDLE_SPEED;
            }
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
            if(isChasing) {
                velocity.x = 0;
            }
            else {
                velocity.x = -velocity.x;
            }
        }

        moveBy(velocity.x * Main.getDelta(), 0, ["walls", "enemy"]);
        animation();

        if(isChasing) {
            if(!chaseSfx.playing && !soundsStopped) {
                chaseSfx.loop();
            }
            chaseSfx.volume = (1 - Math.min(
                distanceFrom(player, true), SFX_DISTANCE
            ) / SFX_DISTANCE) / 2;
            idleSfx.stop();
        }
        else {
            if(!idleSfx.playing && !soundsStopped) {
                idleSfx.loop();
            }
            idleSfx.volume = (1 - Math.min(
                distanceFrom(player, true), SFX_DISTANCE
            ) / SFX_DISTANCE) / 4;
            chaseSfx.stop();
        }

        super.update();
    }

    override public function stopSound() {
        idleSfx.stop();
        chaseSfx.stop();
        soundsStopped = true;
    }

    private function makeDustOnGround() {
        var dust:Dust;
        dust = new Dust(centerX, bottom, "slide");
        scene.add(dust);
    }

    private function animation() {
        if(velocity.x < 0) {
            sprite.flipX = false;
            lightning.flipX = false;
            eye.flipX = false;
        }
        else if(velocity.x > 0) {
            sprite.flipX = true;
            lightning.flipX = true;
            eye.flipX = true;
        }

        if(isChasing) {
            sprite.play("chasing");
            makeDustOnGround();
        }
        else {
            sprite.play("idle");
        }
        eye.visible = isChasing;
        lightning.visible = stopFlasher.active;
    }

    public override function moveCollideX(e:Entity) {
        if(isChasing) {
            velocity.x = 0;
        }
        else {
            velocity.x = -velocity.x;
        }
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}
