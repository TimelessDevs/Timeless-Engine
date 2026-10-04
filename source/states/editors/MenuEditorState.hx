package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using StringTools;

typedef MenuLayoutData = {
	var items:Array<MenuItemProps>;
	var globalScale:Float;
	var backgroundAlpha:Float;
}

typedef MenuItemProps = {
	var name:String;
	var x:Float;
	var y:Float;
	var scaleX:Float;
	var scaleY:Float;
}

class MenuEditorState extends backend.MusicBeatState
{
	private var optionsList:Array<String> = ['story_mode', 'freeplay', 'mods', 'awards', 'credits', 'merch', 'options'];
	private var displayGroup:flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>;
	
	private var layoutData:MenuLayoutData;
	private var currentSelected:Int = 0;
	
	private var panelBackground:FlxSprite;
	private var neonTrim:FlxSprite;
	private var titleTextDisplay:FlxText;
	private var infoTextDisplay:FlxText;
	private var statusOverlayText:FlxText;
	private var selectionIndicatorBox:FlxSprite;
	
	private var targetPanelX:Float = 920;
	
	private var pulseTimer:Float = 0;
	private var titleAnimTimer:Float = 0;
	private var isDraggingItem:Bool = false;

	override function create()
	{
		FlxG.sound.playMusic(backend.Paths.music('freakyMenu'), 0.5);
		FlxG.mouse.visible = true;

		var backdrop:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image('menuDesat'));
		backdrop.color = 0xFF050208;
		backdrop.scrollFactor.set();
		add(backdrop);

		displayGroup = new flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>();
		add(displayGroup);

		loadCurrentMenuLayoutConfig();
		regenerateWorkspaceDisplayElements();

		panelBackground = new FlxSprite(1280, 20).makeGraphic(340, 680, 0xFA0B0A12);
		panelBackground.scrollFactor.set();
		add(panelBackground);

		neonTrim = new FlxSprite(1280, 20).makeGraphic(4, 680, 0xFFBF55EC);
		neonTrim.scrollFactor.set();
		add(neonTrim);

