package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class MissileTurret extends MemoryEntity {
    public static inline var TIME_BETWEEN_LOBS = 1;
    public static inline var LOB_ANTICIPATION = 0.25;

    private var sprite:Spritemap;
    private var eyes:Spritemap;
    private var lightning:Spritemap;
    private var lobTimer:Alarm;
    private var lobSfx:Sfx;
    private var prepareSfx:Sfx;
    private var isAncipatingLob:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/missileturret.png", 24, 16);
        sprite.add("idle", [0]);
        sprite.add("idleprepare", [1]);
        sprite.add("left", [2]);
        sprite.add("leftprepare", [3]);
        sprite.add("right", [4]);
        sprite.add("rightprepare", [5]);
        sprite.play("idle");
        lightning = new Spritemap("graphics/missileturret.png", 24, 16);
        lightning.add("idle", [6, 7], 24);
        lightning.play("idle");
        lightning.visible = false;
        eyes = new Spritemap("graphics/missileturret.png", 24, 16);
        eyes.add("idle", [8]);
        eyes.add("evil", [9]);
        eyes.play("idle");
        setGraphic(sprite);
        addGraphic(eyes);
        addGraphic(lightning);
        setHitbox(24, 16);
        health = 1;
        lobTimer = new Alarm(TIME_BETWEEN_LOBS, TweenType.Looping);
        lobTimer.onComplete.bind(function() {
            var player = scene.getInstance("player");
            if(
                !isOnScreen()
                || scene.getInstance(getTag()) != null
                || centerY > player.centerY
                || (
                    scene.collideLine(
                        "walls",
                        Std.int(centerX),
                        Std.int(centerY),
                        Std.int(player.centerX),
                        Std.int(player.centerY)
                    ) != null
                    && scene.collideLine(
                        "walls",
                        Std.int(centerX),
                        Std.int(centerY),
                        Std.int(player.centerX),
                        Std.int(player.centerY - 100)
                    ) != null
                    && scene.collideLine(
                        "walls",
                        Std.int(centerX),
                        Std.int(centerY),
                        Std.int(player.centerX + 100),
                        Std.int(player.centerY - 100)
                    ) != null
                    && scene.collideLine(
                        "walls",
                        Std.int(centerX),
                        Std.int(centerY),
                        Std.int(player.centerX - 100),
                        Std.int(player.centerY - 100)
                    ) != null
                )
            ) {
                return;
            }
            isAncipatingLob = true;
            prepareSfx.play();
            var preLob = new Alarm(LOB_ANTICIPATION, TweenType.OneShot);
            preLob.onComplete.bind(function() {
                lob();
            });
            addTween(preLob, true);
        });
        addTween(lobTimer);
        var lobTimerDelay = new Alarm(
            Math.random() * TIME_BETWEEN_LOBS, TweenType.OneShot
        );
        lobTimerDelay.onComplete.bind(function() {
            lobTimer.start();
        });
        addTween(lobTimerDelay, true);
        lobSfx = new Sfx("audio/turretshoot.wav");
        prepareSfx = new Sfx("audio/turretprepare.wav");
    }

    public function getTag() {
        return '${x}-${y}';
    }

    private function lob() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(0, 0);
        //towardsPlayer.x = LOB_POWER;
        //if(centerX > player.centerX) {
            //towardsPlayer.x = -LOB_POWER;
        //}
        //towardsPlayer.y = -LOB_POWER/2;
        var missile = new Missile(centerX - 4, bottom, towardsPlayer, getTag());
        //if(towardsPlayer.x > 0) {
            //grenade.x -= grenade.width/2;
        //}
        //else {
            //grenade.x -= grenade.width + grenade.width/2;
        //}
        scene.add(missile);
        lobSfx.play();
        isAncipatingLob = false;
    }

    override public function update() {
        animation();
        super.update();
    }

    private function animation() {
        lightning.visible = stopFlasher.active;
        var player = scene.getInstance("player");
        //if(x > player.x) {
            //sprite.play(isAncipatingLob ? "leftprepare" : "left");
        //}
        //else {
            sprite.play(isAncipatingLob ? "idleprepare" : "idle");
        //}
    }
}

