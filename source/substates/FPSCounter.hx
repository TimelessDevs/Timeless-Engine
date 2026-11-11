package substates;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;

#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;

	public var memoryMegas(get, never):Float;

	static inline final RING_SIZE:Int = 4096;
	static inline final RING_MASK:Int = RING_SIZE - 1;
	@:noCompletion private var times:haxe.ds.Vector<Float>;
	@:noCompletion private var ringHead:Int = 0;
	@:noCompletion private var ringTail:Int = 0;
	@:noCompletion private var ringCount:Int = 0;

	@:noCompletion private var _memText:String = '';
	@:noCompletion private var _memTimer:Float = 1000.0;
	@:noCompletion private var _lastText:String = null;
	@:noCompletion private var _lastRed:Bool = false;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		#if !officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";

		times = new haxe.ds.Vector<Float>(RING_SIZE);
	}

	var deltaTimeout:Float = 0.0;

	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times[ringHead] = now;
		ringHead = (ringHead + 1) & RING_MASK;
		if (ringCount < RING_SIZE)
			ringCount++;
		else
			ringTail = (ringTail + 1) & RING_MASK;
		final limit:Float = now - 1000;
		while (ringCount > 0 && times[ringTail] < limit)
		{
			ringTail = (ringTail + 1) & RING_MASK;
			ringCount--;
		}

		deltaTimeout += deltaTime;
		_memTimer += deltaTime;
		if (deltaTimeout < 100)
			return;
		deltaTimeout = 0.0;

		if (!visible)
			return;

		currentFPS = ringCount < FlxG.updateFramerate ? ringCount : FlxG.updateFramerate;
		updateText();
	}

	public dynamic function updateText():Void
	{
		if (_memTimer >= 500)
		{
			_memTimer = 0;
			_memText = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
		}

		final newText:String = 'FPS: $currentFPS' + '\nMemory: $_memText' + os;
		final red:Bool = currentFPS < FlxG.drawFramerate * 0.5;
		final changed:Bool = newText != _lastText;
		if (changed)
		{
			_lastText = newText;
			text = newText;
		}
		if (changed || red != _lastRed)
		{
			_lastRed = red;
			textColor = red ? 0xFFFF0000 : 0xFFFFFFFF;
		}
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}