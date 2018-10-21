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

	override public function begin() {
        addGraphic(new Image("graphics/mainmenu.png"));
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();
    }

    public override function update() {
        if(Main.inputPressed("jump") || Main.inputPressed("act")) {
            curtain.fadeOut();
            var resetTimer = new Alarm(1, TweenType.OneShot);
                resetTimer.onComplete.bind(function() {
                    clearTweens();
                    HXP.scene = new GameScene();
                });
            addTween(resetTimer, true);
        }
        super.update();
    }
}
