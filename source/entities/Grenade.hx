package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Grenade extends MemoryEntity {
    public static inline var ACCEL = 0.05;
    public static inline var BOUNCE_FACTOR = 0.75;
    public static inline var GRAVITY = 0.2;
    public static inline var MAX_FALL_VELOCITY = 6;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var explodeTimer:Alarm;
    private var bounceSfxs:Array<Sfx>;
    private var explodeSfx:Sfx;
    private var warnSfx:Sfx;
    private var colorTween:ColorTween;

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
        explodeTimer = new Alarm(1, TweenType.OneShot);
        explodeTimer.onComplete.bind(function() {
            scene.remove(this);
            scene.add(new Explosion(centerX - 72, centerY - 72));
            explodeSfx.play();
        });
        addTween(explodeTimer, true);
        bounceSfxs = new Array<Sfx>();
        bounceSfxs.push(new Sfx("audio/grenadebounce1.wav"));
        bounceSfxs.push(new Sfx("audio/grenadebounce2.wav"));
        bounceSfxs.push(new Sfx("audio/grenadebounce3.wav"));
        explodeSfx = new Sfx("audio/grenadeexplode.wav");
        warnSfx = new Sfx("audio/grenadewarn.wav");
        warnSfx.play();
        colorTween = new ColorTween(TweenType.OneShot);
        colorTween.tween(1, 0xFF0000, 0xffff89, 1, 1, Ease.sineIn);
        addTween(colorTween, true);
    }

    override public function update() {
        var player = scene.getInstance("player");
        var gravity = GRAVITY * Main.getDelta();
        velocity.y += gravity;
        velocity.y = Math.min(velocity.y, MAX_FALL_VELOCITY);
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(), "walls"
        );
        sprite.color = colorTween.color;
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x * BOUNCE_FACTOR;
        var player = scene.getInstance("player");
        var volume = (Math.max(1, distanceFrom(player, true)) / 350);
        bounceSfxs[Std.random(bounceSfxs.length)].play();
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y * BOUNCE_FACTOR;
        bounceSfxs[Std.random(bounceSfxs.length)].play();
        return true;
    }
}
