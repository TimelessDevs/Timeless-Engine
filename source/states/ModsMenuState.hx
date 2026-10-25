package states;

import openfl.display.BitmapData;
import backend.Mods;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSpriteUtil;
import options.ModSettingsSubState;
import mikolka.vslice.ui.title.TitleState;
import mikolka.funkin.custom.mobile.MobileScaleMode;

class ModsMenuState extends MusicBeatState
{
	public static var modsGroup:FlxTypedGroup<ModItem>;
	public static var curSelectedMod:Int = 0;

	var modsList:ModsList;
	var startMod:String;
	var bg:FlxSprite;
	var headerText:FlxText;
	var countText:FlxText;
	var listPanel:FlxSprite;
	var detailPanel:FlxSprite;
	var accent:FlxSprite;
	var detailIcon:FlxSprite;
	var detailName:FlxText;
	var detailFolder:FlxText;
	var detailDesc:FlxText;
	var statusText:FlxText;
	var hintText:FlxText;
	var actionLabels:Array<FlxText> = [];
	var actionNames:Array<String> = ["TOGGLE MOD", "MOD SETTINGS", "MOVE UP", "MOVE DOWN", "ENABLE ALL", "DISABLE ALL", "RELOAD LIST"];
	var selectedAction:Int = 0;
	var inActions:Bool = false;
	var exiting:Bool = false;
	var waitingToRestart:Bool = false;
	var controllerMode:Bool = false;
	var noModsText:FlxText;
	var refreshTimer:Float = 1;

	static inline var BG_COLOR:Int = 0xFF10131C;
	static inline var PANEL_COLOR:Int = 0xFF191E2B;
	static inline var PANEL_LIGHT:Int = 0xFF232A3A;
	static inline var TEXT_COLOR:Int = 0xFFF3F5FA;
	static inline var MUTED_COLOR:Int = 0xFF9AA5B8;
	static inline var ACCENT_COLOR:Int = 0xFF9B7BFF;
	static inline var GREEN_COLOR:Int = 0xFF53D6A0;
	static inline var RED_COLOR:Int = 0xFFFF7185;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	override function create()
	{
		CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();
		persistentUpdate = false;
		modsList = Mods.parseList();
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().makeGraphic(1, 1, BG_COLOR);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		// Soft color fields give the screen depth without depending on external assets.
		var glow = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF171A2A);
		glow.alpha = 0.65;
		add(glow);

		var margin:Float = Math.max(28, FlxG.width * 0.045);
		var top:Float = 28;
		headerText = new FlxText(margin, top, FlxG.width - margin * 2, "MODS", 42);
		headerText.setFormat(Paths.font("vcr.ttf"), 42, TEXT_COLOR, LEFT);
		add(headerText);

		countText = new FlxText(margin, top + 48, FlxG.width - margin * 2, "", 16);
		countText.setFormat(Paths.font("vcr.ttf"), 16, MUTED_COLOR, LEFT);
		add(countText);

		var contentTop:Float = top + 88;
		var contentHeight:Float = FlxG.height - contentTop - 56;
		var listWidth:Float = Math.min(FlxG.width * 0.38, 430);
		var gap:Float = 18;
		var rightWidth:Float = FlxG.width - margin * 2 - listWidth - gap;

		listPanel = panel(margin, contentTop, listWidth, contentHeight, PANEL_COLOR);
		add(listPanel);
		detailPanel = panel(margin + listWidth + gap, contentTop, rightWidth, contentHeight, PANEL_COLOR);
		add(detailPanel);

		modsGroup = new FlxTypedGroup<ModItem>();
		for (i => folder in modsList.all)
		{
			var item = new ModItem(folder);
			item.x = listPanel.x + 12;
			item.y = listPanel.y + 12 + i * 76;
			item.scale.set(0.9, 0.9);
			if (modsList.disabled.contains(folder))
			{
				item.icon.color = RED_COLOR;
				item.text.color = MUTED_COLOR;
			}
			modsGroup.add(item);
		}
		add(modsGroup);

		var rightX = detailPanel.x + 28;
		var rightY = detailPanel.y + 26;
		accent = new FlxSprite(rightX, rightY).makeGraphic(5, 88, ACCENT_COLOR);
		add(accent);

