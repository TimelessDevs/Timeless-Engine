package mikolka.vslice.ui.title;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.components.crash.Logger;
import mikolka.vslice.ui.title.IntroSubstate;

import mikolka.vslice.ui.MainMenuState;
import shaders.ColorSwap;

import flixel.graphics.frames.FlxFrame;
import flixel.input.gamepad.FlxGamepad;
import StringTools as HaxeStringTools;

import states.editors.MenuEditorState.MenuLayoutIO;
import states.editors.MenuEditorState.MenuLayoutData;
import states.editors.MenuEditorState.MenuItemProps;
import states.editors.MenuEditorState.MenuFx;

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
	var musicBPM:Float = 104;
	private var sickBeats:Int = 0;

	var layoutData:MenuLayoutData;
	var layoutFromFile:Bool = false;
	var bgSpr:FlxSprite;
	var beatTargets:Array<{spr:FlxSprite, p:MenuItemProps, rx:Float, ry:Float, rest:String}> = [];
	var hideTargets:Array<FlxSprite> = [];
	var enterTargets:Array<{spr:FlxSprite, p:MenuItemProps}> = [];
	var lockEnterPulse:Bool = false;

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

		loadLayout();
		musicBPM = MenuLayoutIO.bpmOf(layoutData, musicBPM);
		Conductor.bpm = musicBPM;

		var logoProps:MenuItemProps = findItem('logo');
		var enterProps:MenuItemProps = findItem('enter');
		var itemScale:Float = layoutData.globalScale;

		logoBl = new FlxSprite(0, 40);
		logoBl.loadGraphic(Paths.image('titleLogo'));
		logoBl.antialiasing = VsliceOptions.ANTIALIASING;
		logoBl.scale.set(logoProps.scaleX * itemScale, logoProps.scaleY * itemScale);
		logoBl.updateHitbox();
		logoBl.setPosition(logoProps.x, logoProps.y);

		if (VsliceOptions.SHADERS)
		{
			swagShader = new ColorSwap();
			logoBl.shader = swagShader.shader;
		}

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(0, 0);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		var pressPrefix:String = MenuLayoutIO.hasText(enterProps.enterPrefix) ? HaxeStringTools.trim(enterProps.enterPrefix) : '';
		if (animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			if (pressPrefix == MenuFx.CLASSIC_PRESS)
				titleText.animation.addByPrefix('press', VsliceOptions.FLASHBANG ? "ENTER PRESSED" : "ENTER FREEZE", 24);
			else if (pressPrefix != '')
				titleText.animation.addByPrefix('press', pressPrefix, 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			if (pressPrefix != '')
				titleText.animation.addByPrefix('press', (pressPrefix == MenuFx.CLASSIC_PRESS) ? "ENTER PRESSED" : pressPrefix, 24);
		}
		titleText.animation.play('idle');
		MenuFx.setupAnims(titleText, enterProps, 'ENTER');
		titleText.scale.set(enterProps.scaleX * itemScale, enterProps.scaleY * itemScale);
		titleText.updateHitbox();
		titleText.setPosition(layoutFromFile ? enterProps.x : enterProps.x + cutoutSize, enterProps.y);

		if (swagShader != null)
			titleText.shader = swagShader.shader;

		logoBl.visible = logoProps.enabled != false;
		titleText.visible = enterProps.enabled != false;

		buildLayoutScene(logoProps, enterProps, itemScale);

		if (initialized)	
			skipIntro();
		else
		{
			openSubState(new IntroSubstate());
			initialized = true;
		}
	}

	function loadLayout()
	{
		layoutData = MenuLayoutIO.loadTitle();
		layoutFromFile = (layoutData != null);
		if (!layoutFromFile)
			layoutData = MenuLayoutIO.makeDefaultTitle();
	}

	function findItem(name:String):MenuItemProps
	{
		for (it in layoutData.items)
			if (it.name == name)
				return it;
		return MenuLayoutIO.makeDefaultTitle().items[name == 'logo' ? 0 : 1];
	}

	function buildLayoutScene(logoProps:MenuItemProps, enterProps:MenuItemProps, itemScale:Float)
	{
		if (layoutFromFile && MenuLayoutIO.hasText(layoutData.bgImage))
		{
			var b = new FlxSprite();
			if (MenuFx.applyBackground(b, layoutData, false, 1.0))
			{
				bgSpr = b;
				bgSpr.alpha = layoutData.backgroundAlpha;
				bgSpr.scrollFactor.set();
				add(bgSpr);
			}
			else
				b.destroy();
		}

		var front:Array<FlxSprite> = [];
		for (p in layoutData.decor)
		{
			var spr = MenuFx.makeDecor(p);
			MenuFx.place(spr, p);
			if (p.front)
				front.push(spr);
			else
				add(spr);
			if (p.beatAnim != 'none')
				beatTargets.push({spr: spr, p: p, rx: p.scaleX, ry: p.scaleY, rest: 'main'});
			if (p.hideOnEnter)
				hideTargets.push(spr);
			else if (MenuLayoutIO.hasText(p.enterPrefix))
				enterTargets.push({spr: spr, p: p});
		}

		var added:Array<FlxSprite> = [];
		for (it in layoutData.items)
		{
			var s:FlxSprite = (it.name == 'logo') ? logoBl : ((it.name == 'enter') ? titleText : null);
			if (s != null && added.indexOf(s) < 0)
			{
				add(s);
				added.push(s);
			}
		}
		for (s in [logoBl, titleText])
			if (added.indexOf(s) < 0)
				add(s);
		for (s in front)
			add(s);

		for (pair in [{spr: logoBl, p: logoProps, rest: ''}, {spr: titleText, p: enterProps, rest: 'idle'}])
		{
			if (pair.p.enabled == false)
				continue;
			if (pair.p.beatAnim != 'none')
				beatTargets.push({spr: pair.spr, p: pair.p, rx: pair.p.scaleX * itemScale, ry: pair.p.scaleY * itemScale, rest: pair.rest});
			if (pair.p.hideOnEnter)
				hideTargets.push(pair.spr);
		}
		lockEnterPulse = enterProps.hideOnEnter;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

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

		if (!pressedEnter && !(transitioning && lockEnterPulse))
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
			if (titleText.animation.exists('press'))
				titleText.animation.play('press');

			FlxG.camera.flash(VsliceOptions.FLASHBANG ? FlxColor.WHITE : 0x4CFFFFFF, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			backend.events.NotesEvent.triggerStandalone(this);

			if (logoBl != null)
			{
				remove(logoBl);
				insert(members.length, logoBl);
			}

			if (FlxG.sound.music != null) 
			{
				if (!FlxG.sound.music.playing) FlxG.sound.music.play();
				FlxG.sound.music.volume = 0.7;
			}
				
			if (titleMenuMusic != null) 
			{
				titleMenuMusic.volume = 0.0;
				if (titleMenuMusic.playing) titleMenuMusic.stop();
			}

			for (h in hideTargets)
				MenuFx.hide(h);
			if (bgSpr != null && layoutData.bgSparrow == true && MenuLayoutIO.hasText(layoutData.bgEnter))
				MenuFx.playOnce(bgSpr, 'enter', '');
			for (e in enterTargets)
				MenuFx.playEnterAnim(e.spr, e.p);

			if (logoBl != null) {
				flixel.tweens.FlxTween.cancelTweensOf(logoBl);
				flixel.tweens.FlxTween.cancelTweensOf(logoBl.scale);
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

		if (layoutFromFile && layoutData.bgSparrow == true && MenuLayoutIO.hasText(layoutData.bgBeat) && (!transitioning || !MenuLayoutIO.hasText(layoutData.bgEnter)))
			MenuFx.playOnce(bgSpr, 'beat', 'main');
		for (t in beatTargets)
			if (!transitioning || (t.p.beatAnim == 'sparrow' && !MenuLayoutIO.hasText(t.p.enterPrefix) && t.spr != logoBl))
				MenuFx.beat(t.spr, t.p, t.rx, t.ry, curBeat, t.rest);

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