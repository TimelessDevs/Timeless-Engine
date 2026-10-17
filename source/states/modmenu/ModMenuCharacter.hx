package states.modmenu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import backend.Paths;
import backend.Mods;
import backend.ClientPrefs;

enum abstract CharacterAnimation(String) to String
{
	var IDLE = 'idle';
	var ELECTROCUTED = 'electrocuted';
	var CRISPY = 'crispy';
	var CRISPY_LOOP = 'crispy-loop';
}

enum abstract ModMenuInstallState(String) to String
{
	var Hidden = 'Hidden';
	var Busy = 'Busy';
	var Downloading = 'Downloading';
	var Result = 'Result';
}

typedef ModItemData =
{
	var id:String;
	var title:String;
	var description:String;
	var isEnabled:Bool;
	var iconData:Null<BitmapData>;
}

class ModMenuState extends backend.MusicBeatState
{
	public static var instance:Null<ModMenuState> = null;
	public static inline final BASE_GAME_MOD_ID:String = '__base_game__';
	static inline final BASE_GAME_MOD_ICON_PATH:String = 'ui/mods/base-icon';

	public static var disabledModsList:Array<ModItemData> = [];
	public static var enabledModsList:Array<ModItemData> = [];
	public static var curSelectedMod:Int = 0;

	public var bf:ModMenuCharacter;
	public var gf:ModMenuCharacter;
	public var sparks:ModMenuSparks;
	public var installPopup:ModMenuInstallPopup;

	public var camCharacters:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	var menuBG:FlxSprite;
	var bgWires:FlxSprite;
	var fgWires:FlxSprite;
	var carBattery:FlxSprite;
	var gfWire:FlxSprite;
	var topText:FlxSprite;
	var leftRectangle:FlxSprite;
	var rightRectangle:FlxSprite;

	var buttonBackToMenu:ModMenuButton;
	var buttonOpenFolder:ModMenuButton;
	var buttonDone:ModMenuButton;

	var disabledModItems:ModMenuItemList;
	var enabledModItems:ModMenuItemList;
	var selection:Int = 0;
	var transitionLayer:FlxSpriteGroup;

	var crispySmokeBF:FlxSprite;
	var crispySmokeGF:FlxSprite;
	var smokeCloud:FlxSprite;
	var shockTimer:FlxTimer = new FlxTimer();

	var secondCounter:Float = 0;
	var blinkTimer:Float = 0;
	var bfBlink:Float = 0;
	var gfBlink:Float = 0;
	var crispyTimer:Float = 0;
	var inputDelay:Float = 0.4;
	var backTimer:Float = 0;
	var backPressStage:Int = 0;
	var allowInput:Bool = true;
	var playedCrispySFX:Bool = false;
	var exitingMenu:Bool = false;

	public function new()
	{
		super();
		camCharacters = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
	}

	override public function create():Void
	{
		instance = this;

		camCharacters.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camOther);
		FlxG.cameras.add(camCharacters, false);
		FlxG.cameras.add(camHUD, false);

		super.create();

		FlxG.sound.playMusic(Paths.music('modsmenu/mod-menu-ambience'), 1, true);

