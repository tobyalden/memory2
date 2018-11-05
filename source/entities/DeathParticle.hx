package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.utils.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class DeathParticle extends MemoryEntity
{
    private var sprite:Spritemap;
    private var velocity:Vector2;

    public function new(
        x:Float, y:Float, velocity:Vector2, goQuickly:Bool = false
    )
    {
	    super(x, y);
        this.velocity = velocity;
        sprite = new Spritemap("graphics/explosion.png", 24, 24);
        if(goQuickly) {
            sprite.add(
                "idle", [0, 1, 2, 3], Std.int(Math.random() * 4 + 4), false
            );
        }
        else {
            sprite.add(
                "idle", [0, 1, 2, 3], Std.int(Math.random() * 4 + 2), false
            );
        }
        sprite.play("idle");
        sprite.originX = 12;
        sprite.originY = 12;
        setGraphic(sprite);
        layer = -999;
    }

    public override function update() {
        moveBy(
            velocity.x * Main.getDelta() * 17,
            velocity.y * Main.getDelta() * 17
        );
        velocity.scale(0.97);
        graphic.alpha -= (
            (1 - (Math.abs(velocity.x) + Math.abs(velocity.y)))
            * Main.getDelta() * 0.003
        );
        if(sprite.complete) {
            scene.remove(this);
        }
    }
}

