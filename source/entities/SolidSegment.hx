package entities;

import haxepunk.*;
import haxepunk.masks.*;

class SolidSegment extends Segment {
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "walls";
        updateGraphic();
        mask = walls;
    }

    override private function loadSegment(_:Int) {
        walls = new Grid(
            Segment.MIN_SEGMENT_WIDTH, Segment.MIN_SEGMENT_HEIGHT,
            Segment.TILE_SIZE, Segment.TILE_SIZE
        );
        walls.setRect(0, 0, walls.columns, walls.rows);
    }
}
