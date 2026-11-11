package states;

import openfl.display.BitmapData;
import backend.Mods;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSpriteUtil;
import options.ModSettingsSubState;
import mikolka.vslice.ui.title.TitleState;
import mikolka.funkin.custom.mobile.MobileScaleMode;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import openfl.display.Shape;
import openfl.geom.Matrix;

class ModsMenuState extends MusicBeatState
{
	var bg:FlxSprite;
	var icon:FlxSprite;
	var modName:Alphabet;
	var modDesc:FlxText;
	var modRestartText:FlxText;
	var modsList:ModsList = null;

	var bgList:FlxSprite;
	var buttonReload:MenuButton;
	var buttonEnableAll:MenuButton;
	var buttonDisableAll:MenuButton;
	var buttons:Array<MenuButton> = [];
	var settingsButton:MenuButton;

	var bgTitle:FlxSprite;
	var bgDescription:FlxSprite;
	var bgButtons:FlxSprite;

	public static var modsGroup:FlxTypedGroup<ModItem>;
	public static var curSelectedMod:Int = 0;

	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = 0;
	var modNameInitialY:Float = 0;

	var noModsSine:Float = 0;
	var noModsTxt:FlxText;

	var _lastControllerMode:Bool = false;
	var startMod:String = null;

	static inline var PV_MIN_W:Int = 640;
	static inline var PV_MIN_H:Int = 360;
	static inline var PV_MAX_W:Int = 1920;
	static inline var PV_MAX_H:Int = 1080;
	static inline var PV_MAX:Int = 12;
	static inline var PV_PAD:Int = 10;
	static inline var PV_BIG_W:Int = 352;
	static inline var PV_BIG_H:Int = 198;
	static inline var PV_GAP:Int = 14;
	static inline var PV_COLS:Int = 4;
	static inline var PV_TH_W:Int = 107;
	static inline var PV_TH_H:Int = 60;
	static inline var PV_TH_GX:Int = 8;
	static inline var PV_TH_GY:Int = 9;
	static inline var PV_ELL_BIG:Int = 20;
	static inline var PV_ELL_TH:Int = 14;
	static inline var PV_DELAY:Float = 0.25;
	static inline var HIT_BIG:Int = 1000;
	static inline var FS_EDGE:Int = 100;
	static inline var DESC_AREA_H:Int = 350;
	static inline var DESC_SB:Int = 8;
	static final PV_EXTS:Array<String> = ['.png', '.jpg', '.jpeg'];

	var previewGroup:FlxTypedGroup<FlxSprite>;
	var bigFrame:FlxSprite;
	var bigBack:FlxSprite;
	var bigSpr:FlxSprite;
	var bigLabelBg:FlxSprite;
	var bigLabel:FlxText;
	var descDivider:FlxSprite;
	var thumbFrames:Array<FlxSprite> = [];
	var thumbBacks:Array<FlxSprite> = [];
	var thumbSprs:Array<FlxSprite> = [];
	var previewQueue:Array<String> = [];
	var previewPaths:Array<String> = [];
	var fsCache:Map<String, FlxGraphic> = new Map();
	var shownFolder:String = null;
	var pvWaiting:Bool = false;
	var pvLoading:Bool = false;
	var pvIdx:Int = 0;
	var pvCounter:Int = 0;
	var previewTimer:Float = 0;
	var hasGallery:Bool = false;

	var bottomText:FlxText;
	var bottomBase:String = '';

	var descViewX:Float = 0;
	var descViewY:Float = 0;
	var descViewW:Float = 0;
	var descViewH:Float = 0;
	var descScroll:Float = 0;
	var descTarget:Float = 0;
	var descMax:Float = 0;
	var descTrack:FlxSprite;
	var descThumb:FlxSprite;
	var descDragging:Bool = false;
	var descDragY:Float = 0;

