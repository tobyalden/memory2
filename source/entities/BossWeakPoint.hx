package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;

class BossWeakPoint extends MemoryEntity {
    private var sprite:Spritemap;
    private var boss:Boss;

    public function new(boss:Boss) {
        super(0, 0);
        this.boss = boss;
        type = "enemy";
        sprite = new Spritemap("graphics/bossweakpoint.png", 40, 40);
        sprite.add("idle", [0]);
        sprite.play("idle");
        setGraphic(sprite);
        setHitbox(40, 40);
        health = 3;
    }

    override public function update() {
        x = boss.centerX - width/2;
        y = boss.top - height;
        super.update();
    }

    override public function takeHit(arrow:Arrow) {
        super.takeHit(arrow);
    }

    override private function die() {
        boss.die();
        super.die();
    }
}