		menuBG = new FlxSprite().loadGraphic(Paths.image('modsmenu/bg'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
		add(menuBG);

		bgWires = new FlxSprite().loadGraphic(Paths.image('modsmenu/bgwires'));
		bgWires.antialiasing = ClientPrefs.data.antialiasing;
		bgWires.screenCenter();
		add(bgWires);

		topText = new FlxSprite(0, FlxG.height * 0.02).loadGraphic(Paths.image('modsmenu/top-text'));
		topText.antialiasing = ClientPrefs.data.antialiasing;
		topText.screenCenter(X);
		add(topText);

		leftRectangle = new FlxSprite(40, FlxG.height * 0.15).loadGraphic(Paths.image('modsmenu/box'));
		leftRectangle.antialiasing = ClientPrefs.data.antialiasing;
		add(leftRectangle);

		rightRectangle = new FlxSprite(leftRectangle.x + leftRectangle.width + 20, leftRectangle.y).loadGraphic(Paths.image('modsmenu/box'));
		rightRectangle.antialiasing = ClientPrefs.data.antialiasing;
		add(rightRectangle);

		var dragText:FlxText = new FlxText(leftRectangle.x, FlxG.height * 0.10, leftRectangle.width + rightRectangle.width + 20,
			'DRAG PACKS ONTO THIS WINDOW TO ADD NEW STUFF');
		dragText.setFormat(Paths.font('inter.ttf'), 18, FlxColor.WHITE, CENTER);
		dragText.bold = true;
		add(dragText);

		disabledModItems = new ModMenuItemList(this, "DISABLED", leftRectangle.x, leftRectangle.y, Std.int(leftRectangle.width), Std.int(leftRectangle.height));
		enabledModItems = new ModMenuItemList(this, "ENABLED", rightRectangle.x, rightRectangle.y, Std.int(rightRectangle.width),
			Std.int(rightRectangle.height));

		add(disabledModItems);
		add(enabledModItems);

		transitionLayer = new FlxSpriteGroup();
		add(transitionLayer);

		buttonBackToMenu = new ModMenuButton(leftRectangle.x - 20, topText.y + 5, 'back-arrow');
		buttonBackToMenu.camera = camHUD;
		add(buttonBackToMenu);

		carBattery = new FlxSprite(rightRectangle.x + rightRectangle.width - 120, FlxG.height * 0.12);
		carBattery.frames = Paths.getSparrowAtlas('modsmenu/carbattery');
		carBattery.animation.addByPrefix('idle', 'idle', 24);
		carBattery.animation.play('idle');
		carBattery.animation.pause();
		carBattery.scale.set(0.65, 0.65);
		carBattery.updateHitbox();
		carBattery.camera = camCharacters;
		add(carBattery);

		gfWire = new FlxSprite(carBattery.x - 90, carBattery.y - 15);
		gfWire.frames = Paths.getSparrowAtlas('modsmenu/gfwire');
		gfWire.animation.addByPrefix('idle', 'idle0', 24, false);
		gfWire.animation.addByPrefix('idle-emptychair', 'idle empty chair0', 24, false);
		gfWire.animation.addByPrefix('shock', 'shock', 24, false);
		gfWire.animation.play('idle');
		gfWire.scale.set(0.6, 0.6);
		gfWire.updateHitbox();
		gfWire.camera = camCharacters;
		add(gfWire);

		bf = new ModMenuCharacter(carBattery.x - 100, carBattery.y + 40, 'bf');
		bf.camera = camCharacters;
		add(bf);

		gf = new ModMenuCharacter(bf.x - 130, bf.y, 'gf', true);
		gf.camera = camCharacters;
		add(gf);

		fgWires = new FlxSprite(bf.x - 110, bf.y - 70);
		fgWires.frames = Paths.getSparrowAtlas('modsmenu/foreground-wires');
		fgWires.animation.addByPrefix('idle', 'idle', 24);
		fgWires.animation.addByPrefix('idle-pinhead', 'idle pinhead', 24);
		fgWires.animation.addByPrefix('shock', 'shock', 24);
		fgWires.animation.addByPrefix('end', 'end', 24, false);
		fgWires.animation.play('idle');
		fgWires.scale.set(0.6, 0.6);
		fgWires.updateHitbox();
		fgWires.camera = camCharacters;
		add(fgWires);

		crispySmokeBF = new FlxSprite(bf.x + 50, bf.y - 140);
		crispySmokeBF.frames = Paths.getSparrowAtlas('modsmenu/smoke');
		crispySmokeBF.animation.addByPrefix('idle', 'retry_smoke', 24);
		crispySmokeBF.animation.play('idle', false, 13);
		crispySmokeBF.scale.set(0.4, 0.4);
		crispySmokeBF.updateHitbox();
		crispySmokeBF.camera = camCharacters;
		crispySmokeBF.visible = false;
		crispySmokeBF.alpha = 0.67;
		add(crispySmokeBF);

		crispySmokeGF = new FlxSprite(gf.x + 50, gf.y - 140);
		crispySmokeGF.frames = Paths.getSparrowAtlas('modsmenu/smoke');
		crispySmokeGF.animation.addByPrefix('idle', 'retry_smoke', 24);
		crispySmokeGF.animation.play('idle');
		crispySmokeGF.scale.set(0.4, 0.4);
		crispySmokeGF.updateHitbox();
		crispySmokeGF.camera = camCharacters;
		crispySmokeGF.visible = false;
		crispySmokeGF.alpha = 0.67;
		add(crispySmokeGF);

		sparks = new ModMenuSparks();
		sparks.camera = camCharacters;
		add(sparks);

		buttonOpenFolder = new ModMenuButton(leftRectangle.x + 100, FlxG.height * 0.88, 'open-folder');
		buttonOpenFolder.camera = camHUD;
		add(buttonOpenFolder);

		buttonDone = new ModMenuButton(rightRectangle.x + 100, FlxG.height * 0.88, 'done');
		buttonDone.camera = camHUD;
		add(buttonDone);

		installPopup = new ModMenuInstallPopup();
		installPopup.camera = camHUD;
		add(installPopup);

		scanAvailableMods();
		regenerateModTexts();

		bfBlink = Math.random() * 5 + 2;
		gfBlink = Math.random() * 6 + 3;

		changeCharacters();
		FlxG.camera.flash(0x44FFFFFF, 0.6);
	}

	function playBackButtonAnimation(name:String, force:Bool = false):Void
	{
		if (buttonBackToMenu != null && buttonBackToMenu.animation != null)
			buttonBackToMenu.animation.play(name, force);
	}

	function pressBackButton():Void
	{
		if (exitingMenu)
			return;
		exitingMenu = true;
		backPressStage = 3;
		backTimer = 0;
	}

	function changeCharacters():Void
	{
		var modIds:Array<String> = grabEnabledModList();

		bf.prepareToSwitch('mod-bf', modIds);
		gf.prepareToSwitch('mod-gf', modIds);

		if (modIds.length > 1)
		{
			if (bf.isPinhead && !gf.isPinhead)
				bf.currentCharacterId = 'empty-chair';
			else if (!bf.isPinhead && gf.isPinhead)
				gf.currentCharacterId = 'empty-chair';
		}

		bf.switchCharacter();
		gf.switchCharacter();

		gfWire.visible = true;
		if (gf.currentCharacterId == 'empty-chair')
			gfWire.animation.play('idle-emptychair');
		else
			gfWire.animation.play('idle');

		if (bf.useSmallWire)
			fgWires.animation.play('idle-pinhead');
		else
			fgWires.animation.play('idle');
	}

	function grabEnabledModList():Array<String>
	{
		var modIds:Array<String> = [];
		for (item in ModMenuState.enabledModsList)
			modIds.push(item.id);
		modIds.push(BASE_GAME_MOD_ID);
		return modIds;
	}

	override public function create():Void
	{
		instance = this;

		camCharacters.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camOther);
		FlxG.cameras.add(camCharacters, false);
		FlxG.cameras.add(camHUD, false);

		super.create();

		FlxG.sound.playMusic(Paths.music('modsmenu/mod-menu-ambience'), 1, true);

		menuBG = new FlxSprite().loadGraphic(Paths.image('modsmenu/bg'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
		add(menuBG);

		bgWires = new FlxSprite().loadGraphic(Paths.image('modsmenu/bgwires'));
		bgWires.antialiasing = ClientPrefs.data.antialiasing;
		bgWires.screenCenter();
		add(bgWires);

		topText = new FlxSprite(0, FlxG.height * 0.02).loadGraphic(Paths.image('modsmenu/top-text'));
		topText.antialiasing = ClientPrefs.data.antialiasing;
		topText.screenCenter(X);
		add(topText);

		leftRectangle = new FlxSprite(40, FlxG.height * 0.15).loadGraphic(Paths.image('modsmenu/box'));
		leftRectangle.antialiasing = ClientPrefs.data.antialiasing;
		add(leftRectangle);

		rightRectangle = new FlxSprite(leftRectangle.x + leftRectangle.width + 20, leftRectangle.y).loadGraphic(Paths.image('modsmenu/box'));
		rightRectangle.antialiasing = ClientPrefs.data.antialiasing;
		add(rightRectangle);

		var dragText:FlxText = new FlxText(leftRectangle.x, FlxG.height * 0.10, leftRectangle.width + rightRectangle.width + 20,
			'DRAG PACKS ONTO THIS WINDOW TO ADD NEW STUFF');
		dragText.setFormat(Paths.font('inter.ttf'), 18, FlxColor.WHITE, CENTER);
		dragText.bold = true;
		add(dragText);

		disabledModItems = new ModMenuItemList(this, "DISABLED", leftRectangle.x, leftRectangle.y, Std.int(leftRectangle.width), Std.int(leftRectangle.height));
		enabledModItems = new ModMenuItemList(this, "ENABLED", rightRectangle.x, rightRectangle.y, Std.int(rightRectangle.width),
			Std.int(rightRectangle.height));

		add(disabledModItems);
		add(enabledModItems);

		transitionLayer = new FlxSpriteGroup();
		add(transitionLayer);

		buttonBackToMenu = new ModMenuButton(leftRectangle.x - 20, topText.y + 5, 'back-arrow');
		buttonBackToMenu.camera = camHUD;
		add(buttonBackToMenu);

		carBattery = new FlxSprite(rightRectangle.x + rightRectangle.width - 120, FlxG.height * 0.12);
		carBattery.frames = Paths.getSparrowAtlas('modsmenu/carbattery');
		carBattery.animation.addByPrefix('idle', 'idle', 24);
		carBattery.animation.play('idle');
		carBattery.animation.pause();
		carBattery.scale.set(0.65, 0.65);
		carBattery.updateHitbox();
		carBattery.camera = camCharacters;
		add(carBattery);

		gfWire = new FlxSprite(carBattery.x - 90, carBattery.y - 15);
		gfWire.frames = Paths.getSparrowAtlas('modsmenu/gfwire');
		gfWire.animation.addByPrefix('idle', 'idle0', 24, false);
		gfWire.animation.addByPrefix('idle-emptychair', 'idle empty chair0', 24, false);
		gfWire.animation.addByPrefix('shock', 'shock', 24, false);
		gfWire.animation.play('idle');
		gfWire.scale.set(0.6, 0.6);
		gfWire.updateHitbox();
		gfWire.camera = camCharacters;
		add(gfWire);

		bf = new ModMenuCharacter(carBattery.x - 100, carBattery.y + 40, 'bf');
		bf.camera = camCharacters;
		add(bf);

		gf = new ModMenuCharacter(bf.x - 130, bf.y, 'gf', true);
		gf.camera = camCharacters;
		add(gf);

		fgWires = new FlxSprite(bf.x - 110, bf.y - 70);
		fgWires.frames = Paths.getSparrowAtlas('modsmenu/foreground-wires');
		fgWires.animation.addByPrefix('idle', 'idle', 24);
		fgWires.animation.addByPrefix('idle-pinhead', 'idle pinhead', 24);
		fgWires.animation.addByPrefix('shock', 'shock', 24);
		fgWires.animation.addByPrefix('end', 'end', 24, false);
		fgWires.animation.play('idle');
		fgWires.scale.set(0.6, 0.6);
		fgWires.updateHitbox();
		fgWires.camera = camCharacters;
		add(fgWires);

		crispySmokeBF = new FlxSprite(bf.x + 50, bf.y - 140);
		crispySmokeBF.frames = Paths.getSparrowAtlas('modsmenu/smoke');
		crispySmokeBF.animation.addByPrefix('idle', 'retry_smoke', 24);
		crispySmokeBF.animation.play('idle', false, 13);
		crispySmokeBF.scale.set(0.4, 0.4);
		crispySmokeBF.updateHitbox();
		crispySmokeBF.camera = camCharacters;
		crispySmokeBF.visible = false;
		crispySmokeBF.alpha = 0.67;
		add(crispySmokeBF);

		crispySmokeGF = new FlxSprite(gf.x + 50, gf.y - 140);
		crispySmokeGF.frames = Paths.getSparrowAtlas('modsmenu/smoke');
		crispySmokeGF.animation.addByPrefix('idle', 'retry_smoke', 24);
		crispySmokeGF.animation.play('idle');
		crispySmokeGF.scale.set(0.4, 0.4);
		crispySmokeGF.updateHitbox();
		crispySmokeGF.camera = camCharacters;
		crispySmokeGF.visible = false;
		crispySmokeGF.alpha = 0.67;
		add(crispySmokeGF);

		sparks = new ModMenuSparks();
		sparks.camera = camCharacters;
		add(sparks);

		buttonOpenFolder = new ModMenuButton(leftRectangle.x + 100, FlxG.height * 0.88, 'open-folder');
		buttonOpenFolder.camera = camHUD;
		add(buttonOpenFolder);

		buttonDone = new ModMenuButton(rightRectangle.x + 100, FlxG.height * 0.88, 'done');
		buttonDone.camera = camHUD;
		add(buttonDone);

		installPopup = new ModMenuInstallPopup();
		installPopup.camera = camHUD;
		add(installPopup);

		scanAvailableMods();
		regenerateModTexts();

		bfBlink = Math.random() * 5 + 2;
		gfBlink = Math.random() * 6 + 3;

		changeCharacters();
		FlxG.camera.flash(0x44FFFFFF, 0.6);
	}

	function playBackButtonAnimation(name:String, force:Bool = false):Void
	{
		if (buttonBackToMenu != null && buttonBackToMenu.animation != null)
			buttonBackToMenu.animation.play(name, force);
	}

	function pressBackButton():Void
	{
		if (exitingMenu)
			return;
		exitingMenu = true;
		backPressStage = 3;
		backTimer = 0;
	}

	function changeCharacters():Void
	{
		var modIds:Array<String> = grabEnabledModList();

		bf.prepareToSwitch('mod-bf', modIds);
		gf.prepareToSwitch('mod-gf', modIds);

		if (modIds.length > 1)
		{
			if (bf.isPinhead && !gf.isPinhead)
				bf.currentCharacterId = 'empty-chair';
			else if (!bf.isPinhead && gf.isPinhead)
				gf.currentCharacterId = 'empty-chair';
		}

		bf.switchCharacter();
		gf.switchCharacter();

		gfWire.visible = true;
		if (gf.currentCharacterId == 'empty-chair')
			gfWire.animation.play('idle-emptychair');
		else
			gfWire.animation.play('idle');

		if (bf.useSmallWire)
			fgWires.animation.play('idle-pinhead');
		else
			fgWires.animation.play('idle');
	}

	function grabEnabledModList():Array<String>
	{
		var modIds:Array<String> = [];
		for (item in ModMenuState.enabledModsList)
			modIds.push(item.id);
		modIds.push(BASE_GAME_MOD_ID);
		return modIds;
	}

	function scanAvailableMods():Void
	{
		ModMenuState.disabledModsList.clear();
		ModMenuState.enabledModsList.clear();

		#if MODS_ALLOWED
		var modsPath:String = "mods/";
		if (FileSystem.exists(modsPath))
		{
			for (folder in FileSystem.readDirectory(modsPath))
			{
				if (FileSystem.isDirectory(modsPath + folder) && folder != 'images' && folder != 'data')
				{
					var isCurrentlyEnabled:Bool = backend.Mods.getGlobalMods().contains(folder);
					var title:String = folder.replace('-', ' ').replace('_', ' ').toUpperCase();
					var desc:String = "DEFAULT MOD CONTENT DESCRIPTION.";
					var imgData:Null<BitmapData> = null;

					var jsonPath:String = modsPath + folder + '/pack.json';
					if (FileSystem.exists(jsonPath))
					{
						try
						{
							var rawJson:String = File.getContent(jsonPath);
							var parsed = Json.parse(rawJson);
							if (parsed.title != null)
								title = parsed.title.toUpperCase();
							if (parsed.description != null)
								desc = parsed.description;
						}
						catch (e:Dynamic)
						{
						}
					}

					var pngPath:String = modsPath + folder + '/pack.png';
					if (FileSystem.exists(pngPath))
					{
						try
						{
							imgData = openfl.display.BitmapData.fromFile(pngPath);
						}
						catch (e:Dynamic)
						{
						}
					}

					var modMeta:ModItemData = {
						id: folder,
						title: title,
						description: desc,
						isEnabled: isCurrentlyEnabled,
						iconData: imgData
					};

					if (isCurrentlyEnabled)
						ModMenuState.enabledModsList.push(modMeta);
					else
						ModMenuState.disabledModsList.push(modMeta);
				}
			}
		}
		#end
	}

	function regenerateModTexts():Void
	{
		disabledModItems.clearList();
		enabledModItems.clearList();

		for (i in 0...ModMenuState.disabledModsList.length)
		{
			disabledModItems.addModCard(ModMenuState.disabledModsList[i], i);
		}

		for (i in 0...ModMenuState.enabledModsList.length)
		{
			enabledModItems.addModCard(ModMenuState.enabledModsList[i], i);
		}

		updateSelectionHighlight();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (inputDelay > 0)
			inputDelay -= elapsed;

		if (backPressStage == 3)
		{
			backTimer += elapsed;
			if (backTimer >= 0.35)
				backToMainMenu();
		}

		if (!exitingMenu && allowInput)
		{
			blinkTimer += elapsed;

			if (blinkTimer >= bfBlink && (bf.animation.curAnim == null || bf.animation.curAnim.finished))
			{
				bfBlink = blinkTimer + Math.random() * 5 + 2;
				bf.playAnimation(IDLE);
			}

			if (blinkTimer >= gfBlink && (gf.animation.curAnim == null || gf.animation.curAnim.finished))
			{
				gfBlink = blinkTimer + Math.random() * 6 + 3;
				gf.playAnimation(IDLE);
			}
		}

		handleInput(elapsed);

		if (!allowInput && !shockTimer.active)
		{
			crispyTimer += elapsed;

			if (bf.animation.curAnim != null && bf.animation.curAnim.name == CRISPY && gf.animation.curAnim != null && gf.animation.curAnim.name == CRISPY)
			{
				if (crispyTimer >= 0.7 && !playedCrispySFX)
				{
					playedCrispySFX = true;
					FlxG.sound.play(Paths.sound('ui/mods/sounds/crispy'));
				}
			}

			if (crispyTimer >= 2.5)
			{
				applyModlist();
			}
		}
	}

	function handleInput(elapsed:Float):Void
	{
		var changedPos:Bool = false;
		if (!allowInput || exitingMenu || inputDelay > 0)
			return;

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			pressBackButton();
			return;
		}

		if (controls.UI_LEFT_P && selection == 1)
		{
			selection = 0;
			ModMenuState.curSelectedMod = 0;
			changedPos = true;
			updateSelectionHighlight();
		}
		else if (controls.UI_RIGHT_P && selection == 0)
		{
			selection = 1;
			ModMenuState.curSelectedMod = 0;
			changedPos = true;
			updateSelectionHighlight();
		}

		var currentList:Array<ModItemData> = (selection == 0) ? ModMenuState.disabledModsList : ModMenuState.enabledModsList;
		if (currentList.length > 0)
		{
			if (controls.UI_UP_P)
			{
				ModMenuState.curSelectedMod = FlxMath.wrap(ModMenuState.curSelectedMod - 1, 0, currentList.length - 1);
				changedPos = true;
				updateSelectionHighlight();
			}
			if (controls.UI_DOWN_P)
			{
				ModMenuState.curSelectedMod = FlxMath.wrap(ModMenuState.curSelectedMod + 1, 0, currentList.length - 1);
				changedPos = true;
				updateSelectionHighlight();
			}
		}

		if (changedPos)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if (controls.ACCEPT)
		{
			toggleModState();
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(buttonOpenFolder))
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
				#if sys Sys.command('explorer', ['mods']); #end
			}
			else if (FlxG.mouse.overlaps(buttonDone))
			{
				playElectrocutionSequence();
			}
			else if (FlxG.mouse.overlaps(buttonBackToMenu))
			{
				pressBackButton();
			}
		}
	}

	function toggleModState():Void
	{
		if (selection == 0 && ModMenuState.disabledModsList.length > 0)
		{
			var mod = ModMenuState.disabledModsList[ModMenuState.curSelectedMod];
			mod.isEnabled = true;
			ModMenuState.disabledModsList.remove(mod);
			ModMenuState.enabledModsList.push(mod);

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
			ModMenuState.curSelectedMod = 0;
			regenerateModTexts();
		}
		else if (selection == 1 && ModMenuState.enabledModsList.length > 0)
		{
			var mod = ModMenuState.enabledModsList[ModMenuState.curSelectedMod];
			if (mod.id == BASE_GAME_MOD_ID)
				return;
			mod.isEnabled = false;
			ModMenuState.enabledModsList.remove(mod);
			ModMenuState.disabledModsList.push(mod);

			FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
			ModMenuState.curSelectedMod = 0;
			regenerateModTexts();
		}
	}

	function playElectrocutionSequence():Void
	{
		allowInput = false;
		bf.playAnimation(ELECTROCUTED, true);
		gf.playAnimation(ELECTROCUTED, true);

		fgWires.animation.play('shock');
		gfWire.visible = true;
		gfWire.animation.play('shock');

		sparks.startElectrocution();

		shockTimer.start(81 / 24, (_) ->
		{
			FlxG.camera.flash(0xFFFFFFFF, 0.1);

			changeCharacters();

			carBattery.visible = true;
			carBattery.animation.reset();

			sparks.endElectrocution();

			fgWires.visible = true;
			bgWires.visible = true;

			var showSmoke:Bool = false;
			if (bf.hasAnimation(CRISPY))
			{
				showSmoke = true;
				bf.playAnimation(CRISPY, true);
			}
			else
			{
				bf.playAnimation(IDLE, true);
			}

			if (gf.hasAnimation(CRISPY))
			{
				showSmoke = true;
				gf.playAnimation(CRISPY, true);
			}
			else
			{
				gf.playAnimation(IDLE, true);
			}

			if (showSmoke)
			{
				crispySmokeBF.visible = (bf.currentCharacterId != 'empty-chair');
				crispySmokeGF.visible = (gf.currentCharacterId != 'empty-chair');
				fgWires.animation.play('end');
			}

			crispyTimer = 0;
		});
	}

	function applyModlist():Void
	{
		var newActiveList:Array<String> = [];
		for (mod in ModMenuState.enabledModsList)
		{
			if (mod.id == BASE_GAME_MOD_ID)
				continue;
			newActiveList.push(mod.id);
		}

		@:privateAccess {
			backend.Mods.globalMods = newActiveList;
			backend.Mods.updateModList();
		}

		FlxG.camera.flash(0xFFFFFFFF, 0.2);
		new flixel.util.FlxTimer().start(0.4, function(_)
		{
			backend.MusicBeatState.switchState(new mikolka.vslice.ui.MainMenuState());
		});
	}

	function backToMainMenu():Void
	{
		exitingMenu = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		backend.MusicBeatState.switchState(new mikolka.vslice.ui.MainMenuState());
	}

	function updateSelectionHighlight():Void
	{
		disabledModItems.updateHighlight(selection == 0, ModMenuState.curSelectedMod);
		enabledModItems.updateHighlight(selection == 1, ModMenuState.curSelectedMod);
	}
}

