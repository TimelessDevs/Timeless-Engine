package mikolka.vslice.ui.title;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.components.crash.Logger;
import mikolka.vslice.ui.title.IntroSubstate;

import mikolka.vslice.ui.MainMenuState;
import shaders.ColorSwap;

import flixel.graphics.frames.FlxFrame;
import flixel.input.gamepad.FlxGamepad;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var closedState:Bool = false;

	var enterTimer:FlxTimer;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	public static var titleMenuMusic:FlxSound = null;
	
	var danceLeft:Bool = false;
	var transitioning:Bool = false;
	var skippedIntro:Bool = false;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var titleTimer:Float = 0;
	var musicBPM:Float = 102;
	private var sickBeats:Int = 0;

	override public function create():Void
	{
		CacheSystem.clearStoredMemory();
		super.create();
		CacheSystem.clearUnusedMemory();
		startIntro();
	}

	function startIntro()
	{
		#if sys
		Logger.enforceLogSettings = true;
		#end

		persistentUpdate = true;
		@:privateAccess
		if (!initialized && FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			
			titleMenuMusic = new FlxSound();
			titleMenuMusic.loadEmbedded(Paths.music('titleMenu'), true, false);
			titleMenuMusic.volume = 0.7;
			titleMenuMusic.play();
			FlxG.sound.list.add(titleMenuMusic);
			
			titleMenuMusic.time = FlxG.sound.music.time;
		}


		var cutoutSize:Float = MobileScaleMode.gameCutoutSize.x / 2.5;
		Conductor.bpm = musicBPM;

		logoBl = new FlxSprite(0, 40);
		logoBl.loadGraphic(Paths.image('logoBumpin'));
		logoBl.antialiasing = VsliceOptions.ANTIALIASING;
		logoBl.updateHitbox();
		
		logoBl.origin.set(logoBl.width * 0.5, logoBl.height * 0.5);
		logoBl.screenCenter(flixel.util.FlxAxes.X);

		if (VsliceOptions.SHADERS)
		{
			swagShader = new ColorSwap();
			logoBl.shader = swagShader.shader;
		}

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(100 + cutoutSize, 576);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', VsliceOptions.FLASHBANG ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();

		if (swagShader != null)
			titleText.shader = swagShader.shader;

		add(logoBl);
		add(titleText);

		if (initialized)
			skipIntro();
		else
		{
			openSubState(new IntroSubstate());
			initialized = true;
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (logoBl != null && !transitioning) {
			var snapSpeed:Float = FlxMath.bound(elapsed * 15.0, 0, 1);
			var snapAngleSpeed:Float = FlxMath.bound(elapsed * 10.0, 0, 1);

			logoBl.scale.x += (1.0 - logoBl.scale.x) * snapSpeed;
			logoBl.scale.y += (1.0 - logoBl.scale.y) * snapSpeed;
			logoBl.angle += (0.0 - logoBl.angle) * snapAngleSpeed;
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || (TouchUtil.justReleased && !SwipeUtil.swipeAny);
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null && gamepad.justPressed.START)
			pressedEnter = true;

		if (enterTimer != null && pressedEnter)
		{
			enterTimer.cancel();
			enterTimer.onComplete(enterTimer);
			enterTimer = null;
		}

		if (!pressedEnter)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;

			var timer:Float = titleTimer >= 1 ? (-titleTimer) + 2 : titleTimer;
			timer = FlxEase.quadInOut(timer);

			titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
			titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
		}
		else if (!transitioning && initialized && skippedIntro)
		{
			titleText.color = FlxColor.WHITE;
			titleText.alpha = 1;
			titleText.animation.play('press');

			FlxG.camera.flash(VsliceOptions.FLASHBANG ? FlxColor.WHITE : 0x4CFFFFFF, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			if (FlxG.sound.music != null) FlxG.sound.music.fadeIn(1.0, 0.0, 0.7);
			if (titleMenuMusic != null) titleMenuMusic.fadeOut(1.0, 0.0);

			if (logoBl != null) {
				var randomExitTilt:Float = FlxG.random.float(25, 25) * FlxG.random.sign();

				flixel.tweens.FlxTween.tween(logoBl, {y: logoBl.y - 110, angle: logoBl.angle + (randomExitTilt * 0.3)}, 0.18, {
					ease: flixel.tweens.FlxEase.quadOut,
					onComplete: function(twn:flixel.tweens.FlxTween) {
						flixel.tweens.FlxTween.tween(logoBl, {y: FlxG.height + 650, angle: logoBl.angle + randomExitTilt}, 0.48, {
							ease: flixel.tweens.FlxEase.quadIn
						});
					}
				});
				FlxG.camera.zoom += 0.04;
			}

			transitioning = true;
			enterTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				FlxTransitionableState.skipNextTransIn = true;
				MusicBeatState.switchState(new MainMenuState());
				closedState = true;
			});
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();

		#if desktop
		if (controls.BACK) openfl.Lib.application.window.close();
		#end

		super.update(elapsed);
	}

	override function beatHit()
	{

		super.beatHit();

		if (logoBl != null) {
			logoBl.scale.set(0.9, 0.9);
			danceLeft = !danceLeft;
			
			var randomBaseAngle:Float = FlxG.random.float(7.5, 11.5);
			logoBl.angle = danceLeft ? -randomBaseAngle : randomBaseAngle;
		}

		if (!closedState)
		{
			sickBeats++;
			if (sickBeats == 1)
			{
				if (titleMenuMusic != null && !titleMenuMusic.playing) titleMenuMusic.play();
			}

			else if (sickBeats == 17)
			{
				skipIntro();
			}
		}
	}

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			closeSubState();
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}