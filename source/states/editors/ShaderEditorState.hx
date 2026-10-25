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
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import backend.MusicBeatState;
import backend.Paths;
import sys.io.File;
import sys.FileSystem;
import states.editors.content.*;

typedef ShaderPointData = {
	var x:Float;
	var y:Float;
	var radius:Float;
	var brightness:Float;
	var fadeout:Float;
	var gradient:Float;
	var angle:Float;
	var colorHex:String;
	var colorHex2:String;
	var isExpanded:Bool;
	var isPulse:Bool;
}

class RuntimeErectShader extends FlxShader
{
	@:glFragmentSource("
		#pragma header
		vec2 uv = openfl_TextureCoordv.xy;
		uniform vec2 u_centers[8];
		uniform vec3 u_colors[8];
		uniform vec3 u_colors2[8];
		uniform float u_radii[8];
		uniform float u_brightnesses[8];
		uniform float u_fadeouts[8];
		uniform float u_gradients[8];
		uniform float u_angles[8];
		uniform int u_total_points;

		void main() {
			vec4 color = flixel_texture2D(bitmap, uv);
			if (color.a == 0.0) {
				gl_FragColor = color;
				return;
			}

			vec3 totalRimLight = vec3(0.0);
			for(int i = 0; i < 8; i++) {
				if (i >= u_total_points) break;
				
				float radAngle = radians(u_angles[i]);
				vec2 offset = vec2(cos(radAngle), sin(radAngle)) * (u_radii[i] * 0.03);
				
				float alphaAlpha = flixel_texture2D(bitmap, uv - offset).a;
				
				if (alphaAlpha < 0.9) {
					float edgeGlow = smoothstep(0.9, u_fadeouts[i], alphaAlpha);
					vec3 mixedColor = mix(u_colors[i], u_colors2[i], u_gradients[i]);
					
					float aaFactor = smoothstep(0.0, fwidth(alphaAlpha), 0.9 - alphaAlpha);
					totalRimLight += mixedColor * u_brightnesses[i] * edgeGlow * aaFactor;
				}
			}
			
			color.rgb += totalRimLight * color.a;
			gl_FragColor = color;
		}
	")
	public function new()
	{
		super();
	}
}

class ShaderEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var points:Array<ShaderPointData> = [];
	var curPointIndex:Int = -1;
	var isDraggingWheel:Bool = false;

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
	
	var editorBox:PsychUIBox;
	var camUI:FlxCamera;
	var successText:FlxText;

	var dadShader:RuntimeErectShader;
	var bfShader:RuntimeErectShader;

