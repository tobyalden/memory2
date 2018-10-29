package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Turret extends MemoryEntity {
    public static inline var TIME_BETWEEN_LOBS = 3;
    public static inline var LOB_POWER = 5;

    private var sprite:Spritemap;
    private var eyes:Spritemap;
    private var lightning:Spritemap;
    private var lobTimer:Alarm;
    private var lobSfx:Sfx;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/turret.png", 24, 16);
        sprite.add("idle", [1]);
        sprite.add("left", [3]);
        sprite.add("right", [5]);
        sprite.play("idle");
        lightning = new Spritemap("graphics/turret.png", 24, 16);
        lightning.add("idle", [6, 7], 24);
        lightning.play("idle");
        lightning.visible = false;
        eyes = new Spritemap("graphics/turret.png", 24, 16);
        eyes.add("idle", [8]);
        eyes.add("evil", [9]);
        eyes.play("idle");
        setGraphic(sprite);
        addGraphic(eyes);
        addGraphic(lightning);
        setHitbox(24, 16);
        health = 3;
        lobTimer = new Alarm(TIME_BETWEEN_LOBS, TweenType.Looping);
        lobTimer.onComplete.bind(function() {
            lob();
        });
        addTween(lobTimer);
        var lobTimerDelay = new Alarm(Math.random(), TweenType.OneShot);
        lobTimerDelay.onComplete.bind(function() {
            lobTimer.start();
        });
        addTween(lobTimerDelay, true);
        lobSfx = new Sfx("audio/turretshoot.wav");
    }

    private function lob() {
        var player = scene.getInstance("player");
        if(!isOnScreen()) {
            return;
        }
        var towardsPlayer = new Vector2(0, 0);
        towardsPlayer.x = LOB_POWER;
        if(x > player.x) {
            towardsPlayer.x = -LOB_POWER;
        }
        towardsPlayer.y = -LOB_POWER;
        var grenade = new Grenade(centerX, top, towardsPlayer);
        scene.add(grenade);
        lobSfx.play();
    }

    override public function update() {
        animation();
        super.update();
    }

    private function animation() {
        lightning.visible = stopFlasher.active;
        var player = scene.getInstance("player");
        if(x > player.x) {
            sprite.play("left");
        }
        else {
            sprite.play("right");
        }
    }
}
