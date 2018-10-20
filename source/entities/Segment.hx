package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.*;

class Segment extends MemoryEntity {
    public static inline var NUMBER_OF_SEGMENTS = 4;
    public static inline var MIN_SEGMENT_WIDTH = 640;
    public static inline var MIN_SEGMENT_HEIGHT = 352;
    public static inline var MIN_SEGMENT_WIDTH_IN_TILES = 40;
    public static inline var MIN_SEGMENT_HEIGHT_IN_TILES = 22;
    public static inline var TILE_SIZE = 16;

    private var walls:Grid;
    private var tiles:Tilemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "walls";
        loadSegment(Random.randInt(NUMBER_OF_SEGMENTS));
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
        //if(fastXml.hasNode.optionalWalls) {
            //for (r in fastXml.node.optionalWalls.nodes.rect) {
                //if(Random.random < 0.5) {
                    //continue;
                //}
                //walls.setRect(
                    //Std.int(Std.parseInt(r.att.x) / TILE_SIZE),
                    //Std.int(Std.parseInt(r.att.y) / TILE_SIZE),
                    //Std.int(Std.parseInt(r.att.w) / TILE_SIZE),
                    //Std.int(Std.parseInt(r.att.h) / TILE_SIZE)
                //);
            //}
        //}
    }

    public function makeSolid1x1() {
        walls = new Grid(
            MIN_SEGMENT_WIDTH, MIN_SEGMENT_HEIGHT, TILE_SIZE, TILE_SIZE
        );
        walls.setRect(0, 0, walls.columns, walls.rows);
        updateGraphic();
    }

    public function fillLeft(offsetY:Int) {
        for(tileY in 0...MIN_SEGMENT_HEIGHT_IN_TILES) {
            walls.setTile(0, tileY + offsetY * MIN_SEGMENT_HEIGHT_IN_TILES);
        }
    }

    public function fillRight(offsetY:Int) {
        for(tileY in 0...MIN_SEGMENT_HEIGHT_IN_TILES) {
            walls.setTile(
                walls.columns - 1,
                tileY + offsetY * MIN_SEGMENT_HEIGHT_IN_TILES);
        }
    }

    public function fillTop(offsetX:Int) {
        for(tileX in 0...MIN_SEGMENT_WIDTH_IN_TILES) {
            walls.setTile(tileX + offsetX * MIN_SEGMENT_WIDTH_IN_TILES, 0);
        }
    }

    public function fillBottom(offsetX:Int) {
        for(tileX in 0...MIN_SEGMENT_WIDTH_IN_TILES) {
            walls.setTile(
                tileX + offsetX * MIN_SEGMENT_WIDTH_IN_TILES,
                walls.rows - 1
            );
        }
    }

    public function updateGraphic() {
        tiles = new Tilemap(
            'graphics/tiles.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        tiles.loadFromString(walls.saveToString(',', '\n', '1', '0'));
        setGraphic(tiles);
    }

}