		titleTextDisplay = new FlxText(1300, 40, 300, "MENU EDITOR", 22);
		titleTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 22, 0xFFBF55EC, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF4A0E4E);
		add(titleTextDisplay);

		infoTextDisplay = new FlxText(1300, 90, 300, "", 14);
		infoTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 14, 0xFFD2B4DE, "left");
		add(infoTextDisplay);

		statusOverlayText = new FlxText(40, 650, 800, "[SYSTEM]: Timeless UI ready. Drag items with Mouse or use Arrows.", 14);
		statusOverlayText.setFormat(backend.Paths.font("vcr.ttf"), 14, 0xFF00FF66, "left");
		add(statusOverlayText);

		selectionIndicatorBox = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		selectionIndicatorBox.visible = false;
		add(selectionIndicatorBox);

		FlxTween.tween(panelBackground, {x: targetPanelX}, 0.85, {ease: FlxEase.elasticOut});
		FlxTween.tween(neonTrim, {x: targetPanelX}, 0.85, {ease: FlxEase.elasticOut});
		FlxTween.tween(titleTextDisplay, {x: targetPanelX + 20}, 0.85, {ease: FlxEase.elasticOut});
		FlxTween.tween(infoTextDisplay, {x: targetPanelX + 20}, 0.85, {
			ease: FlxEase.elasticOut,
			onComplete: function(twn:FlxTween) {
				updateDashboardTextLogFeed();
				refreshSelectionBoundingBoxWireframe(true);
			}
		});

		super.create();
	}

		private function loadCurrentMenuLayoutConfig():Void
	{
		// TIMELESS MATRIX RESOLUTION: Сканируем все три папки в строгом приоритете
		var pathsToScan:Array<String> = [
			'assets/shared/menulayouts/menu_layout.json',
			'mods/' + backend.Mods.currentModDirectory + '/menulayouts/menu_layout.json',
			'mods/menulayouts/menu_layout.json' // Наша общая папка в корне mods
		];

		var validPath:String = "";
		for (path in pathsToScan) {
			if (sys.FileSystem.exists(path)) {
				validPath = path;
				break;
			}
		}

		if (validPath != "") {
			try {
				var content:String = File.getContent(validPath);
				layoutData = Json.parse(content);
				trace("[DESIGNER SUCCESS]: Layout loaded from: " + validPath);
			} catch(e:Dynamic) {
				trace("[DESIGNER CRASH]: Failed to load layout from: " + validPath + " -> " + e);
				generateDefaultLayoutDataMatrix();
			}
		} else {
			generateDefaultLayoutDataMatrix();
		}
	}

	private function generateDefaultLayoutDataMatrix():Void
	{
		layoutData = {
			items: [],
			globalScale: 1.0,
			backgroundAlpha: 1.0
		};

		for (i in 0...optionsList.length) {
			var itemProps:MenuItemProps = {
				name: optionsList[i],
				x: 90,
				y: 60 + (i * 90),
				scaleX: 0.8,
				scaleY: 0.8
			};
			layoutData.items.push(itemProps);
		}
	}

	private function regenerateWorkspaceDisplayElements():Void
	{
		displayGroup.clear();
		
		for (i in 0...layoutData.items.length) {
			var data = layoutData.items[i];
			var spr:FlxSprite = new FlxSprite(data.x, data.y);
			spr.frames = backend.Paths.getSparrowAtlas('mainmenu/menu_' + data.name);
			spr.animation.addByPrefix('idle', 'menu_' + data.name + ' idle', 24, true);
			spr.animation.play('idle');
			spr.scale.set(data.scaleX * layoutData.globalScale, data.scaleY * layoutData.globalScale);
			spr.updateHitbox();
			spr.ID = i;
			displayGroup.add(spr);
		}
	}

	private function updateDashboardTextLogFeed():Void
	{
		if (layoutData == null || layoutData.items.length <= currentSelected) return;

		var currentItem = layoutData.items[currentSelected];
		infoTextDisplay.text = "SELECTED COMPONENT:\n[" + currentItem.name.toUpperCase() + "]\n\n"
			+ "TRANSFORMS MATRICES:\n"
			+ "Position X: " + FlxMath.roundDecimal(currentItem.x, 1) + " px\n"
			+ "Position Y: " + FlxMath.roundDecimal(currentItem.y, 1) + " px\n"
			+ "Scale Vector X: " + FlxMath.roundDecimal(currentItem.scaleX, 2) + "\n"
			+ "Scale Vector Y: " + FlxMath.roundDecimal(currentItem.scaleY, 2) + "\n\n"
			+ "GLOBAL PARAMETERS:\n"
			+ "Global Scale: " + FlxMath.roundDecimal(layoutData.globalScale, 2) + "x\n\n"
			+ "CONTROLS SHORTCUTS:\n"
			+ "• Left Click + Drag: Move Item\n"
			+ "• W/S or Wheel: Change Item\n"
			+ "• Arrow Keys: Pixel Precision\n"
			+ "• A/D: Adjust Item Scale\n"
			+ "• Q/E: Global Scale Mod\n"
			+ "• CTRL + S: Direct Save Content";
	}

	private function refreshSelectionBoundingBoxWireframe(snapInstant:Bool = false):Void
	{
		if (displayGroup == null || displayGroup.members.length <= currentSelected) return;

		var targetSprite = displayGroup.members[currentSelected];
		if (targetSprite != null && targetSprite.visible) {
			selectionIndicatorBox.visible = true;
			
			if (snapInstant) {
				selectionIndicatorBox.x = targetSprite.x - 4;
				selectionIndicatorBox.y = targetSprite.y - 4;
			} else {
				selectionIndicatorBox.x = FlxMath.lerp(selectionIndicatorBox.x, targetSprite.x - 4, flixel.math.FlxMath.bound(FlxG.elapsed * 18, 0, 1));
				selectionIndicatorBox.y = FlxMath.lerp(selectionIndicatorBox.y, targetSprite.y - 4, flixel.math.FlxMath.bound(FlxG.elapsed * 18, 0, 1));
			}
			
			selectionIndicatorBox.makeGraphic(Std.int(targetSprite.width) + 8, Std.int(targetSprite.height) + 8, FlxColor.TRANSPARENT);
			
			// Рисуем неоновые фиолетовые линии рамки
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, selectionIndicatorBox.width, 2), 0xFFBF55EC);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, selectionIndicatorBox.height - 2, selectionIndicatorBox.width, 2), 0xFFBF55EC);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, selectionIndicatorBox.height), 0xFFBF55EC);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(selectionIndicatorBox.width - 2, 0, 2, selectionIndicatorBox.height), 0xFFBF55EC);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (layoutData == null || layoutData.items.length == 0) return;

		pulseTimer += elapsed * 3;
		if (neonTrim != null) neonTrim.alpha = 0.6 + (Math.sin(pulseTimer) * 0.4);
		
		titleAnimTimer += elapsed * 2;
		if (titleTextDisplay != null) {
			titleTextDisplay.y = 40 + (Math.sin(titleAnimTimer) * 4);
		}

		var currentItem = layoutData.items[currentSelected];
		var targetSprite = displayGroup.members[currentSelected];
		var speedMultiplier:Float = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;
		var needsUpdate:Bool = false;

		if (FlxG.mouse.justPressed)
		{
			for (i in 0...displayGroup.members.length)
			{
				var spr = displayGroup.members[i];
				if (spr != null && FlxG.mouse.overlaps(spr))
				{
					FlxG.sound.play(backend.Paths.sound('scrollMenu'), 0.4);
					currentSelected = i;
					currentItem = layoutData.items[currentSelected];
					targetSprite = spr;
					isDraggingItem = true;
					needsUpdate = true;
					break;
				}
			}
		}

		if (FlxG.mouse.pressed && isDraggingItem && targetSprite != null)
		{
			currentItem.x = FlxG.mouse.x - (targetSprite.width / 2);
			currentItem.y = FlxG.mouse.y - (targetSprite.height / 2);
			targetSprite.x = currentItem.x;
			targetSprite.y = currentItem.y;
			needsUpdate = true;
		}

		if (FlxG.mouse.justReleased)
		{
			isDraggingItem = false;
		}

		if (FlxG.mouse.wheel != 0) {
			FlxG.sound.play(backend.Paths.sound('scrollMenu'));
			currentSelected -= FlxG.mouse.wheel;
			if (currentSelected < 0) currentSelected = layoutData.items.length - 1;
			if (currentSelected >= layoutData.items.length) currentSelected = 0;
			needsUpdate = true;
		}

		if (FlxG.keys.pressed.LEFT) {
			currentItem.x -= speedMultiplier;
			if (targetSprite != null) targetSprite.x = currentItem.x;
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.RIGHT) {
			currentItem.x += speedMultiplier;
			if (targetSprite != null) targetSprite.x = currentItem.x;
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.UP) {
			currentItem.y -= speedMultiplier;
			if (targetSprite != null) targetSprite.y = currentItem.y;
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.DOWN) {
			currentItem.y += speedMultiplier;
			if (targetSprite != null) targetSprite.y = currentItem.y;
			needsUpdate = true;
		}

		if (FlxG.keys.pressed.A) {
			currentItem.scaleX = FlxMath.bound(currentItem.scaleX - (0.01 * speedMultiplier), 0.1, 4.0);
			currentItem.scaleY = FlxMath.bound(currentItem.scaleY - (0.01 * speedMultiplier), 0.1, 4.0);
			if (targetSprite != null) {
				targetSprite.scale.set(currentItem.scaleX * layoutData.globalScale, currentItem.scaleY * layoutData.globalScale);
				targetSprite.updateHitbox();
			}
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.D) {
			currentItem.scaleX = FlxMath.bound(currentItem.scaleX + (0.01 * speedMultiplier), 0.1, 4.0);
			currentItem.scaleY = FlxMath.bound(currentItem.scaleY + (0.01 * speedMultiplier), 0.1, 4.0);
			if (targetSprite != null) {
				targetSprite.scale.set(currentItem.scaleX * layoutData.globalScale, currentItem.scaleY * layoutData.globalScale);
				targetSprite.updateHitbox();
			}
			needsUpdate = true;
		}

		if (FlxG.keys.pressed.Q) {
			layoutData.globalScale = FlxMath.bound(layoutData.globalScale - 0.01, 0.2, 3.0);
			regenerateWorkspaceDisplayElements();
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.E) {
			layoutData.globalScale = FlxMath.bound(layoutData.globalScale + 0.01, 0.2, 3.0);
			regenerateWorkspaceDisplayElements();
			needsUpdate = true;
		}

		if (FlxG.keys.justPressed.H) {
			FlxG.sound.play(backend.Paths.sound('scrollMenu'));
			displayStatusMessage("HELP: Drag items with Mouse | Shift=Fast Mode | Arrows=Precision | Ctrl+S=Save Layout");
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
			saveLayoutConfigToDiskStorage();
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;
			FlxG.sound.play(backend.Paths.sound('cancelMenu'));
			backend.MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}

		refreshSelectionBoundingBoxWireframe(false);

		if (needsUpdate) {
			updateDashboardTextLogFeed();
		}
	}

	private function saveLayoutConfigToDiskStorage():Void
	{
		try {
			var jsonContent:String = Json.stringify(layoutData, "\t");
			
			var directoryPath:String = 'mods/' + backend.Mods.currentModDirectory + '/menulayouts/';
			if (!FileSystem.exists(directoryPath)) {
				FileSystem.createDirectory(directoryPath);
			}

			var fullPath:String = directoryPath + 'menu_layout.json';
			File.saveContent(fullPath, jsonContent);
			
			FlxG.sound.play(backend.Paths.sound('confirmMenu'));
			displayStatusMessage("[SUCCESS]: Configuration layout file written to target paths!");
		} catch(e:Dynamic) {
			displayStatusMessage("[CRASH ERROR]: Hardware disk write failed. Check storage permissions.");
		}
	}

	private function displayStatusMessage(msg:String):Void
	{
		if (statusOverlayText != null) {
			statusOverlayText.text = msg;
			statusOverlayText.color = msg.contains("SUCCESS") ? 0xFF00FF66 : (msg.contains("ERROR") ? 0xFFFF0033 : 0xFFBF55EC);
			
			statusOverlayText.scale.set(1.05, 1.05);
			FlxTween.tween(statusOverlayText.scale, {x: 1.0, y: 1.0}, 0.25, {ease: FlxEase.cubeOut});
		}
	}

	override function destroy()
	{
		displayGroup = null;
		layoutData = null;
		optionsList = null;
		super.destroy();
	}
}