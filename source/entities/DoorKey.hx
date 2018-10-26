package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class DoorKey extends MemoryEntity {
    public static inline var BOB_AMOUNT = 0.2;

    private var sprite:Image;
    private var bob:NumTween;

    public function new(x:Float, y:Float) {
        super(x, y);
        sprite = new Image("graphics/key.png");
        setGraphic(sprite);
        setHitbox(12, 6);
        bob = new NumTween(TweenType.PingPong);
        bob.tween(-BOB_AMOUNT, BOB_AMOUNT, 1, Ease.sineInOut);
        addTween(bob, true);
    }

    public override function update() {
        y += bob.value;
        if(collide("player", x, y) != null) {
            var doors = new Array<Entity>();
            scene.getType("door", doors);
            for(door in doors) {
                cast(door, Door).open();
            }
            scene.remove(this);
            explode(2, 0.1);
        }
        super.update();
    }
} 
