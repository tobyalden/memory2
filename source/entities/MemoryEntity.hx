package entities;

import haxepunk.*;
import haxepunk.graphics.*;

class MemoryEntity extends Entity
{
    public function new(x:Float, y:Float) {
        super(x, y);
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
        super.update();
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

