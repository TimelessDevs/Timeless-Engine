package mobile.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.ClientPrefs;
import mobile.backend.SwipeUtil;
import mobile.backend.TouchUtil;
import mobile.objects.GridButtons;
import mobile.objects.grid.GridTile;

class CustState extends MusicBeatState
{
	var bgAsset:FlxSprite;
	var titleText:FlxText;
	var promptText:FlxText;

	var optDownscroll:FlxText;
	var optMiddlescroll:FlxText;
	var optNoteSkin:FlxText;
	var optNoteSplash:FlxText;

	var previewNotes:Array<FlxSprite> = [];
	var previewSplashes:Array<FlxSprite> = [];

	var noteSkinsList:Array<String> = ['Default'];
	var noteSplashesList:Array<String> = ['Psych'];

	var curSelectedMenu:Int = 0;
	var busy:Bool = false;

	var skinIndex:Int = 0;
	var splashIndex:Int = 0;

	override function create()
	{
		super.create();

		scanModDirectories();

		skinIndex = Math.round(Math.max(0, noteSkinsList.indexOf(ClientPrefs.data.noteSkin)));
		splashIndex = Math.round(Math.max(0, noteSplashesList.indexOf(ClientPrefs.data.splashSkin)));

		bgAsset = new FlxSprite().loadGraphic(Paths.image('menubackgrounds/menu_desat'));
		bgAsset.color = 0xFF5E3A9C;
		bgAsset.antialiasing = ClientPrefs.data.antialiasing;
		add(bgAsset);

		titleText = new FlxText(40, 40, FlxG.width - 80, "UI & NOTE CUSTOMIZER", 48);
		titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
		titleText.bold = true;
		titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(titleText);

		optDownscroll = createOptionText(120, "Downscroll: " + (ClientPrefs.data.downScroll ? "ENABLED" : "DISABLED"));
		optMiddlescroll = createOptionText(180, "Middlescroll: " + (ClientPrefs.data.middleScroll ? "ENABLED" : "DISABLED"));
		optNoteSkin = createOptionText(240, "Note Skin: " + ClientPrefs.data.noteSkin);
		optNoteSplash = createOptionText(300, "Splash Skin: " + ClientPrefs.data.splashSkin);

		promptText = new FlxText(0, FlxG.height - 60, FlxG.width, "UP/DOWN: Menu | LEFT/RIGHT: Change | ACCEPT: Save & Exit", 18);
		promptText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888899, CENTER);
		add(promptText);

