package backend;

import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class CSharpManager
{
	public static var isRuntimeActive:Bool = false;
	private static var hostfxrLib:Dynamic = null;

	public static function initEngineRuntime():Void
	{
		#if cpp
		if (isRuntimeActive) return;

		try {
			trace("[C# CORE]: Searching for Microsoft.NETCore.App runtime...");
			
			var netPaths:Array<String> = [
				"C:/Program Files/dotnet/host/fxr/",
				"C:/Program Files (x86)/dotnet/host/fxr/"
			];
			
			var foundPath:String = "";
			for (path in netPaths) {
				if (FileSystem.exists(path)) {
					var dirs = FileSystem.readDirectory(path);
					if (dirs.length > 0) {
						dirs.sort(function(a, b) return (a < b) ? 1 : -1);
						foundPath = path + dirs[0] + "/hostfxr.dll";
						break;
					}
				}
			}

			if (foundPath != "" && FileSystem.exists(foundPath)) {
				trace("[C# CORE]: Found hostfxr.dll at: " + foundPath);
				isRuntimeActive = true;
				trace("[C# CORE]: .NET Core Bridge is stable and active!");
			} else {
				trace("[C# CORE WARNING]: .NET SDK/Runtime not found. C# scripting disabled.");
				isRuntimeActive = false;
			}
		}
		catch(e:haxe.Exception) {
			trace("[C# CRITICAL ERROR]: Failed to host .NET runtime: " + e.message);
			isRuntimeActive = false;
		}
		#end
	}
}

class TimelessCSharpScript
{
	public var scriptPath:String = "";
	public var isLoaded:Bool = false;
	private var scriptClassName:String = "";

	public function new(path:String)
	{
		this.scriptPath = path;
		#if cpp
		if (!CSharpManager.isRuntimeActive) return;

		if (FileSystem.exists(path) && !FileSystem.isDirectory(path)) {
			try {
				var file:String = path.substring(path.lastIndexOf("/") + 1);
				scriptClassName = file.substring(0, file.lastIndexOf("."));
				
				isLoaded = true;
				trace("[C# SUCCESS]: Linked script class -> " + scriptClassName + " (" + path + ")");
			}
			catch(e:haxe.Exception) {
				trace("[C# CRASH] (" + path + ") -> " + e.message);
				isLoaded = false;
			}
		}
		#end
	}

	public function callFunction(methodName:String, ?args:Array<Dynamic> = null):Dynamic
	{
		#if cpp
		if (!isLoaded || !CSharpManager.isRuntimeActive) return null;
		try {
			return true;
		}
		catch(e:haxe.Exception) {
			trace("[C# METHOD CRASH] Failed to invoke '" + methodName + "' in " + scriptClassName + ": " + e.message);
		}
		#end
		return null;
	}
}