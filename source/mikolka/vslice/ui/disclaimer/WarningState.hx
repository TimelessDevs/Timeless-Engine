package mikolka.vslice.ui.disclaimer;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.transition.FlxTransitionableState;

class WarningState extends MusicBeatState
{
	public var leftState:Bool = false;

	var warnText:FlxText;
	var text:String;
	var onExit:() -> Void;
	var onAccept:() -> Void;
	var nextState:FlxState;

	public function new(text:String, onAccept:() -> Void, onExit:() -> Void, nextState:FlxState)
	{
		this.text = text;
		this.onExit = onExit;
		this.onAccept = onAccept;
		this.nextState = nextState;
		super();
	}

	override function create()
	{
		controls.isInSubstate = false;
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width, text, 32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		warnText.alpha = 0;
		warnText.scale.set(0.8, 0.8);
		FlxTween.tween(warnText, {alpha: 1, "scale.x": 1.0, "scale.y": 1.0}, 0.4, {ease: FlxEase.backOut});

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'A_B');
		#end
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back)
			{
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				
				if (!back)
				{
					if (onAccept != null) onAccept();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					
					FlxTween.tween(warnText.scale, {x: 1.1, y: 1.1}, 0.15, {ease: FlxEase.quadOut, onComplete: function(_) {
						FlxTween.tween(warnText, {alpha: 0, "scale.x": 0.7, "scale.y": 0.7}, 0.3, {
							ease: FlxEase.backIn,
							onComplete: function(_) {
								MusicBeatState.switchState(nextState);
							}
						});
					}});
				}
				else
				{
					if (onExit != null) onExit();
					FlxG.sound.play(Paths.sound('cancelMenu'));
					
					FlxTween.tween(warnText, {alpha: 0, y: warnText.y + 100}, 0.35, {
						ease: FlxEase.backIn,
						onComplete: function(_) {
							MusicBeatState.switchState(nextState);
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}