class ModMenuCharacter extends FlxSprite
{
	public var initialPosition:FlxPoint = new FlxPoint();
	public var currentCharacterId:String = '';
	public var currentModId:String = '';
	public var previousModId:String = '';
	public var isGF:Bool = false;
	public var isPinhead:Bool = false;
	public var hasCustomWires:Bool = false;
	public var useSmallWire:Bool = false;

	var replaceColorShader:FlxRuntimeShader = null;
	var pinheadColor:Array<Float> = [];

	public function new(x:Float = 0, y:Float = 0, characterId:String = '', gf:Bool = false)
	{
		super(x, y);
		this.initialPosition.set(x, y);
		this.currentCharacterId = characterId;
		this.isGF = gf;
		antialiasing = backend.ClientPrefs.data.antialiasing;

		loadGraphics();
		playAnimation(IDLE, true);
	}

	public function getRandomColor():Array<Float>
	{
		var hue:Float = Math.random() * 360;
		var sat:Float = (75 + Math.random() * 5) / 240;
		var lum:Float = (80 + Math.random() * 79) / 240;
		var color:FlxColor = FlxColor.fromHSL(hue, sat, lum);
		return [color.redFloat, color.greenFloat, color.blueFloat];
	}

	public function applyShader():Void
	{
		if (currentCharacterId == 'pinhead')
		{
			if (replaceColorShader == null)
			{
				var fragCode:String = "
					#pragma header
					uniform vec3 uTargetColor;
					uniform vec3 uReplaceColor;
					uniform float uThreshold;
					void main() {
						vec4 color = texture2D(bitmap, openfl_TextureCoordv);
						float dist = distance(color.rgb, uTargetColor);
						if (dist < uThreshold) {
							color.rgb = uReplaceColor;
						}
						gl_FragColor = color;
					}
				";
				replaceColorShader = new FlxRuntimeShader(fragCode);
				replaceColorShader.setFloatArray('uTargetColor', [0.0, 1.0, 0.04]);
				replaceColorShader.setFloat('uThreshold', 0.12);
			}
			pinheadColor = getRandomColor();
			replaceColorShader.setFloatArray('uReplaceColor', pinheadColor);
			shader = replaceColorShader;
		}
		else
		{
			shader = null;
			replaceColorShader = null;
		}
	}

