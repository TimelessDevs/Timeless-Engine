package timelesspython;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions
{
    public static function implement(pyFunk:TimePython)
    {
        var py = pyFunk;
        pyFunk.addLocalCallback("initPyShader", function(name:String){
            if(!ClientPrefs.data.shaders) return false;

            #if(!flash && MODS_ALLOWED && sys)
            return pyFunk.initPyShader(name);
            #else
            TimePython.pythonTrace("initPyShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
            #end
            return false;
        });
        pyFunk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			if(!pyFunk.runtimeShaders.exists(shader) && !pyFunk.initPyShader(shader))
			{
				TimePython.pythonTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = PyUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = PyUtils.getVarInArray(PyUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = pyFunk.runtimeShaders.get(shader);
				leObj.shader = new shaders.ErrorHandlerShader.ErrorHandledRuntimeShader(shader, arr[0], arr[1]);
				return true;
			}
			#else
			TimePython.pythonTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
        py.set("removeSpriteShader", function(obj:String) {
            var split:Array<String> = obj.split('.');
            var leObj:FlxSprite = PyUtils.getObjectDirectly(split[0]);
            if(split.length > 1) {
                leObj = PyUtils.getVarInArray(PyUtils.getPropertyLoop(split), split[split.length-1]);
            }
            if (leObj != null) {
                leObj.shader = null;
                return true;
            }
            return false;
        });
        py.set("getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				TimePython.pythonTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			TimePython.pythonTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
        });
        py.set("finalGetShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				TimePython.pythonTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return haxe.Json.stringify(shader.getBoolArray(prop));
			#else
			TimePython.pythonTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		TimePython.addPyCode(pyFunk, "
import json
def getShaderBoolArray(obj, prop):
	try:
		return json.loads(finalGetShaderBoolArray(obj, prop))
	except Exception: 
		return None
get_shader_bool_list = getShaderBoolArray
get_shader_bool_array = getShaderBoolArray
");
        py.set("getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				TimePython.pythonTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			TimePython.pythonTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
        py.set("finalGetShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
		        TimePython.pythonTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			TimePython.pythonTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		TimePython.addPyCode(pyFunk,"
import json
def getShaderIntArray(obj, prop):
	try:
		return json.loads(finalGetShaderIntArray(obj, prop))
	except Exception:
		return None
get_shader_int_list = getShaderIntArray
get_shader_int_array = getShaderIntArray

");
        py.set("getShaderFloat", function(obj:String, prop:String) {
            #if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				TimePython.pythonTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			TimePython.pythonTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
        });
        py.set("finalGetShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				TimePython.pythonTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return haxe.Json.stringify(shader.getFloatArray(prop));
			#else
			TimePython.pythonTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		TimePython.addPyCode(pyFunk, "
import json
def getShaderFloatArray(obj, prop):
	try:
		return json.loads(finalGetShaderFloatArray(obj, prop))
	except Exception:
		return None
get_shader_float_list = getShaderFloatArray
get_shader_float_array = getShaderFloatArray
");
        py.set("setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			TimePython.pythonTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
        py.set("finalSetShaderBoolArray", function(obj:String, prop:String, valuesJson:String) {
			var values:Dynamic = haxe.Json.parse(valuesJson);
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			TimePython.pythonTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		TimePython.addPyCode(pyFunk, "
import json
def setShaderBoolArray(obj, prop, values):
	finalSetShaderBoolArray(obj, prop, json.dumps(values))
set_shader_bool_list = setShaderBoolArray
set_shader_bool_array = setShaderBoolArray
");
        py.set("setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			TimePython.pythonTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
        py.set("finalSetShaderIntArray", function(obj:String, prop:String, valuesJson:String) {
			var values:Dynamic = haxe.Json.parse(valuesJson);
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			TimePython.pythonTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		TimePython.addPyCode(pyFunk, "
import json
def setShaderIntArray(obj, prop, values):
	finalSetShaderIntArray(obj, prop, json.dumps(values))
set_shader_int_list = setShaderIntArray
set_shader_int_array = setShaderIntArray
");
        py.set("setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			TimePython.pythonTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
        py.set("finalSetShaderFloatArray", function(obj:String, prop:String, valuesJson:String) {
			var values:Dynamic = haxe.Json.parse(valuesJson);
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			TimePython.pythonTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});
		TimePython.addPyCode(pyFunk, "
import json
def setShaderFloatArray(obj, prop, values):
	finalSetShaderFloatArray(obj, prop, values)
set_shader_float_array = setShaderFloatArray
set_shader_float_list = setShaderFloatArray
");
        py.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				TimePython.pythonTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			TimePython.pythonTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
    }
    #if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if(split.length > 1) target = PyUtils.getVarInArray(PyUtils.getPropertyLoop(split), split[split.length-1]);
		else target = PyUtils.getObjectDirectly(split[0]);

		if(target == null)
		{
			TimePython.pythonTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast (target.shader, FlxRuntimeShader);
	}
	#end
}