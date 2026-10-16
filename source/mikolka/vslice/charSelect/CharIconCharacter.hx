package mikolka.vslice.charSelect;

import openfl.display.BitmapData;
import shaders.StrokeShader;

class CharIconCharacter extends CharIcon
{
	var strokeShader:StrokeShader;

	public function new(path:String)
	{
		super(0, 0, false);
		loadGraphic(Paths.image('freeplay/icons/' + path + 'pixel'));
		setGraphicSize(128, 128);
		updateHitbox();
		antialiasing = false;

		strokeShader = new StrokeShader();
	}
}