	public function playAnimation(name:CharacterAnimation, force:Bool = false):Void
	{
		if (animation.getByName(name) != null)
		{
			animation.play(name, force);
		}
	}

	public function prepareToSwitch(characterId:String, modIds:Array<String>):Void
	{
		currentCharacterId = characterId;
		isPinhead = false;
		var foundMod:String = '';

		for (mod in modIds)
		{
			if (mod == ModMenuState.BASE_GAME_MOD_ID)
				continue;

			var assetPath:String = 'mods/' + mod + '/images/ui/mods/characters/' + currentCharacterId;
			if (FileSystem.exists(assetPath + '.png') || FileSystem.exists(assetPath + '/Animation.json'))
			{
				foundMod = mod;
				break;
			}
		}

		if (foundMod == '' && modIds.length > 1)
		{
			currentCharacterId = 'pinhead';
			currentModId = 'basegame';
			isPinhead = true;
		}
		else if (foundMod == '' && modIds.length == 1)
		{
			currentCharacterId = characterId;
			currentModId = 'basegame';
		}
		else
		{
			currentModId = foundMod;
		}
	}

	public function switchCharacter():Void
	{
		loadGraphics();
		applyShader();

		hasCustomWires = (currentCharacterId != 'pinhead' && currentCharacterId != 'empty-chair');
		useSmallWire = (currentCharacterId == 'pinhead');

		setPosition(initialPosition.x, initialPosition.y);
	}

