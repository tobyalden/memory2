package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;

class MainScene extends Scene {
    private var map:Grid;

	override public function begin() {
        loadMap(1);
        placeSegments();
	}

    private function loadMap(mapNumber:Int) {
        var mapPath = 'maps/${mapNumber}.oel';
        var xml = Xml.parse(Assets.getText(mapPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());

        var mapWidth = Std.parseInt(fastXml.node.width.innerData);
        var mapHeight = Std.parseInt(fastXml.node.height.innerData);

        map = new Grid(
            mapWidth, mapHeight, Segment.TILE_SIZE, Segment.TILE_SIZE
        );
        for (r in fastXml.node.walls.nodes.rect) {
            map.setRect(
                Std.int(Std.parseInt(r.att.x) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Segment.TILE_SIZE)
            );
        }
    }

    private function placeSegments() {
        for(tileX in 0...map.columns) {
            for(tileY in 0...map.rows) {
                if(map.getTile(tileX, tileY)) {
                    add(new Segment(
                        tileX * Segment.MIN_SEGMENT_WIDTH,
                        tileY * Segment.MIN_SEGMENT_HEIGHT
                    ));
                }
            }
        }
    }

}
