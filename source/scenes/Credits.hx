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

    private var creditsScroll:Entity;

	override public function begin() {
        creditsScroll = new Entity(0, 0, new Image("graphics/credits.png"));
        creditsScroll.y += HXP.height;
        add(creditsScroll);
    }

    public override function update() {
        creditsScroll.y -= CREDITS_SCROLL_SPEED * Main.getDelta();
        super.update();
    }
}
