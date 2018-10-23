package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class MemoryEntity extends Entity {
    private var anchor(default, null):Entity;
    private var anchorPosition:Vector2;
    private var isFlashing:Bool;
    private var flasher:Alarm;
    private var stopFlasher:Alarm;
    private var health:Int;

    static public var sfxQueue(default, null):Array<String> = (
        new Array<String>()
    );
    static public var allSfx(default, null):Map<String, Sfx> = (
        new Map<String, Sfx>()
    );

    static public function loadSfx(sfxNames:Array<String>) {
        for(sfxName in sfxNames) {
            allSfx[sfxName] = new Sfx('audio/${sfxName}.wav');
        }
    }

    static public function queueSfx(sfxName:String) {
        if(sfxQueue.indexOf(sfxName) == -1) {
            sfxQueue.push(sfxName);
        }
    }

    static public function clearSfxQueue() {
        for(sfxName in sfxQueue) {
            sfxQueue.remove(sfxName);
        }
    }

    public function new(x:Float, y:Float) {
        super(x, y);
        anchor = null;
        anchorPosition = new Vector2();

        isFlashing = false;
        flasher = new Alarm(0.05, TweenType.Looping);
        flasher.onComplete.bind(function() {
            if(isFlashing) {
                visible = !visible;
            }
        });
        addTween(flasher, true);

        stopFlasher = new Alarm(0.2, TweenType.Persist);
        stopFlasher.onComplete.bind(function() {
            visible = true;
            isFlashing = false;
        });
        addTween(stopFlasher, false);
        health = 3;
    }

    private function die() {
        scene.remove(this);
        var arrows = new Array<Entity>();
        scene.getType("arrow", arrows);
        for(_arrow in arrows) {
            var arrow = cast(_arrow, Arrow);
            if(arrow.anchor == this) {
                arrow.anchor = null;
                arrow.setLanded(false);
                arrow.setVelocity(
                    new Vector2(Math.random() * -5, Math.random() * -5)
                );
                arrow.collidable = true;
            }
        }
        explode();
#if desktop
        Sys.sleep(0.02);
#end
    }

    private function explode(numExplosions:Int = 15, speed:Float = 0.4) {
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2/numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(speed * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            var explosion = new DeathParticle(
                centerX, centerY, directions[count], true
            );
            explosion.layer = -99;
            scene.add(explosion);
            count++;
        }
    }

    public function setGraphic(newGraphic:Graphic) {
        newGraphic.smooth = false;
        newGraphic.pixelSnapping = true;
        graphic = newGraphic;
    }

    override public function addGraphic(newGraphic:Graphic) {
        newGraphic.smooth = false;
        newGraphic.pixelSnapping = true;
        super.addGraphic(newGraphic);
        return newGraphic;
    }

    public override function update() {
        updateAnchor();
        super.update();
    }

    public function takeHit(arrow:Arrow) {
        visible = false;
        isFlashing = true;
        stopFlasher.start();
        health -= 1;
        if(health <= 0) {
            die();
        }
    }

    public function updateAnchor() {
        if(anchor != null) {
            moveBy(anchor.x - anchorPosition.x, anchor.y - anchorPosition.y);
            anchorPosition = new Vector2(anchor.x, anchor.y);
        }
    }

    public function setAnchor(newAnchor:Entity) {
        anchor = newAnchor;
        anchorPosition = new Vector2(anchor.x, anchor.y);
    }

    private function isOnGround() {
        return collide("walls", x, y + 1) != null;
    }

    private function isOnCeiling() {
        return collide("walls", x, y - 1) != null;
    }

    private function isOnWall() {
        return isOnRightWall() || isOnLeftWall();
    }

    private function isOnRightWall() {
        return collide("walls", x + 1, y) != null;
    }

    private function isOnLeftWall() {
        return collide("walls", x - 1, y) != null;
    }
}

