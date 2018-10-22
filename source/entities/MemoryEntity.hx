package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class MemoryEntity extends Entity {
    private var anchor:Entity;
    private var anchorPosition:Vector2;
    private var isFlashing:Bool;
    private var flasher:Alarm;
    private var stopFlasher:Alarm;

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

