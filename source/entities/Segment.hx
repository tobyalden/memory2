package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.*;

typedef OpenPoint = {
    var tileX:Int;
    var tileY:Int;
}

class Segment extends MemoryEntity {
    public static inline var NUMBER_OF_SEGMENTS = 12;
    public static inline var MIN_SEGMENT_WIDTH = 640;
    public static inline var MIN_SEGMENT_HEIGHT = 352;
    public static inline var MIN_SEGMENT_WIDTH_IN_TILES = 40;
    public static inline var MIN_SEGMENT_HEIGHT_IN_TILES = 22;
    public static inline var TILE_SIZE = 16;

    public var walls(default, null):Grid;
    public var number(default, null):Int;
    private var tiles:Tilemap;
    private var edges:Tilemap;
    private var openPoints:Array<OpenPoint>;
    private var openGroundPoints:Array<OpenPoint>;
    private var openLeftWallPoints:Array<OpenPoint>;
    private var openRightWallPoints:Array<OpenPoint>;

    public function new(x:Float, y:Float, isBossSegment:Bool = false) {
        super(x, y);
        type = "walls";
        if(isBossSegment) {
            number = 666;
        }
        else {
            number = Random.randInt(NUMBER_OF_SEGMENTS);
        }
        loadSegment(number);
        if(Random.random < 0.5) {
            flipHorizontally();
        }
        updateGraphic();
        mask = walls;
        findOpenPoints();
    }

    public function flipHorizontally() {
        for(tileX in 0...Std.int(walls.columns / 2)) {
            for(tileY in 0...walls.rows) {
                var tempLeft:Bool = walls.getTile(tileX, tileY);
                // For some reason getTile() returns null instead of false!
                if(tempLeft == null) {
                    tempLeft = false;
                }
                var tempRight:Bool = walls.getTile(
                    walls.columns - tileX - 1, tileY
                );
                if(tempRight == null) {
                    tempRight = false;
                }
                walls.setTile(tileX, tileY, tempRight);
                walls.setTile(walls.columns - tileX - 1, tileY, tempLeft);
            }
        }
    }

