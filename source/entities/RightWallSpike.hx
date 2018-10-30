package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class RightWallSpike extends MemoryEntity {
    public static inline var ACTIVATE_DELAY = 0.3;
    public static inline var DEACTIVATE_DELAY = 2;

    public var isActive(default, null):Bool;
    private var sprite:Spritemap;
    private var base:Image;
    private var activateTimer:Alarm;
    private var deactivateTimer:Alarm;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx([
            "spikewarning", "spikeactivate", "spikedeactivate"
        ]);
        type = "rightwallspike";
        sprite = new Spritemap("graphics/rightwallspikes.png", 18, 16);
        setHitbox(18, 16);
        sprite.add("idle", [2]);
        sprite.add("activate", [1, 0], 24, false);
        sprite.add("deactivate", [0, 1, 2], 12, false);
        sprite.play("idle");
        sprite.x = -2;
        setGraphic(sprite);
        base = new Image("graphics/spikebase.png");
        base.x = base.width;
        addGraphic(base);
        activateTimer = new Alarm(ACTIVATE_DELAY, TweenType.Persist);
        activateTimer.onComplete.bind(function() {
            activate();
        });
        addTween(activateTimer);
        deactivateTimer = new Alarm(DEACTIVATE_DELAY, TweenType.Persist);
        deactivateTimer.onComplete.bind(function() {
            deactivate();
        });
        addTween(deactivateTimer);
        isActive = false;
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        if(
            collideWith(player, x, y) != null
            && player.isOnWall()
            && !isActive
            && !activateTimer.active
        ) {
            activateTimer.start();
            MemoryEntity.allSfx["spikewarning"].play();
        }
    }

    private function activate() {
        deactivateTimer.start();
        isActive = true;
        sprite.play("activate");
        MemoryEntity.allSfx["spikeactivate"].play();
    }

    private function deactivate() {
        isActive = false;
        sprite.play("deactivate");
        MemoryEntity.allSfx["spikedeactivate"].play();
    }
}


