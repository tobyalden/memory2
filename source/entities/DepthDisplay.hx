package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class DepthDisplay extends MemoryEntity {
    public static inline var MESSAGE_TIME = 2;
    public static inline var MESSAGE_FADE_TIME = 1;

    private var message:Spritemap;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        layer = -20;

        message = new Spritemap("graphics/depthdisplay.png", 640, 41);
        for(i in 0...7) {
            message.add('${i+1}', [i]);
        }
        message.play('${GameScene.depth}');
        setGraphic(message);

        var messageFade = new VarTween(TweenType.OneShot);
        messageFade.tween(
            message, "alpha", 0, MESSAGE_FADE_TIME, Ease.sineOut
        );
        addTween(messageFade);

        var fadeTimerDelay = new Alarm(MESSAGE_TIME, TweenType.OneShot);
        fadeTimerDelay.onComplete.bind(function() {
            messageFade.start();
        });
        addTween(fadeTimerDelay, true);
    }

    public override function update() {
        if(GameScene.depth < 7) {
            var player = scene.getInstance("player");
            if(player != null) {
                x = player.centerX - message.width / 2;
                y = player.centerY - message.height / 2 - 80;
            }
        }
        super.update();
    }
}
