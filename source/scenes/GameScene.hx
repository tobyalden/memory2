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

typedef SegmentPoint = {
    var segment:Segment;
    var point:Vector2;
    var tileX:Int;
    var tileY:Int;
}

class GameScene extends Scene {
    public static inline var CAMERA_FOLLOW_SPEED = 3.5;
    public static inline var STARTING_NUMBER_OF_ENEMIES = 30;
    public static inline var MIN_ENEMY_DISTANCE_FROM_PLAYER = 350;
    public static inline var MIN_ENEMY_DISTANCE_FROM_EACHOTHER = 200;
    public static inline var MAX_CONSECUTIVE_SPIKES = 10;

    public var music(default, null):Sfx;
    private var mapBlueprint:Grid;
    private var map:Grid;
    private var player:Player;
    private var door:Door;
    private var key:DoorKey;
    private var curtain:Curtain;
    private var allSegments:Array<Segment>;

	override public function begin() {
        loadMap(1);

        addBackgrounds();
        placeSegments();
        fillEmptySegments();

        addPlayer();
        addKeyAndDoor();
        addEnemies();

        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();
        camera.pixelSnapping = true;

        music = new Sfx("audio/music.wav");
        //music.loop();
    }

    public function spawnRoboPlant() {
        add(new RoboPlant(
            player.x + (Random.random < 0.5 ? HXP.width/1.5 : -HXP.width/1.5),
            player.y + (Random.random < 0.5 ? HXP.height/1.5 : -HXP.height/1.5)
        ));
    }

    private function addBackgrounds() {
        // Add map background
        var distanceBackground = new Backdrop("graphics/mapbackground.png");
        distanceBackground.scrollX = 0.5;
        distanceBackground.scrollY = 0.5;
        addGraphic(distanceBackground, 1000);

        // Add segment backgrounds
        for(mapX in 0...mapBlueprint.columns) {
            for(mapY in 0...mapBlueprint.rows) {
                if(mapBlueprint.getTile(mapX, mapY)) {
                    var segmentBackgrounds = new Image(
                        "graphics/segmentbackgrounds.png"
                    );
                    var numBackgrounds = Std.int(
                        segmentBackgrounds.height / Segment.MIN_SEGMENT_HEIGHT
                    );
                    var clipRect = new Rectangle(
                        0,
                        Random.randInt(numBackgrounds)
                        * Segment.MIN_SEGMENT_HEIGHT,
                        Segment.MIN_SEGMENT_WIDTH,
                        Segment.MIN_SEGMENT_HEIGHT
                    );
                    var segmentBackground = new Image(
                        "graphics/segmentbackgrounds.png", clipRect
                    );
                    addGraphic(
                        segmentBackground, 100,
                        mapX * Segment.MIN_SEGMENT_WIDTH,
                        mapY * Segment.MIN_SEGMENT_HEIGHT
                    );
                }
            }
        }
    }

