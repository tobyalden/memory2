package scenes;

import entities.*;
import haxepunk.*;

class MainScene extends Scene {
	override public function begin() {
        add(new Level(0, 0));
	}
}
