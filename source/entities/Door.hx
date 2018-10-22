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
    private var sprite:Image;

    public function new(x:Float, y:Float) {
        super(x, y);
        sprite = new Image("graphics/door.png");
        setGraphic(sprite);
        setHitbox(24, 24);
    }
} 

