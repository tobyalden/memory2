package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Door extends MemoryEntity {
    public var isOpen(default, null):Bool;
    private var sprite:Spritemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "door";
        sprite = new Spritemap("graphics/door.png", 24, 36);
        sprite.add("closed", [0]);
        sprite.add("open", [1]);
        sprite.play("closed");
        setGraphic(sprite);
        setHitbox(24, 36);
        isOpen = false;
    }

    public function open() {
        sprite.play("open");
        isOpen = true;
    }
} 

