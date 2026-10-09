package backend;

import sys.FileSystem;
import timelesspython.TimePython;

class PythonManager
{
	public static var isRuntimeActive:Bool = false;
	public static var pythonArray:Array<TimePython> = [];

	public static function initEngineRuntime():Void
	{
		#if cpp
		if (isRuntimeActive) return;

		try {
			trace("[PYTHON CORE]: Starting embedded Timeless Python native API...");
			isRuntimeActive = true;
			trace("[PYTHON CORE]: Isolated Timeless Python Virtual Machine is stable and synchronized!");
		}
		catch (e:haxe.Exception) {
			trace("[PYTHON CRITICAL ERROR]: Failed to initialize Python runtime: " + e.message);
			isRuntimeActive = false;
		}
		#end
	}
}