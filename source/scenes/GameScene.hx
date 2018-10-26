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
import scenes.*;

class GameScene extends Scene {
    public static inline var CAMERA_FOLLOW_SPEED = 3.5;
    public static inline var STARTING_NUMBER_OF_ENEMIES = 20;
    public static inline var MIN_ENEMY_DISTANCE = 350;

    private var mapBlueprint:Grid;
    private var map:Grid;
    private var player:Player;
    private var curtain:Curtain;
    private var allSegments:Array<Segment>;

	override public function begin() {
        loadMap(1);
        allSegments = new Array<Segment>();
        placeSegments();
        fillEmptySegments();

        addPlayer();
        addKeyAndDoor();
        addEnemies();

        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();
        camera.pixelSnapping = true;
    }

    public function onDeath() {
        curtain.fadeOut();
        var resetTimer = new Alarm(1.5, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            HXP.scene = new MainMenu();
        });
        addTween(resetTimer, true);
    }

    public function descend() {
        curtain.fadeOut();
        var resetTimer = new Alarm(1.5, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            HXP.scene = new GameScene();
        });
        addTween(resetTimer, true);
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

    private function addPlayer() {
        var playerStart = getRandomOpenGroundPoint();
        player = new Player(playerStart.x, playerStart.y);
        player.y += Segment.TILE_SIZE - player.height;
        add(player);
    }

    private function addKeyAndDoor() {
        var keyPoint = getRandomOpenGroundPoint();
        var doorPoint = getRandomOpenGroundPoint();
        var playerPoint = new Vector2(player.x, player.y);
        for (i in 0...500) {
            var newKeyPoint = getRandomOpenGroundPoint();
            var newDoorPoint = getRandomOpenGroundPoint();
            if(
                newKeyPoint.distance(newDoorPoint) > keyPoint.distance(doorPoint)
                && newKeyPoint.distance(playerPoint) > keyPoint.distance(playerPoint)
                && newDoorPoint.distance(playerPoint) > doorPoint.distance(playerPoint)
            ) {
                keyPoint = newKeyPoint;
                doorPoint = newDoorPoint;
            }
        }
        var key = new DoorKey(keyPoint.x, keyPoint.y);
        key.y -= Segment.TILE_SIZE;
        var door = new Door(doorPoint.x, doorPoint.y);
        door.y += Segment.TILE_SIZE - door.height;
        add(key);
        add(door);
    }

    private function addEnemies() {
        var numberOfEnemies = STARTING_NUMBER_OF_ENEMIES;
        var playerPoint = new Vector2(player.x, player.y);
        var enemyPoints = new Array<Vector2>();
        var groundEnemyPoints = new Array<Vector2>();
        for(i in 0...numberOfEnemies) {
            var isGroundEnemy = Random.random < 0.5;
            if(isGroundEnemy) {
                var enemyPoint = getRandomOpenGroundPoint();
                while(enemyPoint.distance(playerPoint) < MIN_ENEMY_DISTANCE) {
                    enemyPoint = getRandomOpenGroundPoint();
                }
                groundEnemyPoints.push(enemyPoint);
            }
            else {
                var enemyPoint = getRandomOpenPoint();
                while(enemyPoint.distance(playerPoint) < MIN_ENEMY_DISTANCE) {
                    enemyPoint = getRandomOpenPoint();
                }
                enemyPoints.push(enemyPoint);
            }
        }
        for(enemyPoint in enemyPoints) {
            add(new Follower(enemyPoint.x, enemyPoint.y));
        }
        for(enemyPoint in groundEnemyPoints) {
            var enemy = new Roombad(enemyPoint.x, enemyPoint.y);
            enemy.y += Segment.TILE_SIZE - enemy.height;
            add(enemy);
        }
    }

    private function getWeightedSegments() {
        var weightedSegments = new Array<Segment>();
        for(segment in allSegments) {
            var weightX = Std.int(segment.width / Segment.MIN_SEGMENT_WIDTH);
            var weightY = Std.int(segment.height / Segment.MIN_SEGMENT_HEIGHT);
            for(i in 0...weightX) {
                for(j in 0...weightY) {
                    weightedSegments.push(segment);
                }
            }
        }
        return weightedSegments;
    }

    private function getRandomOpenPoint() {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenTile();
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenTile();
        }
        return new Vector2(
            segment.x + randomTile.tileX * Segment.TILE_SIZE,
            segment.y + randomTile.tileY * Segment.TILE_SIZE
        );
    }

    private function getRandomOpenGroundPoint() {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenGroundTile();
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenGroundTile();
        }
        return new Vector2(
            segment.x + randomTile.tileX * Segment.TILE_SIZE,
            segment.y + randomTile.tileY * Segment.TILE_SIZE
        );
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
                            allSegments.push(segment);
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
                    allSegments.push(segment);
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
            HXP.scene = new GameScene();
        }
        if(curtain.graphic.alpha > 0.95) {
            camera.x = Math.floor(player.x - HXP.width/2);
            camera.y = Math.floor(player.y - HXP.height/2);
        }
        super.update();

        for(sfxName in MemoryEntity.sfxQueue) {
            if(MemoryEntity.allSfx.exists(sfxName)) {
                MemoryEntity.allSfx[sfxName].play();
            }
        }

        MemoryEntity.clearSfxQueue();
        if(curtain.graphic.alpha <= 0.95 && player.visible) {
            // This screwy code duplication is because of a weird issue
            // where setting the camera before super.update() causes
            // jitter, but setting it after screws up the fade in
            camera.x = Math.floor(player.x - HXP.width/2);
            camera.y = Math.floor(player.y - HXP.height/2);
        }
    }
}
