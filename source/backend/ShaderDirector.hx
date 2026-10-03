package backend;

import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import sys.FileSystem;
import sys.io.File;

class ShaderDirector
{
	public static var activeShaders:Map<String, FlxRuntimeShader> = new Map();

	public static function loadShaderFromSource(name:String, glslContent:String):FlxRuntimeShader
	{
		if (activeShaders.exists(name)) return activeShaders.get(name);

		try {
			var shader = new FlxRuntimeShader(glslContent, null);
			activeShaders.set(name, shader);
			return shader;
		} catch(e:Dynamic) {
			trace("[SHADERS ERROR]: Failed to compile runtime shader -> " + name + ": " + e);
			return null;
		}
	}

	public static function loadShaderFromFile(name:String, modFolder:String):FlxRuntimeShader
	{
		if (activeShaders.exists(name)) return activeShaders.get(name);

		var path:String = 'mods/' + modFolder + '/shaders/' + name + '.frag';
		if (!FileSystem.exists(path)) {
			path = 'assets/shaders/' + name + '.frag';
		}

		if (FileSystem.exists(path)) {
			var code:String = File.getContent(path);
			return loadShaderFromSource(name, code);
		}
		
		trace("[SHADERS WARNING]: Shader file not found -> " + name);
		return null;
	}

	public static function applyShaderToCamera(shaderName:String, cameraName:String, gameInstance:Dynamic)
	{
		var shader = activeShaders.get(shaderName);
		if (shader == null) return;

		var targetCam = Reflect.field(gameInstance, cameraName);
		if (targetCam != null) {
			var filter = new ShaderFilter(shader);
			if (targetCam.filters == null) targetCam.filters = [];
			targetCam.filters.push(filter);
		}
	}
}