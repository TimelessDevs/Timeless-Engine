package states.editors;

import mikolka.vslice.ui.obj.ModSelector;
import objects.AlphabetMenu;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.editors.CharSelectEditor;
import mikolka.editors.StickerTest;
import mikolka.compatibility.VsliceOptions;
import backend.WeekData;
import mikolka.vslice.results.ResultState;
import objects.Character;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Chart Editor', 
		'Character Editor', 
		'Stage Editor',  
		'Music Player',  
		'Main Menu Editor', 
		'Week Editor',
		'shit',
		'Test stickers',
		'Menu Character Editor', 
		'Dialogue Editor', 
		'Dialogue Portrait Editor',
		'Player editor',
		#if PROFILE_BUILD
		'Crash the game',
		'Usermess the game',
		#end
		'Note Splash Editor', 
		'Result Preview Menu'
	];
	
	var menu:AlphabetMenu;
	var sidebarBg:FlxSprite;
	var infoText:FlxText;
	var categoryLabel:FlxText;
	private var modDir:ModSelector;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		bg.screenCenter();
		bg.color = 0xFF141A16;
		add(bg);

		sidebarBg = new FlxSprite(0, 0).makeGraphic(420, FlxG.height, 0xDD0D0D11);
		sidebarBg.scrollFactor.set();
		sidebarBg.x = -sidebarBg.width;
		add(sidebarBg);

		categoryLabel = new FlxText(30, 40, 360, "TIMELESS DEVELOPMENT", 24);
		categoryLabel.setFormat(Paths.font("vcr.ttf"), 24, 0xFF4CAF50, LEFT);
		categoryLabel.bold = true;
		categoryLabel.scrollFactor.set();
		categoryLabel.alpha = 0;
		add(categoryLabel);

		infoText = new FlxText(30, 90, 360, "Use UI_UP / UI_DOWN to browse through system engines.\n\nPress ACCEPT to initialize core editor modules.", 18);
		infoText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF8E8E9F, LEFT);
		infoText.scrollFactor.set();
		infoText.alpha = 0;
		add(infoText);

		menu = new AlphabetMenu(options);
		menu.onSelect.add(onAccept);
		add(menu);

		#if MODS_ALLOWED
		modDir = new ModSelector(null);
		modDir.allowInput = true;
		modDir.x = 30;
		modDir.y = FlxG.height - 150;
		add(modDir);

		if (controls.mobileC)
		{
			var btnY = FlxG.height - 80;
			var prevBtn = new PsychUIButton(30, btnY, "<=", () -> modDir.changeDirectory(-1), 170, 50);
			var nextBtn = new PsychUIButton(220, btnY, "=>", () -> modDir.changeDirectory(1), 170, 50);
			
			for (btn in [prevBtn, nextBtn]) {
				btn.text.size = 24;
				btn.text.y -= 5;
				btn.normalStyle.bgColor = 0xEA2A2A35;
				btn.scrollFactor.set();
				add(btn);
			}
		}
		#end

		FlxG.mouse.visible = false;
		
		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'B_TOP');
		#end

		FlxTween.tween(sidebarBg, {x: 0}, 0.5, {
			ease: FlxEase.expoOut,
			onComplete: function(_) {
				FlxTween.tween(categoryLabel, {alpha: 1}, 0.2);
				FlxTween.tween(infoText, {alpha: 1}, 0.2);
			}
		});

		super.create();
		
		for (item in menu.members) {
			if (item != null && Std.isOfType(item, flixel.FlxSprite)) {
				cast(item, flixel.FlxSprite).x += 420;
			}
		}
	}

	override function update(elapsed:Float)
	{
		#if MODS_ALLOWED
		if (controls.UI_LEFT_P) modDir.changeDirectory(-1);
		if (controls.UI_RIGHT_P) modDir.changeDirectory(1);
		#end

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	function onAccept(option:String)
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		switch (option)
		{
			case 'Chart Editor':
				LoadingState.loadAndSwitchState(new ChartingState(), false);
			case 'Character Editor':
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
			case 'Stage Editor':
				LoadingState.loadAndSwitchState(new StageEditorState());
			case 'Music Player':
				LoadingState.loadAndSwitchState(new MusicPlayerState());
			case 'Main Menu Editor':
				MusicBeatState.switchState(new MenuEditorState());
			case 'Week Editor':
				MusicBeatState.switchState(new WeekEditorState());
			case 'shit':
				MusicBeatState.switchState(new CustState());
			case 'Menu Character Editor':
				MusicBeatState.switchState(new MenuCharacterEditorState());
			case 'Dialogue Editor':
				LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
			case 'Dialogue Portrait Editor':
				LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
			case 'Note Splash Editor':
				MusicBeatState.switchState(new NoteSplashEditorState());
			case 'Test stickers':
				MusicBeatState.switchState(new StickerTest());
			case 'Player editor':
				MusicBeatState.switchState(new CharSelectEditor());
			#if PROFILE_BUILD
			case 'Crash the game':
				untyped __cpp__("throw \"This is a native C++ exception!\";");
			case 'Usermess the game':
				UserErrorSubstate.makeMessage("The devs are too stupid and they write way too long errors", "Skill issue : :/ ");
			#end
			case 'Result Preview Menu':
				MusicBeatState.switchState(new ResultPreviewMenu());
		}
		FlxG.sound.music.volume = 0;
	}
}