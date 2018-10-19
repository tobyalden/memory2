package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.*;

class Segment extends Entity {
    public static inline var MIN_SEGMENT_WIDTH = 640;
    public static inline var MIN_SEGMENT_HEIGHT = 352;
    public static inline var TILE_SIZE = 16;

    private var walls:Grid;
    private var tiles:Tilemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        loadSegment(1);
        updateGraphic();
        mask = walls;
    }

    private function loadSegment(segmentNumber:Int) {
        var segmentPath = 'segments/${segmentNumber}.oel';
        var xml = Xml.parse(Assets.getText(segmentPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());

        var segmentWidth = Std.parseInt(fastXml.node.width.innerData);
        var segmentHeight = Std.parseInt(fastXml.node.height.innerData);

        walls = new Grid(segmentWidth, segmentHeight, TILE_SIZE, TILE_SIZE);
        for (r in fastXml.node.walls.nodes.rect) {
            walls.setRect(
                Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
            );
        }
        for (r in fastXml.node.optionalWalls.nodes.rect) {
            if(Random.random < 0.5) {
                continue;
            }
            walls.setRect(
                Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
            );
        }
    }

    private function updateGraphic() {
        tiles = new Tilemap(
            'graphics/tiles.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        tiles.loadFromString(walls.saveToString(',', '\n', '1', '0'));
        graphic = tiles;
    }

    override public function update() {
        if(Key.pressed(Key.R)) {
            loadSegment(1);
        }
        if(Key.pressed(Key.ANY)) {
            updateGraphic();
        }
    }
}
