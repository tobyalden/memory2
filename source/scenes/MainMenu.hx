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
    public static inline var GRADIENT_SCROLL_SPEED = 6;

    private var curtain:Curtain;
    private var controllerConnected:Spritemap;
    private var gradient:Entity;
    private var music:Sfx;

	override public function begin() {
        gradient = new Entity(0, 0, new Backdrop("graphics/gradient.png"));
        gradient.layer = 100;
        add(gradient);

        addGraphic(new Image("graphics/mainmenu.png"));
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();

        controllerConnected = new Spritemap(
            "graphics/controllerconnected.png", 412, 41
        );
        controllerConnected.add("nocontroller", [0]);
        controllerConnected.add("controller", [1]);
        add(new Entity(30, 315, controllerConnected));
        music = new Sfx("audio/mainmenu.wav");
        music.loop();
    }

    public override function update() {
        controllerConnected.play(
            Main.gamepad != null ? "controller" : "nocontroller"
        );
        if(Main.inputPressed("jump") || Main.inputPressed("act")) {
            curtain.fadeOut();
            var resetTimer = new Alarm(1, TweenType.OneShot);
                resetTimer.onComplete.bind(function() {
                    music.stop();
                    clearTweens();
                    GameScene.depth = 1;
                    Tutorial.messageNum = 1;
                    HXP.scene = new GameScene();
                });
            addTween(resetTimer, true);
        }

        gradient.y -= GRADIENT_SCROLL_SPEED * Main.getDelta();
        if(gradient.y > 1200) {
            gradient.y -= 1200;
        }

        super.update();
    }
}
