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

class Credits extends Scene {
    public static inline var CREDITS_SCROLL_SPEED = 0.65;

    private var creditsScroll:MemoryEntity;
    private var unlockDisplay:MemoryEntity;
    private var unlockSfx:Sfx;
    private var isDoneScrolling:Bool;
    private var curtain:Curtain;

	override public function begin() {
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();

        creditsScroll = new MemoryEntity(0, 0);
        var creditsScrollImage = new Image("graphics/credits.png");
        creditsScroll.setGraphic(creditsScrollImage);
        creditsScroll.y += HXP.height;
        add(creditsScroll);

        unlockDisplay = new MemoryEntity(0, 0);
        var unlockDisplayImage = new Image("graphics/unlockdisplay1.png");
        unlockDisplay.setGraphic(unlockDisplayImage);
        unlockDisplay.visible = false;
        add(unlockDisplay);

        Main.music = new Sfx("audio/credits.wav");
        Main.music.play();

        unlockSfx = new Sfx("audio/unlockmode.wav");
        isDoneScrolling = false;
    }

    public override function update() {
        creditsScroll.y -= CREDITS_SCROLL_SPEED * Main.getDelta();
        trace(creditsScroll.y);
        if(creditsScroll.y < -1700) {
            if(!isDoneScrolling) {
                Main.music.stop();
                unlockDisplay.visible = true;
                unlockSfx.play();
                fadeToMenu(5);
            }
            isDoneScrolling = true;
        }
        super.update();
    }

    private function fadeToMenu(delay:Float) {
        var fadeTimer = new Alarm(delay, TweenType.OneShot);
        fadeTimer.onComplete.bind(function() {
            curtain.fadeOut();
            var toMenuTimer = new Alarm(1, TweenType.OneShot);
            toMenuTimer.onComplete.bind(function() {
                HXP.scene = new MainMenu();
            });
            addTween(toMenuTimer, true);
        });
        addTween(fadeTimer, true);
    }
}