	var fsGroup:FlxTypedGroup<FlxSprite>;
	var fsBg:FlxSprite;
	var fsSpr:FlxSprite;
	var fsHint:FlxText;
	var fsPrev:FlxText;
	var fsNext:FlxText;
	var fsOpen:Bool = false;
	var fsIndex:Int = 0;
	var fsDownX:Float = -1;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	override function create()
	{
		var daButton:String = "BACKSPACE";
		var CUTOUT_WIDTH:Float = MobileScaleMode.gameCutoutSize.x / 1.5;

		if (controls.mobileC)
			daButton = 'B';
		CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();
		persistentUpdate = false;

		modsList = Mods.parseList();
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF665AFF;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		bgList = FlxSpriteUtil.drawRoundRect(new FlxSprite(CUTOUT_WIDTH+40, 40).makeGraphic(340, 440, FlxColor.TRANSPARENT), 0, 0, 340, 440, 15, 15, FlxColor.BLACK);
		bgList.alpha = 0.6;

		modsGroup = new FlxTypedGroup<ModItem>();

		for (i => mod in modsList.all)
		{
			if (startMod == mod)
				curSelectedMod = i;

			var modItem:ModItem = new ModItem(mod);
			if (modsList.disabled.contains(mod))
			{
				modItem.icon.color = 0xFFFF6666;
				modItem.text.color = FlxColor.GRAY;
			}
			modsGroup.add(modItem);
		}

		var mod:ModItem = modsGroup.members[curSelectedMod];
		if (mod != null)
			bg.color = mod.bgColor;

		var buttonX = bgList.x;
		var buttonWidth = Std.int(bgList.width);
		var buttonHeight = 80;
		var daY = 20;

		buttonReload = new MenuButton(buttonX, bgList.y + bgList.height + daY, buttonWidth, buttonHeight, Language.getPhrase('reload_button', 'RELOAD'),
			reload);
		add(buttonReload);

		var myY = buttonReload.y + buttonReload.bg.height + 20;

		buttonEnableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, Language.getPhrase('enable_all_button', 'ENABLE ALL'), function()
		{
			buttonEnableAll.ignoreCheck = false;
			for (mod in modsGroup.members)
			{
				if (modsList.disabled.contains(mod.folder))
				{
					modsList.disabled.remove(mod.folder);
					modsList.enabled.push(mod.folder);
					mod.icon.color = FlxColor.WHITE;
					mod.text.color = FlxColor.WHITE;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonEnableAll.bg.color = FlxColor.GREEN;
		buttonEnableAll.focusChangeCallback = function(focus:Bool) if (!focus)
		buttonEnableAll.bg.color = FlxColor.GREEN;
		add(buttonEnableAll);

		buttonDisableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, Language.getPhrase('disable_all_button', 'DISABLE ALL'), function()
		{
			buttonDisableAll.ignoreCheck = false;
			for (mod in modsGroup.members)
			{
				if (modsList.enabled.contains(mod.folder))
				{
					modsList.enabled.remove(mod.folder);
					modsList.disabled.push(mod.folder);
					mod.icon.color = 0xFFFF6666;
					mod.text.color = FlxColor.GRAY;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDisableAll.bg.color = 0xFFFF6666;
		buttonDisableAll.focusChangeCallback = function(focus:Bool) if (!focus)
		buttonDisableAll.bg.color = 0xFFFF6666;
		add(buttonDisableAll);
		checkToggleButtons();

		if (modsList.all.length < 1)
		{
			buttonDisableAll.visible = buttonDisableAll.enabled = false;
			buttonEnableAll.visible = true;

			var myX = bgList.x + bgList.width + 20;
			noModsTxt = new FlxText(myX, 0, FlxG.width - myX - 20, Language.getPhrase('no_mods_installed', "NO MODS INSTALLED\nPRESS {1} TO EXIT OR INSTALL A MOD", [daButton]), 48);
			if(FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.';
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noModsTxt.borderSize = 2;
			add(noModsTxt);
			noModsTxt.screenCenter(Y);

			var txt = new FlxText(bgList.x + 15, bgList.y + 15, bgList.width - 30, Language.getPhrase('no_mods_found', "No Mods found."), 16);
			txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
			add(txt);

			FlxG.autoPause = false;
			changeSelectedMod();

			#if TOUCH_CONTROLS_ALLOWED
			addTouchPad('NONE', 'B');
			#end

			return super.create();
		}

		bgTitle = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgList.x + bgList.width + 20, 40).makeGraphic(840, 180, FlxColor.TRANSPARENT), 0, 0, 840,
			180, 15, 15, 0, 0, FlxColor.BLACK);
		bgTitle.alpha = 0.6;
		add(bgTitle);

		icon = new FlxSprite(bgTitle.x + 15, bgTitle.y + 15);
		add(icon);

		modNameInitialY = icon.y + 80;
		modName = new Alphabet(icon.x + 165, modNameInitialY, "", true);
		modName.scaleY = 0.8;
		add(modName);

		bgDescription = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgTitle.x, bgTitle.y + 200).makeGraphic(840, 450, FlxColor.TRANSPARENT), 0, 0, 840,
			450, 0, 0, 15, 15, FlxColor.BLACK);
		bgDescription.alpha = 0.6;
		add(bgDescription);

		modDesc = new FlxText(bgDescription.x + 15, bgDescription.y + 15, bgDescription.width - 30, "", 24);
		modDesc.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(modDesc);

		var gx:Float = bgDescription.x + PV_PAD;
		var gy:Float = bgDescription.y + PV_PAD;
		previewGroup = new FlxTypedGroup<FlxSprite>();
		add(previewGroup);

		bigFrame = makeRound(gx - 3, gy - 3, PV_BIG_W + 6, PV_BIG_H + 6, PV_ELL_BIG + 6, FlxColor.WHITE);
		bigFrame.visible = false;
		bigBack = makeRound(gx, gy, PV_BIG_W, PV_BIG_H, PV_ELL_BIG, FlxColor.BLACK);
		bigBack.alpha = 0.5;
		bigSpr = new FlxSprite(gx, gy);
		bigSpr.visible = false;
		bigLabelBg = new FlxSprite();
		bigLabelBg.alpha = 0.6;
		bigLabelBg.visible = false;
		bigLabel = new FlxText(0, 0, 0, "", 14);
		bigLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		bigLabel.visible = false;
		previewGroup.add(bigFrame);
		previewGroup.add(bigBack);
		previewGroup.add(bigSpr);
		previewGroup.add(bigLabelBg);
		previewGroup.add(bigLabel);

		var thX:Float = gx + PV_BIG_W + PV_GAP;
		for (i in 0...PV_MAX)
		{
			var tx:Float = thX + (i % PV_COLS) * (PV_TH_W + PV_TH_GX);
			var ty:Float = gy + Std.int(i / PV_COLS) * (PV_TH_H + PV_TH_GY);

			var tf = makeRound(tx - 3, ty - 3, PV_TH_W + 6, PV_TH_H + 6, PV_ELL_TH + 6, FlxColor.WHITE);
			tf.visible = false;
			var tb = makeRound(tx, ty, PV_TH_W, PV_TH_H, PV_ELL_TH, FlxColor.BLACK);
			tb.alpha = 0.5;
			tb.visible = false;
			var ts = new FlxSprite(tx, ty);
			ts.visible = false;

			thumbFrames.push(tf);
			thumbBacks.push(tb);
			thumbSprs.push(ts);
			previewGroup.add(tf);
			previewGroup.add(tb);
			previewGroup.add(ts);
		}

		descDivider = new FlxSprite(bgDescription.x + PV_PAD, bgDescription.y + PV_PAD + PV_BIG_H + 7).makeGraphic(Std.int(bgDescription.width) - PV_PAD * 2, 2,
			FlxColor.WHITE, true);
		descDivider.alpha = 0.12;
		previewGroup.add(descDivider);
		previewGroup.visible = false;

		descTrack = new FlxSprite().makeGraphic(4, 4, FlxColor.WHITE, true);
		descTrack.alpha = 0.15;
		descTrack.visible = false;
		add(descTrack);
		descThumb = new FlxSprite().makeGraphic(4, 4, FlxColor.WHITE, true);
		descThumb.alpha = 0.7;
		descThumb.visible = false;
		add(descThumb);

		var myHeight = 100;
		modRestartText = new FlxText(bgDescription.x + 15, bgDescription.y + bgDescription.height - myHeight + 18, 290,
			Language.getPhrase('mod_restart', '* Moving or Toggling On/Off this Mod will restart the game.'), 14);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		modRestartText.alpha = 0.85;
		add(modRestartText);

		bgButtons = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgDescription.x,
			bgDescription.y + bgDescription.height - myHeight).makeGraphic(840, myHeight, FlxColor.TRANSPARENT), 0, 0, 840,
			myHeight, 0, 0, 15, 15, FlxColor.WHITE);
		bgButtons.color = FlxColor.BLACK;
		bgButtons.alpha = 0.2;
		add(bgButtons);

		var buttonsX = bgButtons.x + 320;
		var buttonsY = bgButtons.y + 10;

		var button = new MenuButton(buttonsX, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(0), 54, 54);
		button.icon.animation.add('icon', [0]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button = new MenuButton(buttonsX + 100, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod - 1), 54,
			54);
		button.icon.animation.add('icon', [1]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button = new MenuButton(buttonsX + 200, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod + 1), 54,
			54);
		button.icon.animation.add('icon', [2]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		if (modsList.all.length < 2)
		{
			for (button in buttons)
				button.enabled = false;
		}

		settingsButton = new MenuButton(buttonsX + 300, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function()
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null && curMod.settings != null && curMod.settings.length > 0)
			{
				openSubState(new ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
			}
		}, 54, 54);

		settingsButton.icon.animation.add('icon', [3]);
		settingsButton.icon.animation.play('icon', true);
		add(settingsButton);
		buttons.push(settingsButton);

		if (modsGroup.members[curSelectedMod].settings == null || modsGroup.members[curSelectedMod].settings.length < 1)
			settingsButton.enabled = false;

		var button = new MenuButton(buttonsX + 400, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function()
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			var mod:String = curMod.folder;
			if (!modsList.disabled.contains(mod))
			{
				modsList.enabled.remove(mod);
				modsList.disabled.push(mod);
			}
			else
			{
				modsList.disabled.remove(mod);
				modsList.enabled.push(mod);
			}
			curMod.icon.color = modsList.disabled.contains(mod) ? 0xFFFF6666 : FlxColor.WHITE;
			curMod.text.color = modsList.disabled.contains(mod) ? FlxColor.GRAY : FlxColor.WHITE;

			if (curMod.mustRestart)
				waitingToRestart = true;
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}, 54, 54);
		button.icon.animation.add('icon', [4]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		button.focusChangeCallback = function(focus:Bool)
		{
			if (!focus)
				button.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? FlxColor.GREEN : 0xFFFF6666;
		};

		if (modsList.all.length < 1)
		{
			for (btn in buttons)
				btn.enabled = false;
			button.focusChangeCallback = null;
		}

		add(bgList);
		add(modsGroup);
		_lastControllerMode = controls.controllerMode;

		changeSelectedMod();

		var bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, Language.getPhrase('mods_leave', "Press {1} To Leave", [daButton]), 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		bottomBase = bottomText.text;
		updateBottomHint();

		fsGroup = new FlxTypedGroup<FlxSprite>();
		fsBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, true);
		fsBg.alpha = 0.94;
		fsSpr = new FlxSprite();
		fsHint = new FlxText(0, FlxG.height - 26, FlxG.width, "", 16);
		fsHint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fsPrev = new FlxText(0, FlxG.height / 2 - 40, FS_EDGE, "<", 64);
		fsPrev.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fsNext = new FlxText(FlxG.width - FS_EDGE, FlxG.height / 2 - 40, FS_EDGE, ">", 64);
		fsNext.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fsGroup.add(fsBg);
		fsGroup.add(fsSpr);
		fsGroup.add(fsPrev);
		fsGroup.add(fsNext);
		fsGroup.add(fsHint);
		fsGroup.visible = false;
		add(fsGroup);

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'B');
		touchPad.y -= 215;
		if (controls.mobileC)
			touchPad.alpha = 0.3;
		#end