    public function onDeath() {
        curtain.fadeOut();
        var resetTimer = new Alarm(1.5, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            stopAllSounds();
            HXP.scene = new MainMenu();
        });
        addTween(resetTimer, true);
    }

    public function descend() {
        curtain.fadeOut();
        var resetTimer = new Alarm(1.5, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            stopAllSounds();
            HXP.scene = new GameScene();
        });
        addTween(resetTimer, true);
    }

    private function stopAllSounds() {
        var roboPlants = new Array<Entity>();
        getType("roboplant", roboPlants);
        for(roboPlant in roboPlants) {
            cast(roboPlant, RoboPlant).stopThemeSong();
        }
        var entities = new Array<Entity>();
        getClass(MemoryEntity, entities);
        for(entity in entities) {
            cast(entity, MemoryEntity).stopSound();
        }
        music.stop();
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
        player = new Player(playerStart.point.x, playerStart.point.y);
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
                newKeyPoint.point.distance(newDoorPoint.point)
                > keyPoint.point.distance(doorPoint.point)
                && newKeyPoint.point.distance(playerPoint)
                > keyPoint.point.distance(playerPoint)
                && newDoorPoint.point.distance(playerPoint)
                > doorPoint.point.distance(playerPoint)
            ) {
                keyPoint = newKeyPoint;
                doorPoint = newDoorPoint;
            }
        }
        key = new DoorKey(keyPoint.point.x, keyPoint.point.y);
        key.y -= Segment.TILE_SIZE;
        door = new Door(doorPoint.point.x, doorPoint.point.y);
        door.y += Segment.TILE_SIZE - door.height;
        add(key);
        add(door);
    }

    private function addEnemies() {
        var numberOfEnemies = STARTING_NUMBER_OF_ENEMIES;
        var enemyPoints = new Array<SegmentPoint>();
        var groundEnemyPoints = new Array<SegmentPoint>();
        var leftWallEnemyPoints = new Array<SegmentPoint>();
        var rightWallEnemyPoints = new Array<SegmentPoint>();
        for(i in 0...numberOfEnemies) {
            //var isGroundEnemy = Random.random < 0.5;
            var enemyType = HXP.choose("rightwall", "leftwall");
            var existingPoints = (
                enemyPoints
                .concat(groundEnemyPoints)
                .concat(leftWallEnemyPoints)
                .concat(rightWallEnemyPoints)
            );
            if(enemyType == "ground") {
                groundEnemyPoints.push(
                    getEnemyPoint("ground", existingPoints)
                );
            }
            else if(enemyType == "leftwall") {
                leftWallEnemyPoints.push(
                    getEnemyPoint("leftwall", existingPoints)
                );
            }
            else if(enemyType == "rightwall") {
                rightWallEnemyPoints.push(
                    getEnemyPoint("rightwall", existingPoints)
                );
            }
            else {
                enemyPoints.push(getEnemyPoint("air", existingPoints));
            }
        }
        for(enemyPoint in enemyPoints) {
            add(new Follower(enemyPoint.point.x, enemyPoint.point.y));
        }
        for(enemyPoint in leftWallEnemyPoints) {
            var enemy = new LeftWallSpike(
                enemyPoint.point.x, enemyPoint.point.y
            );
            if(enemy.type == "leftwallspike") {
                var extendUp = Random.random < 0.5;
                for(i in 1...Random.randInt(MAX_CONSECUTIVE_SPIKES)) {
                    var extendCount = extendUp ? -i : i;
                    var extraSpike = new LeftWallSpike(
                        enemy.x, enemy.y + extendCount * Segment.TILE_SIZE
                    );
                    if(enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX, enemyPoint.tileY + extendCount
                    )) {
                        break;
                    }
                    if(!enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX - 1, enemyPoint.tileY + extendCount
                    )) {
                        break;
                    }
                    add(extraSpike);
                }
            }
            add(enemy);
        }
        for(enemyPoint in rightWallEnemyPoints) {
            var enemy = new RightWallSpike(
                enemyPoint.point.x, enemyPoint.point.y
            );
            if(enemy.type == "rightwallspike") {
                var extendUp = Random.random < 0.5;
                for(i in 1...Random.randInt(MAX_CONSECUTIVE_SPIKES)) {
                    var extendCount = extendUp ? -i : i;
                    var extraSpike = new RightWallSpike(
                        enemy.x, enemy.y + extendCount * Segment.TILE_SIZE
                    );
                    if(enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX, enemyPoint.tileY + extendCount
                    )) {
                        break;
                    }
                    if(!enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX + 1, enemyPoint.tileY + extendCount
                    )) {
                        break;
                    }
                    add(extraSpike);
                }
            }
            add(enemy);
        }
        for(enemyPoint in groundEnemyPoints) {
            var enemy = new Turret(enemyPoint.point.x, enemyPoint.point.y);
            enemy.y += Segment.TILE_SIZE - enemy.height;
            if(enemy.type == "floorspike") {
                var extendLeft = Random.random < 0.5;
                for(i in 1...Random.randInt(MAX_CONSECUTIVE_SPIKES)) {
                    var extendCount = extendLeft ? -i : i;
                    var extraSpike = new FloorSpike(
                        enemy.x + extendCount * Segment.TILE_SIZE, enemy.y
                    );
                    if(!enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX + extendCount, enemyPoint.tileY + 1
                    )) {
                        break;
                    }
                    if(enemyPoint.segment.walls.getTile(
                        enemyPoint.tileX + extendCount, enemyPoint.tileY
                    )) {
                        break;
                    }
                    //add(extraSpike);
                }
            }
            add(enemy);
        }
    }

    private function getEnemyPoint(
        enemyType:String, existingPoints:Array<SegmentPoint>
    ) {
        var playerPoint = new Vector2(player.x, player.y);
        var isValid = false;
        var enemyPoint:SegmentPoint = null;
        var count = 0;
        while(!isValid && count < 1000) {
            count++;
            isValid = true;
            if(enemyType == "ground") {
                enemyPoint = getRandomOpenGroundPoint();
            }
            else if(enemyType == "leftwall") {
                enemyPoint = getRandomOpenLeftWallPoint();
            }
            else if(enemyType == "rightwall") {
                enemyPoint = getRandomOpenRightWallPoint();
            }
            else {
                enemyPoint = getRandomOpenPoint();
            }

            var distanceFromPlayer = enemyPoint.point.distance(playerPoint);
            var distanceFromDoor = door.distanceToPoint(
                enemyPoint.point.x, enemyPoint.point.y, true
            );
            var distanceFromKey = key.distanceToPoint(
                enemyPoint.point.x, enemyPoint.point.y, true
            );
            if(
                distanceFromPlayer < MIN_ENEMY_DISTANCE_FROM_PLAYER
                || distanceFromDoor < MIN_ENEMY_DISTANCE_FROM_EACHOTHER
                || distanceFromKey < MIN_ENEMY_DISTANCE_FROM_EACHOTHER
            ) {
                isValid = false;
                continue;
            }
            if(enemyType == "ground") {
                if(enemyPoint.point.y + Segment.TILE_SIZE == player.bottom) {
                    isValid = false;
                    continue;
                }
            }
            for(existingPoint in existingPoints) {
                var distanceFromEnemy = enemyPoint.point.distance(
                    existingPoint.point
                );
                if(distanceFromEnemy < MIN_ENEMY_DISTANCE_FROM_EACHOTHER) {
                    isValid = false;
                    break;
                }
            }
        }
        return enemyPoint;
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
        var openPoint:SegmentPoint = {
            point: new Vector2(
                segment.x + randomTile.tileX * Segment.TILE_SIZE,
                segment.y + randomTile.tileY * Segment.TILE_SIZE
            ),
            segment: segment,
            tileX: randomTile.tileX,
            tileY: randomTile.tileY
        };
        return openPoint;
    }

    private function getRandomOpenLeftWallPoint() {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenLeftWallTile();
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenLeftWallTile();
        }
        var openPoint:SegmentPoint = {
            point: new Vector2(
                segment.x + randomTile.tileX * Segment.TILE_SIZE,
                segment.y + randomTile.tileY * Segment.TILE_SIZE
            ),
            segment: segment,
            tileX: randomTile.tileX,
            tileY: randomTile.tileY
        };
        return openPoint;
    }

    private function getRandomOpenRightWallPoint() {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenRightWallTile();
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenRightWallTile();
        }
        var openPoint:SegmentPoint = {
            point: new Vector2(
                segment.x + randomTile.tileX * Segment.TILE_SIZE,
                segment.y + randomTile.tileY * Segment.TILE_SIZE
            ),
            segment: segment,
            tileX: randomTile.tileX,
            tileY: randomTile.tileY
        };
        return openPoint;
    }

    private function getRandomOpenGroundPoint() {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenGroundTile();
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenGroundTile();
        }
        var openGroundPoint:SegmentPoint = {
            point: new Vector2(
                segment.x + randomTile.tileX * Segment.TILE_SIZE,
                segment.y + randomTile.tileY * Segment.TILE_SIZE
            ),
            segment: segment,
            tileX: randomTile.tileX,
            tileY: randomTile.tileY
        };
        return openGroundPoint;
    }

    private function placeSegments() {
        allSegments = new Array<Segment>();
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
            stopAllSounds();
            HXP.scene = new GameScene();
        }
        if(curtain.graphic.alpha > 0.95) {
            camera.x = Math.floor(player.x - HXP.width/2);
            camera.y = Math.floor(player.y - HXP.height/2);
        }

        var updateFirst = new Array<Entity>();
        for(e in _update) {
            if(Type.getClass(e) == RoboPlant) {
                _update.remove(e);
                updateFirst.push(e);
            }
        }
        for(e in updateFirst) {
            _update.push(e);
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
