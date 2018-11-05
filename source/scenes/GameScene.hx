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
    public static inline var TOTAL_NUMBER_OF_MAPS = 40;

    public static inline var CAMERA_FOLLOW_SPEED = 3.5;
    public static inline var STARTING_NUMBER_OF_ENEMIES = 10;
    public static inline var STARTING_NUMBER_OF_TRAPS = 10;
    //public static inline var STARTING_NUMBER_OF_ENEMIES = 0;
    //public static inline var STARTING_NUMBER_OF_TRAPS = 0;
    public static inline var STARTING_SCATTERED_ARROWS = 10;
    public static inline var NUMBER_OF_DECORATIONS = 10;
    public static inline var MAX_PLACEMENT_RETRIES = 10000;
    public static inline var MIN_ENEMY_DISTANCE_FROM_PLAYER = 350;
    public static inline var MIN_ENEMY_DISTANCE_FROM_EACHOTHER = 200;
    public static inline var MAX_CONSECUTIVE_SPIKES = 10;
    public static inline var NUMBER_OF_DECORATION_TYPES = 18;

    public static var easyMode:Bool = true;

    public static var depth:Int = 1;

    public var music(default, null):Sfx;
    private var mapBlueprint:Grid;
    private var map:Grid;
    private var player:Player;
    private var door:Door;
    private var key:DoorKey;
    private var curtain:Curtain;
    private var allSegments:Array<Segment>;
    private var allEnemies:Array<MemoryEntity>;

    private var depthDisplay:DepthDisplay;

    static public function getDepthBlock() {
        if(depth < 3) {
            return "";
        }
        else if(depth < 5) {
            return "2";
        }
        else {
            return "3";
        }
    }

	override public function begin() {
        if(depth == 7) {
            loadBossRoom();
            return;
        }
        loadMap(Random.randInt(TOTAL_NUMBER_OF_MAPS));

        addBackgrounds();
        placeSegments();
        fillEmptySegments();

        var playerPoint = addPlayer();
        var keyAndDoorPoints = addKeyAndDoor();
        var enemyPoints = addEnemies();
        addDecorations(
            enemyPoints.concat(keyAndDoorPoints).concat(playerPoint)
        );

        var numArrows = STARTING_SCATTERED_ARROWS - depth;
        if(!easyMode) {
            numArrows -= 3;
        }
        scatterArrows(numArrows);

        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();
        camera.pixelSnapping = true;

        music = new Sfx('audio/music${depth}.wav');
        music.volume = 0.6;
        music.loop();

        depthDisplay = new DepthDisplay();
        add(depthDisplay);

        if(depth == 1) {
            add(new Tutorial());
        }

        removeEnemiesTooCloseToPlayer();
    }

    private function removeEnemiesTooCloseToPlayer() {
        for(enemy in allEnemies) {
            if(enemy.distanceFrom(player) < MIN_ENEMY_DISTANCE_FROM_PLAYER) {
                remove(enemy);
            }
        }
    }

    private function loadBossRoom() {
        placeBossSegment();
        player = new Player(
            allSegments[0].centerX - 6,
            allSegments[0].bottom - Segment.TILE_SIZE * 2 - 24
        );
        add(player);
        var boss = new Boss(
            allSegments[0].centerX - 50,
            allSegments[0].top + Segment.TILE_SIZE + 50
        );
        add(boss);
        add(boss.weakPoint);
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();
        camera.pixelSnapping = true;
        camera.x = Math.floor(allSegments[0].centerX - HXP.width/2);
        camera.y = allSegments[0].y;
        depthDisplay = new DepthDisplay(0, HXP.height/2);
        add(depthDisplay);
        music = new Sfx('audio/boss.wav');
        music.loop();
    }

    public function spawnRoboPlant() {
        add(new RoboPlant(
            player.x + (Random.random < 0.5 ? HXP.width/1.5 : -HXP.width/1.5),
            player.y + (Random.random < 0.5 ? HXP.height/1.5 : -HXP.height/1.5)
        ));
    }

    private function addBackgrounds() {
        // Add map background
        var distanceBackground = new Backdrop(
            'graphics/mapbackground${GameScene.getDepthBlock()}.png'
        );
        distanceBackground.scrollX = 0.25;
        distanceBackground.scrollY = 0.25;
        addGraphic(distanceBackground, 1000);

        // Add segment backgrounds
        for(mapX in 0...mapBlueprint.columns) {
            for(mapY in 0...mapBlueprint.rows) {
                if(mapBlueprint.getTile(mapX, mapY)) {
                    var segmentBackgrounds = new Image(
                        'graphics/segmentbackgrounds${
                            GameScene.getDepthBlock()
                        }.png'
                    );
                    var numBackgrounds = Std.int(
                        segmentBackgrounds.height / Segment.MIN_SEGMENT_HEIGHT
                    );
                    if(depth < 3) {
                        numBackgrounds -= 2;
                    }
                    else if(depth < 5) {
                        numBackgrounds -= 1;
                    }
                    var clipRect = new Rectangle(
                        0,
                        Random.randInt(numBackgrounds)
                        * Segment.MIN_SEGMENT_HEIGHT,
                        Segment.MIN_SEGMENT_WIDTH,
                        Segment.MIN_SEGMENT_HEIGHT
                    );
                    var segmentBackground = new Image(
                        'graphics/segmentbackgrounds${
                            GameScene.getDepthBlock()
                        }.png',
                        clipRect
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
        music.stop();
        addTween(resetTimer, true);
    }

    public function descend() {
        depth++;
        curtain.fadeOut();
        var resetTimer = new Alarm(1.5, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            stopAllSounds();
            HXP.scene = new GameScene();
        });
        music.stop();
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
        //var mapPath = 'maps/tiny.oel';
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
        var playerStart = getRandomOpenGroundPoint(3);
        player = new Player(playerStart.point.x, playerStart.point.y);
        player.x += 3;
        player.y += Segment.TILE_SIZE - player.height;
        add(player);
        var disabledDoor = new MemoryEntity(
            playerStart.point.x, playerStart.point.y
        );
        var disabledShaft = new MemoryEntity(
            playerStart.point.x, playerStart.point.y
        );

        // Add disabled door and shaft
        if(depth == 1) {
            var disabledDoorImg = new Image("graphics/drain.png");
            disabledDoor.setGraphic(disabledDoorImg);
            disabledDoor.x -= (disabledDoorImg.width - Segment.TILE_SIZE)/2;
            disabledDoor.x += player.width/2;
            disabledDoor.y -= 70;
            disabledDoor.layer = 40;
            var shaftHeight = 700 * 5;
            var disabledShaftImg = new TiledImage(
                "graphics/fatshaft.png", 90, shaftHeight
            );
            disabledShaft.setGraphic(disabledShaftImg);
            disabledShaft.x -= (disabledShaftImg.width - Segment.TILE_SIZE)/2;
            disabledShaft.x += player.width/2;
            disabledShaft.y += Segment.TILE_SIZE - shaftHeight;
            disabledShaft.layer = 60;
        }
        else {
            var disabledDoorImg = new Image('graphics/disableddoor${getDepthBlock()}.png');
            disabledDoor.setGraphic(disabledDoorImg);
            disabledDoor.x -= (disabledDoorImg.width - Segment.TILE_SIZE)/2;
            disabledDoor.x += player.width/2;
            disabledDoor.y += Segment.TILE_SIZE - disabledDoorImg.height;
            disabledDoor.layer = 40;
            var shaftHeight = 700 * 5;
            var disabledShaftImg = new TiledImage(
                'graphics/elevatorshaft${getDepthBlock()}.png', 38, shaftHeight
            );
            disabledShaft.setGraphic(disabledShaftImg);
            disabledShaft.x -= (disabledShaftImg.width - Segment.TILE_SIZE)/2;
            disabledShaft.x += player.width/2;
            disabledShaft.y += Segment.TILE_SIZE - shaftHeight;
            disabledShaft.layer = 60;
        }
        add(disabledDoor);
        add(disabledShaft);

        return [playerStart];
    }

    private function addKeyAndDoor() {
        var keyPoint = getRandomOpenGroundPoint();
        var doorPoint = getRandomOpenGroundPoint(3);
        var playerPoint = new Vector2(player.x, player.y);
        for (i in 0...500) {
            var newKeyPoint = getRandomOpenGroundPoint();
            var newDoorPoint = getRandomOpenGroundPoint(3);
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
        door.door.y += Segment.TILE_SIZE - door.height;
        add(key);
        add(door);
        add(door.door);

        var shaft = new MemoryEntity(
            door.x, doorPoint.point.y
        );
        var shaftHeight = 700 * 5;
        var shaftImg = new TiledImage(
            'graphics/elevatorshaft${getDepthBlock()}.png', 38, shaftHeight
        );
        shaft.setGraphic(shaftImg);
        shaft.y += Segment.TILE_SIZE - door.height;
        shaft.y += 10;
        shaft.layer = 60;
        add(shaft);
        var shaftTop = new MemoryEntity(shaft.x, shaft.y);
        shaftTop.setGraphic(new Image('graphics/shafttop${getDepthBlock()}.png'));
        shaftTop.layer = 59;
        add(shaftTop);

        return [keyPoint, doorPoint];
    }

    private function scatterArrows(numArrows:Int) {
        var arrowPoints = new Array<SegmentPoint>();
        for(i in 0...numArrows) {
            arrowPoints.push(getEnemyPoint("air", arrowPoints));
        }
        for(arrowPoint in arrowPoints) {
            var awayFromPlayer = new Vector2(
                player.centerX - arrowPoint.point.x,
                player.centerY - arrowPoint.point.y
            );
            awayFromPlayer.inverse();
            awayFromPlayer.normalize(Arrow.INITIAL_VELOCITY);
            var isVertical = (
                Math.abs(awayFromPlayer.y) > Math.abs(awayFromPlayer.x)
            );
            add(new Arrow(
                arrowPoint.point.x, arrowPoint.point.y, awayFromPlayer,
                isVertical, true
            ));
        }
    }

    private function addEnemies() {
        allEnemies = new Array<MemoryEntity>();
        var numberOfEnemies = STARTING_NUMBER_OF_ENEMIES;
        var enemyPoints = new Array<SegmentPoint>();
        var groundEnemyPoints = new Array<SegmentPoint>();

        var numberOfTraps = STARTING_NUMBER_OF_TRAPS;
        var groundTrapPoints = new Array<SegmentPoint>();
        var leftWallTrapPoints = new Array<SegmentPoint>();
        var rightWallTrapPoints = new Array<SegmentPoint>();

        if(easyMode) {
            numberOfEnemies = Std.int(Math.floor(numberOfEnemies / 2));
            numberOfTraps = Std.int(Math.floor(numberOfTraps / 2));
        }

        numberOfEnemies += depth - 1;
        numberOfTraps += depth - 1;

        var existingPoints:Array<SegmentPoint> = [];
        for(i in 0...numberOfTraps) {
            var trapType = ["rightwall", "leftwall", "ground"][
                Random.randInt(3)
            ];
            existingPoints = (
                groundTrapPoints
                .concat(leftWallTrapPoints)
                .concat(rightWallTrapPoints)
            );
            if(trapType == "ground") {
                groundTrapPoints.push(
                    getEnemyPoint("ground", existingPoints)
                );
            }
            else if(trapType == "leftwall") {
                leftWallTrapPoints.push(
                    getEnemyPoint("leftwall", existingPoints)
                );
            }
            else if(trapType == "rightwall") {
                rightWallTrapPoints.push(
                    getEnemyPoint("rightwall", existingPoints)
                );
            }
        }
        for(i in 0...numberOfEnemies) {
            var enemyType = ["air", "ground"][Random.randInt(2)];
            //var enemyType = "air";
            var existingPoints = (
                enemyPoints
                .concat(groundEnemyPoints)
                .concat(groundTrapPoints)
                .concat(leftWallTrapPoints)
                .concat(rightWallTrapPoints)
            );
            if(enemyType == "ground") {
                groundEnemyPoints.push(
                    getEnemyPoint("ground", existingPoints)
                );
            }
            else {
                enemyPoints.push(getEnemyPoint("air", existingPoints));
            }
        }

        // Add enemies
        for(enemyPoint in enemyPoints) {
            var choice = Random.randInt(3);
            var enemy:MemoryEntity;
            if(choice == 0) {
                enemy = new Bouncer(enemyPoint.point.x, enemyPoint.point.y);
            }
            else if(choice == 1) {
                enemy = new Follower(enemyPoint.point.x, enemyPoint.point.y);
            }
            else {
                enemy = new Ghost(enemyPoint.point.x, enemyPoint.point.y);
            }
            add(enemy);
            allEnemies.push(enemy);
        }
        for(enemyPoint in groundEnemyPoints) {
            var choice = Random.randInt(3);
            var enemy:MemoryEntity;
            //choice = 0;
            if(choice == 0) {
                enemy = new Turret(enemyPoint.point.x, enemyPoint.point.y);
            }
            else if(choice == 1) {
                enemy = new Hopper(enemyPoint.point.x, enemyPoint.point.y - 1);
            }
            else {
                enemy = new Roombad(enemyPoint.point.x, enemyPoint.point.y);
            }
            enemy.y += Segment.TILE_SIZE - enemy.height;
            add(enemy);
            allEnemies.push(enemy);
        }

        // Add traps
        for(enemyPoint in leftWallTrapPoints) {
            var enemy:MemoryEntity;
            if(Random.random < 0.5) {
                enemy = new Mine(
                    enemyPoint.point.x, enemyPoint.point.y
                );
            }
            else {
                enemy = new LeftWallSpike(
                    enemyPoint.point.x, enemyPoint.point.y
                );
            }
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
                    allEnemies.push(extraSpike);
                }
            }
            add(enemy);
            allEnemies.push(enemy);
        }
        for(enemyPoint in rightWallTrapPoints) {
            var enemy:MemoryEntity;
            if(Random.random < 0.5) {
                enemy = new Mine(
                    enemyPoint.point.x, enemyPoint.point.y
                );
            }
            else {
                enemy = new RightWallSpike(
                    enemyPoint.point.x, enemyPoint.point.y
                );
            }
            if(enemy.type == "mine") {
                enemy.x += 4;
            }
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
                    allEnemies.push(extraSpike);
                }
            }
            add(enemy);
            allEnemies.push(enemy);
        }
        for(enemyPoint in groundTrapPoints) {
            var enemy = new FloorSpike(enemyPoint.point.x, enemyPoint.point.y);
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
                    add(extraSpike);
                    allEnemies.push(extraSpike);
                }
            }
            add(enemy);
            allEnemies.push(enemy);
        }
        return existingPoints;
    }

    private function addDecorations(enemyPoints:Array<SegmentPoint>) {
        var decorationPoints = new Array<SegmentPoint>();
        for(i in 0...NUMBER_OF_DECORATIONS) {
            decorationPoints.push(
                getEnemyPoint("ground", decorationPoints.concat(enemyPoints))
            );
        }
        for(decorationPoint in decorationPoints) {
            var decorationNum = Random.randInt(NUMBER_OF_DECORATION_TYPES);
            var decoration = new Image(
                'graphics/decorations${GameScene.getDepthBlock()}.png',
                new Rectangle(decorationNum * 30, 0, 30, 30)
            );
            decoration.flipX = Random.random < 0.5;
            addGraphic(
                decoration,
                1,
                decorationPoint.point.x,
                decorationPoint.point.y + Segment.TILE_SIZE - 30
            );
        }

        // Add more skeletons at lower depths
        var skeletonPoints = new Array<SegmentPoint>();
        for(i in 0...(depth * 4)) {
            skeletonPoints.push(
                getEnemyPoint(
                    "ground",
                    skeletonPoints.concat(enemyPoints).concat(decorationPoints)
                )
            );
        }
        for(skeletonPoint in skeletonPoints) {
            var skeletonNum = 14;
            var skeleton = new Image(
                'graphics/decorations${GameScene.getDepthBlock()}.png',
                new Rectangle(skeletonNum * 30, 0, 30, 30)
            );
            skeleton.flipX = Random.random < 0.5;
            addGraphic(
                skeleton,
                1,
                skeletonPoint.point.x,
                skeletonPoint.point.y + Segment.TILE_SIZE - 30
            );
        }

        // Add more plants at lower depths
        var plantPoints = new Array<SegmentPoint>();
        for(i in 0...(depth * 10)) {
            plantPoints.push(
                getEnemyPoint(
                    "ground",
                    plantPoints
                    .concat(enemyPoints)
                    .concat(decorationPoints)
                    .concat(skeletonPoints)
                )
            );
        }
        for(plantPoint in plantPoints) {
            var plantNum = 9 + Random.randInt(5);
            var plant = new Image(
                'graphics/decorations${GameScene.getDepthBlock()}.png',
                new Rectangle(plantNum * 30, 0, 30, 30)
            );
            plant.flipX = Random.random < 0.5;
            addGraphic(
                plant,
                1,
                plantPoint.point.x,
                plantPoint.point.y + Segment.TILE_SIZE - 30
            );
        }
    }

    private function getEnemyPoint(
        enemyType:String, existingPoints:Array<SegmentPoint>
    ) {
        var playerPoint = new Vector2(player.x, player.y);
        var isValid = false;
        var enemyPoint:SegmentPoint = null;
        var count = 0;
        while(!isValid && count < MAX_PLACEMENT_RETRIES) {
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

    private function getRandomOpenGroundPoint(extraSpace:Int = 0) {
        var weightedSegments = getWeightedSegments();
        var segment = weightedSegments[Random.randInt(weightedSegments.length)];
        var randomTile = segment.getRandomOpenGroundTile(extraSpace);
        while(randomTile == null) {
            segment = weightedSegments[Random.randInt(weightedSegments.length)];
            randomTile = segment.getRandomOpenGroundTile(extraSpace);
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

    private function placeBossSegment() {
        allSegments = new Array<Segment>();
        var segment = new Segment(0, 0, true);
        add(segment);
        allSegments.push(segment);
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
        if(Key.pressed(Key.N)) {
            depth++;
            stopAllSounds();
            HXP.scene = new GameScene();
        }
        if(Key.pressed(Key.D)) {
            player.x = door.x;
            player.y = door.y;
        }
        if(Key.pressed(Key.P)) {
            for(segment in allSegments) {
                if(player.collideRect(
                    player.x, player.y, segment.x, segment.y, segment.width,
                    segment.height
                )) {
                    trace('player is in segment #${segment.number}');
                    break;
                }
            }
        }
        if(curtain.graphic.alpha > 0.95) {
            centerCameraOnPlayer();
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
             centerCameraOnPlayer();
        }
    }

    private function centerCameraOnPlayer() {
        if(depth == 7) {
            return;
        }
        camera.x = Math.floor(player.x - HXP.width/2);
        camera.y = Math.floor(player.y - HXP.height/2);
    }
}
