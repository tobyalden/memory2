package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class FloorSpike extends MemoryEntity {
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
        type = "spike";
        sprite = new Spritemap("graphics/floorspikes.png", 16, 18);
        setHitbox(16, 18);
        sprite.add("idle", [0]);
        sprite.add("activate", [1, 2], 24, false);
        sprite.add("deactivate", [2, 1, 0], 12, false);
        sprite.play("idle");
        setGraphic(sprite);
        base = new Image("graphics/spikebase.png");
        base.y = sprite.height;
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
            && player.isOnGround()
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
