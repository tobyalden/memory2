package entities;

import haxepunk.*;
import haxepunk.utils.*;
import haxepunk.graphics.*;

class Dust extends MemoryEntity {
    public var sprite:Spritemap;

    public function new(x:Float, y:Float, kind:String) {
        super(x, y);
        if(kind == "ground") {
            sprite = new Spritemap("graphics/grounddust.png", 8, 4);
            sprite.add("idle", [0, 1, 2, 3, 4], 16, false);
        }
        else if(kind == "wall") {
            sprite = new Spritemap("graphics/walldust.png", 4, 8);
            sprite.add("idle", [0, 1, 2, 3, 4], 16, false);
        }
        else { // if kind == "slide"
            sprite = new Spritemap("graphics/wallslidedust.png", 12, 12);
            sprite.add("idle", [1, 2, 3], 16, false);
            sprite.originX = 6;
            sprite.originY = 6;
            layer = 10;
        }
        sprite.play("idle");
        graphic = sprite;
    }

    public override function update() {
        if(sprite.complete) {
            scene.remove(this);
        }
    }
}