		super.create();
	}

	var nextAttempt:Float = 1;
	var holdingMod:Bool = false;
	var mouseOffsets:FlxPoint = new FlxPoint();
	var holdingElapsed:Float = 0;
	var gottaClickAgain:Bool = false;

	var holdTime:Float = 0;
	var exiting:Bool = false;

	override function update(elapsed:Float)
	{

		if (!exiting && modsList.all.length > 0)
		{
			if (pvWaiting)
			{
				previewTimer -= elapsed;
				if (previewTimer <= 0)
				{
					pvWaiting = false;
					pvLoading = true;
					pvIdx = 0;
				}
			}
			else if (pvLoading)
				loadNextPreview();

			if (fsOpen)
			{
				updateFullscreen();
				super.update(elapsed);
				return;
			}

			updateDescScroll(elapsed);
			if (updateGallery())
			{
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK && hoveringOnMods && !exiting)
		{
			exiting = true;
			saveTxt();

			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (waitingToRestart)
			{
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.sound.music.fadeOut(0.3);
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
			}
			else
				MusicBeatState.switchState(new MainMenuState());

			persistentUpdate = false;
			FlxG.autoPause = ClientPrefs.data.autoPause;
			FlxG.mouse.visible = false;
			return;
		}

		if (Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10)
		{
			controls.controllerMode = false;
			if (!FlxG.mouse.visible)
				FlxG.mouse.visible = true;
		}

		if (controls.controllerMode != _lastControllerMode)
		{
			if (controls.controllerMode)
				FlxG.mouse.visible = false;
			_lastControllerMode = controls.controllerMode;
		}

		if (controls.UI_DOWN_R || controls.UI_UP_R)
			holdTime = 0;

		if (modsList.all.length > 0)
		{
			if (controls.controllerMode && holdingMod)
			{
				holdingMod = false;
				holdingElapsed = 0;
				updateItemPositions();
			}

			var lastMode = hoveringOnMods;
			if (modsList.all.length > 1)
			{
				if (FlxG.mouse.justPressed)
				{
					for (i in centerMod - 2...centerMod + 3)
					{
						var mod = modsGroup.members[i];
						if (mod != null && mod.visible && FlxG.mouse.overlaps(mod))
						{
							hoveringOnMods = true;
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							mouseOffsets.x = FlxG.mouse.x - mod.x;
							mouseOffsets.y = FlxG.mouse.y - mod.y;
							curSelectedMod = i;
							changeSelectedMod();
							break;
						}
					}
					hoveringOnMods = true;
					var button = getButton();
					button.ignoreCheck = button.onFocus = false;
					gottaClickAgain = false;
				}

				if (hoveringOnMods)
				{
					var shiftMult:Int = (FlxG.keys.pressed.SHIFT
						|| FlxG.gamepads.anyPressed(LEFT_SHOULDER)
						|| FlxG.gamepads.anyPressed(RIGHT_SHOULDER)) ? 4 : 1;
					if (controls.UI_DOWN_P)
						changeSelectedMod(shiftMult);
					else if (controls.UI_UP_P)
						changeSelectedMod(-shiftMult);
					else if (FlxG.mouse.wheel != 0 && !wheelOnDesc())
						changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
					else if (FlxG.keys.justPressed.HOME
						|| FlxG.keys.justPressed.END
						|| FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)
						|| FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					{
						if (FlxG.keys.justPressed.END || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
							curSelectedMod = modsList.all.length - 1;
						else
							curSelectedMod = 0;
						changeSelectedMod();
					}
					else if (controls.UI_UP || controls.UI_DOWN)
					{
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if (holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8))
							changeSelectedMod(shiftMult * (controls.UI_UP ? -1 : 1));
					}
					else if (FlxG.mouse.pressed  && !gottaClickAgain)
					{
						var curMod:ModItem = modsGroup.members[curSelectedMod];
						if (curMod != null)
						{
							if (!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod))
								holdingMod = true;

							if (holdingMod)
							{
								var moved:Bool = false;
								for (i in centerMod - 2...centerMod + 3)
								{
									var mod = modsGroup.members[i];
									if (mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i)
									{
										moveModToPosition(i);
										moved = true;
										break;
									}
								}

								if (!moved)
								{
									var factor:Float = -1;
									if (FlxG.mouse.y < bgList.y)
										factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (bgList.y - FlxG.mouse.y) / 100)));
									else if (FlxG.mouse.y > bgList.y + bgList.height)
										factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - bgList.y - bgList.height) / 100)));

									if (factor >= 0)
									{
										holdingElapsed += elapsed;
										if (holdingElapsed >= factor)
										{
											holdingElapsed = 0;
											var newPos = curSelectedMod;
											if (FlxG.mouse.y < bgList.y)
												newPos--;
											else
												newPos++;
											moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
										}
									}
								}
								curMod.x = FlxG.mouse.x - mouseOffsets.x;
								curMod.y = FlxG.mouse.y - mouseOffsets.y;
							}
						}
					}
					else if (FlxG.mouse.justReleased && holdingMod)
					{
						holdingMod = false;
						holdingElapsed = 0;
						updateItemPositions();
					}
				}
			}

			if (lastMode == hoveringOnMods)
			{
				if (hoveringOnMods)
				{
					if (controls.UI_RIGHT_P)
					{
						hoveringOnMods = false;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						curSelectedButton = 0;
						changeSelectedButton();
					}
				}
				else
				{
					if (controls.BACK)
					{
						hoveringOnMods = true;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						changeSelectedMod();
					}
					else if (controls.ACCEPT)
					{
						var button = getButton();
						if (button.onClick != null)
							button.onClick();
					}
					else if (curSelectedButton < 0)
					{
						if (controls.UI_UP_P)
						{
							switch (curSelectedButton)
							{
								case -2:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
								case -1:
									changeSelectedButton(-1);
							}
						}
						else if (controls.UI_DOWN_P)
						{
							switch (curSelectedButton)
							{
								case -2:
									changeSelectedButton(1);
								case -1:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
							}
						}
						else if (controls.UI_RIGHT_P)
						{
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							curSelectedButton = 0;
							changeSelectedButton();
						}
					}
					else if (controls.UI_LEFT_P)
						changeSelectedButton(-1);
					else if (controls.UI_RIGHT_P)
						changeSelectedButton(1);
				}
			}
		}
		else
		{
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);

			nextAttempt -= elapsed;
			if (nextAttempt < 0)
			{
				nextAttempt = 1;
				@:privateAccess
				Mods.updateModList();
				modsList = Mods.parseList();
				if (modsList.all.length > 0)
				{
					trace('mod(s) found! reloading');
					reload();
				}
			}
		}
		super.update(elapsed);
	}

	function changeSelectedButton(add:Int = 0)
	{
		var max = buttons.length - 1;

		var button = getButton();
		button.ignoreCheck = button.onFocus = false;

		curSelectedButton += add;
		if (curSelectedButton < -2)
			curSelectedButton = -2;
		else if (curSelectedButton > max)
			curSelectedButton = max;

		var button = getButton();
		button.ignoreCheck = button.onFocus = true;

		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod != null)
			curMod.selectBg.visible = false;
		if (curSelectedButton < 0)
		{
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		}
		else
		{
			bgButtons.color = FlxColor.WHITE;
			bgButtons.alpha = 0.8;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function getButton()
	{
		switch (curSelectedButton)
		{
			case -2:
				return buttonReload;
			case -1:
				return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
		}

		if (modsList.all.length < 1)
			return buttonReload;
		return buttons[Std.int(Math.max(0, Math.min(buttons.length - 1, curSelectedButton)))];
	}

	function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false)
	{
		var max = modsList.all.length - 1;
		if (max < 0)
			return;

		if (hoveringOnMods)
		{
			var button = getButton();
			button.ignoreCheck = button.onFocus = false;
		}

		var lastSelected = curSelectedMod;
		curSelectedMod += add;

		var limited:Bool = false;
		if (curSelectedMod < 0)
		{
			curSelectedMod = 0;
			limited = true;
		}
		else if (curSelectedMod > max)
		{
			curSelectedMod = max;
			limited = true;
		}

		if (!controls.mobileC && !isMouseWheel && limited && Math.abs(add) == 1)
		{
			if (add < 0)
			{
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -1;
				changeSelectedButton();
				return;
			}
			else
			{
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -2;
				changeSelectedButton();
				return;
			}
		}

		holdingMod = false;
		holdingElapsed = 0;
		gottaClickAgain = true;
		updateModDisplayData();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		if (hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null)
				curMod.selectBg.visible = true;
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		}
	}

	function updateModDisplayData()
	{
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod == null)
			return;

		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 1, bg.color, curMod.bgColor);

		if (Math.abs(centerMod - curSelectedMod) > 2)
		{
			if (centerMod < curSelectedMod)
				centerMod = curSelectedMod - 2;
			else
				centerMod = curSelectedMod + 2;
		}
		updateItemPositions();

		icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		icon.antialiasing = curMod.icon.antialiasing;

		if (curMod.totalFrames > 0)
		{
			icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			icon.animation.play("icon");
			icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}

		if (modName.scaleX != 0.8)
			modName.setScale(0.8);
		modName.text = curMod.name;
		var newScale = Math.min(620 / (modName.width / 0.8), 0.8);
		modName.setScale(newScale, Math.min(newScale * 1.35, 0.8));
		modName.y = modNameInitialY - (modName.height / 2);
		modRestartText.visible = curMod.mustRestart;
		modDesc.text = curMod.desc;
		refreshPreviews(curMod.folder);

		for (button in buttons)
			if (button.focusChangeCallback != null)
				button.focusChangeCallback(button.onFocus);
		settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
	}

	var centerMod:Int = 2;

	function updateItemPositions()
	{
		var maxVisible = Math.max(4, centerMod + 2);
		var minVisible = Math.max(0, centerMod - 2);
		for (i => mod in modsGroup.members)
		{
			if (mod == null)
			{
				trace('Mod #$i is null, maybe it was ' + modsList.all[i]);
				continue;
			}

			mod.visible = (i >= minVisible && i <= maxVisible);
			mod.x = bgList.x + 5;
			mod.y = bgList.y + (86 * (i - centerMod + 2)) + 5;

			mod.alpha = 0.6;
			if (i == curSelectedMod)
				mod.alpha = 1;
			mod.selectBg.visible = (i == curSelectedMod && hoveringOnMods);
		}
	}

	var waitingToRestart:Bool = false;

	function moveModToPosition(?mod:String = null, position:Int = 0)
	{
		if (mod == null)
			mod = modsList.all[curSelectedMod];
		if (position >= modsList.all.length)
			position = 0;
		else if (position < 0)
			position = modsList.all.length - 1;

		trace('Moved mod $mod to position $position');
		var id:Int = modsList.all.indexOf(mod);
		if (position == id)
			return;

		var curMod:ModItem = modsGroup.members[id];
		if (curMod == null)
			return;

		if (curMod.mustRestart || modsGroup.members[position].mustRestart)
			waitingToRestart = true;

		modsGroup.remove(curMod, true);
		modsList.all.remove(mod);
		modsGroup.insert(position, curMod);
		modsList.all.insert(position, mod);

		curSelectedMod = position;
		updateModDisplayData();
		updateItemPositions();

		if (!hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null)
				curMod.selectBg.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function makeRound(x:Float, y:Float, w:Int, h:Int, ellipse:Int, color:FlxColor):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite(x, y).makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		return FlxSpriteUtil.drawRoundRect(spr, 0, 0, w, h, ellipse, ellipse, color);
	}

	function mouseIn(x:Float, y:Float, w:Float, h:Float):Bool
	{
		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;
		return mx >= x && mx <= x + w && my >= y && my <= y + h;
	}

	function renderCover(src:BitmapData, w:Int, h:Int, ellipse:Int):BitmapData
	{
		var cur:BitmapData = src;
		while (Math.max(w / cur.width, h / cur.height) <= 0.5 && cur.width > 2 && cur.height > 2)
		{
			var half:BitmapData = new BitmapData(Math.ceil(cur.width / 2), Math.ceil(cur.height / 2), true, 0x00000000);
			var hm:Matrix = new Matrix();
			hm.scale(0.5, 0.5);
			half.draw(cur, hm, null, null, null, true);
			if (cur != src)
				cur.dispose();
			cur = half;
		}

		var s:Float = Math.max(w / cur.width, h / cur.height);
		var m:Matrix = new Matrix();
		m.scale(s, s);
		m.translate((w - cur.width * s) / 2, (h - cur.height * s) / 2);

		var shape:Shape = new Shape();
		shape.graphics.beginBitmapFill(cur, m, false, true);
		shape.graphics.drawRoundRect(0, 0, w, h, ellipse, ellipse);
		shape.graphics.endFill();

		var out:BitmapData = new BitmapData(w, h, true, 0x00000000);
		out.draw(shape, null, null, null, null, true);
		if (cur != src)
			cur.dispose();
		return out;
	}

	function fitSprite(spr:FlxSprite, g:FlxGraphic, x:Float, y:Float, w:Float, h:Float)
	{
		spr.loadGraphic(g);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		var s:Float = Math.min(w / spr.frameWidth, h / spr.frameHeight);
		spr.scale.set(s, s);
		spr.updateHitbox();
		spr.setPosition(x + (w - spr.width) / 2, y + (h - spr.height) / 2);
	}

	function updateBottomHint()
	{
		if (bottomText == null)
			return;
		var extra:String = '';
		if (!controls.mobileC)
		{
			if (hasGallery)
				extra += '   |   ENTER: enlarge preview';
			if (descMax > 0)
				extra += '   |   PAGE UP/DOWN: scroll description';
		}
		bottomText.text = bottomBase + extra;
	}

	function scanPreviews(folder:String):Array<String>
	{
		var dir:String = Paths.mods('$folder/images/previews');
		var firsts:Array<String> = [];
		var rest:Array<String> = [];
		try
		{
			if (!NativeFileSystem.exists(dir))
				return [];
			for (f in NativeFileSystem.readDirectory(dir))
			{
				var lower:String = f.toLowerCase();
				var ext:String = null;
				for (e in PV_EXTS)
					if (lower.endsWith(e))
					{
						ext = e;
						break;
					}
				if (ext == null)
					continue;

				var name:String = lower.substr(0, lower.length - ext.length);
				if (name.endsWith('-first'))
					firsts.push(f);
				else
					rest.push(f);
			}
		}
		catch (e:Dynamic)
		{
			trace('[Mods] cannot read previews of "$folder": $e');
			return [];
		}

		var byName = function(a:String, b:String):Int return Reflect.compare(a.toLowerCase(), b.toLowerCase());
		firsts.sort(byName);
		rest.sort(byName);

		var all:Array<String> = [for (f in firsts.concat(rest)) '$dir/$f'];
		if (all.length > PV_MAX)
			all = all.slice(0, PV_MAX);
		return all;
	}

	function galleryWanted():Bool
	{
		return pvWaiting || pvLoading || previewPaths.length > 0;
	}

	function refreshPreviews(folder:String)
	{
		if (shownFolder != folder)
		{
			shownFolder = folder;
			descScroll = descTarget = 0;
			
			if (ClientPrefs.data.modPreviews)
				previewQueue = scanPreviews(folder);
			else
				previewQueue = [];
				
			previewPaths = [];
			fsCache = new Map();
			pvLoading = false;
			pvWaiting = previewQueue.length > 0;
			previewTimer = PV_DELAY;
		}
		layoutDesc(galleryWanted());
	}

	function applyToSprite(spr:FlxSprite, bmp:BitmapData, key:String)
	{
		var g:FlxGraphic = CacheSystem.cacheBitmap(key, bmp);
		spr.loadGraphic(g);
		spr.scale.set(1, 1);
		spr.updateHitbox();
		spr.antialiasing = ClientPrefs.data.antialiasing;
		FlxTween.cancelTweensOf(spr);
		spr.alpha = 0;
		spr.visible = true;
		FlxTween.tween(spr, {alpha: 1}, 0.25);
	}

	function loadNextPreview()
	{
		if (pvIdx >= previewQueue.length)
		{
			pvLoading = false;
			layoutDesc(galleryWanted());
			return;
		}

		var p:String = previewQueue[pvIdx++];
		var bmp:BitmapData = null;
		try
		{
			bmp = NativeFileSystem.getBitmap(p);
		}
		catch (e:Dynamic)
		{
			bmp = null;
		}
		if (bmp == null)
			return;

		if (bmp.width < PV_MIN_W || bmp.height < PV_MIN_H || bmp.width > PV_MAX_W || bmp.height > PV_MAX_H)
		{
			trace('[Mods] preview "$p" is ${bmp.width}x${bmp.height}: allowed sizes are from ${PV_MIN_W}x${PV_MIN_H} to ${PV_MAX_W}x${PV_MAX_H}');
			return;
		}

		var slot:Int = previewPaths.length;
		if (slot == 0)
			applyToSprite(bigSpr, renderCover(bmp, PV_BIG_W, PV_BIG_H, PV_ELL_BIG), p + '#pvbig');
		else
			applyToSprite(thumbSprs[slot - 1], renderCover(bmp, PV_TH_W, PV_TH_H, PV_ELL_TH), p + '#pvthumb');
		previewPaths.push(p);
		refreshSlots();
	}

	/** Full-size image for the fullscreen view. Decoded only when you open it. */
	function getFullGraphic(i:Int):FlxGraphic
	{
		var p:String = previewPaths[i];
		var g:FlxGraphic = fsCache.get(p);
		if (g != null)
			return g;
		var bmp:BitmapData = null;
		try
		{
			bmp = NativeFileSystem.getBitmap(p);
		}
		catch (e:Dynamic)
		{
			bmp = null;
		}
		if (bmp == null)
			return null;
		g = CacheSystem.cacheBitmap(p, bmp);
		fsCache.set(p, g);
		return g;
	}

	function refreshSlots()
	{
		var loaded:Int = previewPaths.length;
		var slots:Int = (hasGallery && (pvWaiting || pvLoading)) ? previewQueue.length : loaded;
		bigBack.visible = hasGallery;
		bigSpr.visible = hasGallery && loaded > 0;
		bigLabel.visible = bigLabelBg.visible = hasGallery && loaded > 0;
		for (i in 0...PV_MAX)
		{
			thumbBacks[i].visible = hasGallery && i < slots - 1;
			thumbSprs[i].visible = hasGallery && i < loaded - 1;
			thumbFrames[i].visible = false;
		}
		bigFrame.visible = false;
		if (loaded > 0)
			setBigLabel(loaded == 1 ? '1 IMAGE' : '$loaded IMAGES');
	}

	function setBigLabel(t:String)
	{
		if (bigLabel.text == t)
			return;
		bigLabel.text = t;
		var w:Int = Std.int(bigLabel.textField.textWidth) + 20;
		var h:Int = 24;
		bigLabelBg.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(bigLabelBg, 0, 0, w, h, 14, 14, FlxColor.BLACK);
		bigLabelBg.setPosition(bigBack.x + 10, bigBack.y + PV_BIG_H - h - 10);
		bigLabel.setPosition(bigLabelBg.x + 10, bigLabelBg.y + (h - bigLabel.height) / 2);
	}

	/** Switches the panel between "description only" and "gallery on top + description below". */
	function layoutDesc(gallery:Bool)
	{
		hasGallery = gallery;
		descViewX = bgDescription.x + 15;
		descViewW = bgDescription.width - 30 - DESC_SB;
		if (gallery)
		{
			descViewY = bgDescription.y + 222;
			descViewH = DESC_AREA_H - 222 - 6;
		}
		else
		{
			descViewY = bgDescription.y + 12;
			descViewH = DESC_AREA_H - 24;
		}

		modDesc.size = gallery ? 18 : 24;
		modDesc.fieldWidth = descViewW;
		modDesc.x = descViewX;

		previewGroup.visible = gallery;
		refreshSlots();

		descMax = Math.max(0, modDesc.textField.textHeight + 6 - descViewH);
		if (descMax < 2)
			descMax = 0;
		descScroll = FlxMath.bound(descScroll, 0, descMax);
		descTarget = FlxMath.bound(descTarget, 0, descMax);
		applyDescScroll();
		updateBottomHint();
	}

	function galleryHit():Int
	{
		var n:Int = previewPaths.length;
		if (!hasGallery || n < 1)
			return -1;
		if (mouseIn(bigBack.x, bigBack.y, PV_BIG_W, PV_BIG_H))
			return HIT_BIG;
		for (i in 0...n - 1)
			if (mouseIn(thumbBacks[i].x, thumbBacks[i].y, PV_TH_W, PV_TH_H))
				return i + 1;
		return -1;
	}

	function updateGallery():Bool
	{
		var n:Int = previewPaths.length;
		if (!hasGallery || n < 1)
			return false;

		var hit:Int = galleryHit();
		var hover:Int = controls.controllerMode ? -1 : hit;
		bigFrame.visible = (hover == HIT_BIG);
		for (i in 0...PV_MAX)
			thumbFrames[i].visible = (hover == i + 1);
		if (hover == HIT_BIG)
			setBigLabel(controls.mobileC ? 'TAP TO ENLARGE' : 'CLICK TO ENLARGE');
		else
			setBigLabel(n == 1 ? '1 IMAGE' : '$n IMAGES');

		var open:Int = -1;
		if (FlxG.mouse.justPressed && hit >= 0)
			open = (hit == HIT_BIG) ? 0 : hit;
		else if (hoveringOnMods && controls.ACCEPT)
			open = 0;

		if (open < 0)
			return false;
		openFs(open);
		return true;
	}

	function setMenuActive(on:Bool)
	{
		buttonReload.active = on;
		for (b in buttons)
			b.active = on;
		if (on)
			checkToggleButtons();
		else
			buttonEnableAll.active = buttonDisableAll.active = false;
	}

	function openFs(i:Int)
	{
		if (previewPaths.length < 1)
			return;
		fsOpen = true;
		fsIndex = i;
		fsDownX = -1;
		gottaClickAgain = true;
		bigFrame.visible = false;
		for (f in thumbFrames)
			f.visible = false;

		FlxTween.cancelTweensOf(fsBg);
		fsBg.alpha = 0;
		fsGroup.visible = true;
		FlxTween.tween(fsBg, {alpha: 0.94}, 0.18);

		setMenuActive(false);
		showFsImage();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function closeFs()
	{
		fsOpen = false;
		gottaClickAgain = true;
		setMenuActive(true);
		fsPrev.visible = fsNext.visible = fsHint.visible = false;
		FlxTween.cancelTweensOf(fsBg);
		FlxTween.cancelTweensOf(fsSpr);
		FlxTween.tween(fsSpr, {alpha: 0}, 0.12);
		FlxTween.tween(fsBg, {alpha: 0}, 0.12, {onComplete: function(_) if (!fsOpen) fsGroup.visible = false});
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
	}

	function fsMove(d:Int)
	{
		var n:Int = previewPaths.length;
		if (n < 2)
			return;
		fsIndex = FlxMath.wrap(fsIndex + d, 0, n - 1);
		showFsImage();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function showFsImage()
	{
		var n:Int = previewPaths.length;
		var g:FlxGraphic = getFullGraphic(fsIndex);

		fsPrev.visible = fsNext.visible = n > 1;
		fsHint.visible = true;

		var hint:String = '${fsIndex + 1} / $n';
		if (n > 1)
			hint += controls.mobileC ? '   Swipe or tap the edges to switch' : '   LEFT/RIGHT or mouse wheel to switch';
		hint += controls.mobileC ? '   Tap or B to close' : '   Click or BACKSPACE to close';

		FlxTween.cancelTweensOf(fsSpr);
		FlxTween.cancelTweensOf(fsSpr.scale);
		if (g == null)
		{
			fsSpr.visible = false;
			hint = 'Could not load this image   ' + hint;
		}
		else
		{
			fitSprite(fsSpr, g, 0, 0, FlxG.width, FlxG.height - 30);
			var s:Float = fsSpr.scale.x;
			fsSpr.visible = true;
			fsSpr.alpha = 0;
			fsSpr.scale.set(s * 0.96, s * 0.96);
			FlxTween.tween(fsSpr, {alpha: 1}, 0.18);
			FlxTween.tween(fsSpr.scale, {x: s, y: s}, 0.18, {ease: FlxEase.quadOut});
		}
		fsHint.text = hint;
	}

	function updateFullscreen()
	{
		if (controls.BACK || controls.ACCEPT)
		{
			closeFs();
			return;
		}

		var n:Int = previewPaths.length;
		if (n > 1)
		{
			if (controls.UI_LEFT_P || controls.UI_UP_P)
				fsMove(-1);
			else if (controls.UI_RIGHT_P || controls.UI_DOWN_P)
				fsMove(1);
			else if (FlxG.mouse.wheel != 0)
				fsMove(FlxG.mouse.wheel > 0 ? -1 : 1);
		}

		if (FlxG.mouse.justPressed)
			fsDownX = FlxG.mouse.x;
		if (FlxG.mouse.justReleased && fsDownX >= 0)
		{
			var down:Float = fsDownX;
			var dx:Float = FlxG.mouse.x - fsDownX;
			fsDownX = -1;
			if (n > 1 && Math.abs(dx) > 60)
				fsMove(dx > 0 ? -1 : 1);
			else if (Math.abs(dx) < 20)
			{
				if (n > 1 && down < FS_EDGE)
					fsMove(-1);
				else if (n > 1 && down > FlxG.width - FS_EDGE)
					fsMove(1);
				else
					closeFs();
			}
		}
	}

	function wheelOnDesc():Bool
	{
		return descMax > 0 && mouseIn(descViewX, descViewY, descViewW + DESC_SB + 4, descViewH);
	}

	function scrollDesc(dy:Float)
	{
		descTarget = FlxMath.bound(descTarget + dy, 0, descMax);
	}

	function applyDescScroll()
	{
		modDesc.y = descViewY - descScroll;
		modDesc.clipRect = (descMax > 0) ? FlxRect.get(0, descScroll, descViewW + 4, descViewH) : null;

		var on:Bool = descMax > 0;
		descTrack.visible = descThumb.visible = on;
		if (!on)
			return;
		descTrack.setGraphicSize(4, Std.int(descViewH));
		descTrack.updateHitbox();
		descTrack.setPosition(descViewX + descViewW + 2, descViewY);
		var th:Float = Math.max(24, descViewH * descViewH / (descViewH + descMax));
		descThumb.setGraphicSize(4, Std.int(th));
		descThumb.updateHitbox();
		descThumb.x = descTrack.x;
		descThumb.y = descViewY + (descViewH - th) * (descScroll / descMax);
	}

	function updateDescScroll(elapsed:Float)
	{
		if (descMax <= 0)
		{
			descDragging = false;
			return;
		}

		var over:Bool = wheelOnDesc();
		if (over && FlxG.mouse.wheel != 0)
			scrollDesc(-FlxG.mouse.wheel * 54);

		if (FlxG.keys.pressed.PAGEUP)
			scrollDesc(-520 * elapsed);
		if (FlxG.keys.pressed.PAGEDOWN)
			scrollDesc(520 * elapsed);

		var pad = FlxG.gamepads.lastActive;
		if (pad != null)
		{
			var ry:Float = pad.analog.value.RIGHT_STICK_Y;
			if (Math.abs(ry) > 0.3)
				scrollDesc(ry * 520 * elapsed);
		}

		if (FlxG.mouse.justPressed && over)
		{
			descDragging = true;
			descDragY = FlxG.mouse.y;
		}
		if (descDragging)
		{
			if (FlxG.mouse.pressed)
			{
				descTarget = FlxMath.bound(descTarget + (descDragY - FlxG.mouse.y), 0, descMax);
				descScroll = descTarget;
				descDragY = FlxG.mouse.y;
				applyDescScroll();
				return;
			}
			descDragging = false;
		}

		if (descScroll != descTarget)
		{
			descScroll = FlxMath.lerp(descScroll, descTarget, FlxMath.bound(elapsed * 16, 0, 1));
			if (Math.abs(descScroll - descTarget) < 0.4)
				descScroll = descTarget;
			applyDescScroll();
		}
	}

	function checkToggleButtons()
	{
		var anyDisabledMods = modsList.disabled.length > 0;
		buttonEnableAll.visible = buttonEnableAll.enabled = buttonEnableAll.active = anyDisabledMods;
		buttonDisableAll.visible = buttonDisableAll.enabled = buttonDisableAll.active = !anyDisabledMods;
	}

	function reload()
	{
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		MusicBeatState.switchState(new ModsMenuState(curMod != null ? curMod.folder : null));
	}

	function saveTxt()
	{
		var fileStr:String = '';
		for (mod in modsList.all)
		{
			if (mod.trim().length < 1)
				continue;

			if (fileStr.length > 0)
				fileStr += '\n';

			var on = '1';
			if (modsList.disabled.contains(mod))
				on = '0';
			fileStr += '$mod|$on';
		}

		var path:String = StorageUtil.getStorageDirectory()+'/modsList.txt';
		try{
			File.saveContent(path, fileStr);
		}
		catch(x:Exception){}

		Mods.parseList();
		Mods.loadTopMod();
	}
}

class ModItem extends FlxSpriteGroup
{
	public var selectBg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var iconFps:Int = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic = null;
	public var folder:String = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String)
	{
		super();

		this.folder = folder;
		pack = Mods.getPack(folder);

		var path:String = Paths.mods('$folder/data/settings.json');
		if (NativeFileSystem.exists(path))
		{
			try
			{
				settings = tjson.TJSON.parse(File.getContent(path));
			}
			catch (e:Dynamic)
			{
				var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
				var errorMsg = 'An error occurred: $e';
				CoolUtil.showPopUp(errorMsg, errorTitle);
			}
		}

		selectBg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectBg.alpha = 0.8;
		selectBg.visible = false;
		add(selectBg);

		icon = new FlxSprite(5, 5);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		text = new FlxText(95, 38, 230, "", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		text.y -= Std.int(text.height / 2);
		add(text);

		var isPixel = false;
		var file:String = Paths.mods('$folder/pack.png');
		if (!NativeFileSystem.exists(file))
		{
			file = Paths.mods('$folder/pack-pixel.png');
			isPixel = true;
		}

		var bmp:BitmapData = NativeFileSystem.getBitmap(file);	

		if (bmp != null)
		{
			icon.loadGraphic(CacheSystem.cacheBitmap(file, bmp), true, 150, 150);
			if (isPixel)
				icon.antialiasing = false;
		}
		else{
			isPixel = false;
			icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);
		}
		icon.scale.set(0.5, 0.5);
		icon.updateHitbox();

		this.name = folder;
		if (pack != null)
		{
			if (pack.name != null)
				this.name = pack.name;
			if (pack.description != null)
				this.desc = pack.description;
			if (pack.iconFramerate != null)
				this.iconFps = pack.iconFramerate;
			if (pack.color != null)
			{
				this.bgColor = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170, pack.color[1] != null ? pack.color[1] : 0,
					pack.color[2] != null ? pack.color[2] : 255);
			}
			this.mustRestart = (pack.restart == true);
		}
		text.text = this.name;

		if (bmp != null)
		{
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}
		selectBg.scale.set(width + 5, height + 5);
		selectBg.updateHitbox();
	}
}

class MenuButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;
	private var skipThisFrame:Bool = false;

	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0,
			animHeight:Int = 0)
	{
		super(x, y);

		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 15, 15, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		add(bg);

		if (text != null)
		{
			textOn = new Alphabet(0, 0, "", false);
			textOn.setScale(0.6);
			textOn.text = text;
			textOn.alpha = 0.6;
			textOn.visible = false;
			centerOnBg(textOn);
			textOn.y -= 30;
			add(textOn);

			textOff = new Alphabet(0, 0, "", true);
			textOff.setScale(0.52);
			textOff.text = text;
			textOff.alpha = 0.6;
			centerOnBg(textOff);
			add(textOff);
		}
		else if (img != null)
		{
			icon = new FlxSprite();
			if (animWidth > 0 || animHeight > 0)
				icon.loadGraphic(img, true, animWidth, animHeight);
			else
				icon.loadGraphic(img);
			centerOnBg(icon);
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;

	private var _needACheck:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!enabled)
		{
			onFocus = false;
			return;
		}

		if (Controls.instance.mobileC)
		{
			if (!ignoreCheck)
				onFocus = TouchUtil.overlaps(this);

			if (onFocus && TouchUtil.justReleased)
				onFocus = false;

			if (onFocus && onClick != null && !skipThisFrame && TouchUtil.justPressed)
				onClick();

			if (_needACheck)
			{
				_needACheck = false;
				setButtonVisibility(TouchUtil.overlaps(this));
			}
		}
		else{

			if (!ignoreCheck && !Controls.instance.controllerMode && FlxG.mouse.justMoved && FlxG.mouse.visible)
				onFocus = FlxG.mouse.overlaps(this);

			if (onFocus && onClick != null && !skipThisFrame &&  FlxG.mouse.justPressed)
				onClick();
			
			if (_needACheck)
				{
					_needACheck = false;
					if (!Controls.instance.controllerMode)
						setButtonVisibility(FlxG.mouse.overlaps(this));
				}
			}
		skipThisFrame = false;
	}

	function set_onFocus(newValue:Bool)
	{
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if (onFocus != lastFocus && enabled)
			setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool)
	{
		enabled = newValue;
		skipThisFrame = true;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;

		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool)
	{
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : FlxColor.BLACK;
		bg.alpha = focusVal ? 0.8 : 0.6;

		var focusAlpha = focusVal ? 1 : 0.6;
		if (textOn != null && textOff != null)
		{
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible = focusVal;
			textOff.visible = !focusVal;
		}
		else if (icon != null)
		{
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}

		if (!enabled)
			alpha = 0.4;
		if (focusChangeCallback != null)
			focusChangeCallback(focusVal);
	}

	public function centerOnBg(spr:FlxSprite)
	{
		spr.x = bg.width / 2 - spr.width / 2;
		spr.y = bg.height / 2 - spr.height / 2;
	}
}