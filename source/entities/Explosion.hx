package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Explosion extends MemoryEntity {
    private var sprite:Spritemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "explosion";
        sprite = new Spritemap("graphics/grenadeexplosion.png", 144, 144);
        setHitbox(100, 100, -22, -22);
        sprite.add("idle", [0, 1, 2, 3, 4, 5, 6, 7], 20, false);
        sprite.play("idle");
        setGraphic(sprite);
    }

    override public function update() {
        collidable = sprite.index < 2;
        var arrows = new Array<Entity>();
        scene.getType("arrow", arrows);
        for(arrow in arrows) {
            var tempCollidable = arrow.collidable;
            arrow.collidable = true;
            if(collideWith(arrow, x, y) != null) {
                cast(arrow, Arrow).explode(2, 0.05);
                scene.remove(arrow);
            }
            else {
                arrow.collidable = tempCollidable;
            }
        }

        var enemy = collide("enemy", x, y);
        if(enemy != null) {
            cast(enemy, MemoryEntity).die();
        }

        if(sprite.complete) {
            scene.remove(this);
        }
        super.update();
    }
}

