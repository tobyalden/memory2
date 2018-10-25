package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Arrow extends MemoryEntity {
    public static inline var INITIAL_VELOCITY = 15;
    public static inline var INITIAL_LIFT = 0.1;
    public static inline var GRAVITY = 0.2;
    public static inline var DISAPPEAR_DELAY = 5;

    public var velocity(default, null):Vector2;
    public var landed(default, null):Bool;
    private var sprite:Image;
    private var isVertical:Bool;
    private var disappearTimer:Alarm;

    public function setLanded(newLanded:Bool, disappear:Bool = false) {
        landed = newLanded;
        if(landed && disappear) {
            disappearTimer.start();
        }
    }

    public function setVelocity(newVelocity:Vector2) {
        velocity = newVelocity;
    }

    public function new(x:Float, y:Float, direction:Vector2, isVertical:Bool) {
	    super(x, y);
        MemoryEntity.loadSfx(["arrowhit1", "arrowhit2", "arrowhit3"]);
        this.isVertical = isVertical;
        layer = 1;
        type = "arrow";
        velocity = direction;
        velocity.normalize(INITIAL_VELOCITY);
        sprite = new Image("graphics/arrow.png");
        sprite.centerOrigin();
        var angle = MathUtil.angle(0, 0, velocity.x, velocity.y);
        sprite.angle = angle;
        setGraphic(sprite);
        if(isVertical) {
            setHitbox(3, 16, 1, 8);
        }
        else {
            setHitbox(16, 3, 8, 1);
        }
        landed = false;
        disappearTimer = new Alarm(DISAPPEAR_DELAY, TweenType.OneShot);
        disappearTimer.onComplete.bind(function() {
            scene.remove(this);
        });
        addTween(disappearTimer);
    }

    public override function update() {
        if(!landed) {
            var gravity = GRAVITY * Main.getDelta();
            if(isVertical) {
                gravity *= 3;
            }
            velocity.y += gravity;
            var angle = MathUtil.angle(0, 0, velocity.x, velocity.y);
            sprite.angle = angle;
            moveBy(
                velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
                ["walls", "enemy"], true
            );
        }
        else {
            if(disappearTimer.percent > 0.5) {
                isFlashing = true;
            }
        }
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        if(e.type == "enemy") {
            setLanded(true, false);
            setAnchor(e);
            var towardsEnemy = new Vector2(
                e.centerX - centerX, e.centerY - centerY
            );
            towardsEnemy.normalize(4);
            x += towardsEnemy.x;
            y += towardsEnemy.y;
            collidable = false;
            cast(e, MemoryEntity).takeHit(this);
        }
        else {
            setLanded(true, true);
        }
        var hitVolume = Math.min(velocity.length / INITIAL_VELOCITY, 1);
        MemoryEntity.allSfx['arrowhit${HXP.choose(1, 2, 3)}'].play(hitVolume/3);
        return true;
    }

    public override function moveCollideY(e:Entity) {
        if(e.type == "enemy") {
            setLanded(true, false);
            setAnchor(e);
            var towardsEnemy = new Vector2(
                e.centerX - centerX, e.centerY - centerY
            );
            towardsEnemy.normalize(4);
            x += towardsEnemy.x;
            y += towardsEnemy.y;
            collidable = false;
            cast(e, MemoryEntity).takeHit(this);
        }
        else {
            setLanded(true, true);
        }
        var hitVolume = Math.min(velocity.length / INITIAL_VELOCITY, 1);
        MemoryEntity.allSfx['arrowhit${HXP.choose(1, 2, 3)}'].play(hitVolume/3);
        return true;
    }
}
