package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import psychhx.HScript;
import sys.FileSystem;
import sys.io.File;

class ShadersState extends backend.MusicBeatState
{
	public var attachedScript:String;
	public var hscript:HScript = null;
	
	#if LUA_ALLOWED
	public var luaArray:Array<psychlua.FunkinLua> = [];
	#end

	public var sandboxShaders:Map<String, FlxRuntimeShader> = new Map();
	public var spriteFilters:Map<String, Array<ShaderFilter>> = new Map();
	
	public var boyfriend:flixel.FlxSprite = null;
	public var dad:flixel.FlxSprite = null;
	public var gf:flixel.FlxSprite = null;
	public var customSprites:Map<String, flixel.FlxSprite> = new Map();

	public function new(attachedScript:String)
	{
		super();
		this.attachedScript = attachedScript;
	}

	override function create()
	{
		boyfriend = new flixel.FlxSprite(770, 450);
		dad = new flixel.FlxSprite(100, 100);
		gf = new flixel.FlxSprite(400, 130);

		loadSandboxScriptsPipeline();

		super.create();
	}
	
	private function loadSandboxScriptsPipeline():Void
	{
		var baseFolder:String = 'mods/' + Mods.currentModDirectory + '/states/';
		
		// Target execution paths for Hx text layouts and compiled bytecode frameworks (.hxc)
		var hxPath:String = baseFolder + attachedScript + '.hx';
		var hxcPath:String = baseFolder + attachedScript + '.hxc';
		
		var activePath:String = FileSystem.exists(hxPath) ? hxPath : (FileSystem.exists(hxcPath) ? hxcPath : "");
		
		if (activePath != "") 
		{
			try {
				hscript = new HScript(null, activePath);
				injectSandboxAPI(hscript.variables);
				if (hscript.exists("onCreate")) hscript.call("onCreate");
				trace("[SANDBOX HAXE]: Bound script environment framework successfully.");
			} catch(e:Dynamic) {
				trace("[SANDBOX HAXE ERROR]: Compilation engine failure: " + e);
			}
		}

		#if LUA_ALLOWED
		var luaPath:String = baseFolder + attachedScript + '.lua';
		if (FileSystem.exists(luaPath)) 
		{
			try {
				var luaScript = new psychlua.FunkinLua(luaPath);
				injectLuaCallbacks(luaScript);
				luaArray.push(luaScript);
				luaScript.call("onCreate", []);
				trace("[SANDBOX LUA]: Connected standalone script frame wrapper.");
			} catch(e:Dynamic) {
				trace("[SANDBOX LUA ERROR]: Lua VM mapping crash: " + e);
			}
		}
		#end
	}

	private function injectSandboxAPI(map:Map<String, Dynamic>):Void
	{
		map.set("compileShader", compileShader);
		map.set("compileShaderFromSource", compileShaderFromSource);
		map.set("attachShaderToTarget", attachShaderToTarget);
		map.set("removeShaderFromTarget", removeShaderFromTarget);
		map.set("createSandboxSprite", createSandboxSprite);
		map.set("setShaderFloat", setShaderFloat);
		map.set("setShaderInt", setShaderInt);
		map.set("add", add);
		map.set("remove", remove);
		map.set("FlxG", flixel.FlxG);
		map.set("Paths", backend.Paths);
		map.set("boyfriend", boyfriend);
		map.set("dad", dad);
		map.set("gf", gf);
		map.set("this", this);
		map.set("exitToMainMenu", function() {
			flixel.FlxG.sound.play(backend.Paths.sound('cancelMenu'));
			backend.MusicBeatState.switchState(new states.MainMenuState());
		});
	}

	#if LUA_ALLOWED
	private function injectLuaCallbacks(lua:psychlua.FunkinLua):Void
	{
		llua.Lua_helper.add_callback(lua.lua, "compileShader", compileShader);
		llua.Lua_helper.add_callback(lua.lua, "attachShaderToTarget", attachShaderToTarget);
		llua.Lua_helper.add_callback(lua.lua, "setShaderFloat", setShaderFloat);
	}
	#end

