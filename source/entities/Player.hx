package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Player extends MemoryEntity {
    // Movement constants
    public static inline var RUN_ACCEL = 0.25;
    public static inline var RUN_DECCEL = 0.3;
    public static inline var AIR_ACCEL = 0.2;
    public static inline var AIR_DECCEL = 0.1;
    public static inline var MAX_RUN_VELOCITY = 3.5;
    public static inline var MAX_AIR_VELOCITY = 4.3;
    public static inline var MAX_AIM_VELOCITY = 1.75;
    public static inline var JUMP_POWER = 5;
    public static inline var WALL_JUMP_POWER_X = 3;
    public static inline var WALL_JUMP_POWER_Y = 5;
    public static inline var JUMP_CANCEL_POWER = 1;
    public static inline var GRAVITY = 0.2;
    public static inline var WALL_GRAVITY = 0.1;
    public static inline var MAX_FALL_VELOCITY = 6;
    public static inline var MAX_WALL_VELOCITY = 4;
    public static inline var WALL_STICK_VELOCITY = 2;

    // Animation constants
    public static inline var LAND_SQUASH = 0.5;
    public static inline var SQUASH_RECOVERY = 0.05;
    public static inline var HORIZONTAL_SQUASH_RECOVERY = 0.08;
    public static inline var AIR_SQUASH_RECOVERY = 0.03;
    public static inline var JUMP_STRETCH = 1.5;
    public static inline var WALL_SQUASH = 0.5;
    public static inline var WALL_JUMP_STRETCH_X = 1.4;
    public static inline var WALL_JUMP_STRETCH_Y = 1.4;

    public static inline var MAX_ARROWS = 5;

    private var isTurning:Bool;
    private var wasOnGround:Bool;
    private var wasOnWall:Bool;
    private var lastWallWasRight:Bool;

    private var canMove:Bool;

    private var sprite:Spritemap;
    private var armsAndBow:Spritemap;
    private var velocity:Vector2;
    private var quiver:Int;
    private var quiverDisplay:Graphiclist;

    public function new(x:Float, y:Float) {
	    super(x, y);
        MemoryEntity.loadSfx([
            "arrowshoot1", "arrowshoot2", "arrowshoot3", "arrowdraw",
            "outofarrows", "playerdeath", "runloop", "walkloop", "slide",
            "jump", "land", "arrowpickup", "skid"
        ]);
        type = "player";
        name = "player";
        sprite = new Spritemap("graphics/player.png", 24, 32);
        sprite.add("idle", [2, 1, 0, 1], 2);
        sprite.add("run", [4, 5, 6, 7, 8, 9], 10);
        sprite.add("walk", [4, 5, 6, 7, 8, 9], 5);
        sprite.add("jump", [10]);
        sprite.add("fall", [11]);
        sprite.add("rightwall", [12]);
        sprite.add("leftwall", [13]);
        sprite.add("skid", [14]);
        sprite.play("idle");
        sprite.y = -8;
        addGraphic(sprite);

        armsAndBow = new Spritemap("graphics/armsandbow.png", 24, 32);
        armsAndBow.y = -8;
        armsAndBow.add("idle", [0]);
        armsAndBow.add("idle_forward", [1]);
        armsAndBow.add("idle_up", [2]);
        armsAndBow.add("run", [3, 4, 5, 6, 7, 8], 10);
        armsAndBow.add("walk", [3, 4, 5, 6, 7, 8], 5);
        armsAndBow.add("run_forward", [9]);
        armsAndBow.add("run_forwardup", [10]);
        armsAndBow.add("walk_forward", [9]);
        armsAndBow.add("walk_forwardup", [10]);
        armsAndBow.add("run_up", [11]);
        armsAndBow.add("walk_up", [11]);
        armsAndBow.add("jump", [12]);
        armsAndBow.add("jump_forward", [13]);
        armsAndBow.add("jump_forwardup", [14]);
        armsAndBow.add("jump_forwarddown", [15]);
        armsAndBow.add("jump_up", [16]);
        armsAndBow.add("jump_down", [17]);
        armsAndBow.add("fall", [12]);
        armsAndBow.add("fall_forward", [13]);
        armsAndBow.add("fall_forwardup", [14]);
        armsAndBow.add("fall_forwarddown", [15]);
        armsAndBow.add("fall_up", [16]);
        armsAndBow.add("fall_down", [17]);
        armsAndBow.add("empty", [18]);
        addGraphic(armsAndBow);

        velocity = new Vector2(0, 0);
        setHitbox(12, 24, -6, 0);
        isTurning = false;
        wasOnGround = false;
        wasOnWall = false;
        lastWallWasRight = false;
        canMove = true;
        quiver = MAX_ARROWS;
        quiverDisplay = new Graphiclist();
        quiverDisplay.y = -20;
        addGraphic(quiverDisplay);
        updateQuiverDisplay();
    }

    private function updateQuiverDisplay() {
        quiverDisplay.removeAll();
        for(i in 0...quiver) {
            var arrowDisplay = new Image("graphics/arrowdisplay.png");
            arrowDisplay.smooth = false;
            arrowDisplay.pixelSnapping = true;
            arrowDisplay.x = i * arrowDisplay.width;
            quiverDisplay.add(arrowDisplay);
        }
        var arrowDisplay = new Image("graphics/arrowdisplay.png");
        quiverDisplay.x = (
            width/2 - (quiver * arrowDisplay.width / 2) - originX/2 + 1.5
        );
    }

    private function scaleX(newScaleX:Float, toLeft:Bool) {
        // Scales sprite horizontally in the specified direction
        sprite.scaleX = newScaleX;
        if(toLeft) {
            sprite.originX = width - (width / sprite.scaleX);
        }
    }

    private function scaleY(newScaleY:Float) {
        // Scales sprite vertically upwards
        sprite.scaleY = newScaleY;
        sprite.originY = height - (height / sprite.scaleY);
    }

    private function makeDustOnWall(isLeftWall:Bool, fromSlide:Bool) {
        var dust:Dust;
        if(fromSlide) {
            if(isLeftWall) {
                dust = new Dust(left, centerY, "slide");
            }
            else {
                dust = new Dust(right, centerY, "slide");
            }
        }
        else {
            if(isLeftWall) {
                dust = new Dust(x + 1, centerY - 2, "wall");
            }
            else {
                dust = new Dust(x + width - 3, centerY - 2, "wall");
                dust.sprite.flipX = true;
            }
        }
        scene.add(dust);
    }

    private function makeDustAtFeet() {
        var dust = new Dust(x, bottom - 8, "ground");
        if(sprite.flipX) {
            dust.x += 0.5;
        }
        scene.add(dust);
    }

    public override function update() {
        collisions();
        if(canMove) {
            movement();
            shooting();
        }
        animation();
        super.update();
    }

    private function collisions() {
        var door = collide("door", x, y);
        if(door != null) {
            if(cast(door, Door).isOpen) {
                enterDoor();
            }
        }
        if(collide("enemy", x, y) != null) {
            die();
        }
        var spike = collide("spike", x, y);
        if(spike != null) {
            if(cast(spike, FloorSpike).isActive) {
                die();
            }
        }
        var arrow = collide("arrow", x, y);
        if(arrow != null && quiver < MAX_ARROWS && cast(arrow, Arrow).landed) {
            scene.remove(arrow);
            quiver++;
            updateQuiverDisplay();
            MemoryEntity.allSfx["arrowpickup"].play();
        }
    }

    public function enterDoor() {
        collidable = false;
        canMove = false;
        cast(scene, GameScene).descend();
    }

    override private function die() {
        visible = false;
        collidable = false;
        canMove = false;
        var numExplosions = 100;
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2/numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(0.8 * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            var explosion = new DeathParticle(
                centerX, centerY, directions[count]
            );
            explosion.layer = -99;
            scene.add(explosion);
            count++;
        }
        var resetTimer = new Alarm(1.75, TweenType.OneShot);
        resetTimer.onComplete.bind(function() {
            cast(scene, GameScene).onDeath();
        });
        addTween(resetTimer, true);
#if desktop
        Sys.sleep(0.02);
#end
        scene.camera.shake(2, 8);
        MemoryEntity.allSfx["playerdeath"].play(0.7);
    }

    private function movement() {
        isTurning = (
            Main.inputCheck("left") && velocity.x > 0 ||
            Main.inputCheck("right") && velocity.x < 0
        );

        // If the player is changing directions or just starting to move,
        // multiply their acceleration
        var accelMultiplier = 1.0;
        if(velocity.x == 0 && isOnGround()) {
            accelMultiplier = 3;
        }

        var accel:Float = AIR_ACCEL;
        var deccel:Float = AIR_DECCEL;
        if(isOnGround()) {
            accel = RUN_ACCEL;
            deccel = RUN_DECCEL;
        }
        if(isOnWall()) {
            sprite.flipX = isOnLeftWall();
            velocity.x = 0;
        }

        if(isOnCeiling()) {
            velocity.y = 0;
            scaleY(1);
        }
        accel *= Main.getDelta();
        deccel *= Main.getDelta();

        // Check if the player is moving left or right
        if(Main.inputCheck("left")) {
            velocity.x -= accel * accelMultiplier;
        }
        else if(Main.inputCheck("right")) {
            velocity.x += accel * accelMultiplier;
        }
        else {
            if(velocity.x > 0) {
                velocity.x = Math.max(0, velocity.x - deccel);
            }
            else {
                velocity.x = Math.min(0, velocity.x + deccel);
            }
        }

        var gravity = GRAVITY * Main.getDelta();
        var wallGravity = WALL_GRAVITY * Main.getDelta();

        // Check if the player is jumping or falling
        if(isOnGround()) {
            velocity.y = 0;
            if(Main.inputPressed("jump")) {
                velocity.y = -JUMP_POWER;
                MemoryEntity.allSfx["jump"].play();
                scaleY(JUMP_STRETCH);
                makeDustAtFeet();
            }
        }
        else if(isOnWall()) {
            if(velocity.y < 0) {
                velocity.y += gravity;
            }
            else {
                velocity.y += wallGravity;
            }
            if(Main.inputReleased("jump")) {
                velocity.y = Math.max(-JUMP_CANCEL_POWER, velocity.y);
            }
            if(Main.inputPressed("jump")) {
                velocity.y = -WALL_JUMP_POWER_Y;
                scaleY(WALL_JUMP_STRETCH_Y);
                MemoryEntity.allSfx["jump"].play();
                if(isOnLeftWall()) {
                    velocity.x = WALL_JUMP_POWER_X;
                    scaleX(WALL_JUMP_STRETCH_X, false);
                    makeDustOnWall(true, false);
                }
                else {
                    velocity.x = -WALL_JUMP_POWER_X;
                    scaleX(WALL_JUMP_STRETCH_X, true);
                    makeDustOnWall(false, false);
                }
            }
        }
        else {
            velocity.y += gravity;
            if(Main.inputReleased("jump")) {
                velocity.y = Math.max(-JUMP_CANCEL_POWER, velocity.y);
            }
        }

        // Cap the player's velocity
        var maxVelocity:Float = MAX_AIR_VELOCITY;
        if(isOnGround()) {
            if(Main.inputCheck("act")) {
                maxVelocity = MAX_AIM_VELOCITY;
            }
            else {
                maxVelocity = MAX_RUN_VELOCITY;
            }
        }
        velocity.x = Math.min(velocity.x, maxVelocity);
        velocity.x = Math.max(velocity.x, -maxVelocity);
        var maxFallVelocity = MAX_FALL_VELOCITY;
        if(isOnWall()) {
            maxFallVelocity = MAX_WALL_VELOCITY;
            if(velocity.y > 0) {
                if(
                    isOnLeftWall() &&
                    scene.collidePoint("walls", left - 1, top) != null
                ) {
                    makeDustOnWall(true, true);
                }
                else if(
                    isOnRightWall() &&
                    scene.collidePoint("walls", right + 1, top) != null
                ) {
                    makeDustOnWall(false, true);
                }
            }
        }
        velocity.y = Math.min(velocity.y, maxFallVelocity);

        wasOnGround = isOnGround();
        wasOnWall = isOnWall();

        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(), "walls"
        );
    }

    private function shooting() {
        if(!isOnGround() && isOnWall()) {
            return;
        }
        if(Main.inputPressed("act")) {
            if(quiver <= 0) {
                MemoryEntity.allSfx["outofarrows"].play();
                return;
            }
            MemoryEntity.allSfx["arrowdraw"].play();
        }
        else if(Main.inputReleased("act")) {
            if(quiver <= 0) {
                return;
            }
            var direction:Vector2;
            var arrow:Arrow;
            if(Main.inputCheck("up")) {
                direction = new Vector2(0, -1);
                if(Main.inputCheck("left")) {
                    direction.x = -1;
                }
                else if(Main.inputCheck("right")) {
                    direction.x = 1;
                }
                arrow = new Arrow(centerX, centerY, direction, true);
            }
            else if(Main.inputCheck("down") && !isOnGround()) {
                direction = new Vector2(0, 1);
                if(Main.inputCheck("left")) {
                    direction.x = -1;
                    direction.y = 0.75;
                }
                else if(Main.inputCheck("right")) {
                    direction.x = 1;
                    direction.y = 0.75;
                }
                arrow = new Arrow(centerX, centerY, direction, true);
            }
            else {
                direction = new Vector2(0, -Arrow.INITIAL_LIFT);
                if(Main.inputCheck("left")) {
                    direction.x = -1;
                }
                else if(Main.inputCheck("right")) {
                    direction.x = 1;
                }
                else {
                    direction.x = sprite.flipX ? -1: 1;
                }
                arrow = new Arrow(centerX, centerY, direction, false);
            }
            var kickback = direction.clone();
            kickback.scale(0.2);
            kickback.y = kickback.y/2;
            if(isOnGround()) {
                kickback.scale(0.75);
            }
            velocity.subtract(kickback);
            scene.add(arrow);
            MemoryEntity.allSfx['arrowshoot${HXP.choose(1, 2, 3)}'].play(0.5);
            MemoryEntity.allSfx["arrowdraw"].stop();
            quiver--;
            updateQuiverDisplay();
        }
    }

    private function animation() {
        var squashRecovery:Float = AIR_SQUASH_RECOVERY;
        if(isOnGround()) {
            squashRecovery = SQUASH_RECOVERY;
        }
        squashRecovery *= Main.getDelta();

        if(sprite.scaleY > 1) {
            scaleY(Math.max(sprite.scaleY - squashRecovery, 1));
        }
        else if(sprite.scaleY < 1) {
            scaleY(Math.min(sprite.scaleY + squashRecovery, 1));
        }

        squashRecovery = HORIZONTAL_SQUASH_RECOVERY * Main.getDelta();

        if(sprite.scaleX > 1) {
            scaleX(
                Math.max(sprite.scaleX - squashRecovery, 1), lastWallWasRight
            );
        }
        else if(sprite.scaleX < 1) {
            scaleX(
                Math.min(sprite.scaleX + squashRecovery, 1), lastWallWasRight
            );
        }

        if(!wasOnGround && isOnGround()) {
            scaleY(LAND_SQUASH);
            makeDustAtFeet();
            MemoryEntity.allSfx["land"].play();
        }
        if(!wasOnWall && isOnWall()) {
            if(isOnRightWall()) {
                lastWallWasRight = true;
                velocity.x = Math.min(velocity.x, WALL_STICK_VELOCITY);
            }
            else {
                lastWallWasRight = false;
                velocity.x = Math.max(velocity.x, -WALL_STICK_VELOCITY);
            }
            scaleX(WALL_SQUASH, lastWallWasRight);
            MemoryEntity.allSfx["land"].play();
        }

        var spriteAnimationName = "idle";

        if(!isOnGround()) {
            if(isOnWall()) {
                if(isOnLeftWall()) {
                    spriteAnimationName = "leftwall";
                }
                else {
                    spriteAnimationName = "rightwall";
                }
            }
            else {
                if(velocity.y < 0) {
                    spriteAnimationName = "jump";
                }
                else {
                    spriteAnimationName = "fall";
                }
            }
        }
        else if(velocity.x != 0) {
            if(isTurning) {
                spriteAnimationName = "skid";
                if(!MemoryEntity.allSfx["skid"].playing) {
                    MemoryEntity.allSfx["skid"].play();
                }
            }
            else {
                if(Main.inputCheck("act")) {
                    spriteAnimationName = "walk";
                }
                else {
                    spriteAnimationName = "run";
                }
            }
        }
        else {
            spriteAnimationName = "idle";
        }

        if(spriteAnimationName == "run") {
            if(!MemoryEntity.allSfx["runloop"].playing) {
                MemoryEntity.allSfx["runloop"].loop();
            }
        }
        else {
            MemoryEntity.allSfx["runloop"].stop();
        }

        if(spriteAnimationName == "walk") {
            if(!MemoryEntity.allSfx["walkloop"].playing) {
                MemoryEntity.allSfx["walkloop"].loop();
            }
        }
        else {
            MemoryEntity.allSfx["walkloop"].stop();
        }

        if(
            spriteAnimationName == "leftwall"
            || spriteAnimationName == "rightwall"
        ) {
            if(!MemoryEntity.allSfx["slide"].playing) {
                MemoryEntity.allSfx["slide"].loop();
            }
        }
        else {
            MemoryEntity.allSfx["slide"].stop();
        }
        MemoryEntity.allSfx["slide"].volume = Math.min(
            Math.abs(velocity.y) / MAX_WALL_VELOCITY, 1
        );

        sprite.play(spriteAnimationName);

        if(!isOnGround() && isOnWall()) {
            sprite.flipX = false;
        }
        else if(Main.inputCheck("left") && !(isOnGround() && isTurning)) {
            sprite.flipX = true;
            armsAndBow.flipX = true;
        }
        else if(Main.inputCheck("right") && !(isOnGround() && isTurning)) {
            sprite.flipX = false;
            armsAndBow.flipX = false;
        }

        // Animate arms and bow
        if(
            spriteAnimationName == "skid"
            || spriteAnimationName == "rightwall"
            || spriteAnimationName == "leftwall"
        ) {
            armsAndBow.play("empty");
        }
        else if(Main.inputCheck("act") && quiver > 0) {
            var suffix:String;
            if(
                Main.inputCheck("up")
                && !(Main.inputCheck("right") || Main.inputCheck("left"))
            ) {
                suffix = "_up";
            }
            else if(
                Main.inputCheck("down")
                && !isOnGround()
                && !(Main.inputCheck("right") || Main.inputCheck("left"))
            ) {
                suffix = "_down";
            }
            else if(Main.inputCheck("up")) {
                suffix = "_forwardup";
            }
            else if(Main.inputCheck("down") && !isOnGround()) {
                suffix = "_forwarddown";
            }
            else {
                suffix = "_forward";
            }
            armsAndBow.play(spriteAnimationName + suffix);
        }
        else {
            armsAndBow.play(spriteAnimationName);
        }
    }
}