		createLivePreviews();
		updateMenuSelection();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('FULL', 'A_B');
		#end
	}

	function createOptionText(yPos:Float, textStr:String):FlxText
	{
		var txt = new FlxText(60, yPos, FlxG.width - 120, textStr, 28);
		txt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT);
		txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(txt);
		return txt;
	}

	function scanModDirectories()
	{
		var checkPaths:Array<String> = [
			'images/noteSkins',
			'shared/images/noteSkins'
		];
		
		#if MODS_ALLOWED
		for (mod in sys.FileSystem.readDirectory('mods/')) {
			if (sys.FileSystem.isDirectory('mods/' + mod)) {
				checkPaths.push('mods/' + mod + '/images/noteSkins');
				checkPaths.push('mods/' + mod + '/images/noteSplash');
			}
		}
		checkPaths.push('mods/images/noteSkins');
		#end

		for (path in checkPaths) {
			try {
				if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
					for (file in sys.FileSystem.readDirectory(path)) {
						if (file.endsWith('.png') && !file.contains('pixel')) {
							var name = file.split('.')[0].replace('NOTE_assets', 'Default');
							if (path.contains('noteSplash') && !noteSplashesList.contains(name)) 
								noteSplashesList.push(name);
							else if (!path.contains('noteSplash') && !noteSkinsList.contains(name)) 
								noteSkinsList.push(name);
						}
					}
				}
			} catch(e:Dynamic) {}
		}
	}

	function createLivePreviews()
	{
		for (i in 0...4) {
			var note = new FlxSprite(FlxG.width * 0.6 + (i * 85), FlxG.height * 0.4);
			note.antialiasing = ClientPrefs.data.antialiasing;
			add(note);
			previewNotes.push(note);

			var splash = new FlxSprite(note.x - 40, note.y - 40);
			splash.antialiasing = ClientPrefs.data.antialiasing;
			splash.visible = false;
			add(splash);
			previewSplashes.push(splash);
		}
		refreshLiveGraphics();
	}

	function refreshLiveGraphics()
	{
		var curSkin = noteSkinsList[skinIndex];
		var curSplash = noteSplashesList[splashIndex];

		for (i in 0...4) {
			try {
				var suffix = (curSkin == 'Default') ? 'NOTE_assets' : curSkin;
				previewNotes[i].frames = Paths.getSparrowAtlas('noteSkins/' + suffix);
				var anims = ['purple0', 'blue0', 'green0', 'red0'];
				previewNotes[i].animation.addByPrefix('idle', anims[i], 24, true);
				previewNotes[i].animation.play('idle');
				previewNotes[i].scale.set(0.7, 0.7);
				previewNotes[i].updateHitbox();
			} catch(e:Dynamic) {}

			try {
				previewSplashes[i].frames = Paths.getSparrowAtlas('noteSplash/' + curSplash);
				previewSplashes[i].animation.addByPrefix('pop', 'note splash purple 1', 24, false);
				previewSplashes[i].scale.set(0.6, 0.6);
				previewSplashes[i].updateHitbox();
			} catch(e:Dynamic) {}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (busy) return;

		if (controls.UI_UP_P) changeMenuSelection(-1);
		if (controls.UI_DOWN_P) changeMenuSelection(1);

		var change = 0;
		if (controls.UI_LEFT_P || SwipeUtil.swipeLeft) change = -1;
		if (controls.UI_RIGHT_P || SwipeUtil.swipeRight) change = 1;

		if (change != 0) modifyOption(change);

		if (controls.ACCEPT) {
			applyAndExit();
		} else if (controls.BACK) {
			busy = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeMenuSelection(change:Int)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
		curSelectedMenu = FlxMath.wrap(curSelectedMenu + change, 0, 3);
		updateMenuSelection();
	}

	function updateMenuSelection()
	{
		var menuItems = [optDownscroll, optMiddlescroll, optNoteSkin, optNoteSplash];
		for (i in 0...menuItems.length) {
			menuItems[i].color = (i == curSelectedMenu) ? 0xFFF9CF51 : FlxColor.WHITE;
			menuItems[i].scale.set((i == curSelectedMenu) ? 1.05 : 1.0, (i == curSelectedMenu) ? 1.05 : 1.0);
		}
	}

	function modifyOption(change:Int)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
		switch (curSelectedMenu) {
			case 0:
				ClientPrefs.data.downScroll = !ClientPrefs.data.downScroll;
				optDownscroll.text = "Downscroll: " + (ClientPrefs.data.downScroll ? "ENABLED" : "DISABLED");
			case 1:
				ClientPrefs.data.middleScroll = !ClientPrefs.data.middleScroll;
				optMiddlescroll.text = "Middlescroll: " + (ClientPrefs.data.middleScroll ? "ENABLED" : "DISABLED");
			case 2:
				skinIndex = FlxMath.wrap(skinIndex + change, 0, noteSkinsList.length - 1);
				ClientPrefs.data.noteSkin = noteSkinsList[skinIndex];
				optNoteSkin.text = "Note Skin: " + ClientPrefs.data.noteSkin;
				refreshLiveGraphics();
				bounceNotesPreview();
			case 3:
				splashIndex = FlxMath.wrap(splashIndex + change, 0, noteSplashesList.length - 1);
				ClientPrefs.data.splashSkin = noteSplashesList[splashIndex];
				optNoteSplash.text = "Splash Skin: " + ClientPrefs.data.splashSkin;
				refreshLiveGraphics();
				playSplashPreview();
		}
	}

	function bounceNotesPreview()
	{
		for (note in previewNotes) {
			note.y -= 15;
			FlxTween.tween(note, {y: note.y + 15}, 0.25, {ease: FlxEase.bounceOut});
		}
	}

	function playSplashPreview()
	{
		for (splash in previewSplashes) {
			splash.visible = true;
			splash.alpha = 1;
			splash.animation.play('pop', true);
			FlxTween.tween(splash, {alpha: 0}, 0.3, {
				ease: FlxEase.quadIn,
				onComplete: function(_) { splash.visible = false; }
			});
		}
	}

	function applyAndExit()
	{
		busy = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		ClientPrefs.saveSettings();

		FlxG.camera.flash(0x33FFFFFF, 0.3);
		FlxTween.tween(bgAsset, {alpha: 0}, 0.4, {
			onComplete: function(_) {
				MusicBeatState.switchState(new MainMenuState());
			}
		});
	}
}