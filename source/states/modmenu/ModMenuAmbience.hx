package states.modmenu;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxG;

class ModMenuAmbience extends FunkinSoundscape
{
	public static final EASTER_EGG_TIMER:Float = 180.0;
	public static final EASTER_EGG_PATH:String = Paths.sound('ui/mods/sounds/phantomarcade-trapped');

	var _easterEgg:Null<FunkinSound> = null;

	public function new(params:FunkinSoundscapeSettings)
	{
		super(params);
	}

	override function playRandomSound():Void
	{
		super.playRandomSound();

		if (_currentSFX != null)
		{
			@:privateAccess
			var index:Int = Std.int(soundList.indexOf(_currentSFX._label));
			var usedWeight:Float = weights[index];

			if (usedWeight <= 1)
			{
				soundList.splice(index, 1);
				weights.splice(index, 1);
			}
		}
	}

	override function onSoundFadeIn(tween:FlxTween):Void
	{
		FlxTimer.wait(EASTER_EGG_TIMER, () ->
		{
			_easterEgg = FunkinSound.playOnce(EASTER_EGG_PATH);
		});

		super.onSoundFadeIn(tween);
	}

	override public function destroy():Void
	{
		super.destroy();

		if (_easterEgg != null)
			_easterEgg.destroy();
	}
}