	public function compileShader(shaderKey:String, fileName:String):Bool
	{
		if (sandboxShaders.exists(shaderKey)) return true;
		var path:String = 'mods/' + Mods.currentModDirectory + '/shaders/' + fileName + '.frag';
		if (!FileSystem.exists(path)) path = 'assets/shaders/' + fileName + '.frag';

		if (FileSystem.exists(path)) {
			return compileShaderFromSource(shaderKey, File.getContent(path));
		}
		return false;
	}

	public function compileShaderFromSource(shaderKey:String, glslSource:String):Bool
	{
		if (sandboxShaders.exists(shaderKey)) return true;
		try {
			var shader = new FlxRuntimeShader(glslSource, null);
			shader.setFloat("iTime", 0.0);
			sandboxShaders.set(shaderKey, shader);
			return true;
		} catch(e:Dynamic) {
			trace("[SANDBOX SOURCE ERROR]: Direct GLSL compile crash: " + e);
		}
		return false;
	}

	public function createSandboxSprite(tag:String, imageAsset:String, x:Float, y:Float):Void
	{
		var sprite = new flixel.FlxSprite(x, y).loadGraphic(backend.Paths.image(imageAsset));
		add(sprite);
		customSprites.set(tag, sprite);
	}

	public function attachShaderToTarget(shaderKey:String, targetName:String):Void
	{
		var shader = sandboxShaders.get(shaderKey);
		if (shader == null) return;

		var targetObj:flixel.FlxSprite = null;

		// Map structural target identifiers safely
		if (targetName.toLowerCase() == "bf" || targetName.toLowerCase() == "boyfriend") targetObj = boyfriend;
		else if (targetName.toLowerCase() == "dad" || targetName.toLowerCase() == "opponent") targetObj = dad;
		else if (targetName.toLowerCase() == "gf") targetObj = gf;
		else if (customSprites.exists(targetName)) targetObj = customSprites.get(targetName);

		if (targetObj == null) {
			var targetCam = Reflect.field(this, targetName);
			if (targetCam == null) targetCam = FlxG.camera;
			if (targetCam != null) {
				var filter = new ShaderFilter(shader);
				if (targetCam.filters == null) targetCam.filters = [];
				targetCam.filters.push(filter);
			}
			return;
		}

		var filter = new ShaderFilter(shader);
		var filterArray = targetObj.shader != null ? [filter] : [filter]; 
		
		@:privateAccess
		if (targetObj.sprite != null || true) {
			var targetSprite:Dynamic = targetObj;
			if (targetSprite.filters == null) targetSprite.filters = [];
			targetSprite.filters.push(filter);
		}
		
		if (!spriteFilters.exists(targetName)) spriteFilters.set(targetName, []);
		spriteFilters.get(targetName).push(filter);
	}

	public function removeShaderFromTarget(shaderKey:String, targetName:String):Void
	{
	}

	public function setShaderFloat(shaderKey:String, variable:String, value:Float):Void
	{
		var shader = sandboxShaders.get(shaderKey);
		if (shader != null) shader.setFloat(variable, value);
	}

	public function setShaderInt(shaderKey:String, variable:String, value:Int):Void
	{
		var shader = sandboxShaders.get(shaderKey);
		if (shader != null) shader.setInt(variable, value);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		@:privateAccess
		var globalTime:Float = FlxG.sound.music != null ? FlxG.sound.music.time / 1000 : 0.0;
		for (shader in sandboxShaders) {
			if (shader != null) {
				try { shader.setFloat("iTime", globalTime); } catch(e:Dynamic) {}
			}
		}

		if (hscript != null && hscript.exists("onUpdate")) hscript.call("onUpdate", [elapsed]);
		
		#if LUA_ALLOWED
		for (lua in luaArray) {
			if (lua != null) lua.call("onUpdate", [elapsed]);
		}
		#end

		if (FlxG.keys.justPressed.ESCAPE) {
			flixel.FlxG.sound.play(backend.Paths.sound('cancelMenu'));
			backend.MusicBeatState.switchState(new states.MainMenuState());
		}
	}

	override function destroy()
	{
		if (hscript != null) hscript.destroy();
		#if LUA_ALLOWED
		for (lua in luaArray) if (lua != null) lua.stop();
		#end
		sandboxShaders.clear();
		spriteFilters.clear();
		customSprites.clear();
		super.destroy();
	}
}