	override public function create()
	{
		super.create();

		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF18181F;
		bg.setGraphicSize(Std.int(bg.width * 1.15));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var title:FlxText = new FlxText(25, 20, FlxG.width, "SHADER EDITOR", 24);
		title.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		title.cameras = [camUI];
		add(title);

		dadShader = new RuntimeErectShader();
		bfShader = new RuntimeErectShader();

		var dadXml:String = '<?xml version="1.0" encoding="UTF-8"?><TextureAtlas imagePath="DADDY_DEAREST.png"><SubTexture name="idle0001" x="1723" y="8" width="421" height="767" frameX="-5" frameY="-0" frameWidth="429" frameHeight="767" /><SubTexture name="idle0002" x="1723" y="8" width="421" height="767" frameX="-5" frameY="-0" frameWidth="429" frameHeight="767" /><SubTexture name="idle0003" x="1820" y="791" width="429" height="759" frameX="-0" frameY="-8" frameWidth="429" frameHeight="767" /><SubTexture name="idle0004" x="1820" y="791" width="429" height="759" frameX="-0" frameY="-8" frameWidth="429" frameHeight="767" /><SubTexture name="idle0005" x="2265" y="783" width="425" height="758" frameX="-1" frameY="-9" frameWidth="429" frameHeight="767" /><SubTexture name="idle0006" x="2265" y="783" width="425" height="758" frameX="-1" frameY="-9" frameWidth="429" frameHeight="767" /><SubTexture name="idle0007" x="2160" y="8" width="424" height="759" frameX="-2" frameY="-8" frameWidth="429" frameHeight="767" /><SubTexture name="idle0008" x="2160" y="8" width="424" height="759" frameX="-2" frameY="-8" frameWidth="429" frameHeight="767" /></TextureAtlas>';
		var bfXml:String = '<?xml version="1.0" encoding="utf-8"?><TextureAtlas imagePath="BOYFRIEND.png"><SubTexture name="BF idle dance0000" x="3189" y="868" width="406" height="392" frameX="-1" frameY="-20" frameWidth="411" frameHeight="412" /><SubTexture name="BF idle dance0001" x="3189" y="868" width="406" height="392" frameX="-1" frameY="-20" frameWidth="411" frameHeight="412" /><SubTexture name="BF idle dance0002" x="3597" y="868" width="408" height="393" frameX="0" frameY="-19" frameWidth="411" frameHeight="412" /><SubTexture name="BF idle dance0003" x="3597" y="868" width="408" height="393" frameX="0" frameY="-19" frameWidth="411" frameHeight="412" /><SubTexture name="BF idle dance0004" x="2" y="1311" width="405" height="398" frameX="-3" frameY="-14" frameWidth="411" frameHeight="412" /><SubTexture name="BF idle dance0005" x="2" y="1311" width="405" height="398" frameX="-3" frameY="-14" frameWidth="411" frameHeight="412" /></TextureAtlas>';

		dadPreview = new FlxSprite(30, 110);
		dadPreview.frames = FlxAtlasFrames.fromSparrow(Paths.image('characters/DADDY_DEAREST'), dadXml);
		dadPreview.animation.addByPrefix('idle', 'idle', 24, false);
		dadPreview.animation.play('idle');
		dadPreview.antialiasing = true;
		dadPreview.scale.set(0.7, 0.7);
		dadPreview.updateHitbox();
		dadPreview.shader = dadShader;
		add(dadPreview);

		bfPreview = new FlxSprite(240, 230);
		bfPreview.frames = FlxAtlasFrames.fromSparrow(Paths.image('characters/BOYFRIEND'), bfXml);
		bfPreview.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		bfPreview.animation.play('idle');
		bfPreview.antialiasing = true;
		bfPreview.scale.set(0.7, 0.7);
		bfPreview.updateHitbox();
		bfPreview.shader = bfShader;
		add(bfPreview);

		editorBox = new PsychUIBox(FlxG.width - 390, 45, 360, 650, ['Light', 'Settings']);
		editorBox.scrollFactor.set();
		editorBox.cameras = [camUI];
		add(editorBox);

		addNewPoint();
		
		FlxG.mouse.visible = true;
	}

