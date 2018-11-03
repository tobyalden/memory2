package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Mine extends MemoryEntity {
    public static inline var WARN_DISTANCE = 150;
    public static inline var DETONATE_DISTANCE = 50;
    public static inline var DETONATE_DELAY = 0.5;

    private var sprite:Spritemap;
    private var warnSfx:Sfx;
    private var predetonateSfx:Sfx;
    private var detonateSfx:Sfx;
    private var detonateTimer:Alarm;
    private var prevDistanceFromPlayer:Float;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "mine";
        sprite = new Spritemap("graphics/mine.png", 12, 12);
        sprite.add("idle", [0]);
        sprite.add("warn", [1]);
        sprite.add("detonate", [2]);
        sprite.play("idle");
        setGraphic(sprite);
        setHitbox(12, 12);
        warnSfx = new Sfx("audio/warn.wav");
        predetonateSfx = new Sfx("audio/predetonate.wav");
        detonateSfx = new Sfx("audio/grenadeexplode.wav");
        detonateTimer = new Alarm(DETONATE_DELAY, TweenType.OneShot);
        detonateTimer.onComplete.bind(function() {
            detonate();
        });
        addTween(detonateTimer);
        prevDistanceFromPlayer = 1000000;
    }

    override public function update() {
        var player = scene.getInstance("player");
        var playerDistance = distanceFrom(player, true);
        if(
            distanceFrom(player, true) < DETONATE_DISTANCE
            && !detonateTimer.active
        ) {
            detonateTimer.start();
            predetonateSfx.play();
        }

        if(detonateTimer.active) {
            sprite.play("detonate");
        }
        else if(playerDistance < WARN_DISTANCE) {
            sprite.play("warn");
            if(prevDistanceFromPlayer > WARN_DISTANCE) {
                warnSfx.play();
            }
        }
        else {
            sprite.play("idle");
        }

        prevDistanceFromPlayer = playerDistance;

        super.update();
    }

    public function detonate(makeSound:Bool = true) {
        scene.remove(this);
        scene.add(new Explosion(centerX - 72, centerY - 72));
        if(makeSound) {
            detonateSfx.play();
#if desktop
            Sys.sleep(0.02);
#end
        }
    }

    override public function takeHit(arrow:Arrow) {
        if(arrow.isScattered) {
            detonate(false);
        }
        else {
            MemoryEntity.allSfx['robothit${HXP.choose(1, 2, 3)}'].play();
            detonate();
        }
    }
}

