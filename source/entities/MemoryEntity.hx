package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class MemoryEntity extends Entity {
    private var anchor:Entity;
    private var anchorPosition:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        anchor = null;
        anchorPosition = new Vector2();
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

