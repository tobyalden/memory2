package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Player extends MemoryEntity {
    // Movement constants
    public static inline var RUN_ACCEL = 0.15;
    public static inline var RUN_DECCEL = 0.3;
    public static inline var AIR_ACCEL = 0.13;
    public static inline var AIR_DECCEL = 0.1;
    public static inline var MAX_RUN_VELOCITY = 1.6;
    public static inline var MAX_AIR_VELOCITY = 2;
    public static inline var JUMP_POWER = 2.4;
    public static inline var DOUBLE_JUMP_POWER = 2;
    public static inline var WALL_JUMP_POWER_X = 3;
    public static inline var WALL_JUMP_POWER_Y = 2.1;
    public static inline var JUMP_CANCEL_POWER = 0.5;
    public static inline var GRAVITY = 0.13;
    public static inline var WALL_GRAVITY = 0.08;
    public static inline var MAX_FALL_VELOCITY = 3;
    public static inline var MAX_WALL_VELOCITY = 2;
    public static inline var WALL_STICK_VELOCITY = 1;

    // Animation constants
    public static inline var LAND_SQUASH = 0.5;
    public static inline var SQUASH_RECOVERY = 0.05;
    public static inline var HORIZONTAL_SQUASH_RECOVERY = 0.08;
    public static inline var AIR_SQUASH_RECOVERY = 0.03;
    public static inline var JUMP_STRETCH = 1.5;
    public static inline var DOUBLE_JUMP_STRETCH = 1.4;
    public static inline var WALL_SQUASH = 0.5;
    public static inline var WALL_JUMP_STRETCH_X = 1.4;
    public static inline var WALL_JUMP_STRETCH_Y = 1.4;

    private var isTurning:Bool;
    private var canDoubleJump:Bool;
    private var wasOnGround:Bool;
    private var wasOnWall:Bool;
    private var lastWallWasRight:Bool;

    private var isDying:Bool;
    private var canMove:Bool;

    private var sprite:Spritemap;
    private var velocity:Vector2;

    public function new(x:Float, y:Float) {
	    super(x, y);
        type = "player";
        sprite = new Spritemap("graphics/player.png", 8, 12);
        sprite.add("idle", [0]);
        sprite.add("run", [1, 2, 3, 2], 10);
        sprite.add("jump", [4]);
        sprite.add("wall", [5]);
        sprite.add("skid", [6]);
        sprite.play("idle");
        graphic = sprite;

        velocity = new Vector2(0, 0);
        setHitbox(6, 12, -1, 0);
        isTurning = false;
        canDoubleJump = false;
        wasOnGround = false;
        wasOnWall = false;
        lastWallWasRight = false;
        canMove = true;
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
        var dust = new Dust(x, bottom - 4, "ground");
        if(sprite.flipX) {
            dust.x += 0.5;
        }
        scene.add(dust);
    }

    public override function update() {
        collisions();
        if(canMove) {
            movement();
        }
        animation();
        super.update();
    }

    private function collisions() {

    }

    private function movement() {
        isTurning = (
            Main.inputCheck("left") && velocity.x >= 0 ||
            Main.inputCheck("right") && velocity.x <= 0
        );

        // If the player is changing directions or just starting to move,
        // multiply their acceleration
        var accelMultiplier = 1.0;
        if(velocity.x == 0 && isOnGround()) {
            accelMultiplier = 3;
        }
        else if(Main.inputPressed("jump") && canDoubleJump) {
            accelMultiplier = 2;
        }

        var accel:Float = AIR_ACCEL;
        var deccel:Float = AIR_DECCEL;
        if(isOnGround()) {
            accel = RUN_ACCEL;
            deccel = RUN_DECCEL;
            if(isOnWall()) {
                velocity.x = 0;
            }
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
            canDoubleJump = true;
            if(Main.inputPressed("jump")) {
                velocity.y = -JUMP_POWER;
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
            if(Main.inputPressed("jump")) {
                velocity.y = -WALL_JUMP_POWER_Y;
                scaleY(WALL_JUMP_STRETCH_Y);
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
            if(Main.inputPressed("jump") && canDoubleJump) {
                velocity.y = Math.min(velocity.y, -DOUBLE_JUMP_POWER);
                scaleY(DOUBLE_JUMP_STRETCH);
                makeDustAtFeet();
                canDoubleJump = false;
            }
            if(Main.inputReleased("jump")) {
                velocity.y = Math.max(-JUMP_CANCEL_POWER, velocity.y);
            }
        }

        // Cap the player's velocity
        var maxVelocity:Float = MAX_AIR_VELOCITY;
        if(isOnGround()) {
            maxVelocity = MAX_RUN_VELOCITY;
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
        }

        if(!isOnGround()) {
            if(isOnWall()) {
                sprite.play("wall");
            }
            else {
                sprite.play("jump");
            }
        }
        else if(velocity.x != 0) {
            if(isTurning) {
                sprite.play("skid");
            }
            else {
                sprite.play("run");
            }
        }
        else {
            sprite.play("idle");
        }

        if(velocity.x < 0) {
            sprite.flipX = true;
        }
        else if(velocity.x > 0) {
            sprite.flipX = false;
        }
    }
}

