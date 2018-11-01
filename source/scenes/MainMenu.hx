package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;

class MainMenu extends Scene {
    private var curtain:Curtain;
    private var controllerConnected:Spritemap;

	override public function begin() {
        addGraphic(new Image("graphics/mainmenu.png"));
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();

        controllerConnected = new Spritemap(
            "graphics/controllerconnected.png", 640, 41
        );
        controllerConnected.add("nocontroller", [0]);
        controllerConnected.add("controller", [1]);
        add(new Entity(0, 300, controllerConnected));
    }

    public override function update() {
        controllerConnected.play(
            Main.gamepad != null ? "controller" : "nocontroller"
        );
        if(Main.inputPressed("jump") || Main.inputPressed("act")) {
            curtain.fadeOut();
            var resetTimer = new Alarm(1, TweenType.OneShot);
                resetTimer.onComplete.bind(function() {
                    clearTweens();
                    GameScene.depth = 1;
                    Tutorial.messageNum = 1;
                    HXP.scene = new GameScene();
                });
            addTween(resetTimer, true);
        }
        super.update();
    }
}
