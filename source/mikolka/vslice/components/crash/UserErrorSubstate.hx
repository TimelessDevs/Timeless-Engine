package mikolka.vslice.components.crash;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.ui.title.TitleState;
import mikolka.compatibility.ModsHelper;
import haxe.CallStack.StackItem;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class UserErrorSubstate extends MusicBeatSubstate
{
	var error:CrashData;
	var isCritical:Bool;
	var allowClosing:Bool = false;
	var camOverlay:FlxCamera;

	var panelBg:FlxSprite;
	var titleText:FlxText;
	var errorText:FlxText;
	var hintText:FlxText;

	public static function makeMessage(errorMessage:String, description:String)
	{
		var state = FlxG.state;
		while (state.subState != null)
			state = state.subState;
		state.persistentUpdate = false;
		state.openSubState(new UserErrorSubstate(UserErrorSubstate.collectMessageData(errorMessage, description)));
	}

	public static function makeError(error:CrashData, isCritical:Bool = false)
	{
		var state = FlxG.state;
		while (state.subState != null)
			state = state.subState;
		state.persistentUpdate = false;
		state.openSubState(new UserErrorSubstate(error, isCritical));
	}

	public function new(error:CrashData, isCritical:Bool = false)
	{
		this.error = error;
		this.isCritical = isCritical;
		camOverlay = new FlxCamera();
		camOverlay.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camOverlay, false);
		super();
	}

	override function create()
	{
		super.create();
		_parentState.persistentUpdate = false;

		panelBg = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.85), Std.int(FlxG.height * 0.75), 0xEA16161F);
		panelBg.screenCenter();
		panelBg.alpha = 0;
		panelBg.scale.set(0.9, 0.9);
		panelBg.camera = camOverlay;
		add(panelBg);

		titleText = new FlxText(panelBg.x + 40, panelBg.y + 30, panelBg.width - 80, isCritical ? "CRASH" : "SYSTEM WARNING", 38);
		titleText.setFormat(Paths.font("vcr.ttf"), 38, isCritical ? 0xFFFF4444 : 0xFFFFCC44, LEFT);
		titleText.bold = true;
		titleText.alpha = 0;
		titleText.camera = camOverlay;
		add(titleText);

		var traceLines:String = "";
		if (error.extendedTrace != null && error.extendedTrace.length > 0)
		{
			var limit = Math.min(error.extendedTrace.length, 6);
			for (i in 0...Std.int(limit))
				traceLines += "\n" + error.extendedTrace[i];
		}
		else if (error.trace != null)
		{
			var limit = Math.min(error.trace.length, 6);
			for (i in 0...Std.int(limit))
				traceLines += "\n" + error.trace[i].join(" ");
		}

		var displayInfo = "Message: " + error.message + "\n\nStack Trace:" + (traceLines != "" ? traceLines : "\nNo trace available.") + 
			"\n\nActive Mod: " + error.activeMod + " | Platform: " + error.systemName + "\n" + getLogger();

		errorText = new FlxText(panelBg.x + 40, titleText.y + 70, panelBg.width - 80, displayInfo, 18);
		errorText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFE0E0E6, LEFT);
		errorText.alpha = 0;
		errorText.camera = camOverlay;
		add(errorText);

		var actionKey:String = controls.mobileC ? "TAP ANYWHERE" : (isCritical ? "ENTER" : "ENTER");
		var actionDesc:String = isCritical ? "to restart the game" : "to continue";
		var hintMsg:String = "Press " + actionKey + " " + actionDesc + ".";
		#if (sys && !mobile)
		if (isCritical) hintMsg += " Press BACKSPACE to exit.";
		#end

		hintText = new FlxText(panelBg.x + 40, panelBg.y + panelBg.height - 50, panelBg.width - 80, hintMsg, 16);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF888899, LEFT);
		hintText.alpha = 0;
		hintText.camera = camOverlay;
		add(hintText);

		FlxTween.tween(panelBg, {alpha: 1, "scale.x": 1.0, "scale.y": 1.0}, 0.4, {
			ease: FlxEase.backOut,
			onComplete: function(_) {
				FlxTween.tween(titleText, {alpha: 1}, 0.15);
				FlxTween.tween(errorText, {alpha: 1}, 0.2);
				FlxTween.tween(hintText, {alpha: 1}, 0.25);
				allowClosing = true;
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!allowClosing) return;

		if (TouchUtil.justPressed || controls.ACCEPT)
		{
			FlxG.cameras.remove(camOverlay);
			if (!isCritical)
			{
				_parentState.persistentUpdate = true;
				close();
				return;
			}
			TitleState.initialized = false;
			ScreenshotPlugin.instance.destroy();
			ScreenshotPlugin.instance = null;
			TitleState.closedState = false;
			
			if (Main.debugDisplay != null)
				Main.debugDisplay.visible = #if LEGACY_PSYCH ClientPrefs.showFPS #else ClientPrefs.data.showFPS #end;

			FlxG.sound.pause();
			FlxTween.globalManager.clear();
			FlxG.resetGame();
		}
		#if sys
		else if (controls.BACK && isCritical)
		{
			Sys.exit(1);
		}
		#end
	}

	public static function collectErrorData(errorMessage:String, callStack:Array<StackItem>):CrashData
	{
		var errMsg = new Array<Array<String>>();
		var errExtended = new Array<String>();
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, pos_line, column):
					var line = new Array<String>();
					switch (s)
					{
						case Module(m): line.push("MD:" + m);
						case CFunction: line.push("Native function");
						case Method(classname, method):
							var regex = ~/(([A-Z]+[A-z]*)\.?)+/g;
							regex.match(classname);
							line.push("CLS:" + regex.matched(0) + ":" + method + "()");
						default:
					}
					line.push("Line:" + pos_line);
					errMsg.push(line);
					errExtended.push('In file ${file}: ${line.join("  ")}');
				default:
			}
		}
		return {
			logToFile: true,
			message: errorMessage,
			trace: errMsg,
			extendedTrace: errExtended,
			date: Date.now().toString(),
			systemName: getPlatform(),
			activeMod: ModsHelper.getActiveMod()
		}
	}

	public static function collectMessageData(errorMessage:String, description:String):CrashData
	{
		var tbl = new Array<Array<String>>();
		for (x in description.split("\n"))
		{
			tbl.push([x]);
		}
		return {
			logToFile: false,
			extendedTrace: [],
			trace: tbl,
			message: errorMessage,
			date: Date.now().toString(),
			systemName: getPlatform(),
			activeMod: ModsHelper.getActiveMod()
		};
	}

	public inline static function getPlatform():String
	{
		return #if android 'Android' #elseif linux 'Linux' #elseif mac 'macOS' #elseif ios 'iOS' #elseif windows 'Windows' #elseif html5 FlxG.html5.platform.getName() + '(${FlxG.html5.browser.getName()})' #else 'Unknown' #end;
	}

	public inline static function getLogger():String
	{
		return switch(VsliceOptions.LOGGING){
			case "File": "Logs available in the 'latest.log' file";
			case "Console": "Check the console for logs";
			case "None": "Logs disabled!";
			default: "Is the logger corrupted???";
		}
	}
}

typedef CrashData =
{
	logToFile:Bool,
	message:String,
	trace:Array<Array<String>>,
	extendedTrace:Array<String>,
	date:String,
	systemName:String,
	activeMod:String
}