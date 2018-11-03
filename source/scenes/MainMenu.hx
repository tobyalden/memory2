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
    public static inline var MENU_SPACING = 35;
    public static inline var CURSOR_PAUSE_TIME = 0.5;
    public static inline var BOB_AMOUNT = 0.25;
    public static inline var BOB_SPEED = 0.75;

    private static var hardModeUnlocked:Bool = true;

    private var curtain:Curtain;
    private var controllerConnected:Spritemap;
    private var gradient:Entity;
    private var music:Sfx;
    private var menu:Array<Spritemap>;
    private var cursor:Entity;
    private var cursorPosition:Int;
    private var cursorPause:Alarm;
    private var bob:NumTween;

	override public function begin() {
        gradient = new Entity(0, 0, new Backdrop("graphics/gradient.png"));
        gradient.layer = 100;
        add(gradient);

        addGraphic(new Image("graphics/mainmenu.png"));
        curtain = new Curtain(0, 0);
        add(curtain);
        curtain.fadeIn();

        menu = new Array<Spritemap>();
        if(hardModeUnlocked) {
            var startHard = new Spritemap("graphics/menuselection.png", 412, 41);
            startHard.add("idle", [2]);
            startHard.play("idle");
            menu.push(startHard);
            var dailyHard = new Spritemap("graphics/menuselection.png", 412, 41);
            dailyHard.add("idle", [3]);
            dailyHard.play("idle");
            menu.push(dailyHard);
        }
        var start = new Spritemap("graphics/menuselection.png", 412, 41);
        start.add("idle", [0]);
        start.play("idle");
        menu.push(start);
        var daily = new Spritemap("graphics/menuselection.png", 412, 41);
        daily.add("idle", [1]);
        daily.play("idle");
        menu.push(daily);

        cursorPosition = 0;
        cursor = new Entity(15, 101, new Image("graphics/cursor.png"));
        add(cursor);

        cursorPause = new Alarm(CURSOR_PAUSE_TIME, TweenType.Persist);
        addTween(cursorPause);

        bob = new NumTween(TweenType.PingPong);
        bob.tween(-BOB_AMOUNT, BOB_AMOUNT, BOB_SPEED, Ease.sineInOut);
        addTween(bob, true);

        var count = 0;
        for(menuItem in menu) {
            addGraphic(menuItem, 0, 30, 100 + MENU_SPACING * count);
            count++;
        }

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
        if(Main.inputCheck("up")) {
            if(!cursorPause.active) {
                cursorPosition--;
                if(cursorPosition < 0) {
                    cursorPosition = menu.length - 1;
                }
                cursorPause.start();
            }
        }
        else if(Main.inputCheck("down")) {
            if(!cursorPause.active) {
                cursorPosition++;
                if(cursorPosition >= menu.length) {
                    cursorPosition = 0;
                }
                cursorPause.start();
            }
        }
        else {
            cursorPause.cancel();
        }
        cursor.y = 101 + cursorPosition * MENU_SPACING;
        cursor.x += bob.value;

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