    private function findOpenPoints() {
        openPoints = new Array<OpenPoint>();
        openGroundPoints = new Array<OpenPoint>();
        openLeftWallPoints = new Array<OpenPoint>();
        openRightWallPoints = new Array<OpenPoint>();
        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(
                    !walls.getTile(tileX, tileY)
                    && walls.getTile(tileX, tileY + 1)
                ) {
                    openGroundPoints.push({tileX: tileX, tileY: tileY});
                }
                else if(
                    !walls.getTile(tileX, tileY)
                    && walls.getTile(tileX - 1, tileY)
                ) {
                    openLeftWallPoints.push({tileX: tileX, tileY: tileY});
                }
                else if(
                    !walls.getTile(tileX, tileY)
                    && walls.getTile(tileX + 1, tileY)
                ) {
                    openRightWallPoints.push({tileX: tileX, tileY: tileY});
                }
                else if(!walls.getTile(tileX, tileY)) {
                    openPoints.push({tileX: tileX, tileY: tileY});
                }
            }
        }
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
        if(fastXml.hasNode.optionalWalls) {
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
    }

    public function getRandomOpenTile() {
        var randomTile:OpenPoint = openPoints[
            Random.randInt(openPoints.length)
        ];
        for(checkX in -1...2) {
            for(checkY in -1...2) {
                if(walls.getTile(
                    randomTile.tileX + checkX, randomTile.tileY + checkY
                )) {
                    return null;
                }
            }
        }
        return {tileX: randomTile.tileX, tileY: randomTile.tileY};
    }

    public function getRandomOpenLeftWallTile() {
        var randomTile:OpenPoint = openLeftWallPoints[
            Random.randInt(openLeftWallPoints.length)
        ];
        for(checkY in -1...2) {
            if(walls.getTile(randomTile.tileX, randomTile.tileY + checkY)) {
                return null;
            }
            if(!walls.getTile(randomTile.tileX - 1, randomTile.tileY + checkY)) {
                return null;
            }
        }
        return {tileX: randomTile.tileX, tileY: randomTile.tileY};
    }

    public function getRandomOpenRightWallTile() {
        var randomTile:OpenPoint = openRightWallPoints[
            Random.randInt(openRightWallPoints.length)
        ];
        for(checkY in -1...2) {
            if(walls.getTile(randomTile.tileX, randomTile.tileY + checkY)) {
                return null;
            }
            if(!walls.getTile(randomTile.tileX + 1, randomTile.tileY + checkY)) {
                return null;
            }
        }
        return {tileX: randomTile.tileX, tileY: randomTile.tileY};
    }

    public function getRandomOpenGroundTile(extraSpace:Int = 0) {
        var randomTile:OpenPoint = openGroundPoints[
            Random.randInt(openGroundPoints.length)
        ];
        for(checkX in -(1 - extraSpace)...(2 + extraSpace)) {
            for(checkY in -2...1) {
                if(
                    walls.getTile(randomTile.tileX + checkX, randomTile.tileY + checkY)
                ) {
                    return null;
                }
            }
        }
        for(checkX in (-1 - extraSpace)...(2 + extraSpace)) {
            if(!walls.getTile(randomTile.tileX + checkX, randomTile.tileY + 1)) {
                return null;
            }
        }
        return {tileX: randomTile.tileX, tileY: randomTile.tileY};
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
        var tilesetName = 'tiles${GameScene.getDepthBlock()}';
        if(GameScene.depth == 7) {
            tilesetName = "bosstiles";
        }
        tiles = new Tilemap(
            'graphics/${tilesetName}.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        tiles.loadFromString(walls.saveToString(',', '\n', '1', '0'));
        setGraphic(tiles);
        edges = new Tilemap(
            'graphics/${tilesetName}.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(!walls.getTile(tileX, tileY)) {
                    continue;
                }
                var hasLeftEdge = (
                    tileX > 0 && !walls.getTile(tileX - 1, tileY)
                );
                var hasRightEdge = (
                    tileX < walls.columns - 1
                    && !walls.getTile(tileX + 1, tileY)
                );
                var hasTopEdge = (
                    tileY > 0 && !walls.getTile(tileX, tileY - 1)
                );
                var hasBottomEdge = (
                    tileY < walls.rows - 1
                    && !walls.getTile(tileX, tileY + 1)
                );
                if(
                    hasTopEdge && hasBottomEdge
                    && hasLeftEdge && hasRightEdge
                ) {
                    edges.setTile(tileX, tileY, 9);
                }
                else if(hasTopEdge && hasBottomEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 13);
                }
                else if(hasBottomEdge && hasLeftEdge && hasTopEdge) {
                    edges.setTile(tileX, tileY, 14);
                }
                else if(hasBottomEdge && hasLeftEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 15);
                }
                else if(hasTopEdge && hasLeftEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 16);
                }
                else if(hasTopEdge && hasBottomEdge) {
                    edges.setTile(tileX, tileY, 4);
                }
                else if(hasLeftEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 12);
                }
                else if(hasTopEdge && hasLeftEdge) {
                    edges.setTile(tileX, tileY, 5);
                }
                else if(hasTopEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 6);
                }
                else if(hasBottomEdge && hasLeftEdge) {
                    edges.setTile(tileX, tileY, 7);
                }
                else if(hasBottomEdge && hasRightEdge) {
                    edges.setTile(tileX, tileY, 8);
                }
                else if(hasTopEdge) {
                    edges.setTile(tileX, tileY, 2);
                }
                else if(hasBottomEdge) {
                    edges.setTile(tileX, tileY, 3);
                }
                else if(hasLeftEdge) {
                    edges.setTile(tileX, tileY, 10);
                }
                else if(hasRightEdge) {
                    edges.setTile(tileX, tileY, 11);
                }
            }
        }
        addGraphic(edges);
    }
}
