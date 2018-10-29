package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Bouncer extends MemoryEntity {
    public static inline var MAX_SPEED = 2;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var HUM_DISTANCE = 280;
    public static inline var SPARK_TIME = 0.4;
    public static inline var TIME_BETWEEN_SPARKS = 1;

    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var hum:Sfx;
    private var soundsStopped:Bool;
    private var sparker:Alarm;
    private var stopSparker:Alarm;
    private var isSparking:Bool;
    private var bounceSfx:Sfx;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("hit", [4]);
        sprite.play("hit");
        lightning = new Spritemap("graphics/follower.png", 24, 24);
        lightning.add("idle", [5, 6, 7], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        velocity = new Vector2(
            Random.random < 0.5 ? MAX_SPEED : -MAX_SPEED,
            Random.random < 0.5 ? MAX_SPEED : -MAX_SPEED
        );
        setHitbox(23, 23, -1, -1);
        hum = new Sfx("audio/bouncer.wav");
        hum.volume = 0;
        soundsStopped = false;
        isSparking = false;
        sparker = new Alarm(Random.random, TweenType.Persist);
        sparker.onComplete.bind(function() {
            isSparking = !isSparking;
            if(isSparking) {
                sparker.reset(SPARK_TIME * Math.random());
                MemoryEntity.allSfx['robothit${HXP.choose(1, 2, 3)}'].play(
                    hum.volume
                );
            }
            else {
                sparker.reset(TIME_BETWEEN_SPARKS * Math.random());
            }
        });
        addTween(sparker, true);
        bounceSfx = new Sfx("audio/bounce.wav");
        health = 2;
    }

    override public function stopSound() {
        hum.stop();
        soundsStopped = true;
    }

    override public function update() {
        var player = scene.getInstance("player");
        if(!hum.playing && !soundsStopped) {
            hum.loop();
        }
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls", "enemy"]
        );
        animation();

        hum.volume = 1 - Math.min(
            distanceFrom(player, true), HUM_DISTANCE
        ) / HUM_DISTANCE;

        super.update();
    }

    private function animation() {
        var player = scene.getInstance("player");
        sprite.flipX = velocity.x > 0;
        lightning.visible = stopFlasher.active || isSparking;
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        bounceSfx.play(Math.min(hum.volume * 2, 1));
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y;
        bounceSfx.play(Math.min(hum.volume * 2, 1));
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}