		detailIcon = new FlxSprite(rightX + 20, rightY);
		detailIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(detailIcon);

		detailName = new FlxText(rightX + 190, rightY + 3, rightWidth - 235, "", 30);
		detailName.setFormat(Paths.font("vcr.ttf"), 30, TEXT_COLOR, LEFT);
		add(detailName);

		detailFolder = new FlxText(rightX + 190, rightY + 43, rightWidth - 235, "", 15);
		detailFolder.setFormat(Paths.font("vcr.ttf"), 15, MUTED_COLOR, LEFT);
		add(detailFolder);

		var divider = new FlxSprite(rightX, rightY + 112).makeGraphic(Std.int(rightWidth - 56), 2, 0xFF30384A);
		add(divider);

		var descLabel = new FlxText(rightX, rightY + 132, rightWidth - 56, "DESCRIPTION", 14);
		descLabel.setFormat(Paths.font("vcr.ttf"), 14, ACCENT_COLOR, LEFT);
		add(descLabel);

		detailDesc = new FlxText(rightX, rightY + 160, rightWidth - 56, "", 19);
		detailDesc.setFormat(Paths.font("vcr.ttf"), 19, TEXT_COLOR, LEFT);
		detailDesc.wordWrap = true;
		add(detailDesc);

		statusText = new FlxText(rightX, detailPanel.y + contentHeight - 115, rightWidth - 56, "", 16);
		statusText.setFormat(Paths.font("vcr.ttf"), 16, GREEN_COLOR, LEFT);
		add(statusText);

		var actionTop:Float = detailPanel.y + contentHeight - 76;
		var actionWidth:Float = (rightWidth - 56 - 12) / 2;
		for (i in 0...actionNames.length)
		{
			var col = i % 2;
			var row = Math.floor(i / 2);
			var x = rightX + col * (actionWidth + 12);
			var y = actionTop + row * 35;
			var label = new FlxText(x, y, actionWidth, actionNames[i], 15);
			label.setFormat(Paths.font("vcr.ttf"), 15, i == 0 ? ACCENT_COLOR : TEXT_COLOR, LEFT);
			actionLabels.push(label);
			add(label);
		}

		hintText = new FlxText(margin, FlxG.height - 30, FlxG.width - margin * 2, "↑ / ↓ SELECT     ENTER CONFIRM     ← / → SWITCH PANEL     ESC BACK", 13);
		hintText.setFormat(Paths.font("vcr.ttf"), 13, MUTED_COLOR, CENTER);
		add(hintText);

		if (modsList.all.length == 0)
		{
			noModsText = new FlxText(listPanel.x + 18, listPanel.y + 28, listWidth - 36,
				"NO MODS FOUND\n\nPlace mods in your mods folder.\nThis screen will refresh automatically.", 18);
			noModsText.setFormat(Paths.font("vcr.ttf"), 18, MUTED_COLOR, CENTER);
			add(noModsText);
		}
		else
		{
			if (startMod != null)
			{
				var found = modsList.all.indexOf(startMod);
				if (found >= 0) curSelectedMod = found;
			}
			curSelectedMod = Std.int(Math.max(0, Math.min(modsList.all.length - 1, curSelectedMod)));
		}

