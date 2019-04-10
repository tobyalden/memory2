package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Missile extends MemoryEntity {
    public static inline var ACCEL = 0.10;
    public static inline var MAX_SPEED = 3.1;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var explodeSfx:Sfx;
    private var tag:String;

    public function new(x:Float, y:Float, velocity:Vector2, tag:String) {
        super(x, y);
        this.velocity = velocity;
        type = "missile";
        name = tag;
        layer = 10;
        sprite = new Spritemap("graphics/missile.png", 8, 16);
        mask = new Hitbox(8, 16);
        sprite.add("idle", [0, 1], 5);
        sprite.play("idle");
        sprite.centerOrigin();
        setGraphic(sprite);
        explodeSfx = new Sfx("audio/grenadeexplode.wav");
    }

    public function detonate() {
        scene.remove(this);
        scene.add(new Explosion(centerX - 72, centerY - 72));
        explodeSfx.play();
    }

    override public function update() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        ); var accel = ACCEL;
        //if(distanceFrom(player, true) < 50) {
            //accel *= 2;
        //}
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls", "player", "arrow", "enemy"]
        );
        sprite.angle = MathUtil.angle(0, 0, velocity.x, velocity.y) + 90;
        if(Math.abs(velocity.x) < Math.abs(velocity.y)) {
            mask = new Hitbox(8, 16);
            sprite.centerOrigin();
            sprite.x = 4;
            sprite.y = 8;
        }
        else {
            mask = new Hitbox(16, 8);
            sprite.centerOrigin();
            sprite.x = 8;
            sprite.y = 4;
        }
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        if(Type.getClass(e) == MissileTurret) {
            if(name == cast(e, MissileTurret).getTag()) {
                return false;
            }
        }
        detonate();
        return true;
    }

    public override function moveCollideY(e:Entity) {
        if(Type.getClass(e) == MissileTurret) {
            if(name == cast(e, MissileTurret).getTag()) {
                return false;
            }
        }
        detonate();
        return true;
    }
}

