package mikolka.vslice.charSelect;

import mikolka.funkin.FlxAtlasSprite;

class CharSelectPlayer extends FlxAtlasSprite 
{
	public function new(x:Float, y:Float)
	{
		super(x, y, null);

		onAnimationComplete.add(function(animLabel:String) {
			switch (animLabel)
			{
				case "slidein":
					playAnimation(hasAnimation("slidein idle point") ? "slidein idle point" : "idle", true);
				case "deselect":
					playAnimation("deselect loop start", true, false, true);
				case "slidein idle point" | "cannot select Label" | "unlock":
					playAnimation("idle", true);
			}
		});
	}

	public function onBeatHit():Void
	{
		if (getCurrentAnimation() == "idle") playAnimation("idle", true);
	}

	public function updatePosition(str:String)
	{
		switch (str)
		{
			case "bf" | "pico": x = y = 0;
		}
	}

	public function switchChar(str:String)
	{
		loadAtlas("charSelect/" + str + "Chill");
		playAnimation("slidein", true);
		updateHitbox();
		updatePosition(str);
	}
}