		controllerMode = controls.controllerMode;
		FlxG.mouse.visible = !controllerMode;
		refreshLayout();
		super.create();
	}

	function panel(x:Float, y:Float, width:Float, height:Float, color:Int):FlxSprite
	{
		var sprite = new FlxSprite(x, y).makeGraphic(Std.int(width), Std.int(height), color);
		sprite.scrollFactor.set();
		return sprite;
	}

	override function update(elapsed:Float)
	{
		if (!exiting && controls.BACK)
		{
			leaveMenu();
			return;
		}

		if (controls.controllerMode != controllerMode)
		{
			controllerMode = controls.controllerMode;
			FlxG.mouse.visible = !controllerMode;
		}
		if (Math.abs(FlxG.mouse.deltaX) > 3 || Math.abs(FlxG.mouse.deltaY) > 3)
		{
			controls.controllerMode = false;
			FlxG.mouse.visible = true;
		}

		if (modsList.all.length > 0)
		{
			if (FlxG.mouse.wheel != 0 && FlxG.mouse.overlaps(listPanel))
				selectMod(-FlxG.mouse.wheel);
			if (controls.UI_UP_P)
			{
				if (inActions) selectedAction = (selectedAction + actionNames.length - 1) % actionNames.length;
				else selectMod(-1);
				refreshLayout();
			}
			if (controls.UI_DOWN_P)
			{
				if (inActions) selectedAction = (selectedAction + 1) % actionNames.length;
				else selectMod(1);
				refreshLayout();
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
			{
				inActions = !inActions;
				refreshLayout();
			}
			if (controls.ACCEPT)
			{
				if (inActions) runAction(selectedAction);
				else if (FlxG.mouse.justPressed) selectFromMouse();
			}
			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(listPanel)) selectFromMouse();
				else
				{
					for (i in 0...actionLabels.length)
					{
						if (FlxG.mouse.overlaps(actionLabels[i]))
						{
							selectedAction = i;
							inActions = true;
							runAction(i);
							break;
						}
					}
				}
			}
		}
		else
		{
			refreshTimer -= elapsed;
			if (refreshTimer <= 0)
			{
				refreshTimer = 1;
				@:privateAccess Mods.updateModList();
				modsList = Mods.parseList();
				if (modsList.all.length > 0) reload();
			}
		}
		super.update(elapsed);
	}

	function refreshLayout()
	{
		countText.text = '${modsList.all.length} MODS INSTALLED  •  ${modsList.disabled.length} DISABLED';
		for (i in 0...modsGroup.members.length)
		{
			var item = modsGroup.members[i];
			if (item == null) continue;
			item.visible = i >= curSelectedMod - 3 && i <= curSelectedMod + 3;
			item.x = listPanel.x + 12;
			item.y = listPanel.y + 14 + (i - curSelectedMod + 3) * 76;
			item.selectBg.visible = !inActions && i == curSelectedMod;
			item.alpha = i == curSelectedMod ? 1 : 0.72;
		}

		for (i in 0...actionLabels.length)
		{
			actionLabels[i].color = (inActions && i == selectedAction) ? ACCENT_COLOR : TEXT_COLOR;
			actionLabels[i].alpha = actionEnabled(i) ? 1 : 0.4;
		}

		var item = currentItem();
		if (item == null)
		{
			detailName.text = "No mod selected";
			detailFolder.text = "";
			detailDesc.text = "Install a mod to see its description and available actions.";
			detailIcon.visible = false;
			accent.color = ACCENT_COLOR;
			statusText.text = "";
			return;
		}
		detailIcon.visible = true;
		detailIcon.loadGraphic(item.icon.graphic, true, 150, 150);
		detailIcon.scale.set(0.9, 0.9);
		detailIcon.updateHitbox();
		detailName.text = item.name;
		detailFolder.text = item.folder;
		detailDesc.text = item.desc;
		accent.color = item.bgColor;
		var disabled = modsList.disabled.contains(item.folder);
		statusText.color = disabled ? RED_COLOR : GREEN_COLOR;
		statusText.text = (disabled ? "● DISABLED" : "● ENABLED") + (item.mustRestart ? "     • RESTART REQUIRED" : "");
	}

	function currentItem():ModItem
	{
		if (modsGroup == null || curSelectedMod < 0 || curSelectedMod >= modsGroup.members.length) return null;
		return modsGroup.members[curSelectedMod];
	}

	function selectMod(delta:Int)
	{
		if (modsList.all.length == 0) return;
		curSelectedMod = Std.int(Math.max(0, Math.min(modsList.all.length - 1, curSelectedMod + delta)));
		inActions = false;
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.45);
		refreshLayout();
	}

	function selectFromMouse()
	{
		for (i in 0...modsGroup.members.length)
		{
			var item = modsGroup.members[i];
			if (item != null && item.visible && FlxG.mouse.overlaps(item))
			{
				curSelectedMod = i;
				inActions = false;
				refreshLayout();
				return;
			}
		}
	}

	function actionEnabled(index:Int):Bool
	{
		var item = currentItem();
		return switch (index)
		{
			case 0: item != null;
			case 1: item != null && item.settings != null && item.settings.length > 0;
			case 2, 3: modsList.all.length > 1;
			case 4: modsList.disabled.length > 0;
			case 5: modsList.disabled.length < modsList.all.length;
			case 6: true;
			default: false;
		}
	}

	function runAction(index:Int)
	{
		if (!actionEnabled(index)) return;
		var item = currentItem();
		switch (index)
		{
			case 0:
				if (modsList.disabled.contains(item.folder))
				{
					modsList.disabled.remove(item.folder);
					if (!modsList.enabled.contains(item.folder)) modsList.enabled.push(item.folder);
				}
				else
				{
					modsList.enabled.remove(item.folder);
					if (!modsList.disabled.contains(item.folder)) modsList.disabled.push(item.folder);
				}
				if (item.mustRestart) waitingToRestart = true;
				applyModColors();
				saveTxt();
				FlxG.sound.play(Paths.sound("scrollMenu"), 0.6);
			case 1:
				openSubState(new ModSettingsSubState(item.settings, item.folder, item.name));
			case 2: moveMod(-1);
			case 3: moveMod(1);
			case 4:
				for (folder in modsList.all)
				{
					modsList.disabled.remove(folder);
					if (!modsList.enabled.contains(folder)) modsList.enabled.push(folder);
				}
				waitingToRestart = true;
				applyModColors();
				saveTxt();
			case 5:
				for (folder in modsList.all)
				{
					modsList.enabled.remove(folder);
					if (!modsList.disabled.contains(folder)) modsList.disabled.push(folder);
				}
				waitingToRestart = true;
				applyModColors();
				saveTxt();
			case 6: reload();
		}
		refreshLayout();
	}

	function applyModColors()
	{
		for (item in modsGroup.members)
		{
			if (item == null) continue;
			var disabled = modsList.disabled.contains(item.folder);
			item.icon.color = disabled ? RED_COLOR : FlxColor.WHITE;
			item.text.color = disabled ? MUTED_COLOR : TEXT_COLOR;
		}
	}

	function moveMod(delta:Int)
	{
		var target = curSelectedMod + delta;
		if (target < 0 || target >= modsList.all.length) return;
		var moving = modsList.all[curSelectedMod];
		var movingItem = modsGroup.members[curSelectedMod];
		var otherItem = modsGroup.members[target];
		if (movingItem == null || otherItem == null) return;
		if (movingItem.mustRestart || otherItem.mustRestart) waitingToRestart = true;

		modsList.all[curSelectedMod] = modsList.all[target];
		modsList.all[target] = moving;
		modsGroup.members[curSelectedMod] = otherItem;
		modsGroup.members[target] = movingItem;
		curSelectedMod = target;
		updateModOrder();
		saveTxt();
		refreshLayout();
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.6);
	}

	function updateModOrder()
	{
		for (i in 0...modsGroup.members.length)
		{
			var item = modsGroup.members[i];
			if (item != null) item.ID = i;
		}
	}

	function saveTxt()
	{
		var lines:Array<String> = [];
		for (folder in modsList.all)
			if (folder.trim().length > 0) lines.push('$folder|${modsList.disabled.contains(folder) ? "0" : "1"}');
		try File.saveContent(StorageUtil.getStorageDirectory() + "/modsList.txt", lines.join("\n")) catch (e:Dynamic) trace('Unable to save mod list: $e');
		Mods.parseList();
		Mods.loadTopMod();
	}

	function reload()
	{
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var item = currentItem();
		MusicBeatState.switchState(new ModsMenuState(item != null ? item.folder : null));
	}

	function leaveMenu()
	{
		exiting = true;
		saveTxt();
		FlxG.sound.play(Paths.sound("cancelMenu"));
		if (waitingToRestart)
		{
			TitleState.initialized = false;
			TitleState.closedState = false;
			FlxG.sound.music.fadeOut(0.3);
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
		}
		else MusicBeatState.switchState(new MainMenuState());
		persistentUpdate = false;
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxG.mouse.visible = false;
	}
}

class ModItem extends FlxSpriteGroup
{
	public var selectBg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	// options
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
				// trace('trying to load settings: $folder');
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
