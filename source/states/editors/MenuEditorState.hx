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
	private var optionsList:Array<String> = ['story_mode', 'freeplay', 'credits', 'options'];
	private var displayGroup:flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>;
	
	// Layout configuration structures
	private var layoutData:MenuLayoutData;
	private var currentSelected:Int = 0;
	
	// Advanced Premium UI Layout components
	private var panelBackground:FlxSprite;
	private var titleTextDisplay:FlxText;
	private var infoTextDisplay:FlxText;
	private var statusOverlayText:FlxText;
	private var selectionIndicatorBox:FlxSprite;
	
	private var uiTween:FlxTween;
	private var targetPanelX:Float = 920;

	override function create()
	{
		FlxG.sound.playMusic(backend.Paths.music('freakyMenu'), 0.5);
		FlxG.mouse.visible = true;

		// 1. Render core state space backdrop components
		var backdrop:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image('menuDesat'));
		backdrop.color = 0xFF14151F; // High-effort modern matrix dark grey background
		backdrop.scrollFactor.set();
		add(backdrop);

		displayGroup = new flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>();
		add(displayGroup);

		// 2. Parse existing config layout or establish safe default fallback state matrix parameters
		loadCurrentMenuLayoutConfig();

		// 3. Build active workspace render items dynamically
		regenerateWorkspaceDisplayElements();

		// 4. Construct high-fidelity control dashboard container (Right sidebar panel layout)
		panelBackground = new FlxSprite(1280, 20).makeGraphic(340, 680, 0xFA0B0C10); // Glassmorphic cyber panel template
		panelBackground.scrollFactor.set();
		add(panelBackground);

		var neonTrim:FlxSprite = new FlxSprite(1280, 20).makeGraphic(4, 680, 0xFF64FFDA); // Aqua teal accent borders
		neonTrim.scrollFactor.set();
		add(neonTrim);

		titleTextDisplay = new FlxText(1300, 40, 300, "MENU DESIGNER", 20);
		titleTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 20, 0xFF64FFDA, "left");
		add(titleTextDisplay);

		infoTextDisplay = new FlxText(1300, 90, 300, "", 14);
		infoTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 14, 0xFF8F9BB7, "left");
		add(infoTextDisplay);

		statusOverlayText = new FlxText(40, 650, 800, "[SYSTEM]: Designer engine fully operational. Press H for help sheet.", 14);
		statusOverlayText.setFormat(backend.Paths.font("vcr.ttf"), 14, 0xFF00FF66, "left");
		add(statusOverlayText);

		// 5. Active operational selector validation wireframe bounding box tracking instance
		selectionIndicatorBox = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		selectionIndicatorBox.visible = false;
		add(selectionIndicatorBox);

		// 6. Smooth elastic slide-in intro animation sequences for UI viewport panels
		FlxTween.tween(panelBackground, {x: targetPanelX}, 0.65, {ease: FlxEase.cubeOut});
		FlxTween.tween(neonTrim, {x: targetPanelX}, 0.65, {ease: FlxEase.cubeOut});
		FlxTween.tween(titleTextDisplay, {x: targetPanelX + 20}, 0.65, {ease: FlxEase.cubeOut});
		FlxTween.tween(infoTextDisplay, {x: targetPanelX + 20}, 0.65, {
			ease: FlxEase.cubeOut,
			onComplete: function(twn:FlxTween) {
				updateDashboardTextLogFeed();
				refreshSelectionBoundingBoxWireframe();
			}
		});

		super.create();
	}

	private function loadCurrentMenuLayoutConfig():Void
	{
		var path:String = 'mods/' + backend.Mods.currentModDirectory + '/menulayouts/menu_layout.json';
		if (!FileSystem.exists(path)) path = 'assets/shared/menulayouts/menu_layout.json';

		if (FileSystem.exists(path)) {
			try {
				var content:String = File.getContent(path);
				layoutData = Json.parse(content);
				trace("[DESIGNER]: Custom menu configuration parsing success.");
			} catch(e:Dynamic) {
				trace("[DESIGNER ERROR]: Configuration structural corruption, generating safe defaults: " + e);
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

		var startingY:Float = 80;
		for (i in 0...optionsList.length) {
			var prop:MenuItemProps = {
				name: optionsList[i],
				x: 140,
				y: startingY,
				scaleX: 0.8,
				scaleY: 0.8
			};
			layoutData.items.push(prop);
			startingY += 140;
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
			+ "• Arrow Keys: Move Item\n"
			+ "• W/S: Change Selection\n"
			+ "• A/D: Adjust Item Scale\n"
			+ "• Q/E: Global Scale Mod\n"
			+ "• CTRL + S: Direct Save Content";
	}

	private function refreshSelectionBoundingBoxWireframe():Void
	{
		if (displayGroup == null || displayGroup.members.length <= currentSelected) return;

		var targetSprite = displayGroup.members[currentSelected];
		if (targetSprite != null && targetSprite.visible) {
			selectionIndicatorBox.visible = true;
			selectionIndicatorBox.x = targetSprite.x - 4;
			selectionIndicatorBox.y = targetSprite.y - 4;
			
			selectionIndicatorBox.makeGraphic(Std.int(targetSprite.width) + 8, Std.int(targetSprite.height) + 8, FlxColor.TRANSPARENT);
			
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, selectionIndicatorBox.width, 2), 0xFF64FFDA);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, selectionIndicatorBox.height - 2, selectionIndicatorBox.width, 2), 0xFF64FFDA);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, selectionIndicatorBox.height), 0xFF64FFDA);
			selectionIndicatorBox.pixels.fillRect(new openfl.geom.Rectangle(selectionIndicatorBox.width - 2, 0, 2, selectionIndicatorBox.height), 0xFF64FFDA);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (layoutData == null || layoutData.items.length == 0) return;

		var currentItem = layoutData.items[currentSelected];
		var targetSprite = displayGroup.members[currentSelected];
		var speedMultiplier:Float = FlxG.keys.pressed.SHIFT ? 10.0 : 2.0;
		var needsUpdate:Bool = false;

		if (FlxG.keys.justPressed.W) {
			FlxG.sound.play(backend.Paths.sound('scrollMenu'));
			currentSelected--;
			if (currentSelected < 0) currentSelected = layoutData.items.length - 1;
			needsUpdate = true;
		}
		if (FlxG.keys.justPressed.S) {
			FlxG.sound.play(backend.Paths.sound('scrollMenu'));
			currentSelected++;
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
			currentItem.scaleX = FlxMath.bound(currentItem.scaleX - (0.01 * (speedMultiplier / 2)), 0.1, 4.0);
			currentItem.scaleY = FlxMath.bound(currentItem.scaleY - (0.01 * (speedMultiplier / 2)), 0.1, 4.0);
			if (targetSprite != null) {
				targetSprite.scale.set(currentItem.scaleX * layoutData.globalScale, currentItem.scaleY * layoutData.globalScale);
				targetSprite.updateHitbox();
			}
			needsUpdate = true;
		}
		if (FlxG.keys.pressed.D) {
			currentItem.scaleX = FlxMath.bound(currentItem.scaleX + (0.01 * (speedMultiplier / 2)), 0.1, 4.0);
			currentItem.scaleY = FlxMath.bound(currentItem.scaleY + (0.01 * (speedMultiplier / 2)), 0.1, 4.0);
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
			displayStatusMessage("HELP: Shift=Fast | Left/Right/Up/Down=Move | W/S=Select | A/D=Scale | Q/E=Global Scale | Ctrl+S=Save");
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
			saveLayoutConfigToDiskStorage();
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;
			FlxG.sound.play(backend.Paths.sound('cancelMenu'));
			backend.MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}

		if (needsUpdate) {
			updateDashboardTextLogFeed();
			refreshSelectionBoundingBoxWireframe();
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
			displayStatusMessage("[SUCCESS]: Configuration layout file directly written to disk path successfully!");
			trace("[DESIGNER SUCCESS]: Ironclad save content written to: " + fullPath);
		} catch(e:Dynamic) {
			displayStatusMessage("[CRASH ERROR]: Hardware disk write failed. Check active permissions.");
			trace("[DESIGNER CRASH]: Failed to update file allocation tables: " + e);
		}
	}

	private function displayStatusMessage(msg:String):Void
	{
		if (statusOverlayText != null) {
			statusOverlayText.text = msg;
			statusOverlayText.color = msg.contains("SUCCESS") ? 0xFF00FF66 : (msg.contains("ERROR") ? 0xFFFF0033 : 0xFF64FFDA);
			
			// Smooth bounce indicator color updates notification text
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