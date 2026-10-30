package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.display.FlxGridOverlay;

import openfl.display.BitmapData;
import lime.system.Clipboard;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

import backend.MusicBeatState;
import states.editors.content.*;
import states.editors.content.ShaderProject;
import states.editors.content.ShaderGen;
import states.editors.content.ShaderEffectLib;
import states.editors.content.ShaderPresets;
import states.editors.content.ShaderPreviewData;
import mikolka.funkin.custom.mobile.MobileScaleMode;

using StringTools;

typedef PvItem =
{
	var id:String;
	var spr:FlxSprite;
	var shader:FlxRuntimeShader;
}

class ShaderPane
{
	public var group:Dynamic;
	public var objs:Array<Dynamic> = [];

	public function new(group:Dynamic)
		this.group = group;

	public function add(o:Dynamic):Dynamic
	{
		group.add(o);
		objs.push(o);
		return o;
	}

	public function clear()
	{
		for (o in objs)
		{
			group.remove(o, true);
			o.destroy();
		}
		objs = [];
	}
}

class ShaderEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	static inline var PV_X:Int = 305;
	static inline var PV_Y:Int = 75;
	static inline var PV_W:Int = 590;
	static inline var PV_H:Int = 600;

	static final PV_BG_NAMES:Array<String> = ['Checker', 'Dark', 'Gray', 'White', 'Green', 'Blue'];
	static final PV_BG_COLORS:Array<Int> = [0xFF26262E, 0xFF15151A, 0xFF777777, 0xFFFFFFFF, 0xFF00B140, 0xFF2B4C8C];
	static final THEMES:Array<String> = ['default', 'dark', 'light', 'vslice'];

	var proj:ShaderProject;
	var sel:Int = -1;
	var undoStack:Array<String> = [];
	var redoStack:Array<String> = [];
	var lastSnapshot:String = '';
	var dirtyTimer:Float = -1;
	var refreshTimer:Float = -1;
	var clipLayer:String = null;
	var uiSuppress:Bool = false;
	var saveData:FlxSave;

	// ---- ui
	var camUI:FlxCamera;
	var camPreview:FlxCamera;
	var bg:FlxSprite;
	var upperBox:PsychUIBox;
	var layersBox:PsychUIBox;
	var mainBox:PsychUIBox;
	var outputTxt:FlxText;
	var outputAlpha:Float = 0;
	var tipBg:FlxSprite;
	var fullTipText:FlxText;
	var infoText:FlxText;
	var pvHint:FlxText;
	var exportText:FlxText;
	var ignoreClickForThisFrame:Bool = false;
	var theme:String = 'default';

	// ---- shit
	var rowPane:ShaderPane;
	var effPane:ShaderPane;
	var modPane:ShaderPane;
	var tgtPane:ShaderPane;
	var expPane:ShaderPane;
	var pendRows:Bool = false;
	var pendEffect:Bool = false;
	var pendMods:Bool = false;
	var pendTargets:Bool = false;
	var pendExport:Bool = false;

	// ---- layers tab widgets
	var catDrop:PsychUIDropDownMenu;
	var effDrop:PsychUIDropDownMenu;
	var curEffList:Array<EffectDef> = [];
	var appendPreset:PsychUICheckBox;

	// ---- preview
	var pv:Array<PvItem> = [];
	var pvChecker:FlxSprite;
	var pvShow:Map<String, Bool> = new Map();
	var pvBg:Int = 0;
	var pvBpm:Float = 100;
	var pvSpeed:Float = 1;
	var pvTime:Float = 0;
	var pvBeatAge:Float = 0;
	var pvPlaying:Bool = true;
	var bypassToggle:Bool = false;
	var lastBypass:Bool = false;
	var customPath:String = '';
	var texCache:Map<String, BitmapData> = new Map();
	var whiteBmp:BitmapData;
	var curGen:GenResult;
	var lastGlsl:String = '';

	override function create()
	{
		persistentUpdate = false;
		FlxG.mouse.visible = true;

		saveData = new FlxSave();
		saveData.bind('shader_editor_data', CoolUtil.getSavePath(), (raw, err) -> {});

		initPsychCamera();
		camPreview = new FlxCamera(PV_X, PV_Y, PV_W, PV_H);
		camPreview.bgColor = PV_BG_COLORS[0];
		camPreview.zoom = 1;
		FlxG.cameras.add(camPreview, false);
		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		whiteBmp = new BitmapData(1, 1, true, 0xFFFFFFFF);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);
		changeTheme((saveData.data.theme != null) ? saveData.data.theme : 'default', false);

		// ---- project (restore the last session, or start from the classic light preset)
		proj = null;
		if (saveData.data.autosave != null)
		{
			try
			{
				proj = ShaderProject.fromString(saveData.data.autosave);
			}
			catch (e:Dynamic)
			{
				proj = null;
			}
		}
		if (proj == null)
		{
			proj = new ShaderProject();
			ShaderPresets.apply(ShaderPresets.names[0], proj);
		}
		sel = (proj.layers.length > 0) ? 0 : -1;
		lastSnapshot = proj.snapshot();

		// ---- preview stage
		pvChecker = FlxGridOverlay.create(20, 20, PV_W * 2, PV_H * 2, true, 0xFF3C3C46, 0xFF30303A);
		pvChecker.setPosition(-PV_W / 2, -PV_H / 2);
		pvChecker.scrollFactor.set();
		pvChecker.cameras = [camPreview];
		add(pvChecker);

		pvShow.set('dad', (saveData.data.pvDad != null) ? saveData.data.pvDad : true);
		pvShow.set('bf', (saveData.data.pvBf != null) ? saveData.data.pvBf : true);
		pvShow.set('dummy', (saveData.data.pvDummy != null) ? saveData.data.pvDummy : false);
		pvShow.set('custom', false);
		if (saveData.data.pvBg != null)
			pvBg = saveData.data.pvBg;
		if (saveData.data.pvBpm != null)
			pvBpm = saveData.data.pvBpm;
		buildPreviewSprites();
		applyPreviewBg(pvBg);

		// ---- boxes
		var off:Float = (MobileScaleMode.gameCutoutSize.x / 2.5);
		layersBox = new PsychUIBox(20 + off, PV_Y, 270, PV_H, ['Layers', 'Presets', 'Info']);
		layersBox.scrollFactor.set();
		layersBox.cameras = [camUI];
		add(layersBox);

		mainBox = new PsychUIBox(905, 40, 355, 640, ['Effect', 'Modifiers', 'Targets', 'Export', 'Preview']);
		mainBox.scrollFactor.set();
		mainBox.cameras = [camUI];
		add(mainBox);

		if (saveData.data.layersBoxPosition != null && saveData.data.layersBoxPosition.length > 1)
			layersBox.setPosition(saveData.data.layersBoxPosition[0], saveData.data.layersBoxPosition[1]);
		if (saveData.data.mainBoxPosition != null && saveData.data.mainBoxPosition.length > 1)
			mainBox.setPosition(saveData.data.mainBoxPosition[0], saveData.data.mainBoxPosition[1]);

		upperBox = new PsychUIBox(40 + off, 40, 330, 300, ['File', 'Edit', 'View']);
		upperBox.scrollFactor.set();
		upperBox.isMinimized = true;
		upperBox.minimizeOnFocusLost = true;
		upperBox.canMove = false;
		upperBox.cameras = [camUI];
		upperBox.bg.visible = false;

		outputTxt = new FlxText(25, FlxG.height - 50, FlxG.width - 50, '', 20);
		outputTxt.borderSize = 2;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.scrollFactor.set();
		outputTxt.cameras = [camUI];
		add(outputTxt);

		pvHint = new FlxText(PV_X, PV_Y + PV_H + 4, PV_W, 'Hold B: compare with original', 12);
		pvHint.scrollFactor.set();
		pvHint.cameras = [camUI];
		pvHint.alpha = 0.8;
		add(pvHint);

		// ---- tabs
		rowPane = new ShaderPane(layersBox.getTab('Layers').menu);
		effPane = new ShaderPane(mainBox.getTab('Effect').menu);
		modPane = new ShaderPane(mainBox.getTab('Modifiers').menu);
		tgtPane = new ShaderPane(mainBox.getTab('Targets').menu);
		expPane = new ShaderPane(mainBox.getTab('Export').menu);

		buildLayersHeader();
		buildPresetsTab();
		buildInfoTab();
		buildPreviewTab();
		addFileTab();
		addEditTab();
		addViewTab();
		add(upperBox);
		rebuildAllTabs();

		var tipText:FlxText = new FlxText(FlxG.width - 210, FlxG.height - 30, 200, 'Press ${(controls.mobileC) ? 'F' : 'F1'} for Help', 20);
		tipText.cameras = [camUI];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		tipBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		tipBg.cameras = [camUI];
		tipBg.scale.set(FlxG.width, FlxG.height);
		tipBg.updateHitbox();
		tipBg.scrollFactor.set();
		tipBg.visible = tipBg.active = false;
		tipBg.alpha = 0.6;
		add(tipBg);

		fullTipText = new FlxText(0, 0, FlxG.width - 200);
		fullTipText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		fullTipText.cameras = [camUI];
		fullTipText.scrollFactor.set();
		fullTipText.visible = fullTipText.active = false;
		fullTipText.text = [
			"Up/Down - Select Layer",
			"Ctrl + Up/Down - Move Layer",
			"E - Enable/Disable Layer",
			"Delete - Remove Layer",
			"Ctrl + D - Duplicate Layer",
			"Ctrl + C / Ctrl + V - Copy / Paste Layer",
			"",
			"Hold B - Compare with the original sprite",
			"Space - Pause/Resume Preview Animation",
			"Mouse Wheel - Zoom Preview",
			"Middle / Right Mouse Drag - Pan Preview",
			"Home - Reset Preview View",
			"",
			"Ctrl + Z - Undo",
			"Ctrl + Y - Redo",
			"Ctrl + S - Export .frag + .lua",
			"Esc - Exit"
		].join('\n');
		fullTipText.screenCenter();
		add(fullTipText);

		refreshShader(true);
		super.create();
	}

	// ====================================================================== themes / output
	function changeTheme(t:String, doSave:Bool = true)
	{
		theme = t;
		switch (t)
		{
			case 'light': bg.color = 0xFFA0A0A0;
			case 'dark': bg.color = 0xFF222222;
			case 'vslice': bg.color = 0xFF673AB7;
			default: bg.color = 0xFF303030;
		}
		saveData.data.theme = t;
		if (doSave)
			saveData.flush();
	}

	function cycleTheme()
	{
		var i = (THEMES.indexOf(theme) + 1) % THEMES.length;
		changeTheme(THEMES[i]);
		showOutput('Theme: ' + THEMES[i]);
	}

	function showOutput(message:String, isError:Bool = false)
	{
		trace(message);
		outputTxt.text = message;
		outputTxt.y = FlxG.height - outputTxt.height - 30;
		outputAlpha = 4;
		if (isError)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			outputTxt.color = FlxColor.RED;
		}
		else
			outputTxt.color = FlxColor.WHITE;
	}

	// ====================================================================== menus (File / Edit / View)
	function addMenu(tabName:String, items:Array<{label:String, fn:Void->Void}>)
	{
		var tab = upperBox.getTab(tabName);
		var tab_group = tab.menu;
		var btnX = tab.x - upperBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);
		for (it in items)
		{
			var fn = it.fn;
			var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  ' + it.label, function()
			{
				upperBox.isMinimized = true;
				upperBox.bg.visible = false;
				fn();
			}, btnWid);
			btn.text.alignment = LEFT;
			tab_group.add(btn);
			btnY += 21;
		}
	}

	function addFileTab()
	{
		addMenu('File', [
			{label: 'New', fn: newProject},
			{label: 'Open Project...', fn: openProjectList},
			{label: 'Save Project', fn: saveProject},
			{label: 'Export .frag + .lua  (Ctrl+S)', fn: exportFiles},
			{label: 'Copy GLSL to clipboard', fn: copyGlsl},
			{label: 'Copy Lua to clipboard', fn: copyLua},
			{label: 'Exit', fn: exitEditor}
		]);
	}

	function addEditTab()
	{
		addMenu('Edit', [
			{label: 'Undo  (Ctrl+Z)', fn: undo},
			{label: 'Redo  (Ctrl+Y)', fn: redo},
			{label: 'Copy Layer', fn: copyLayer},
			{label: 'Paste Layer', fn: pasteLayer},
			{label: 'Duplicate Layer  (Ctrl+D)', fn: function() duplicateLayer(sel)},
			{label: 'Delete Layer  (Del)', fn: function() removeLayer(sel)},
			{label: 'Move Layer Up', fn: function() moveLayer(sel, -1)},
			{label: 'Move Layer Down', fn: function() moveLayer(sel, 1)},
			{label: 'Clear All Layers', fn: clearAllLayers}
		]);
	}

	function addViewTab()
	{
		addMenu('View', [
			{label: 'Compare with original (toggle)', fn: function()
			{
				bypassToggle = !bypassToggle;
				showOutput(bypassToggle ? 'Showing the ORIGINAL sprites' : 'Showing the shader');
			}},
			{label: 'Pause / Resume animation', fn: function() pvPlaying = !pvPlaying},
			{label: 'Reset preview view', fn: resetView},
			{label: 'Next preview background', fn: function() applyPreviewBg((pvBg + 1) % PV_BG_NAMES.length)},
			{label: 'Next theme', fn: cycleTheme},
			{label: 'Help', fn: toggleHelp}
		]);
	}

	function toggleHelp()
	{
		var vis:Bool = !fullTipText.visible;
		tipBg.visible = tipBg.active = fullTipText.visible = fullTipText.active = vis;
	}

	function exitEditor()
	{
		persistentUpdate = false;
		saveData.flush();
		FlxG.mouse.visible = false;
		ClientPrefs.toggleVolumeKeys(true);
		MusicBeatState.switchState(new MasterEditorMenu());
	}

	public function onUIEvent(id:String, sender:Dynamic)
	{
		switch (id)
		{
			case PsychUIButton.CLICK_EVENT, PsychUIDropDownMenu.CLICK_EVENT:
				ignoreClickForThisFrame = true;

			case PsychUIBox.CLICK_EVENT:
				ignoreClickForThisFrame = true;
				if (sender == upperBox)
					updateUpperBoxBg();

			case PsychUIBox.MINIMIZE_EVENT:
				if (sender == upperBox)
				{
					upperBox.bg.visible = !upperBox.isMinimized;
					updateUpperBoxBg();
				}

			case PsychUIBox.DROP_EVENT:
				saveData.data.layersBoxPosition = [layersBox.x, layersBox.y];
				saveData.data.mainBoxPosition = [mainBox.x, mainBox.y];
		}
	}

	public function UIEvent(id:String, sender:Dynamic):Void
	{
		onUIEvent(id, sender);
	}

	function updateUpperBoxBg()
	{
		if (upperBox.selectedTab != null)
		{
			var menu = upperBox.selectedTab.menu;
			upperBox.bg.x = upperBox.x + upperBox.selectedIndex * (upperBox.width / upperBox.tabs.length);
			upperBox.bg.setGraphicSize(menu.width, menu.height + 21);
			upperBox.bg.updateHitbox();
		}
	}

	override function closeSubState()
	{
		ClientPrefs.toggleVolumeKeys(true);
		super.closeSubState();
		upperBox.isMinimized = true;
		upperBox.visible = mainBox.visible = layersBox.visible = true;
		upperBox.bg.visible = false;
	}

	override function destroy()
	{
		saveData.data.autosave = proj.snapshot();
		saveData.flush();
		for (k in texCache.keys())
			texCache.remove(k);
		super.destroy();
	}

	// ====================================================================== history
	function markDirty()
		dirtyTimer = 0.45;

	function commitNow()
	{
		dirtyTimer = -1;
		commitSnapshot();
	}

	function commitSnapshot()
	{
		var s = proj.snapshot();
		if (s == lastSnapshot)
			return;
		undoStack.push(lastSnapshot);
		if (undoStack.length > 100)
			undoStack.shift();
		lastSnapshot = s;
		redoStack = [];
		saveData.data.autosave = s;
	}

	function applySnapshot(s:String)
	{
		lastSnapshot = s;
		proj = ShaderProject.fromString(s);
		if (sel >= proj.layers.length)
			sel = proj.layers.length - 1;
		if (sel < 0 && proj.layers.length > 0)
			sel = 0;
		saveData.data.autosave = s;
		rebuildAllTabs();
		refreshShader();
	}

	function undo()
	{
		if (dirtyTimer >= 0)
			commitNow();
		if (undoStack.length == 0)
		{
			showOutput('Nothing to undo.', true);
			return;
		}
		redoStack.push(lastSnapshot);
		applySnapshot(undoStack.pop());
		showOutput('Undo');
	}

	function redo()
	{
		if (dirtyTimer >= 0)
			commitNow();
		if (redoStack.length == 0)
		{
			showOutput('Nothing to redo.', true);
			return;
		}
		undoStack.push(lastSnapshot);
		applySnapshot(redoStack.pop());
		showOutput('Redo');
	}

	function onEdit()
	{
		markDirty();
		refreshShader();
	}

	function rebuildAllTabs()
	{
		pendRows = pendEffect = pendMods = pendTargets = pendExport = true;
	}

	function processPending()
	{
		if (pendRows)
		{
			pendRows = false;
			buildLayerRows();
		}
		if (pendEffect)
		{
			pendEffect = false;
			buildEffectTab();
		}
		if (pendMods)
		{
			pendMods = false;
			buildModsTab();
		}
		if (pendTargets)
		{
			pendTargets = false;
			buildTargetsTab();
		}
		if (pendExport)
		{
			pendExport = false;
			buildExportTab();
		}
	}

	// ====================================================================== layer operations
	function curLayer():ShaderLayer
		return (sel >= 0 && sel < proj.layers.length) ? proj.layers[sel] : null;

	function structural()
	{
		commitNow();
		pendRows = pendEffect = pendMods = true;
		refreshShader();
	}

	function addLayer(type:String)
	{
		if (proj.layers.length >= ShaderConst.MAX_LAYERS)
		{
			showOutput('Layer limit reached (' + ShaderConst.MAX_LAYERS + ').', true);
			return;
		}
		var l = proj.addLayer(type, (sel >= 0) ? sel + 1 : -1);
		sel = proj.layers.indexOf(l);
		structural();
		showOutput('Added: ' + l.def().name);
	}

	function selectLayer(i:Int)
	{
		if (i < 0 || i >= proj.layers.length || i == sel)
			return;
		sel = i;
		pendRows = pendEffect = pendMods = true;
	}

	function removeLayer(i:Int)
	{
		if (i < 0 || i >= proj.layers.length)
			return;
		proj.layers.splice(i, 1);
		if (sel >= proj.layers.length)
			sel = proj.layers.length - 1;
		structural();
	}

	function moveLayer(i:Int, dir:Int)
	{
		var j = i + dir;
		if (i < 0 || j < 0 || i >= proj.layers.length || j >= proj.layers.length)
			return;
		var l = proj.layers[i];
		proj.layers[i] = proj.layers[j];
		proj.layers[j] = l;
		sel = j;
		structural();
	}

	function duplicateLayer(i:Int)
	{
		if (i < 0 || i >= proj.layers.length)
			return;
		if (proj.layers.length >= ShaderConst.MAX_LAYERS)
		{
			showOutput('Layer limit reached (' + ShaderConst.MAX_LAYERS + ').', true);
			return;
		}
		var c = proj.layers[i].clone(proj.nextUid++);
		proj.layers.insert(i + 1, c);
		sel = i + 1;
		structural();
	}

	function toggleLayer(i:Int)
	{
		if (i < 0 || i >= proj.layers.length)
			return;
		proj.layers[i].enabled = !proj.layers[i].enabled;
		structural();
	}

	function copyLayer()
	{
		var l = curLayer();
		if (l == null)
			return;
		clipLayer = Json.stringify(l.toJson());
		showOutput('Layer copied.');
	}

	function pasteLayer()
	{
		if (clipLayer == null)
		{
			showOutput('Nothing copied yet.', true);
			return;
		}
		if (proj.layers.length >= ShaderConst.MAX_LAYERS)
		{
			showOutput('Layer limit reached (' + ShaderConst.MAX_LAYERS + ').', true);
			return;
		}
		var l = ShaderLayer.fromJson(Json.parse(clipLayer));
		if (l == null)
			return;
		l.uid = proj.nextUid++;
		var at = (sel >= 0) ? sel + 1 : proj.layers.length;
		proj.layers.insert(at, l);
		sel = at;
		structural();
	}

	function clearAllLayers()
	{
		if (proj.layers.length == 0)
			return;
		openSubState(new Prompt('Remove ALL layers?', function()
		{
			proj.layers = [];
			sel = -1;
			structural();
		}));
	}

	function newProject()
	{
		openSubState(new Prompt('Start a new shader? (Ctrl+Z can undo it)', function()
		{
			proj = new ShaderProject();
			sel = -1;
			commitNow();
			rebuildAllTabs();
			refreshShader();
		}));
	}

	function applyPreset(name:String)
	{
		if (!appendPreset.checked)
		{
			proj.layers = [];
			sel = -1;
		}
		var before = proj.layers.length;
		ShaderPresets.apply(name, proj);
		while (proj.layers.length > ShaderConst.MAX_LAYERS)
			proj.layers.pop();
		sel = (proj.layers.length > before) ? before : (proj.layers.length - 1);
		structural();
		showOutput('Preset loaded: ' + name);
	}

	// ====================================================================== LAYERS box
	function buildLayersHeader()
	{
		var tab = layersBox.getTab('Layers').menu;
		var objX = 10;
		var objY = 30;

		tab.add(new FlxText(objX, objY - 15, 100, 'Category:'));
		tab.add(new FlxText(objX + 110, objY - 15, 130, 'Effect:'));

		var addBtn:PsychUIButton = new PsychUIButton(objX, objY + 30, 'Add Layer', function()
		{
			var idx:Int = Std.int(Math.max(0, effDrop.selectedIndex));
			if (idx < curEffList.length)
				addLayer(curEffList[idx].id);
		}, 100);
		addBtn.normalStyle.bgColor = FlxColor.GREEN;
		addBtn.normalStyle.textColor = FlxColor.WHITE;
		tab.add(addBtn);

		tab.add(new PsychUIButton(objX + 110, objY + 30, 'Paste', pasteLayer, 60));
		var clearBtn:PsychUIButton = new PsychUIButton(objX + 175, objY + 30, 'Clear', clearAllLayers, 60);
		clearBtn.normalStyle.bgColor = FlxColor.RED;
		clearBtn.normalStyle.textColor = FlxColor.WHITE;
		tab.add(clearBtn);

		// effect first, category on top of it
		effDrop = new PsychUIDropDownMenu(objX + 110, objY, [''], function(id:Int, label:String) {}, 125);
		catDrop = new PsychUIDropDownMenu(objX, objY, ShaderEffectLib.categories, function(id:Int, label:String)
		{
			fillEffectList(label);
		}, 100);
		tab.add(effDrop);
		tab.add(catDrop);
		fillEffectList(ShaderEffectLib.categories[0]);
		catDrop.selectedIndex = 0;
	}

	function fillEffectList(cat:String)
	{
		curEffList = ShaderEffectLib.inCategory(cat);
		effDrop.list = [for (d in curEffList) d.name];
		effDrop.selectedIndex = 0;
	}

	function buildLayerRows()
	{
		rowPane.clear();
		var y0 = 95;
		if (proj.layers.length == 0)
		{
			rowPane.add(new FlxText(10, y0, 245, 'No layers yet.\nPick an effect above and press "Add Layer", or open the Presets tab.', 12));
			return;
		}
		var phaseColors:Array<Int> = [0xFF9FDCFF, 0xFFFFC27A, 0xFFFFFFFF];
		for (i in 0...proj.layers.length)
		{
			var L = proj.layers[i];
			var d = L.def();
			var y = y0 + i * 25;
			var name = (i + 1) + '. ' + d.name;
			if (name.length > 17)
				name = name.substr(0, 16) + '.';

			var btn:PsychUIButton = new PsychUIButton(10, y, name, function() selectLayer(i), 118);
			btn.text.alignment = LEFT;
			btn.normalStyle.textColor = L.enabled ? phaseColors[d.phase] : 0xFF777777;
			if (i == sel)
			{
				btn.normalStyle.bgColor = 0xFF2F6FB0;
				btn.normalStyle.textColor = FlxColor.WHITE;
			}
			rowPane.add(btn);

			var eye:PsychUIButton = new PsychUIButton(132, y, L.enabled ? 'On' : 'Off', function() toggleLayer(i), 26);
			if (!L.enabled)
				eye.normalStyle.textColor = 0xFF999999;
			rowPane.add(eye);
			rowPane.add(new PsychUIButton(161, y, '^', function() moveLayer(i, -1), 20));
			rowPane.add(new PsychUIButton(184, y, 'v', function() moveLayer(i, 1), 20));
			rowPane.add(new PsychUIButton(207, y, 'D', function() duplicateLayer(i), 20));
			var del:PsychUIButton = new PsychUIButton(230, y, 'X', function() removeLayer(i), 20);
			del.normalStyle.bgColor = FlxColor.RED;
			del.normalStyle.textColor = FlxColor.WHITE;
			rowPane.add(del);
		}
		rowPane.add(new FlxText(10, y0 + proj.layers.length * 25 + 6, 245, 'Light blue = UV warp, orange = sampling, white = colour.\n' + proj.layers.length + ' / ' + ShaderConst.MAX_LAYERS + ' layers', 10));
	}

	function buildPresetsTab()
	{
		var tab = layersBox.getTab('Presets').menu;
		appendPreset = new PsychUICheckBox(10, 15, 'Append to current layers', 200, null);
		tab.add(appendPreset);
		var names = ShaderPresets.names;
		for (i in 0...names.length)
		{
			var nm = names[i];
			var label = nm.length > 17 ? nm.substr(0, 16) + '.' : nm;
			var btn:PsychUIButton = new PsychUIButton(10 + (i % 2) * 125, 45 + Std.int(i / 2) * 25, label, function() applyPreset(nm), 120);
			tab.add(btn);
		}
		tab.add(new FlxText(10, 45 + Std.int((names.length + 1) / 2) * 25 + 10, 245, 'Presets are only a starting point: every layer stays editable, and Ctrl+Z undoes a preset.', 10));
	}

	function buildInfoTab()
	{
		var tab = layersBox.getTab('Info').menu;
		infoText = new FlxText(10, 15, 250, '', 14);
		infoText.scrollFactor.set();
		tab.add(infoText);
	}

	function updateInfo()
	{
		if (infoText == null || curGen == null)
			return;
		var uv = 0;
		var smp = 0;
		var col = 0;
		for (l in proj.layers)
		{
			var d = l.def();
			if (!l.enabled || d == null)
				continue;
			switch (d.phase)
			{
				case ShaderConst.UV: uv++;
				case ShaderConst.SMP: smp++;
				default: col++;
			}
		}
		var t = 'Active layers: ${curGen.layerCount} / ${proj.layers.length}\nUV: $uv   Sampling: $smp   Colour: $col\n\nUniforms: ${curGen.uniforms.length}\nGLSL lines: ${curGen.lines}\nTexture fetches / pixel: ~${curGen.samples}\n';
		t += (curGen.samples > 250) ? '\nCost: HEAVY' : (curGen.samples > 60 ? '\nCost: medium' : '\nCost: light');
		var targets = proj.targets.length;
		if (targets == 0 && StringTools.trim(proj.customTargets) == '')
			t += '\n\nNo export target selected (Targets tab).';
		if (curGen.warnings.length > 0)
			t += '\n\n' + curGen.warnings.join('\n');
		t += '\n\nIf the preview turns invisible the shader failed to compile: see the console / log for the GLSL error.';
		infoText.text = t;
		infoText.color = (curGen.samples > 250) ? FlxColor.ORANGE : FlxColor.WHITE;
	}

	// ====================================================================== EFFECT tab
	function hexToColor(h:String):FlxColor
	{
		var rgb = ShaderGen.parseHex(h);
		return FlxColor.fromRGBFloat(rgb[0], rgb[1], rgb[2], 1);
	}

	function buildEffectTab()
	{
		effPane.clear();
		var L = curLayer();
		if (L == null)
		{
			effPane.add(new FlxText(10, 20, 330, 'No layer selected.\nAdd an effect in the Layers panel (left) or load a preset.', 14));
			return;
		}
		var d = L.def();
		uiSuppress = true;

		effPane.add(new FlxText(10, 8, 330, d.name, 20));
		effPane.add(new FlxText(10, 34, 330, '[' + ShaderConst.PHASE_TAGS[d.phase] + ']  ' + ShaderConst.PHASE_NAMES[d.phase], 10));

		// opacity + reset
		effPane.add(new FlxText(10, 55, 110, 'Opacity / strength:'));
		var opSt:PsychUINumericStepper = new PsychUINumericStepper(10, 70, 0.05, L.opacity, 0, 2, 2, 80);
		opSt.onValueChange = function()
		{
			if (uiSuppress)
				return;
			L.opacity = opSt.value;
			onEdit();
		};
		effPane.add(opSt);
		var enCb:PsychUICheckBox = new PsychUICheckBox(125, 70, 'Enabled', 80, function()
		{
			if (uiSuppress)
				return;
			L.enabled = !L.enabled;
			structural();
		});
		effPane.add(enCb);
		enCb.checked = L.enabled;
		var rst:PsychUIButton = new PsychUIButton(235, 68, 'Reset params', function()
		{
			L.resetParams();
			structural();
		}, 100);
		effPane.add(rst);

		var dds:Array<{dd:PsychUIDropDownMenu, y:Int, idx:Int}> = [];
		var col = 0;
		var row = 0;
		var y0 = 125;
		for (pd in d.params)
		{
			if (col + pd.cols > 3)
			{
				col = 0;
				row++;
			}
			var x = 10 + col * 115;
			var y = y0 + row * 42;
			var pid = pd.id;
			switch (pd.kind)
			{
				case 'f':
					effPane.add(new FlxText(x, y - 15, 112, pd.label + ':'));
					var st:PsychUINumericStepper = new PsychUINumericStepper(x, y, pd.step, L.getF(pid), pd.min, pd.max, pd.dec, 75);
					st.onValueChange = function()
					{
						if (uiSuppress)
							return;
						L.setV(pid, st.value);
						onEdit();
					};
					effPane.add(st);

				case 'c':
					effPane.add(new FlxText(x, y - 15, 112, pd.label + ':'));
					var inp:PsychUIInputText = new PsychUIInputText(x, y, 70, L.getS(pid), 8);
					inp.maxLength = 6;
					inp.filterMode = ONLY_HEXADECIMAL;
					inp.forceCase = UPPER_CASE;
					var sw:FlxSprite = new FlxSprite(x + 76, y + 1).makeGraphic(16, 16, FlxColor.WHITE);
					sw.color = hexToColor(L.getS(pid));
					inp.onChange = function(old:String, cur:String)
					{
						if (uiSuppress || cur.length != 6)
							return;
						L.setV(pid, cur);
						sw.color = hexToColor(cur);
						onEdit();
					};
					effPane.add(inp);
					effPane.add(sw);

				case 'e':
					effPane.add(new FlxText(x, y - 15, 112, pd.label + ':'));
					var dd:PsychUIDropDownMenu = new PsychUIDropDownMenu(x, y, pd.options, function(id:Int, lbl:String)
					{
						if (uiSuppress)
							return;
						L.setV(pid, id);
						onEdit();
					}, 105);
					dds.push({dd: dd, y: y, idx: L.getI(pid)});

				case 'b':
					var cb:PsychUICheckBox = null;
					cb = new PsychUICheckBox(x, y, pd.label, 100, function()
					{
						if (uiSuppress)
							return;
						L.setV(pid, cb.checked);
						onEdit();
					});
					cb.checked = L.getB(pid);
					effPane.add(cb);

				case 't':
					effPane.add(new FlxText(x, y - 15, 330, pd.label + ':'));
					var ti:PsychUIInputText = new PsychUIInputText(x, y, 320, L.getS(pid), 8);
					ti.onChange = function(old:String, cur:String)
					{
						if (uiSuppress)
							return;
						L.setV(pid, cur);
						markDirty();
						refreshTimer = 0.4; // wait until the typing stops
					};
					effPane.add(ti);
			}
			col += pd.cols;
			if (col >= 3)
			{
				col = 0;
				row++;
			}
		}
		var descY = y0 + (row + (col > 0 ? 1 : 0)) * 42 + 8;
		effPane.add(new FlxText(10, descY, 330, d.desc, 12));

		// dropdowns last, lower ones first, so open lists are drawn over everything
		dds.sort(function(a, b) return b.y - a.y);
		for (o in dds)
		{
			effPane.add(o.dd);
			o.dd.selectedIndex = o.idx;
		}
		uiSuppress = false;
	}

	// ====================================================================== MODIFIERS tab (mask + animation)
	function setAnimDefaults(L:ShaderLayer, pid:String)
	{
		var pd = L.def().param(pid);
		L.animAmt = (pd != null) ? Math.round((pd.max - pd.min) * 0.1 * 1000) / 1000 : 0.2;
		L.animSpeed = 1;
	}

	function buildModsTab()
	{
		modPane.clear();
		var L = curLayer();
		if (L == null)
		{
			modPane.add(new FlxText(10, 20, 330, 'Select a layer to edit its mask and animation.', 14));
			return;
		}
		var d = L.def();
		uiSuppress = true;

		// ---- mask
		modPane.add(new FlxText(10, 8, 330, 'MASK  (where the layer is applied)', 16));
		modPane.add(new FlxText(10, 40, 110, 'Mode:'));
		var inv:PsychUICheckBox = null;
		inv = new PsychUICheckBox(135, 55, 'Invert', 60, function()
		{
			if (uiSuppress)
				return;
			L.maskInvert = inv.checked;
			onEdit();
		});
		inv.checked = L.maskInvert;
		modPane.add(inv);

		var labels = ShaderConst.MASK_LABELS[L.maskMode];
		for (i in 0...labels.length)
		{
			var x = 10 + (i % 3) * 115;
			var y = 110 + Std.int(i / 3) * 42;
			var idx = i;
			modPane.add(new FlxText(x, y - 15, 112, labels[i] + ':'));
			var st:PsychUINumericStepper = new PsychUINumericStepper(x, y, 0.05, L.mask[i], -1000, 1000, 3, 75);
			st.onValueChange = function()
			{
				if (uiSuppress)
					return;
				L.mask[idx] = st.value;
				onEdit();
			};
			modPane.add(st);
		}
		if (L.maskMode == 5)
		{
			var y = 110 + 42;
			modPane.add(new FlxText(10, y - 15, 112, 'Key color:'));
			var inp:PsychUIInputText = new PsychUIInputText(10, y, 70, L.maskColor, 8);
			inp.maxLength = 6;
			inp.filterMode = ONLY_HEXADECIMAL;
			inp.forceCase = UPPER_CASE;
			var sw:FlxSprite = new FlxSprite(86, y + 1).makeGraphic(16, 16, FlxColor.WHITE);
			sw.color = hexToColor(L.maskColor);
			inp.onChange = function(old:String, cur:String)
			{
				if (uiSuppress || cur.length != 6)
					return;
				L.maskColor = cur;
				sw.color = hexToColor(cur);
				onEdit();
			};
			modPane.add(inp);
			modPane.add(sw);
		}
		modPane.add(new FlxText(10, 205, 330, 'Radial/Linear use the sprite frame (0..1). Luma, Color Key and Alpha use the sprite itself, Noise is animated by Speed.', 10));

		// ---- animation
		modPane.add(new FlxText(10, 262, 330, 'ANIMATION  (one parameter per layer)', 16));
		var ids:Array<String> = [''];
		var names:Array<String> = ['(none)'];
		for (pd in d.params)
			if (pd.kind == 'f')
			{
				ids.push(pd.id);
				names.push(pd.label);
			}
		ids.push('opacity');
		names.push('Layer opacity');

		modPane.add(new FlxText(10, 296, 150, 'Animate parameter:'));
		modPane.add(new FlxText(180, 296, 120, 'Wave:'));

		var aSp:PsychUINumericStepper = new PsychUINumericStepper(10, 350, 0.1, L.animSpeed, -100, 100, 2, 75);
		aSp.onValueChange = function()
		{
			if (uiSuppress)
				return;
			L.animSpeed = aSp.value;
			onEdit();
		};
		var aAm:PsychUINumericStepper = new PsychUINumericStepper(125, 350, 0.05, L.animAmt, -100000, 100000, 3, 75);
		aAm.onValueChange = function()
		{
			if (uiSuppress)
				return;
			L.animAmt = aAm.value;
			onEdit();
		};
		var aPh:PsychUINumericStepper = new PsychUINumericStepper(240, 350, 0.05, L.animPhase, -100, 100, 2, 75);
		aPh.onValueChange = function()
		{
			if (uiSuppress)
				return;
			L.animPhase = aPh.value;
			onEdit();
		};
		modPane.add(new FlxText(10, 335, 112, 'Speed (Hz):'));
		modPane.add(new FlxText(125, 335, 112, 'Amount:'));
		modPane.add(new FlxText(240, 335, 112, 'Phase:'));
		modPane.add(aSp);
		modPane.add(aAm);
		modPane.add(aPh);
		modPane.add(new FlxText(10, 385, 330, 'Result = value + amount * wave.\nSine / Triangle / Saw / Square / Flicker: wave goes -1..1 over time.\nBeat: wave is 1 on every beat and fades to 0 (needs the Lua script).\nTip: Saw on "Hue shift" = rainbow cycle; Beat on "Zoom X" = bounce.', 11));

		// dropdowns last (mask mode is the top one)
		var animMode:PsychUIDropDownMenu = new PsychUIDropDownMenu(180, 311, ShaderConst.ANIM_NAMES, function(id:Int, lbl:String)
		{
			if (uiSuppress)
				return;
			L.animMode = id;
			if (id > 0 && L.animParam == '' && ids.length > 1)
			{
				L.animParam = ids[1];
				setAnimDefaults(L, ids[1]);
			}
			if (id == 0)
				L.animParam = '';
			pendMods = true;
			onEdit();
		}, 100);
		var animParam:PsychUIDropDownMenu = new PsychUIDropDownMenu(10, 311, names, function(id:Int, lbl:String)
		{
			if (uiSuppress)
				return;
			L.animParam = ids[id];
			if (ids[id] == '')
				L.animMode = 0;
			else
			{
				if (L.animMode == 0)
					L.animMode = 1;
				setAnimDefaults(L, ids[id]);
			}
			pendMods = true;
			onEdit();
		}, 150);
		var maskMode:PsychUIDropDownMenu = new PsychUIDropDownMenu(10, 55, ShaderConst.MASK_NAMES, function(id:Int, lbl:String)
		{
			if (uiSuppress)
				return;
			L.maskMode = id;
			var defs = ShaderConst.MASK_DEFAULTS[id];
			for (i in 0...4)
				L.mask[i] = defs[i];
			pendMods = true;
			onEdit();
		}, 110);
		modPane.add(animMode);
		modPane.add(animParam);
		modPane.add(maskMode);
		animMode.selectedIndex = L.animMode;
		var pi = ids.indexOf(L.animParam);
		animParam.selectedIndex = (pi < 0) ? 0 : pi;
		maskMode.selectedIndex = L.maskMode;
		uiSuppress = false;
	}

	// ====================================================================== TARGETS tab
	function onMetaEdit()
	{
		markDirty();
		updateInfo();
	}

	function buildTargetsTab()
	{
		tgtPane.clear();
		uiSuppress = true;
		tgtPane.add(new FlxText(10, 8, 330, 'EXPORT TARGETS', 16));
		tgtPane.add(new FlxText(10, 32, 330, 'Objects that receive the shader in the generated .lua:', 11));
		for (i in 0...ShaderConst.TARGET_IDS.length)
		{
			var tid = ShaderConst.TARGET_IDS[i];
			var x = 10 + (i % 2) * 170;
			var y = 70 + Std.int(i / 2) * 30;
			var cb:PsychUICheckBox = null;
			cb = new PsychUICheckBox(x, y, ShaderConst.TARGET_NAMES[i], 150, function()
			{
				if (uiSuppress)
					return;
				if (cb.checked)
				{
					if (proj.targets.indexOf(tid) < 0)
						proj.targets.push(tid);
				}
				else
					proj.targets.remove(tid);
				onMetaEdit();
			});
			cb.checked = proj.targets.indexOf(tid) >= 0;
			tgtPane.add(cb);
		}

		var cy = 70 + 4 * 30 + 30;
		tgtPane.add(new FlxText(10, cy - 15, 330, 'Custom objects (comma separated, e.g. bg, stageFront):'));
		var ci:PsychUIInputText = new PsychUIInputText(10, cy, 320, proj.customTargets, 8);
		ci.onChange = function(old:String, cur:String)
		{
			if (uiSuppress)
				return;
			proj.customTargets = cur;
			onMetaEdit();
		};
		tgtPane.add(ci);

		tgtPane.add(new FlxText(10, cy + 35, 330, [
			'Strums: all 4 arrows of the group get the shader.',
			'Notes: the shader is applied once when a note spawns, so time / beat animation stays frozen on notes.',
			'Sprites with an atlas get their frame rectangle every frame, so positional effects (vignette, gradients, masks) stay inside the current frame.',
			'Cameras cannot be targeted: the Lua API of Timeless Engine only has setSpriteShader for sprites.'
		].join('\n\n'), 11));
		uiSuppress = false;
	}

	// ====================================================================== EXPORT tab
	function textField(pane:ShaderPane, y:Int, label:String, value:String, onSet:String->Void)
	{
		pane.add(new FlxText(10, y - 15, 330, label));
		var inp:PsychUIInputText = new PsychUIInputText(10, y, 220, value, 8);
		inp.onChange = function(old:String, cur:String)
		{
			if (uiSuppress)
				return;
			onSet(cur);
			onMetaEdit();
		};
		pane.add(inp);
	}

	function buildExportTab()
	{
		expPane.clear();
		uiSuppress = true;
		expPane.add(new FlxText(10, 8, 330, 'EXPORT', 16));
		textField(expPane, 55, 'Shader name  ->  shaders/<name>.frag', proj.shaderName, function(s) proj.shaderName = s);
		textField(expPane, 100, 'Script name  ->  scripts/<name>.lua', proj.luaName, function(s) proj.luaName = s);
		textField(expPane, 145, 'Mod folder (empty = global mods/ folder)', proj.modFolder, function(s) proj.modFolder = s);

		var atlas:PsychUICheckBox = null;
		atlas = new PsychUICheckBox(10, 190, 'Atlas aware (use u_frame)', 200, function()
		{
			if (uiSuppress)
				return;
			proj.atlasAware = atlas.checked;
			onEdit();
		});
		atlas.checked = proj.atlasAware;
		expPane.add(atlas);

		expPane.add(new FlxText(10, 223, 330, 'Output mode:'));
		var exportBtn:PsychUIButton = new PsychUIButton(10, 290, 'Export .frag + .lua', exportFiles, 320);
		exportBtn.normalStyle.bgColor = FlxColor.GREEN;
		exportBtn.normalStyle.textColor = FlxColor.WHITE;
		expPane.add(exportBtn);
		expPane.add(new PsychUIButton(10, 320, 'Copy GLSL', copyGlsl, 155));
		expPane.add(new PsychUIButton(175, 320, 'Copy Lua', copyLua, 155));
		expPane.add(new PsychUIButton(10, 350, 'Save Project', saveProject, 155));
		expPane.add(new PsychUIButton(175, 350, 'Open Project...', openProjectList, 155));

		exportText = new FlxText(10, 385, 330, 'Nothing exported yet.', 11);
		expPane.add(exportText);
		expPane.add(new FlxText(10, 440, 330, [
			'Uniforms mode: every value is a uniform and the .lua sets them, so you can tweak them at runtime with setShaderFloat.',
			'Baked mode: values are written into the GLSL, the .lua only attaches the shader (smaller, slightly faster).',
			'The preview always uses the exact same GLSL that gets exported.'
		].join('\n\n'), 11));

		var mode:PsychUIDropDownMenu = new PsychUIDropDownMenu(10, 238, ['Uniforms (tweakable from Lua)', 'Baked constants'], function(id:Int, lbl:String)
		{
			if (uiSuppress)
				return;
			proj.bake = (id == 1);
			onMetaEdit();
		}, 220);
		expPane.add(mode);
		mode.selectedIndex = proj.bake ? 1 : 0;
		uiSuppress = false;
	}

	// ====================================================================== PREVIEW tab
	var pvBgDrop:PsychUIDropDownMenu;

	function buildPreviewTab()
	{
		var tab = mainBox.getTab('Preview').menu;
		tab.add(new FlxText(10, 8, 330, 'PREVIEW STAGE', 16));

		var names = ['dad', 'bf', 'dummy'];
		var labels = ['Daddy Dearest', 'Boyfriend', 'Test dummy'];
		for (i in 0...3)
		{
			var pid = names[i];
			var cb:PsychUICheckBox = null;
			cb = new PsychUICheckBox(10 + (i % 2) * 150, 45 + Std.int(i / 2) * 28, labels[i], 130, function() setPvVisible(pid, cb.checked));
			cb.checked = pvShow.get(pid);
			tab.add(cb);
		}
		var cc:PsychUICheckBox = null;
		cc = new PsychUICheckBox(160, 73, 'Custom image', 130, function() setPvVisible('custom', cc.checked));
		cc.checked = false;
		tab.add(cc);

		tab.add(new FlxText(10, 120, 330, 'Custom image (path in images/, no .png):'));
		var inp:PsychUIInputText = new PsychUIInputText(10, 135, 210, customPath, 8);
		inp.onChange = function(old:String, cur:String) customPath = cur;
		tab.add(inp);
		tab.add(new PsychUIButton(230, 133, 'Load', function() loadCustomPreview(customPath), 100));

		tab.add(new FlxText(10, 165, 110, 'Background:'));
		tab.add(new FlxText(130, 165, 100, 'BPM:'));
		var bpm:PsychUINumericStepper = new PsychUINumericStepper(130, 180, 1, pvBpm, 40, 300, 0, 75);
		bpm.onValueChange = function()
		{
			pvBpm = bpm.value;
			saveData.data.pvBpm = pvBpm;
		};
		tab.add(bpm);
		tab.add(new FlxText(240, 165, 100, 'Speed:'));
		var spd:PsychUINumericStepper = new PsychUINumericStepper(240, 180, 0.1, pvSpeed, 0, 5, 2, 75);
		spd.onValueChange = function() pvSpeed = spd.value;
		tab.add(spd);

		tab.add(new PsychUIButton(10, 225, 'Play / Pause', function() pvPlaying = !pvPlaying, 155));
		tab.add(new PsychUIButton(175, 225, 'Reset time', function()
		{
			pvTime = 0;
			pvBeatAge = 0;
		}, 155));
		tab.add(new PsychUIButton(10, 255, 'Compare original', function() bypassToggle = !bypassToggle, 155));
		tab.add(new PsychUIButton(175, 255, 'Reset view', resetView, 155));

		tab.add(new FlxText(10, 300, 330, 'Each preview sprite has its own shader object, exactly like setSpriteShader in the game.', 11));

		pvBgDrop = new PsychUIDropDownMenu(10, 180, PV_BG_NAMES, function(id:Int, lbl:String)
		{
			if (!uiSuppress)
				applyPreviewBg(id);
		}, 105);
		tab.add(pvBgDrop);
		pvBgDrop.selectedIndex = pvBg;
	}

	function applyPreviewBg(i:Int)
	{
		pvBg = i;
		saveData.data.pvBg = i;
		pvChecker.visible = (i == 0);
		camPreview.bgColor = PV_BG_COLORS[i];
		if (pvBgDrop != null && pvBgDrop.selectedIndex != i)
		{
			var was = uiSuppress;
			uiSuppress = true;
			pvBgDrop.selectedIndex = i;
			uiSuppress = was;
		}
	}

	function resetView()
	{
		camPreview.zoom = 1;
		camPreview.scroll.set(0, 0);
	}

	function makeAtlasSprite(img:String, xml:String, prefix:String, x:Float, y:Float, sc:Float):FlxSprite
	{
		var g = Paths.image(img);
		if (g == null)
			return null;
		var s = new FlxSprite(x, y);
		s.frames = FlxAtlasFrames.fromSparrow(g, xml);
		s.animation.addByPrefix('idle', prefix, 24, false);
		s.animation.play('idle');
		s.scale.set(sc, sc);
		s.updateHitbox();
		s.antialiasing = ClientPrefs.data.antialiasing;
		return s;
	}

	function makeDummy():FlxSprite
	{
		var s = new FlxSprite(330, 10).makeGraphic(220, 280, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawCircle(s, 110, 140, 105, 0x40FFFFFF); // faint halo (semi transparent pixels)
		FlxSpriteUtil.drawRoundRect(s, 50, 135, 120, 130, 36, 36, 0xFF3B6FD1);
		FlxSpriteUtil.drawRect(s, 62, 245, 40, 32, 0xFF222222);
		FlxSpriteUtil.drawRect(s, 118, 245, 40, 32, 0xFF222222);
		FlxSpriteUtil.drawCircle(s, 110, 80, 52, 0xFFE9B58A);
		FlxSpriteUtil.drawCircle(s, 90, 72, 7, 0xFF111111);
		FlxSpriteUtil.drawCircle(s, 130, 72, 7, 0xFF111111);
		FlxSpriteUtil.drawRect(s, 92, 98, 36, 6, 0xFFA02828);
		FlxSpriteUtil.drawCircle(s, 150, 160, 18, 0xFFFFD54F);
		s.antialiasing = true;
		return s;
	}

	function addPv(id:String, spr:FlxSprite)
	{
		spr.cameras = [camPreview];
		spr.visible = pvShow.get(id) == true;
		add(spr);
		pv.push({id: id, spr: spr, shader: null});
	}

	function buildPreviewSprites()
	{
		var dad = makeAtlasSprite('characters/DADDY_DEAREST', ShaderPreviewData.DAD_XML, 'idle', 10, 20, 0.7);
		if (dad != null)
			addPv('dad', dad);
		var bf = makeAtlasSprite('characters/BOYFRIEND', ShaderPreviewData.BF_XML, 'BF idle dance', 300, 270, 0.75);
		if (bf != null)
			addPv('bf', bf);
		if (dad == null && bf == null)
			pvShow.set('dummy', true); // images missing: never leave the stage empty
		addPv('dummy', makeDummy());
	}

	function setPvVisible(id:String, v:Bool)
	{
		pvShow.set(id, v);
		saveData.data.pvDad = pvShow.get('dad');
		saveData.data.pvBf = pvShow.get('bf');
		saveData.data.pvDummy = pvShow.get('dummy');
		for (it in pv)
			if (it.id == id)
				it.spr.visible = v;
	}

	function loadCustomPreview(path:String)
	{
		path = StringTools.trim(path);
		for (it in pv)
			if (it.id == 'custom')
			{
				pv.remove(it);
				remove(it.spr, true);
				it.spr.destroy();
				break;
			}
		if (path == '')
			return;
		var g = Paths.image(path);
		if (g == null)
		{
			showOutput('Image not found: images/' + path + '.png', true);
			return;
		}
		var s = new FlxSprite().loadGraphic(g);
		var sc = Math.min(1, 520 / Math.max(s.width, s.height));
		s.scale.set(sc, sc);
		s.updateHitbox();
		s.setPosition(PV_W / 2 - s.width / 2, PV_H / 2 - s.height / 2);
		s.antialiasing = ClientPrefs.data.antialiasing;
		pvShow.set('custom', true);
		addPv('custom', s);
		var item = pv[pv.length - 1];
		item.shader = makeShader(curGen != null ? curGen.glsl : lastGlsl);
		pushUniforms(item);
		applyShader(item);
		showOutput('Custom preview image loaded.');
	}

	// ====================================================================== shader (preview)
	function makeShader(glsl:String):FlxRuntimeShader
	{
		if (glsl == null || glsl == '')
			return null;
		try
		{
			return new FlxRuntimeShader(glsl);
		}
		catch (e:Dynamic)
		{
			showOutput('Shader error: ' + e, true);
			return null;
		}
	}

	function getTexBitmap(path:String):BitmapData
	{
		if (texCache.exists(path))
			return texCache.get(path);
		var g = Paths.image(path);
		var b:BitmapData = (g != null && g.bitmap != null) ? g.bitmap : whiteBmp;
		texCache.set(path, b);
		return b;
	}

	function pushUniforms(it:PvItem)
	{
		var sh = it.shader;
		if (sh == null || curGen == null)
			return;
		for (u in curGen.uniforms)
		{
			switch (u.type)
			{
				case 'float': sh.setFloat(u.name, u.v);
				case 'vec3': sh.setFloatArray(u.name, u.v);
				case 'sampler2D': sh.setSampler2D(u.name, getTexBitmap(Std.string(u.v)));
				default:
			}
		}
	}

	function applyShader(it:PvItem)
		it.spr.shader = (lastBypass || it.shader == null) ? null : it.shader;

	function refreshShader(force:Bool = false)
	{
		refreshTimer = -1;
		curGen = ShaderGen.build(proj, false);
		var recompile = force || curGen.glsl != lastGlsl;
		if (recompile)
			lastGlsl = curGen.glsl;
		for (it in pv)
		{
			if (recompile)
				it.shader = makeShader(curGen.glsl);
			pushUniforms(it);
			applyShader(it);
		}
		updateInfo();
	}

	function updatePreview(elapsed:Float)
	{
		if (pvPlaying)
		{
			pvTime += elapsed * pvSpeed;
			pvBeatAge += elapsed * pvSpeed;
		}
		var beatLen = 60 / Math.max(pvBpm, 1);
		while (pvBeatAge >= beatLen)
		{
			pvBeatAge -= beatLen;
			for (it in pv)
				if (it.id == 'dad' || it.id == 'bf')
					it.spr.animation.play('idle', true);
		}
		if (curGen == null)
			return;
		var beat = Math.max(0, 1 - pvBeatAge / beatLen);
		for (it in pv)
		{
			var sh = it.shader;
			if (sh == null || !it.spr.visible)
				continue;
			if (curGen.usesTime)
				sh.setFloat('u_time', pvTime);
			if (curGen.usesBeat)
				sh.setFloat('u_beat', beat);
			if (curGen.usesFrame && it.spr.frame != null)
			{
				var fr = it.spr.frame.frame;
				sh.setFloatArray('u_frame', [fr.x, fr.y, fr.width, fr.height]);
			}
		}
	}

	function updateViewport()
	{
		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;
		var inside = mx >= PV_X && mx < PV_X + PV_W && my >= PV_Y && my < PV_Y + PV_H;
		if (!inside)
			return;
		if (FlxG.mouse.wheel != 0 && PsychUIInputText.focusOn == null)
			camPreview.zoom = FlxMath.bound(camPreview.zoom * (1 + FlxG.mouse.wheel * 0.1), 0.5, 4);
		if (FlxG.mouse.pressedMiddle || FlxG.mouse.pressedRight)
		{
			camPreview.scroll.x -= FlxG.mouse.deltaScreenX / camPreview.zoom;
			camPreview.scroll.y -= FlxG.mouse.deltaScreenY / camPreview.zoom;
		}
	}

	// ====================================================================== files
	function exportRoot():String
	{
		var mod = StringTools.trim(proj.modFolder);
		return (mod == '') ? Paths.mods('') : Paths.mods(mod + '/');
	}

	function ensureDir(path:String)
	{
		var cur = path.startsWith('/') ? '/' : '';
		for (part in path.split('/'))
		{
			if (part == '')
				continue;
			cur += ((cur == '' || cur.endsWith('/')) ? '' : '/') + part;
			if (!FileSystem.exists(cur))
				NativeFileSystem.createDirectory(cur);
		}
	}

	function exportFiles()
	{
		if (dirtyTimer >= 0)
			commitNow();
		var shName = ShaderGen.sanitizeName(proj.shaderName, 'my_shader');
		var luName = ShaderGen.sanitizeName(proj.luaName, shName);
		var res = ShaderGen.build(proj, proj.bake);
		var lua = ShaderGen.buildLua(proj, res, shName);
		var root = exportRoot();
		var fragPath = root + 'shaders/' + shName + '.frag';
		var luaPath = root + 'scripts/' + luName + '.lua';
		try
		{
			ensureDir(root + 'shaders/');
			ensureDir(root + 'scripts/');
			File.saveContent(fragPath, res.glsl);
			File.saveContent(luaPath, lua);
			var msg = 'Exported:\n' + fragPath + '\n' + luaPath;
			if (exportText != null)
				exportText.text = msg;
			showOutput('Exported ' + shName + '.frag and ' + luName + '.lua');
			saveData.flush();
		}
		catch (e:Dynamic)
		{
			showOutput('Export failed: ' + e, true);
			if (exportText != null)
				exportText.text = 'Export failed:\n' + e;
		}
	}

	function copyGlsl()
	{
		Clipboard.text = ShaderGen.build(proj, proj.bake).glsl;
		showOutput('GLSL copied to the clipboard.');
	}

	function copyLua()
	{
		var shName = ShaderGen.sanitizeName(proj.shaderName, 'my_shader');
		Clipboard.text = ShaderGen.buildLua(proj, ShaderGen.build(proj, proj.bake), shName);
		showOutput('Lua copied to the clipboard.');
	}

	function saveProject()
	{
		if (dirtyTimer >= 0)
			commitNow();
		var name = ShaderGen.sanitizeName(proj.shaderName, 'my_shader');
		try
		{
			ensureDir('shader_projects/');
			File.saveContent('shader_projects/' + name + '.json', Json.stringify(proj.toJson(), null, '\t'));
			showOutput('Project saved: shader_projects/' + name + '.json');
		}
		catch (e:Dynamic)
		{
			showOutput('Could not save the project: ' + e, true);
		}
	}

	function openProjectList()
	{
		var dir = 'shader_projects/';
		var files:Array<String> = [];
		try
		{
			if (FileSystem.exists(dir))
				files = FileSystem.readDirectory(dir).filter(function(f:String) return f.endsWith('.json'));
		}
		catch (e:Dynamic) {}
		if (files.length < 1)
		{
			showOutput('No saved projects found in shader_projects/.', true);
			return;
		}
		files.sort(function(a:String, b:String) return (a.toLowerCase() < b.toLowerCase()) ? -1 : 1);

		var maxItems:Int = Std.int(Math.min(6, files.length));
		var radioGrp:PsychUIRadioGroup = new PsychUIRadioGroup(0, 0, files, 25, maxItems, false, 280);
		radioGrp.checked = 0;
		var hei:Float = radioGrp.height + 160;

		var promptState = new Prompt('Open Project', function() {
		});

		openSubState(promptState);

		upperBox.isMinimized = true;
		upperBox.bg.visible = false;

		var btn:PsychUIButton = new PsychUIButton(promptState.bg.x + promptState.bg.width - 40, promptState.bg.y, 'X', promptState.close, 40);
		btn.cameras = promptState.cameras;
		promptState.add(btn);

		radioGrp.screenCenter(X);
		radioGrp.y = promptState.bg.y + 80;
		radioGrp.cameras = promptState.cameras;
		promptState.add(radioGrp);

		var load:PsychUIButton = new PsychUIButton(0, radioGrp.y + radioGrp.height + 20, 'Load', function()
		{
			var f = files[radioGrp.checked];
			promptState.close();
			loadProjectFile(dir + f);
		});
		load.screenCenter(X);
		load.cameras = promptState.cameras;
		promptState.add(load);
	}

	function loadProjectFile(path:String)
	{
		try
		{
			var p = ShaderProject.fromString(File.getContent(path));
			proj = p;
			sel = (proj.layers.length > 0) ? 0 : -1;
			commitNow();
			rebuildAllTabs();
			refreshShader();
			showOutput('Project loaded: ' + path);
		}
		catch (e:Dynamic)
		{
			showOutput('Could not load the project: ' + e, true);
		}
	}

	// ====================================================================== update
	override function update(elapsed:Float)
	{
		processPending();
		ClientPrefs.toggleVolumeKeys(PsychUIInputText.focusOn == null);
		outputAlpha = Math.max(0, outputAlpha - elapsed);

		if (dirtyTimer >= 0)
		{
			dirtyTimer -= elapsed;
			if (dirtyTimer < 0)
				commitSnapshot();
		}
		if (refreshTimer >= 0)
		{
			refreshTimer -= elapsed;
			if (refreshTimer < 0)
				refreshShader();
		}

		var typing:Bool = PsychUIInputText.focusOn != null;
		var byp = bypassToggle || (!typing && FlxG.keys.pressed.B);
		if (byp != lastBypass)
		{
			lastBypass = byp;
			for (it in pv)
				applyShader(it);
		}

		if (!typing)
			handleKeys();

		updateViewport();
		updatePreview(elapsed);

		outputTxt.alpha = outputAlpha;
		outputTxt.visible = (outputAlpha > 0);
		ignoreClickForThisFrame = false;
		super.update(elapsed);
	}

	function handleKeys()
	{
		if (FlxG.keys.justPressed.F1)
		{
			toggleHelp();
			return;
		}
		if (fullTipText.visible)
		{
			if (FlxG.keys.justPressed.ESCAPE)
				toggleHelp();
			return;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.Z)
			{
				if (FlxG.keys.pressed.SHIFT)
					redo();
				else
					undo();
			}
			else if (FlxG.keys.justPressed.Y)
				redo();
			else if (FlxG.keys.justPressed.S)
				exportFiles();
			else if (FlxG.keys.justPressed.D)
				duplicateLayer(sel);
			else if (FlxG.keys.justPressed.C)
				copyLayer();
			else if (FlxG.keys.justPressed.V)
				pasteLayer();
			else if (FlxG.keys.justPressed.UP)
				moveLayer(sel, -1);
			else if (FlxG.keys.justPressed.DOWN)
				moveLayer(sel, 1);
			return;
		}

		if (FlxG.keys.justPressed.UP)
			selectLayer(sel - 1);
		else if (FlxG.keys.justPressed.DOWN)
			selectLayer(sel + 1);
		else if (FlxG.keys.justPressed.DELETE)
			removeLayer(sel);
		else if (FlxG.keys.justPressed.E)
			toggleLayer(sel);
		else if (FlxG.keys.justPressed.SPACE)
			pvPlaying = !pvPlaying;
		else if (FlxG.keys.justPressed.HOME)
			resetView();
		else if (FlxG.keys.justPressed.ESCAPE #if mobile || FlxG.android.justPressed.BACK #end)
			exitEditor();
	}
}
