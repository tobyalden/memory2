package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.input.gamepads.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Tutorial extends MemoryEntity {
    public static inline var MESSAGE_DELAY = 3;
    public static inline var MESSAGE_TIME = 2;
    public static inline var MESSAGE_FADE_TIME = 1;

    public static var messageNum:Int = 1;

    private var message:Spritemap;

    public function new() {
        super(0, 0);
        layer = -20;

        message = new Spritemap("graphics/tutorial.png", 640, 41);
        message.add("1", [0]);
        message.add("controller1", [1]);
        message.add("2", [2]);
        message.add("controller2", [3]);
        message.add("3", [4]);
        message.add("controller3", [5]);
        message.add("4", [6]);
        message.add("controller4", [6]);

        message.play(getMessageName());
        message.alpha = 0;

        setGraphic(message);

        var fadeInDelay = new Alarm(messageNum == 1 ? 3 : 0, TweenType.OneShot);
        fadeInDelay.onComplete.bind(function() {
            var fadeIn = new VarTween(TweenType.OneShot);
            fadeIn.tween(
                message, "alpha", 1, MESSAGE_FADE_TIME, Ease.sineIn
            );
            fadeIn.onComplete.bind(function() {
                var hold = new Alarm(MESSAGE_TIME, TweenType.OneShot);
                hold.onComplete.bind(function() {
                    var fadeOut = new VarTween(TweenType.OneShot);
                    fadeOut.tween(
                        message, "alpha", 0, MESSAGE_FADE_TIME, Ease.sineOut
                    );
                    fadeOut.onComplete.bind(function() {
                        scene.remove(this);
                        messageNum++;
                        if(messageNum <= 4) {
                            scene.add(new Tutorial());
                        }
                    });
                    addTween(fadeOut, true);
                });
                addTween(hold, true);
            });
            addTween(fadeIn, true);
        });
        addTween(fadeInDelay, true);

        if(messageNum > 4) {
            enabled = false;
        }
    }

    private function getMessageName() {
        if(Main.gamepad != null) {
            return 'controller${messageNum}';
        }
        else {
            return '${messageNum}';
        }
    }

    public override function update() {
        var player = scene.getInstance("player");
        x = player.centerX - message.width / 2;
        y = player.centerY - message.height / 2 + 100;
        super.update();
    }
}

