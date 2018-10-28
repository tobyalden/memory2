package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class RoboPlant extends MemoryEntity {
    public static inline var ACCEL = 0.055;
    public static inline var MAX_SPEED = 2.9;
    public static inline var ARROW_DEFLECT_FACTOR = 1.5;

    var face:Spritemap;
    var tentacles:Spritemap;
    var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "roboplant";
        face = new Spritemap("graphics/roboplantface.png", 48, 46);
        face.add("evil", [0]);
        face.add("mad", [1]);
        face.add("robot", [2]);
        var faceNames = ["evil", "mad", "robot"];
        face.play(faceNames[Random.randInt(faceNames.length)]);
        tentacles = new Spritemap("graphics/roboplanttentacles.png", 48, 46);
        tentacles.add("idle", [0, 1], 12);
        tentacles.play("idle");
        setGraphic(face);
        addGraphic(tentacles);
        velocity = new Vector2(0, 0);
        setHitbox(48, 46);
    }

    override public function update() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel = ACCEL;
        if(distanceFrom(player, true) < 100) {
            accel *= 2.5;
        }
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }

        moveBy(velocity.x * Main.getDelta(), velocity.y * Main.getDelta());

        var arrow = collide("arrow", x, y);
        if(arrow != null) {
            cast(arrow, Arrow).velocity.inverse();
            cast(arrow, Arrow).velocity.scale(ARROW_DEFLECT_FACTOR);
            MemoryEntity.allSfx['arrowhit${HXP.choose(1, 2, 3)}'].play(1);
        }
        super.update();
    }
}
