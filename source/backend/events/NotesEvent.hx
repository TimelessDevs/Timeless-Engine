package backend.events;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxState;

class NotesEvent
{
	private static final SIZES:Array<Float> = [1.0, 1.3, 0.7, 0.8, 0.6, 1.5];
	private static final NOTE_FILES:Array<String> = ['noteLeft', 'noteDown', 'noteUp', 'noteRight'];

	public static function trigger():Void
	{
		var state = states.PlayState.instance;
		if (state == null) return;
		
		var isLowQuality:Bool = ClientPrefs.data.lowQuality;
		var loops:Int = isLowQuality ? 6 : 9;
		
		for (i in 1...loops + 1)
		{
			triggerSingleDirection('leftBool' + i);
			triggerSingleDirection('downBool' + i);
			triggerSingleDirection('upBool' + i);
			triggerSingleDirection('rightBool' + i);
		}
	}

	private static function triggerSingleDirection(tag:String):Void
	{
		var state = states.PlayState.instance;
		if (state == null) return;

		var sprite:FlxSprite = cast state.variables.get(tag);
		if (sprite == null) return;

		var randomSize:Float = SIZES[FlxG.random.int(0, SIZES.length - 1)];
		sprite.alpha = 1.0;
		sprite.x = FlxG.random.int(-1000, 2000);
		sprite.y = 1100;
		sprite.scale.set(randomSize, randomSize);

		FlxTween.cancelTweensOf(sprite);
		FlxTween.tween(sprite, {y: FlxG.random.int(400, 1000)}, 0.8, {ease: FlxEase.expoOut});
		FlxTween.tween(sprite, {alpha: 0.0}, 0.8, {ease: FlxEase.expoOut});
		FlxTween.tween(sprite, {angle: FlxG.random.int(100, 360)}, 0.8, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween) { sprite.alpha = 0.0; }
		});
	}

	public static function triggerStandalone(targetState:FlxState):Void
	{
		if (targetState == null) return;

		var isLowQuality:Bool = ClientPrefs.data.lowQuality;
		var totalNotes:Int = isLowQuality ? 12 : 24;

		for (i in 0...totalNotes)
		{
			var noteDirIndex = FlxG.random.int(0, 3);
			var note:FlxSprite = new FlxSprite();
			
			var imagePath:String = 'events/' + NOTE_FILES[noteDirIndex];
			note.loadGraphic(Paths.image(imagePath));
			
			note.antialiasing = ClientPrefs.data.antialiasing;
			
			var randomSize:Float = SIZES[FlxG.random.int(0, SIZES.length - 1)] * 1.1;
			note.scale.set(randomSize, randomSize);
			note.updateHitbox();

			note.x = FlxG.random.int(-100, FlxG.width + 100);
			note.y = FlxG.height + 100;

			note.alpha = 0.65;

			targetState.add(note);

			FlxTween.tween(note, {
				x: note.x + FlxG.random.int(-200, 200),
				y: FlxG.random.int(100, Std.int(FlxG.height * 0.6))
			}, 0.85, {ease: FlxEase.expoOut});

			FlxTween.tween(note, {alpha: 0.0, angle: FlxG.random.int(180, 540)}, 0.85, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween) {
					note.kill();
					targetState.remove(note);
					note.destroy();
				}
			});
		}
	}
}