	function refreshLightTab()
	{
		var tab = editorBox.getTab('Light').menu;
		tab.clear();

		var objX = 10;
		var objY = 15;

		var addPointBtn = new PsychUIButton(objX, objY, "ADD POINT", function() {
			addNewPoint();
		}, 120);
		tab.add(addPointBtn);

		var resetBtn = new PsychUIButton(objX + 130, objY, "RESET ALL", function() {
			points = [];
			curPointIndex = -1;
			addNewPoint();
		}, 100);
		resetBtn.normalStyle.bgColor = FlxColor.RED;
		tab.add(resetBtn);

		objY += 40;

		for (i in 0...points.length)
		{
			var pt = points[i];
			var pIndex = i + 1;
			var isCurrent = (curPointIndex == i);

			var foldStr = pt.isExpanded ? "[-] " : "[+] ";
			var titleBtn = new PsychUIButton(objX, objY, foldStr + "PT " + pIndex, function() {
				pt.isExpanded = !pt.isExpanded;
				selectPoint(i);
			}, 65);
			
			var cleanHex = pt.colorHex.trim();
			var parsedColor = FlxColor.fromString("#" + (cleanHex.length == 6 ? cleanHex : "FFFFFF"));
			titleBtn.normalStyle.textColor = isCurrent ? FlxColor.GREEN : parsedColor;
			tab.add(titleBtn);

			var ptColorInput = new PsychUIInputText(objX + 70, objY, 50, pt.colorHex, 8);
			ptColorInput.onChange = function(old:String, cur:String) {
				var h = cur.trim();
				if (h.length == 6 && FlxColor.fromString("#" + h) != null) {
					pt.colorHex = h;
					updateRealtimeShaders();
				}
			}
			tab.add(ptColorInput);

			var ptColorInput2 = new PsychUIInputText(objX + 125, objY, 50, pt.colorHex2, 8);
			ptColorInput2.onChange = function(old:String, cur:String) {
				var h = cur.trim();
				if (h.length == 6 && FlxColor.fromString("#" + h) != null) {
					pt.colorHex2 = h;
					updateRealtimeShaders();
				}
			}
			tab.add(ptColorInput2);

			var cloneBtn = new PsychUIButton(objX + 180, objY, "CLNE", function() {
				clonePoint(i);
			}, 40);
			tab.add(cloneBtn);

			var upBtn = new PsychUIButton(objX + 225, objY, "^", function() { movePointOrder(i, -1); }, 20);
			var dnBtn = new PsychUIButton(objX + 250, objY, "v", function() { movePointOrder(i, 1); }, 20);
			tab.add(upBtn); tab.add(dnBtn);

			var delBtn = new PsychUIButton(objX + 275, objY, "X", function() {
				deletePoint(i);
			}, 25);
			delBtn.normalStyle.bgColor = FlxColor.RED;
			tab.add(delBtn);

			objY += 32;

			if (pt.isExpanded)
			{
				var radSlider = new PsychUISlider(objX + 20, objY + 10, function(v:Float) { pt.radius = v; updateRealtimeShaders(); }, pt.radius, 0.01, 1.0, 160);
				radSlider.label = 'Radius'; tab.add(radSlider); objY += 32;

				var intensSlider = new PsychUISlider(objX + 20, objY + 10, function(v:Float) { pt.brightness = v; updateRealtimeShaders(); }, pt.brightness, 0.0, 5.0, 160);
				intensSlider.label = 'Intensity'; tab.add(intensSlider); objY += 32;

				var fadeSlider = new PsychUISlider(objX + 20, objY + 10, function(v:Float) { pt.fadeout = v; updateRealtimeShaders(); }, pt.fadeout, 0.0, 0.9, 160);
				fadeSlider.label = 'Fade-Out'; tab.add(fadeSlider); objY += 32;

				var gradSlider = new PsychUISlider(objX + 20, objY + 10, function(v:Float) { pt.gradient = v; updateRealtimeShaders(); }, pt.gradient, 0.0, 1.0, 160);
				gradSlider.label = 'Gradient'; tab.add(gradSlider); objY += 35;
			}
		}

		objY = 380;

		pointWheelBg = new FlxSprite(objX + 75, objY).makeGraphic(170, 160, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(pointWheelBg, 85, 80, 78, FlxColor.fromRGB(24, 24, 28, 255));
		FlxSpriteUtil.drawCircle(pointWheelBg, 85, 80, 78, FlxColor.TRANSPARENT, {color: FlxColor.CYAN, thickness: 2});
		FlxSpriteUtil.drawLine(pointWheelBg, 5, 80, 165, 80, {color: FlxColor.fromRGB(90, 90, 110, 130), thickness: 1});
		FlxSpriteUtil.drawLine(pointWheelBg, 85, 5, 85, 155, {color: FlxColor.fromRGB(90, 90, 110, 130), thickness: 1});
		tab.add(pointWheelBg);

		pointWheelMarker = new FlxSprite(0, 0).makeGraphic(12, 12, FlxColor.GREEN);
		pointWheelMarker.visible = false;
		tab.add(pointWheelMarker);

		if (curPointIndex > -1 && curPointIndex < points.length) {
			var pt = points[curPointIndex];
			pointWheelMarker.visible = true;
			pointWheelMarker.setPosition(
				editorBox.x + tab.x + pointWheelBg.x + (pt.x * pointWheelBg.width) - 6,
				editorBox.y + tab.y + pointWheelBg.y + (pt.y * pointWheelBg.height) - 6
			);
		}

		objY += 180;

		var exportBtn = new PsychUIButton(objX, objY, "GENERATE FILES", function() {
			exportShaderFiles();
		}, 310);
		tab.add(exportBtn);

		objY += 40;
		successText = new FlxText(objX, objY, 310, "", 14);
		successText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, CENTER);
		tab.add(successText);
	}

