package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Door extends MemoryEntity {
    public static inline var OPEN_DISTANCE = 140;

    public var isOpen(default, null):Bool;
    public var door(default, null):Entity;
    private var sprite:Spritemap;
    private var floorIndicator:Spritemap;
    private var doorSprite:Spritemap;
    private var gate:Spritemap;
    private var isDoorOpen:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["slidingdooropen", "slidingdoorclose"]);
        type = "door";
        layer = 5;

        sprite = new Spritemap("graphics/elevatortall.png", 38, 60);
        sprite.add("open", [5]);
        sprite.add("closed", [21]);
        sprite.play("closed");

        floorIndicator = new Spritemap("graphics/elevatortall.png", 38, 60);
        floorIndicator.add("1", [12]);
        floorIndicator.add("2", [11]);
        floorIndicator.add("3", [10]);
        floorIndicator.add("4", [9]);
        floorIndicator.add("5", [8]);
        floorIndicator.add("6", [7]);
        floorIndicator.play('${GameScene.depth}');

        gate = new Spritemap("graphics/elevatortall.png", 38, 60);
        gate.add("idle", [20]);
        gate.play("idle");

        setGraphic(sprite);
        addGraphic(floorIndicator);
        addGraphic(gate);

        setHitbox(2, 60, -19, 0);
        isOpen = false;

        doorSprite = new Spritemap("graphics/elevatortall.png", 38, 60);
        doorSprite.add("closed", [1]);
        doorSprite.add("opening", [2, 3, 4, 0], 8, false);
        doorSprite.add("closing", [4, 3, 2, 1], 8, false);
        doorSprite.play("closed");
        door = new Entity(x, y, doorSprite);
        door.setHitbox(38, 40);
        door.layer = 6;
        isDoorOpen = false;
    }

    public override function update() {
        var player = scene.getInstance("player");
        if(
            !isDoorOpen
            && isOpen
            && distanceFrom(player, true) < OPEN_DISTANCE
        ) {
            isDoorOpen = true;
            doorSprite.play("opening");
            MemoryEntity.allSfx["slidingdooropen"].play();
        }
        super.update();
    }

    public function close() {
        door.layer = -4;
        doorSprite.play("closing");
        MemoryEntity.allSfx["slidingdoorclose"].play();
    }

    public function open() {
        door.layer = 4;
        isOpen = true;
        sprite.play("open");
        var gateFade = new VarTween(TweenType.OneShot);
        gateFade.tween(gate, "alpha", 0, 1);
        addTween(gateFade, true);
    }
} 