	public function hasAnimation(name:String):Bool
	{
		return animation.getByName(name) != null;
	}

	function loadGraphics():Void
	{
		var checkId = currentCharacterId;
		if (checkId == 'mod-bf')
			checkId = 'bf';
		if (checkId == 'mod-gf')
			checkId = 'gf';

		if (checkId == 'empty-chair')
		{
			loadGraphic(Paths.image('modsmenu/emptychair'));
			return;
		}

		var atlasPath:String = 'modsmenu/characters/' + checkId;
		frames = Paths.getSparrowAtlas(atlasPath);

		animation.addByPrefix('idle', 'idle', 24, true);
		animation.addByPrefix('electrocuted', 'electrocuted', 24, true);
		animation.addByPrefix('crispy', 'crispy', 24, false);
		animation.addByPrefix('crispy-loop', 'crispy loop', 24, true);
	}
}

class ModMenuSparks extends FlxSprite
{
	var _timer:FlxTimer = new FlxTimer();
	var _randomAnimations:Array<String> = [];

	public function new()
	{
		super();
		visible = false;
		frames = Paths.getSparrowAtlas('modsmenu/sparks');
		antialiasing = backend.ClientPrefs.data.antialiasing;

		for (i in 1...12)
		{
			animation.addByPrefix('$i', 'spark $i', 24, false);
			_randomAnimations.push('$i');
		}
		animation.addByPrefix('electrocution', 'electrocution', 24, true);
		animation.addByPrefix('end', 'end', 24, false);

		animation.onFinish.add((name:String) ->
		{
			if (name != 'electrocution')
				visible = false;
		});
	}