	function refreshSettingsTab()
	{
		var tab = editorBox.getTab('Settings').menu;
		tab.clear();

		var objX = 15;
		var objY = 25;

		shaderNameInput = new PsychUIInputText(objX, objY, 130, 'timeless_erect', 8);
		shaderNameInput.cameras = [camUI];
		
		luaNameInput = new PsychUIInputText(objX + 150, objY, 130, 'timeless_erect', 8);
		luaNameInput.cameras = [camUI];

		var label1 = new FlxText(shaderNameInput.x, shaderNameInput.y - 15, 120, 'Shader Name:');
		label1.cameras = [camUI];
		var label2 = new FlxText(luaNameInput.x, luaNameInput.y - 15, 120, 'Lua Name:');
		label2.cameras = [camUI];

		tab.add(label1); tab.add(label2); tab.add(shaderNameInput); tab.add(luaNameInput);

		objY += 55;
		var targetLabel = new FlxText(objX, objY - 15, 200, 'Targets Config:');
		targetLabel.cameras = [camUI];
		tab.add(targetLabel);

		var targetList:Array<String> = ["opponent", "player", "opponent notes", "player notes", "background"];
		for (i in 0...targetList.length)
		{
			var tName = targetList[i];
			var btn = new PsychUIButton(objX + (i % 2 == 0 ? 0 : 145), objY + (Std.int(i / 2) * 35), tName.toUpperCase(), function() {
				toggleTarget(tName);
			}, 130);
			btn.cameras = [camUI];
			
			tab.add(btn);
			targetButtons.set(tName, btn);
			updateButtonVisual(tName);
		}
	}

	function addNewPoint()
	{
		if (points.length >= 8) return;

		var newPt:ShaderPointData = {
			x: 0.5, y: 0.0, radius: 0.25, brightness: 1.2, fadeout: 0.0, gradient: 0.0, angle: 270.0,
			colorHex: "FFFFFF", colorHex2: "FFFFFF", isExpanded: true, isPulse: false
		};
		
		for(p in points) p.isExpanded = false;
		points.push(newPt);
		selectPoint(points.length - 1);
		updateRealtimeShaders();
	}

	function clonePoint(index:Int)
	{
		if (index > -1 && index < points.length && points.length < 8) {
			var src = points[index];
			var copyPt:ShaderPointData = {
				x: src.x, y: src.y, radius: src.radius, brightness: src.brightness, fadeout: src.fadeout, gradient: src.gradient,
				angle: src.angle, colorHex: src.colorHex, colorHex2: src.colorHex2, isExpanded: true, isPulse: src.isPulse
			};
			for(p in points) p.isExpanded = false;
			points.insert(index + 1, copyPt);
			selectPoint(index + 1);
			updateRealtimeShaders();
		}
	}

