package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import scenes.*;

class Letterbox extends MemoryEntity
{
    private var letterboxTop:ColoredRect;
    private var letterboxBottom:ColoredRect;
    private var letterboxLeft:ColoredRect;
    private var letterboxRight:ColoredRect;

    public function new() {
        super(0, 0);
        letterboxTop = new ColoredRect(0, 0, 0x5ff442);
        letterboxBottom = new ColoredRect(0, 0, 0xd62fac);
        letterboxLeft = new ColoredRect(0, 0, 0xf4f142);
        letterboxRight = new ColoredRect(0, 0, 0xaa00ff);
        addGraphic(letterboxTop);
        addGraphic(letterboxBottom);
        addGraphic(letterboxLeft);
        addGraphic(letterboxRight);
        layer = -999999;
    }

    public function updatePosition() {
        var player = scene.getInstance("player");
        if(player == null) {
            x = scene.camera.x + HXP.width / 2;
            y = scene.camera.y + HXP.height / 2;
        }
        else {
            x = player.centerX;
            y = player.centerY;
        }

        letterboxTop.width = HXP.width;
        letterboxTop.height = (HXP.height - Main.GAME_HEIGHT) / 2 + 50;
        letterboxTop.x = -HXP.width / 2;
        letterboxTop.y = -(Main.GAME_HEIGHT / 2 + letterboxTop.height) - 1;

        letterboxBottom.width = HXP.width;
        letterboxBottom.height = (HXP.height - Main.GAME_HEIGHT) / 2 + 50;
        letterboxBottom.x = -HXP.width / 2;
        letterboxBottom.y = Main.GAME_HEIGHT / 2 + 1;

        letterboxLeft.width = (HXP.width - Main.GAME_WIDTH) / 2 + 50;
        letterboxLeft.height = HXP.height;
        letterboxLeft.x = -(Main.GAME_WIDTH / 2 + letterboxLeft.width) - 1;
        letterboxLeft.y = -HXP.height / 2;

        letterboxRight.width = (HXP.width - Main.GAME_WIDTH) / 2 + 50;
        letterboxRight.height = HXP.height;
        letterboxRight.x = Main.GAME_WIDTH / 2 + 1;
        letterboxRight.y = -HXP.height / 2;

        super.update();
    }
}