	public function startElectrocution():Void
	{
		if (_timer.active)
			_timer.cancel();
		visible = true;
		animation.play('electrocution', true);
		FlxG.sound.play(Paths.sound('ui/mods/sounds/sparks/electrocution'));
	}

	public function endElectrocution():Void
	{
		animation.play('end', true);
	}

	public function playRandomAnimation():Void
	{
		var randomAnimation:String = getRandomAnimation();
		visible = true;
		animation.play(randomAnimation);
		FlxG.sound.play(Paths.sound('ui/mods/sounds/sparks/spark-' + randomAnimation));
		_previousAnimation = randomAnimation;
	}

	function startTimer():Void
	{
		_timer.start(FlxG.random.int(6, 20), (tmr:FlxTimer) ->
		{
			playRandomAnimation();
		});
	}

	var _previousAnimation:String = '';

	function getRandomAnimation():String
	{
		var randomAnimation:String = _randomAnimations[FlxG.random.int(0, _randomAnimations.length - 1)];
		if (randomAnimation == _previousAnimation)
			return getRandomAnimation();
		return randomAnimation;
	}

	override public function destroy():Void
	{
		super.destroy();
		if (_timer.active)
			_timer.cancel();
	}
}

class ModMenuButton extends FlxSprite
{
	var graphicName:String;

