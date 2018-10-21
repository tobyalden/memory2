package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;

class MainScene extends Scene {
    public static inline var CAMERA_FOLLOW_SPEED = 3.5;

    private var mapBlueprint:Grid;
    private var map:Grid;
    private var player:Player;

	override public function begin() {
        loadMap(1);
        placeSegments();
        fillEmptySegments();
        player = new Player(100, 100);
        add(player);
        add(new Follower(300, 100));
        camera.pixelSnapping = true;
    }

    private function loadMap(mapNumber:Int) {
        var mapPath = 'maps/${mapNumber}.oel';
        var xml = Xml.parse(Assets.getText(mapPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());

        var mapWidth = Std.parseInt(fastXml.node.width.innerData);
        var mapHeight = Std.parseInt(fastXml.node.height.innerData);

        mapBlueprint = new Grid(
            mapWidth, mapHeight, Segment.TILE_SIZE, Segment.TILE_SIZE
        );
        map = new Grid(
            mapWidth, mapHeight, Segment.TILE_SIZE, Segment.TILE_SIZE
        );
        for (r in fastXml.node.walls.nodes.rect) {
            mapBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Segment.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Segment.TILE_SIZE)
            );
        }
    }

    private function placeSegments() {
        for(tileX in 0...mapBlueprint.columns) {
            for(tileY in 0...mapBlueprint.rows) {
                if(
                    mapBlueprint.getTile(tileX, tileY)
                    && !map.getTile(tileX, tileY)
                ) {
                    var canPlace = false;
                    while(!canPlace) {
                        var segment = new Segment(
                            tileX * Segment.MIN_SEGMENT_WIDTH,
                            tileY * Segment.MIN_SEGMENT_HEIGHT
                        );
                        var segmentWidth = Std.int(
                            segment.width / Segment.MIN_SEGMENT_WIDTH
                        );
                        var segmentHeight = Std.int(
                            segment.height / Segment.MIN_SEGMENT_HEIGHT
                        );
                        canPlace = true;
                        for(checkX in 0...segmentWidth) {
                            for(checkY in 0...segmentHeight) {
                                if(
                                    map.getTile(
                                        tileX + checkX, tileY + checkY
                                    )
                                    || !mapBlueprint.getTile(
                                        tileX + checkX, tileY + checkY
                                    )
                                ) {
                                    canPlace = false;
                                }
                            }
                        }
                        if(canPlace) {
                            for(checkX in 0...segmentWidth) {
                                for(checkY in 0...segmentHeight) {
                                    map.setTile(
                                        tileX + checkX, tileY + checkY
                                    );
                                    sealSegment(
                                        segment, tileX, tileY, checkX, checkY
                                    );
                                }
                            }
                            segment.updateGraphic();
                            add(segment);
                        }
                    }
                }
            }
        }
    }

    private function fillEmptySegments() {
        for(tileX in -1...mapBlueprint.columns + 1) {
            for(tileY in -1...mapBlueprint.rows + 1) {
                if(!map.getTile(tileX, tileY)) {
                    var segment = new SolidSegment(
                        tileX * Segment.MIN_SEGMENT_WIDTH,
                        tileY * Segment.MIN_SEGMENT_HEIGHT
                    );
                    add(segment);
                }
            }
        }
    }
    private function sealSegment(
        segment:Segment, tileX:Int, tileY:Int, checkX:Int, checkY:Int
    ) {
        if(!mapBlueprint.getTile(tileX + checkX - 1, tileY + checkY)) {
            segment.fillLeft(checkY);
        }
        if(!mapBlueprint.getTile(tileX + checkX + 1, tileY + checkY)) {
            segment.fillRight(checkY);
        }
        if(!mapBlueprint.getTile(tileX + checkX, tileY + checkY - 1)) {
            segment.fillTop(checkX);
        }
        if(!mapBlueprint.getTile(tileX + checkX, tileY + checkY + 1)) {
            segment.fillBottom(checkX);
        }
    }

    override public function update() {
        if(Key.pressed(Key.R)) {
            HXP.scene = new MainScene();
        }
        super.update();
        camera.x = Math.floor(player.x - HXP.width/2);
        camera.y = Math.floor(player.y - HXP.height/2);
    }
}
