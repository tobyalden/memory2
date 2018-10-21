
package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class Follower extends MemoryEntity {
    var sprite:Spritemap;
    var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("idle", [0]);
        setGraphic(sprite);
        velocity = new Vector2(0, 0);
        setHitbox(24, 24);
    }
}
