package states.modmenu;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import backend.Paths;

class ModMenuSparks extends FlxSprite
{
	public static final SHOCK_SOUND_END_TIME:Float = (83 / 24) * 1000;

	var _timer:FlxTimer = new FlxTimer();
	var _previousAnimation:String = '';
	var _randomAnimations:Array<String> = [];
	var shockSound:Null<FunkinSound> = null;

	public function new()
	{
		super();

		this.visible = false;

		loadTextureAtlas('ui/mods/sparks', {
			applyStageMatrix: true
		});

		loadAnimations();
		startTimer();

		animation.onFinish.add((name:String) ->
		{
			if (_randomAnimations.contains(name))
			{
				startTimer();
			}

			this.visible = false;
		});
	}

	public function startElectrocution():Void
	{
		if (_timer.active)
			_timer.cancel();

		this.visible = true;

		animation.play('electrocution');

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	public function endElectrocution():Void
	{
		animation.play('end');

		if (shockSound != null)
		{
			shockSound.time = SHOCK_SOUND_END_TIME;
		}
	}

	public function playRandomAnimation():Void
	{
		var randomAnimation:String = getRandomAnimation();

		this.visible = true;
		animation.play(randomAnimation);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		_previousAnimation = randomAnimation;
	}

	function startTimer():Void
	{
		_timer.start(FlxG.random.int(6, 20), (tmr:FlxTimer) ->
		{
			playRandomAnimation();
		});
	}

	function getRandomAnimation():String
	{
		var randomAnimation:String = _randomAnimations[FlxG.random.int(0, _randomAnimations.length - 1)];

		if (randomAnimation == _previousAnimation)
			return getRandomAnimation();

		return randomAnimation;
	}

	function loadAnimations():Void
	{
		for (i in 1...12)
		{
			anim.addByFrameLabel('$i', 'spark $i', 24, false);

			_randomAnimations.push('$i');
		}

		anim.addByFrameLabel('electrocution', 'electrocution', 24);
		anim.addByFrameLabel('end', 'end', 24, false);
	}

	override public function destroy():Void
	{
		super.destroy();

		if (_timer.active)
			_timer.cancel();
		if (shockSound != null)
			shockSound.destroy();
	}
}
