import haxepunk.*;
import haxepunk.debug.Console;
import haxepunk.input.*;
import haxepunk.input.gamepads.*;
import scenes.*;

class Main extends Engine {
    private static var delta:Float;
    private static var gamepad:Gamepad;

    public static function getDelta() {
        return delta;
    }

	static function main() {
		new Main();
	}

	override public function init() {
        //Console.enable();
		HXP.scene = new MainScene();

        Key.define("left", [Key.LEFT, Key.LEFT_SQUARE_BRACKET]);
        Key.define("right", [Key.RIGHT, Key.RIGHT_SQUARE_BRACKET]);
        Key.define("up", [Key.UP]);
        Key.define("down", [Key.DOWN]);
        Key.define("jump", [Key.Z]);
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
    }

    public static function inputPressed(inputName:String) {
        if(gamepad == null || Input.pressed(inputName)) {
            return Input.pressed(inputName);
        }
        if(inputName == "jump") {
            return gamepad.pressed(XboxGamepad.A_BUTTON);
        }
        if(inputName == "flip") {
            return gamepad.pressed(XboxGamepad.X_BUTTON);
        }
        return false;
    }

    public static function inputReleased(inputName:String) {
        if(gamepad == null || Input.released(inputName)) {
            return Input.released(inputName);
        }
        if(inputName == "jump") {
            return gamepad.released(XboxGamepad.A_BUTTON);
        }
        if(inputName == "flip") {
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
        if(inputName == "flip") {
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