	public function new(x:Float, y:Float, name:String)
	{
		super(x, y);
		this.graphicName = name;
		antialiasing = backend.ClientPrefs.data.antialiasing;
		loadGraphic(Paths.image('modsmenu/' + graphicName));
		updateHitbox();
	}
}

class ModMenuInstallPopup extends FlxSpriteGroup
{
	public var state:String = 'Hidden';

	var background:FlxSprite;
	var modIcon:FlxSprite;

	public function endElectrocution():Void
	{
		animation.play('end', true);
	}

	public function playRandomAnimation():Void
	{
		var randomAnimation:String = getRandomAnimation();
		visible = true;
		animation.play(randomAnimation);
		FlxG.sound.play(Paths.sound('ui/mods/sounds/sparks/spark-' + randomAnimation));
		_previousAnimation = randomAnimation;
	}

	function startTimer():Void
	{
		_timer.start(FlxG.random.int(6, 20), (tmr:FlxTimer) ->
		{
			playRandomAnimation();
		});
	}

	var _previousAnimation:String = '';

	function getRandomAnimation():String
	{
		var randomAnimation:String = _randomAnimations[FlxG.random.int(0, _randomAnimations.length - 1)];
		if (randomAnimation == _previousAnimation)
			return getRandomAnimation();
		return randomAnimation;
	}

