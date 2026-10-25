package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSpriteUtil;
import backend.MusicBeatState;
import backend.Paths;
import sys.io.File;
import sys.FileSystem;
import states.editors.content.*;

typedef ShaderPointData = {
	var x:Float;
	var y:Float;
	var colorHex:String;
	var uiText:FlxText;
	var uiInput:PsychUIInputText;
	var uiDelete:PsychUIButton;
}

class ShaderEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var points:Array<ShaderPointData> = [];
	var curPointIndex:Int = -1;

	var radius:Float = 0.3;
	var brightness:Float = 1.0;

	var targets:Map<String, Bool> = [
		"opponent" => false,
		"player" => false,
		"opponent notes" => false,
		"player notes" => false,
		"background" => false
	];

	var targetButtons:Map<String, PsychUIButton> = new Map<String, PsychUIButton>();
	
	var dadPreview:FlxSprite;
	var bfPreview:FlxSprite;
	var pointWheelBg:FlxSprite;
	var pointWheelMarker:FlxSprite;
	
	var shaderNameInput:PsychUIInputText;
	var luaNameInput:PsychUIInputText;
	
	var radiusSlider:PsychUISlider;
	var intensitySlider:PsychUISlider;
	
	var editorBox:PsychUIBox;
	var camUI:FlxCamera;
	var pointDynamicGroup:FlxTypedGroup<flixel.FlxBasic>;

	override public function create()
	{
		super.create();

		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF242424);
		add(bg);

		dadPreview = new FlxSprite(60, 120);
		dadPreview.frames = Paths.getSparrowAtlas('DADDY_DEAREST');
		dadPreview.animation.addByPrefix('idle', 'idle', 24, true);
		dadPreview.animation.play('idle');
		dadPreview.scale.set(0.75, 0.75);
		dadPreview.updateHitbox();
		add(dadPreview);

		bfPreview = new FlxSprite(320, 260);
		bfPreview.frames = Paths.getSparrowAtlas('BOYFRIEND');
		bfPreview.animation.addByPrefix('idle', 'BF idle dance', 24, true);
		bfPreview.animation.play('idle');
		bfPreview.scale.set(0.75, 0.75);
		bfPreview.updateHitbox();
		add(bfPreview);

		editorBox = new PsychUIBox(FlxG.width - 370, 40, 350, 650, ['Light', 'Settings']);
		editorBox.scrollFactor.set();
		editorBox.cameras = [camUI];
		add(editorBox);

		pointDynamicGroup = new FlxTypedGroup<flixel.FlxBasic>();
		add(pointDynamicGroup);

		refreshLightTab();
		refreshSettingsTab();

		FlxG.mouse.visible = true;
	}

	function refreshLightTab()
	{
		var tab = editorBox.getTab('Light').menu;
		tab.clear();

		var objX = 15;
		var objY = 20;

		var addPointBtn = new PsychUIButton(objX, objY, "ADD POINT", function() {
			addNewPoint();
		}, 140);
		tab.add(addPointBtn);

		objY += 45;

		for (i in 0...points.length)
		{
			var pt = points[i];
			var pIndex = i + 1;

			var ptText = new FlxText(objX, objY + 4, 80, "POINT " + pIndex);
			ptText.setFormat(Paths.font("vcr.ttf"), 14, (curPointIndex == i) ? FlxColor.GREEN : FlxColor.WHITE);
			tab.add(ptText);
			pt.uiText = ptText;

			var ptColorInput = new PsychUIInputText(objX + 80, objY, 70, pt.colorHex, 8);
			ptColorInput.onChange = function(old:String, cur:String) {
				pt.colorHex = cur;
			}
			tab.add(ptColorInput);
			pt.uiInput = ptColorInput;

			var selectBtn = new PsychUIButton(objX + 160, objY, "SELECT", function() {
				selectPoint(i);
			}, 65);
			tab.add(selectBtn);

			var delBtn = new PsychUIButton(objX + 235, objY, "DEL", function() {
				deletePoint(i);
			}, 45);
			delBtn.normalStyle.bgColor = FlxColor.RED;
			tab.add(delBtn);
			pt.uiDelete = delBtn;

			objY += 38;
		}

		objY = 250;

		radiusSlider = new PsychUISlider(objX + 40, objY, function(v:Float) {
			radius = v;
		}, radius, 0.01, 1.0, 200);
		radiusSlider.label = 'Light Radius';
		tab.add(radiusSlider);

		objY += 45;
		intensitySlider = new PsychUISlider(objX + 40, objY, function(v:Float) {
			brightness = v;
		}, brightness, 0.0, 5.0, 200);
		intensitySlider.label = 'Light Intensity';
		tab.add(intensitySlider);

		objY += 55;

		pointWheelBg = new FlxSprite(objX + 50, objY).makeGraphic(160, 160, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(pointWheelBg, 80, 80, 78, FlxColor.fromARGB(255, 31, 31, 31));
		FlxSpriteUtil.drawCircle(pointWheelBg, 80, 80, 78, FlxColor.TRANSPARENT, {color: FlxColor.GRAY, size: 2});
		FlxSpriteUtil.drawLine(pointWheelBg, 0, 80, 160, 80, {color: FlxColor.fromARGB(100, 128, 128, 128), size: 1});
		FlxSpriteUtil.drawLine(pointWheelBg, 80, 0, 80, 160, {color: FlxColor.fromARGB(100, 128, 128, 128), size: 1});
		tab.add(pointWheelBg);

		pointWheelMarker = new FlxSprite(0, 0).makeGraphic(10, 10, FlxColor.GREEN);
		pointWheelMarker.visible = false;
		tab.add(pointWheelMarker);

		if (curPointIndex > -1 && curPointIndex < points.length) {
			var pt = points[curPointIndex];
			pointWheelMarker.visible = true;
			pointWheelMarker.setPosition(
				editorBox.x + tab.x + pointWheelBg.x + (pt.x * pointWheelBg.width) - 5,
				editorBox.y + tab.y + pointWheelBg.y + (pt.y * pointWheelBg.height) - 5
			);
		}

		objY += 175;

		var exportBtn = new PsychUIButton(objX, objY, "GENERATE FILES", function() {
			exportShaderFiles();
		}, 310);
		tab.add(exportBtn);
	}

	function refreshSettingsTab()
	{
		var tab = editorBox.getTab('Settings').menu;
		tab.clear();

		var objX = 15;
		var objY = 25;

		shaderNameInput = new PsychUIInputText(objX, objY, 140, 'timeless_light', 8);
		luaNameInput = new PsychUIInputText(objX + 160, objY, 140, 'timeless_light', 8);
		tab.add(new FlxText(shaderNameInput.x, shaderNameInput.y - 15, 120, 'Shader Name:'));
		tab.add(new FlxText(luaNameInput.x, luaNameInput.y - 15, 120, 'Lua Name:'));
		tab.add(shaderNameInput);
		tab.add(luaNameInput);

		objY += 50;
		tab.add(new FlxText(objX, objY - 15, 200, 'Targets:'));
		var targetList:Array<String> = ["opponent", "player", "opponent notes", "player notes", "background"];
		for (i in 0...targetList.length)
		{
			var tName = targetList[i];
			var btn = new PsychUIButton(objX + (i % 2 == 0 ? 0 : 150), objY + (Std.int(i / 2) * 38), tName.toUpperCase(), function() {
				toggleTarget(tName);
			}, 140);
			tab.add(btn);
			targetButtons.set(tName, btn);
			updateButtonVisual(tName);
		}
	}

	function addNewPoint()
	{
		if (points.length >= 6) return;

		var newPt:ShaderPointData = {
			x: 0.5,
			y: 0.5,
			colorHex: "FFFFFF",
			uiText: null,
			uiInput: null,
			uiDelete: null
		};
		points.push(newPt);
		selectPoint(points.length - 1);
	}

	function selectPoint(index:Int)
	{
		curPointIndex = index;
		refreshLightTab();
	}

	function deletePoint(index:Int)
	{
		if (index > -1 && index < points.length) {
			points.splice(index, 1);
			if (curPointIndex >= points.length) curPointIndex = points.length - 1;
			selectPoint(curPointIndex);
		}
	}

	function toggleTarget(name:String)
	{
		targets.set(name, !targets.get(name));
		updateButtonVisual(name);
	}

	function updateButtonVisual(name:String)
	{
		var btn = targetButtons.get(name);
		if (btn != null) {
			btn.normalStyle.textColor = targets.get(name) ? FlxColor.GREEN : FlxColor.WHITE;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PsychUIInputText.focusOn != null) return;

		if (FlxG.mouse.justPressed || (FlxG.touches.list.length > 0 && FlxG.touches.list[0].justPressed))
		{
			var mouseX = FlxG.mouse.x;
			var mouseY = FlxG.mouse.y;
			
			if (FlxG.touches.list.length > 0 && FlxG.touches.list[0] != null) {
				mouseX = Std.int(FlxG.touches.list[0].x);
				mouseY = Std.int(FlxG.touches.list[0].y);
			}

			if (curPointIndex > -1 && curPointIndex < points.length) {
				var tab = editorBox.getTab('Light').menu;
				var realWheelX = editorBox.x + tab.x + pointWheelBg.x;
				var realWheelY = editorBox.y + tab.y + pointWheelBg.y;

				if (mouseX >= realWheelX && mouseX <= (realWheelX + pointWheelBg.width) &&
					mouseY >= realWheelY && mouseY <= (realWheelY + pointWheelBg.height))
				{
					var pt = points[curPointIndex];
					pt.x = (mouseX - realWheelX) / pointWheelBg.width;
					pt.y = (mouseY - realWheelY) / pointWheelBg.height;
					selectPoint(curPointIndex);
				}
			}
		}

		if (FlxG.keys.justPressed.ESCAPE #if mobile || FlxG.android.justPressed.BACK #end) {
			MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}
	}

	function exportShaderFiles()
	{
		var sName = shaderNameInput.text.trim();
		var lName = luaNameInput.text.trim();

		if (sName.length < 1) sName = "timeless_light";
		if (lName.length < 1) lName = "timeless_light";
		
		var fragCode:String = "
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
uniform vec2 u_centers[8];
uniform vec3 u_colors[8];
uniform int u_total_points;
uniform float u_radius;
uniform float u_brightness;

void main() {
	vec4 color = flixel_texture2D(bitmap, uv);
	vec3 finalLight = vec3(0.0);
	
	for(int i = 0; i < u_total_points; i++) {
		float dist = distance(uv, u_centers[i]);
		if (dist < u_radius) {
			float intensity = 1.0 - (dist / u_radius);
			finalLight += u_colors[i] * intensity * u_brightness;
		}
	}
	
	color.rgb += finalLight;
	gl_FragColor = color;
}";

		var luaCode:String = "function onCreatePost()\n";
		luaCode += "    initLuaShader('" + sName + "')\n";

		var psychTargetMap:Map<String, String> = [
			"opponent" => "dad",
			"player" => "boyfriend",
			"opponent notes" => "opponentStrums",
			"player notes" => "playerStrums",
			"background" => "bg"
		];

		var hasAnyTarget = false;
		for (k in targets.keys())
		{
			if (targets.get(k))
			{
				var psychObj = psychTargetMap.get(k);
				luaCode += "    setSpriteShader('" + psychObj + "', '" + sName + "')\n";
				hasAnyTarget = true;
			}
		}

		if (hasAnyTarget && points.length > 0) {
			luaCode += "    setShaderInt('dad', 'u_total_points', " + points.length + ")\n";
			luaCode += "    setShaderFloat('dad', 'u_radius', " + radius + ")\n";
			luaCode += "    setShaderFloat('dad', 'u_brightness', " + brightness + ")\n";
			
			for(i in 0...points.length) {
				var pt = points[i];
				var flColor = FlxColor.fromString("#" + pt.colorHex.trim());
				luaCode += "    setShaderFloatArray('dad', 'u_centers[" + i + "]', {" + pt.x + ", " + pt.y + "})\n";
				luaCode += "    setShaderFloatArray('dad', 'u_colors[" + i + "]', {" + flColor.redFloat + ", " + flColor.greenFloat + ", " + flColor.blueFloat + "})\n";
			}
		}
		
		luaCode += "end\n";

		try {
			var exportPath = "./saves/shaders/";
			if (!FileSystem.exists(exportPath)) FileSystem.createDirectory(exportPath);

			File.saveContent(exportPath + sName + ".frag", fragCode);
			File.saveContent(exportPath + lName + ".lua", luaCode);
		} catch(e:Dynamic) {}
	}

	public function UIEvent(id:String, sender:Dynamic) {}
}