	function movePointOrder(index:Int, dir:Int)
	{
		var targetIndex = index + dir;
		if (targetIndex >= 0 && targetIndex < points.length) {
			var temp = points[index];
			points[index] = points[targetIndex];
			points[targetIndex] = temp;
			selectPoint(targetIndex);
			updateRealtimeShaders();
		}
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
			updateRealtimeShaders();
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

	function updateRealtimeShaders()
	{
		var total = points.length;
		var centers:Array<Float> = [];
		var colors:Array<Float> = [];
		var colors2:Array<Float> = [];
		var radii:Array<Float> = [];
		var brightnesses:Array<Float> = [];
		var fadeouts:Array<Float> = [];
		var gradients:Array<Float> = [];
		var angles:Array<Float> = [];

		for(i in 0...8) {
			if (i < total) {
				var pt = points[i];
				centers.push(pt.x); centers.push(pt.y);
				
				var h1 = pt.colorHex.trim(); if (h1.length != 6) h1 = "FFFFFF";
				var c1 = FlxColor.fromString("#" + h1);
				colors.push(c1.redFloat); colors.push(c1.greenFloat); colors.push(c1.blueFloat);
				
				var h2 = pt.colorHex2.trim(); if (h2.length != 6) h2 = "FFFFFF";
				var c2 = FlxColor.fromString("#" + h2);
				colors2.push(c2.redFloat); colors2.push(c2.greenFloat); colors2.push(c2.blueFloat);
				
				radii.push(pt.radius);
				brightnesses.push(pt.brightness);
				fadeouts.push(pt.fadeout);
				gradients.push(pt.gradient);
				angles.push(pt.angle);
			} else {
				centers.push(0.5); centers.push(0.5);
				colors.push(0.0); colors.push(0.0); colors.push(0.0);
				colors2.push(0.0); colors2.push(0.0); colors2.push(0.0);
				radii.push(0.0); brightnesses.push(0.0); fadeouts.push(0.0); gradients.push(0.0); angles.push(0.0);
			}
		}

		for(sh in [dadShader, bfShader]) {
			sh.data.u_total_points.value = [total];
			sh.data.u_centers.value = centers;
			sh.data.u_colors.value = colors;
			sh.data.u_colors2.value = colors2;
			sh.data.u_radii.value = radii;
			sh.data.u_brightnesses.value = brightnesses;
			sh.data.u_fadeouts.value = fadeouts;
			sh.data.u_gradients.value = gradients;
			sh.data.u_angles.value = angles;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (dadPreview.animation.finished) dadPreview.animation.play('idle', true);
		if (bfPreview.animation.finished) bfPreview.animation.play('idle', true);

		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		
		if (FlxG.touches.list.length > 0 && FlxG.touches.list != null) {
			mouseX = Std.int(FlxG.touches.list[0].x);
			mouseY = Std.int(FlxG.touches.list[0].y);
		}

		if (FlxG.mouse.justPressed && PsychUIInputText.focusOn != null) {
			if (!FlxG.mouse.overlaps(shaderNameInput) && !FlxG.mouse.overlaps(luaNameInput)) {
				PsychUIInputText.focusOn = null;
			}
		}

		if (PsychUIInputText.focusOn != null) return;

		var tab = editorBox.getTab('Light').menu;
		var realWheelX = editorBox.x + tab.x + pointWheelBg.x;
		var realWheelY = editorBox.y + tab.y + pointWheelBg.y;

		if (FlxG.mouse.justPressed || (FlxG.touches.list.length > 0 && FlxG.touches.list[0].justPressed))
		{
			if (mouseX >= realWheelX && mouseX <= (realWheelX + pointWheelBg.width) &&
				mouseY >= realWheelY && mouseY <= (realWheelY + pointWheelBg.height))
			{
				isDraggingWheel = true;
			}
		}

		if (FlxG.mouse.released || (FlxG.touches.list.length > 0 && FlxG.touches.list[0].released))
		{
			isDraggingWheel = false;
		}

		if (isDraggingWheel && curPointIndex > -1 && curPointIndex < points.length)
		{
			var pt = points[curPointIndex];
			var dx = mouseX - (realWheelX + 85);
			var dy = mouseY - (realWheelY + 80);
			
			pt.angle = Math.atan2(dy, dx) * (180 / Math.PI);
			if (pt.angle < 0) pt.angle += 360;

			var rad = Math.atan2(dy, dx);
			pt.x = 0.5 + (Math.cos(rad) * 0.5);
			pt.y = 0.5 + (Math.sin(rad) * 0.5);

			selectPoint(curPointIndex);
			updateRealtimeShaders();
		}

		if (FlxG.keys.justPressed.ESCAPE #if mobile || FlxG.android.justPressed.BACK #end) {
			MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}
	}

	function exportShaderFiles()
	{
		var sName = shaderNameInput.text.trim();
		var lName = luaNameInput.text.trim();

		if (sName.length < 1) sName = "timeless_erect";
		if (lName.length < 1) lName = "timeless_erect";
		
		var fragCode:String = "
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
uniform vec2 u_centers;
uniform vec3 u_colors;
uniform vec3 u_colors2;
uniform float u_radii;
uniform float u_brightnesses;
uniform float u_fadeouts;
uniform float u_gradients;
uniform float u_angles;
uniform int u_total_points;
uniform float u_time;

void main() {
	vec4 color = flixel_texture2D(bitmap, uv);
	if (color.a == 0.0) {
		gl_FragColor = color;
		return;
	}

	vec3 totalRimLight = vec3(0.0);
	for(int i = 0; i < 8; i++) {
		if (i >= u_total_points) break;
		
		float radAngle = radians(u_angles[i]);
		vec2 offset = vec2(cos(radAngle), sin(radAngle)) * (u_radii[i] * 0.03);
		
		float alphaAlpha = flixel_texture2D(bitmap, uv - offset).a;
		if (alphaAlpha < 0.9) {
			float edgeGlow = smoothstep(0.9, u_fadeouts[i], alphaAlpha);
			vec3 mixedColor = mix(u_colors[i], u_colors2[i], u_gradients[i]);
			float aaFactor = smoothstep(0.0, fwidth(alphaAlpha), 0.9 - alphaAlpha);
			totalRimLight += mixedColor * u_brightnesses[i] * edgeGlow * aaFactor;
		}
	}
	
	color.rgb += totalRimLight * color.a;
	gl_FragColor = color;
}";

		var luaCode:String = "var timerTime = 0\n";
		luaCode += "function onCreatePost()\n";
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
			
			for(i in 0...points.length) {
				var pt = points[i];
				
				var h1 = pt.colorHex.trim(); if (h1.length != 6) h1 = "FFFFFF";
				var c1 = FlxColor.fromString("#" + h1);
				
				var h2 = pt.colorHex2.trim(); if (h2.length != 6) h2 = "FFFFFF";
				var c2 = FlxColor.fromString("#" + h2);
				
				luaCode += "    setShaderFloatArray('dad', 'u_centers[" + i + "]', {" + pt.x + ", " + pt.y + "})\n";
				luaCode += "    setShaderFloatArray('dad', 'u_colors[" + i + "]', {" + c1.redFloat + ", " + c1.greenFloat + ", " + c1.blueFloat + "})\n";
				luaCode += "    setShaderFloatArray('dad', 'u_colors2[" + i + "]', {" + c2.redFloat + ", " + c2.greenFloat + ", " + c2.blueFloat + "})\n";
				luaCode += "    setShaderFloat('dad', 'u_radii[" + i + "]', " + pt.radius + ")\n";
				luaCode += "    setShaderFloat('dad', 'u_brightnesses[" + i + "]', " + pt.brightness + ")\n";
				luaCode += "    setShaderFloat('dad', 'u_fadeouts[" + i + "]', " + pt.fadeout + ")\n";
				luaCode += "    setShaderFloat('dad', 'u_gradients[" + i + "]', " + pt.gradient + ")\n";
				luaCode += "    setShaderFloat('dad', 'u_angles[" + i + "]', " + pt.angle + ")\n";
			}
		}
		luaCode += "end\n\n";

		var hasPulse = false;
		for(p in points) if(p.isPulse) { hasPulse = true; break; }

		if (hasPulse) {
			luaCode += "function onUpdate(elapsed)\n";
			luaCode += "    timerTime = timerTime + (elapsed * 5.0)\n";
			luaCode += "    var pulseWave = 1.0 + (math.sin(timerTime) * 0.3)\n";
			for(i in 0...points.length) {
				if (points[i].isPulse) {
					luaCode += "    setShaderFloat('dad', 'u_brightnesses[" + i + "]', " + points[i].brightness + " * pulseWave)\n";
				}
			}
			luaCode += "end\n";
		}

		try {
			var exportPath = "./saves/shaders/";
			if (!FileSystem.exists(exportPath)) FileSystem.createDirectory(exportPath);

			File.saveContent(exportPath + sName + ".frag", fragCode);
			File.saveContent(exportPath + lName + ".lua", luaCode);
			
			if (successText != null) successText.text = "SAVED TO: SAVES/SHADERS/";
		} catch(e:Dynamic) {}
	}

	public function UIEvent(id:String, sender:Dynamic) {}
}