	override public function destroy():Void
	{
		super.destroy();
		if (_timer.active)
			_timer.cancel();
	}
}

class ModMenuInstallPopup extends FlxSpriteGroup
{
	public var state:String = 'Hidden';

	var background:FlxSprite;
	var modIcon:FlxSprite;

	public function new(state:ModMenuState, title:String, x:Float, y:Float, w:Int, h:Int)
	{
		super(x, y);
		this.state = state;
		this.listTitle = title;

		titleText = new FlxText(0, 15, w, listTitle, 24);
		titleText.setFormat(Paths.font("inter.ttf"), 24, FlxColor.WHITE, CENTER);
		titleText.bold = true;
		add(titleText);

		cardsGroup = new FlxSpriteGroup();
		textGroup = new FlxSpriteGroup();
		add(cardsGroup);
		add(textGroup);
	}

	public function clearList():Void
	{
		cardsGroup.clear();
		textGroup.clear();
	}

	public function addModCard(mod:ModItemData, index:Int):Void
	{
		var startY:Float = 70 + (index * 115);

		var cardBg = new FlxSprite(15, startY).makeGraphic(340, 100, 0xFF171426);
		cardBg.ID = index;
		cardsGroup.add(cardBg);

		var icon = new FlxSprite(25, startY + 10);
		if (mod.iconData != null)
		{
			icon.loadGraphic(mod.iconData);
		}
		else
		{
			icon.loadGraphic(Paths.image('modsmenu/fallback-icon'));
		}
		icon.setGraphicSize(80, 80);
		icon.updateHitbox();
		icon.antialiasing = true;
		cardsGroup.add(icon);

		var txtTitle = new FlxText(115, startY + 10, 230, mod.title, 16);
		txtTitle.setFormat(Paths.font("inter.ttf"), 16, FlxColor.WHITE, LEFT);
		txtTitle.bold = true;
		txtTitle.ID = index;
		textGroup.add(txtTitle);

		var txtDesc = new FlxText(115, startY + 35, 230, mod.description, 11);
		txtDesc.setFormat(Paths.font("inter.ttf"), 11, 0xFF8A82A6, LEFT);
		txtDesc.ID = index;
		textGroup.add(txtDesc);
	}

	public function updateHighlight(isActiveList:Bool, selectedIdx:Int):Void
	{
		cardsGroup.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == selectedIdx)
			{
				spr.color = isActiveList ? ((listTitle == "ENABLED") ? 0xFF1F2F26 : 0xFF2D1B36) : 0xFF171426;
				spr.scale.set(1.02, 1.02);
			}
			else
			{
				spr.color = 0xFF171426;
				spr.scale.set(1.0, 1.0);
			}
		});

		textGroup.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == selectedIdx && Std.isOfType(spr, FlxText))
			{
				var txt:FlxText = cast spr;
				if (txt.size == 16)
				{
					txt.color = isActiveList ? ((listTitle == "ENABLED") ? 0xFF00FF66 : 0xFFBF55EC) : FlxColor.WHITE;
				}
			}
		});
	}

	var cardsGroup:FlxSpriteGroup;
	var textGroup:FlxSpriteGroup;
}

typedef TransitionRecord =
{
	var item:Dynamic;
	var dest:ModMenuItemList;
	var index:Int;
}
