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
    private var showUnlock:Bool;
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
        var unlockDisplayImage;
        if(GameScene.difficulty == GameScene.PLUSPLUS) {
            unlockDisplayImage = new Image("graphics/unlockdisplay3.png");
        }
        else if(GameScene.difficulty == GameScene.PLUS) {
            unlockDisplayImage = new Image("graphics/unlockdisplay2.png");
        }
        else {
            unlockDisplayImage = new Image("graphics/unlockdisplay1.png");
        }
        unlockDisplay.setGraphic(unlockDisplayImage);
        unlockDisplay.visible = false;
        add(unlockDisplay);

        Main.music = new Sfx("audio/credits.ogg");
        Main.music.play();

        unlockSfx = new Sfx("audio/unlockmode.wav");
        isDoneScrolling = false;

        Data.load(MainMenu.SAVE_FILE_NAME);
        var plusModeUnlocked = Data.read("plusModeUnlocked", false);
        var plusPlusModeUnlocked = Data.read("plusPlusModeUnlocked", false);
        if(
            GameScene.difficulty == GameScene.PLUSPLUS
            || GameScene.difficulty == GameScene.PLUS && !plusPlusModeUnlocked
            || GameScene.difficulty == GameScene.NORMAL && !plusModeUnlocked
        ) {
            showUnlock = true;
        }
        else {
            showUnlock = false;
        }

        // Unlock difficulty modes
        if(GameScene.difficulty == GameScene.NORMAL) {
            Data.write("plusModeUnlocked", true);
        }
        else if(GameScene.difficulty == GameScene.PLUS) {
            Data.write("plusPlusModeUnlocked", true);
        }
        Data.save(MainMenu.SAVE_FILE_NAME);
    }

    public override function update() {
        creditsScroll.y -= CREDITS_SCROLL_SPEED * Main.getDelta();
        if(creditsScroll.y < -1700) {
            if(!isDoneScrolling) {
                Main.music.stop();
                if(showUnlock) {
                    unlockDisplay.visible = true;
                    unlockSfx.play();
                    fadeToMenu(5);
                }
                else {
                    fadeToMenu(1);
                }
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
