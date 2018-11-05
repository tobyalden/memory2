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
    public static inline var SAVE_FILE_NAME = "memory.sav";
    public static inline var GRADIENT_SCROLL_SPEED = 6;
    public static inline var MENU_SPACING = 35;
    public static inline var CURSOR_PAUSE_TIME = 0.5;
    public static inline var BOB_AMOUNT = 0.25;
    public static inline var BOB_SPEED = 0.75;

    private static var hardModeUnlocked:Bool;
    private static var lastDailyAttempt:String;
    private static var lastDailyHardAttempt:String;

    private var curtain:Curtain;
    private var controllerConnected:Spritemap;
    private var gradient:Entity;
    private var menu:Array<Spritemap>;
    private var cursor:Entity;
    private var cursorPosition:Int;
    private var cursorPause:Alarm;
    private var bob:NumTween;

	override public function begin() {
        Main.music = new Sfx("audio/mainmenu.wav");
        trace('loading music');
        Main.music.loop();
        trace('looping music');
        Data.load(SAVE_FILE_NAME);
        hardModeUnlocked = Data.read("hardModeUnlocked", false);
        lastDailyAttempt = Data.read("lastDailyAttempt", "");
        lastDailyHardAttempt = Data.read("lastDailyHardAttempt", "");

        gradient = new Entity(0, 0, new Backdrop("graphics/gradient.png"));
        gradient.graphic.smooth = false;
        gradient.graphic.pixelSnapping = true;
        gradient.layer = 100;
        add(gradient);

        var mainMenu = new Image("graphics/mainmenu.png");
        mainMenu.smooth = false;
        mainMenu.pixelSnapping = true;
        addGraphic(mainMenu);
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
            startHard.pixelSnapping = true;
            dailyHard.add("idle", [3]);
            dailyHard.play("idle");
            if(lastDailyHardAttempt == getDailyStamp()) {
                dailyHard.alpha = 0.5;
            }
            menu.push(dailyHard);
        }
        var start = new Spritemap("graphics/menuselection.png", 412, 41);
        start.add("idle", [0]);
        start.play("idle");
        menu.push(start);
        var daily = new Spritemap("graphics/menuselection.png", 412, 41);
        daily.add("idle", [1]);
        daily.play("idle");
        if(lastDailyAttempt == getDailyStamp()) {
            daily.alpha = 0.5;
        }
        menu.push(daily);

        cursorPosition = 0;
        cursor = new Entity(13, 101, new Image("graphics/cursor.png"));
        cursor.graphic.pixelSnapping = true;
        cursor.graphic.smooth = false;
        add(cursor);

        cursorPause = new Alarm(CURSOR_PAUSE_TIME, TweenType.Persist);
        addTween(cursorPause);

        bob = new NumTween(TweenType.PingPong);
        bob.tween(-BOB_AMOUNT, BOB_AMOUNT, BOB_SPEED, Ease.sineInOut);
        addTween(bob, true);

        var count = 0;
        for(menuItem in menu) {
            menuItem.smooth = false;
            menuItem.pixelSnapping = true;
            addGraphic(menuItem, 0, 30, 100 + MENU_SPACING * count);
            count++;
        }

        controllerConnected = new Spritemap(
            "graphics/controllerconnected.png", 412, 41
        );
        controllerConnected.smooth = false;
        controllerConnected.pixelSnapping = true;
        controllerConnected.add("nocontroller", [0]);
        controllerConnected.add("controller", [1]);
        add(new Entity(30, 315, controllerConnected));
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
            if(hardModeUnlocked) {
                if(cursorPosition == 0) {
                    GameScene.easyMode = false;
                    Random.randomizeSeed();
                }
                else if(cursorPosition == 1) {
                    if(lastDailyHardAttempt == getDailyStamp()) {
                        super.update();
                        return;
                    }
                    GameScene.easyMode = false;
                    Random.randomSeed = getDailySeed();
                    lastDailyHardAttempt = getDailyStamp();
                    Data.write("lastDailyHardAttempt", lastDailyHardAttempt);
                    Data.save(SAVE_FILE_NAME);
                }
                else if(cursorPosition == 2) {
                    GameScene.easyMode = true;
                    Random.randomizeSeed();
                }
                else if(cursorPosition == 3) {
                    if(lastDailyAttempt == getDailyStamp()) {
                        super.update();
                        return;
                    }
                    GameScene.easyMode = true;
                    Random.randomSeed = getDailySeed();
                    lastDailyAttempt = getDailyStamp();
                    Data.write("lastDailyAttempt", lastDailyAttempt);
                    Data.save(SAVE_FILE_NAME);
                }
            }
            else {
                if(cursorPosition == 0) {
                    GameScene.easyMode = true;
                    Random.randomizeSeed();
                }
                else if(cursorPosition == 1) {
                    if(lastDailyAttempt == getDailyStamp()) {
                        super.update();
                        return;
                    }
                    GameScene.easyMode = true;
                    Random.randomSeed = getDailySeed();
                    lastDailyAttempt = getDailyStamp();
                    Data.write("lastDailyAttempt", lastDailyAttempt);
                    Data.save(SAVE_FILE_NAME);
                }
            }
            curtain.fadeOut();
            Main.music.stop();
            trace('stopping music');
            var resetTimer = new Alarm(1, TweenType.OneShot);
                resetTimer.onComplete.bind(function() {
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

    private function getDailySeed() {
        var today = Date.now();
        var dailySeed = (
            (today.getDay() * 32 + today.getMonth()) * 13
            + today.getFullYear()
        );
        if(!GameScene.easyMode) {
            dailySeed += 666;
        }
        return dailySeed;
    }

    private function getDailyStamp() {
        var today = Date.now();
        var dailyStamp = (
            '${today.getMonth()}-${today.getDay()}-${today.getFullYear()}'
        );
        return dailyStamp;
    }
}
