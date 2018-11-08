import haxepunk.*;
import haxepunk.debug.Console;
import haxepunk.input.*;
import haxepunk.input.gamepads.*;
import haxepunk.utils.*;
import scenes.*;

class Main extends Engine {
    public static var music:Sfx;
    public static var gamepad:Gamepad;
    private static var delta:Float;

    private static var previousJumpHeld:Bool = false;

    public static function getDelta() {
        return delta;
    }

	static function main() {
		new Main();
	}

	override public function init() {
#if debug
        Console.enable();
#end
        HXP.screen.color = 0x000000;
        HXP.scene = new MainMenu();

        Key.define("left", [Key.LEFT, Key.LEFT_SQUARE_BRACKET]);
        Key.define("right", [Key.RIGHT, Key.RIGHT_SQUARE_BRACKET]);
        Key.define("up", [Key.UP]);
        Key.define("down", [Key.DOWN]);
        Key.define("jump", [Key.Z, Key.SPACE, Key.ENTER]);
        Key.define("act", [Key.X]);

        gamepad = Gamepad.gamepad(0);
        Gamepad.onConnect.bind(function(newGamepad:Gamepad) {
            if(gamepad == null) {
                gamepad = newGamepad;
            }
        });
	}

    override public function update() {
        delta = HXP.elapsed * 60;
        super.update();
        if(gamepad != null) {
            previousJumpHeld = gamepad.check(XboxGamepad.A_BUTTON);
        }
    }

    public static function inputPressed(inputName:String) {
        if(gamepad == null || Input.pressed(inputName)) {
            return Input.pressed(inputName);
        }
        if(inputName == "jump") {
            if(!previousJumpHeld && gamepad.check(XboxGamepad.A_BUTTON)) {
                trace("jump pressed");
                return true;
            }
        }
        if(inputName == "act") {
            return gamepad.pressed(XboxGamepad.X_BUTTON);
        }
        return false;
    }

    public static function inputReleased(inputName:String) {
        if(gamepad == null || Input.released(inputName)) {
            return Input.released(inputName);
        }
        if(inputName == "jump") {
            if(previousJumpHeld && !gamepad.check(XboxGamepad.A_BUTTON)) {
                trace("jump released");
                return true;
            }
        }
        if(inputName == "act") {
            return gamepad.released(XboxGamepad.X_BUTTON);
        }
        return false;
    }

    public static function inputCheck(inputName:String) {
        if(gamepad == null || Input.check(inputName)) {
            if(inputName == "left" && Input.check("right")) {
                return false;
            }
            if(inputName == "right" && Input.check("left")) {
                return false;
            }
            return Input.check(inputName);
        }
        if(inputName == "jump") {
            return gamepad.check(XboxGamepad.A_BUTTON);
        }
        if(inputName == "act") {
            return gamepad.check(XboxGamepad.X_BUTTON);
        }
        if(inputName == "left") {
            return (
                gamepad.getAxis(0) < -0.5
                || gamepad.check(XboxGamepad.DPAD_LEFT)
            );
        }
        if(inputName == "right") {
            return (
                gamepad.getAxis(0) > 0.5
                || gamepad.check(XboxGamepad.DPAD_RIGHT)
            );
        }
        if(inputName == "up") {
            return (
                gamepad.getAxis(1) < -0.5
                || gamepad.check(XboxGamepad.DPAD_UP)
            );
        }
        if(inputName == "down") {
            return (
                gamepad.getAxis(1) > 0.5
                || gamepad.check(XboxGamepad.DPAD_DOWN)
            );
        }
        return false;
    }
}
