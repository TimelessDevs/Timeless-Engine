package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class TimelessConsole extends flixel.group.FlxSpriteGroup
{
	public var isActive:Bool = false;
	public var parentState:states.PlayState;
	
	private var consoleInput:String = "";
	private var consoleHistory:Array<String> = [
		"[SYSTEM]: Timeless Console initialized successfully.",
		"[SYSTEM]: Type 'help' to display the commands."
	];
	
	private var mainPanelBG:FlxSprite;
	private var decorativeGlowBar:FlxSprite;
	private var inputTextDisplay:FlxText;
	private var historyTextDisplay:FlxText;
	private var telemetryTextDisplay:FlxText;
	
	private var blinkTimer:Float = 0;
	private var tweenAnimation:FlxTween;

	public function new(parent:states.PlayState)
	{
		super();
		this.parentState = parent;
		this.scrollFactor.set();
		
		@:privateAccess
		if (parentState != null && parentState.camHUD != null) {
			this.cameras = [parentState.camHUD];
		}

		mainPanelBG = new FlxSprite(20, -320).makeGraphic(1240, 280, 0xFA0A0C14);
		mainPanelBG.scrollFactor.set();
		add(mainPanelBG);

		decorativeGlowBar = new FlxSprite(20, -40).makeGraphic(1240, 4, 0xFFBF55EC);
		decorativeGlowBar.scrollFactor.set();
		add(decorativeGlowBar);

		historyTextDisplay = new FlxText(45, -300, 880, "", 13);
		historyTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 13, 0xFFBF55EC, "left");
		historyTextDisplay.scrollFactor.set();
		add(historyTextDisplay);

		telemetryTextDisplay = new FlxText(940, -300, 300, "", 12);
		telemetryTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 12, 0xFFBF55EC, "right");
		telemetryTextDisplay.scrollFactor.set();
		add(telemetryTextDisplay);

		inputTextDisplay = new FlxText(45, -60, 1180, "TIMELESS_CORE@ROOT:~# ", 15);
		inputTextDisplay.setFormat(backend.Paths.font("vcr.ttf"), 15, 0xFFBF55EC, "left");
		inputTextDisplay.scrollFactor.set();
		add(inputTextDisplay);

		updateVisualComponentCoordinates(-320);
		this.visible = false;
	}

	public function toggleConsoleOverlayVisibility():Void
	{
		isActive = !isActive;

		if (tweenAnimation != null) tweenAnimation.cancel();
		this.visible = true;

		if (isActive) {
			if (parentState != null) {
				if (parentState.opponentVocals != null) parentState.opponentVocals.pause();
				if (parentState.vocals != null) parentState.vocals.pause();
			}
			if (flixel.FlxG.sound.music != null) flixel.FlxG.sound.music.pause();
		}

		var targetY:Float = isActive ? 0 : -320;

		tweenAnimation = FlxTween.tween(mainPanelBG, {y: targetY}, 0.55, {
			ease: FlxEase.elasticOut,
			onUpdate: function(twn:FlxTween) {
				updateVisualComponentCoordinates(mainPanelBG.y);
			},
			onComplete: function(twn:FlxTween) {
				if (!isActive) {
					this.visible = false;
					
					if (parentState != null && !parentState.paused) {
						if (parentState.opponentVocals != null) parentState.opponentVocals.play();
						if (parentState.vocals != null) parentState.vocals.play();
						if (flixel.FlxG.sound.music != null) flixel.FlxG.sound.music.play();
					}
				}
			}
		});

		if (isActive) refreshHistoryLogBuffer();
	}

	private function updateVisualComponentCoordinates(panelY:Float):Void
	{
		mainPanelBG.y = panelY;
		decorativeGlowBar.y = panelY + 276;
		historyTextDisplay.y = panelY + 15;
		telemetryTextDisplay.y = panelY + 15;
		inputTextDisplay.y = panelY + 245;
	}

	private function refreshHistoryLogBuffer():Void
	{
		var linesToDraw:Array<String> = consoleHistory.length > 13 ? consoleHistory.slice(consoleHistory.length - 13) : consoleHistory;
		if (historyTextDisplay != null) historyTextDisplay.text = linesToDraw.join("\n");
	}

	public function updateConsoleRuntimeLogic(elapsed:Float):Void
	{
		if (!isActive) return;

		blinkTimer += elapsed;
		var dynamicCursor:String = (Math.floor(blinkTimer * 3) % 2 == 0) ? "█" : " ";
		if (inputTextDisplay != null) {
			inputTextDisplay.text = "TIMELESS_CORE@ROOT:~# " + consoleInput + dynamicCursor;
		}

		if (telemetryTextDisplay != null && parentState != null) {
			#if cpp
			var memoryUsage:Float = cpp.vm.Gc.memInfo(0) / 1024 / 1024;
			@:privateAccess
			var currentAnim:String = (parentState.boyfriend != null && parentState.boyfriend.animation.curAnim != null) ? parentState.boyfriend.animation.curAnim.name : "NONE";
			telemetryTextDisplay.text = "ENGINE CONTEXT: PLAYSTATE\nRAM LOAD: " + FlxMath.roundDecimal(memoryUsage, 2) + " MB\nBF ANIM: " + currentAnim + "\nSONG POS: " + FlxMath.roundDecimal(FlxG.sound.music.time / 1000, 2) + "s\nACCURACY: " + FlxMath.roundDecimal(parentState.ratingPercent * 100, 2) + "%\nMISSES: " + parentState.songMisses;
			#else
			telemetryTextDisplay.text = "CORE SYSTEM: ONLINE\nWEB GRID STREAM: ACTIVE";
			#end
		}

		if (FlxG.keys.justPressed.ANY)
		{
			var keyCode:Int = FlxG.keys.firstJustPressed();
			
			if (FlxG.keys.justPressed.BACKSPACE && consoleInput.length > 0) {
				consoleInput = consoleInput.substring(0, consoleInput.length - 1);
			}
			else if (FlxG.keys.justPressed.ENTER && consoleInput.length > 0) {
				processTargetTerminalCommand(consoleInput);
				consoleInput = "";
				refreshHistoryLogBuffer();
			}
			else {
				var rawKey:String = flixel.input.keyboard.FlxKey.toStringMap.get(keyCode);
				if (rawKey != null) {
					if (rawKey == "SPACE") consoleInput += " ";
					else if (rawKey == "PERIOD" || rawKey == "NUMPADPERIOD") consoleInput += ".";
					else if (rawKey == "MINUS" || rawKey == "NUMPADMINUS") consoleInput += "-";
					else if (rawKey.startsWith("NUMPAD") && rawKey.length > 6) {
						consoleInput += rawKey.substring(6);
					}
					else if (rawKey.startsWith("DIGIT") && rawKey.length > 5) {
						consoleInput += rawKey.substring(5);
					}
					else if (rawKey.length == 1) {
						consoleInput += rawKey.toLowerCase();
					}
					
					blinkTimer = 0;
				}
			}
		}
	}

	private function processTargetTerminalCommand(rawInstruction:String):Void
	{
		consoleHistory.push("> " + rawInstruction);
		
		var commandTokens:Array<String> = rawInstruction.split(" ");
		var primaryCommand:String = commandTokens != null ? commandTokens[0].trim() : "";
		var val1:String = commandTokens.length > 1 && commandTokens[1] != null ? commandTokens[1].trim() : "";
		var val2:String = commandTokens.length > 2 && commandTokens[2] != null ? commandTokens[2].trim() : "";

		var parseState = function(currentValue:Bool, arg:String):Bool {
			var cleanArg = arg.toLowerCase().trim();
			if (cleanArg == "on" || cleanArg == "1" || cleanArg == "true" || cleanArg == "enable") return true;
			if (cleanArg == "off" || cleanArg == "0" || cleanArg == "false" || cleanArg == "disable") return false;
			return !currentValue;
		};

		try {
			switch (primaryCommand)
			{
				case "help":
					consoleHistory.push("Available command clusters:\n[STATS]: health, hpgain, hploss, score, misses, combo\n[MODIFIERS]: botplay, practice, ghost, nsd, speed, timescale\n[SYSTEM]: clear, skip, chart, mute, volume, exit, crash\n[VISUALS]: shader, bgalpha, bghide, bfflip, dadflip, camzoom");

				case "health" | "hp":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) parentState.health = FlxMath.bound(num, 0, 2);
					consoleHistory.push("[OK]: Health vector adjusted.");

				case "hpgain":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) @:privateAccess parentState.healthGain = num;
					consoleHistory.push("[OK]: HP gain scale modified.");

				case "hploss":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) @:privateAccess parentState.healthLoss = num;
					consoleHistory.push("[OK]: HP loss damage scaling overridden.");

				case "botplay" | "bot":
					parentState.cpuControlled = parseState(parentState.cpuControlled, val1);
					@:privateAccess if (parentState.botplayTxt != null) parentState.botplayTxt.visible = parentState.cpuControlled;
					consoleHistory.push("[OK]: Autopilot state: " + (parentState.cpuControlled ? "ENABLED" : "DISABLED"));

				case "practice":
					parentState.practiceMode = parseState(parentState.practiceMode, val1);
					consoleHistory.push("[OK]: Practice buffer safe mode: " + (parentState.practiceMode ? "ENABLED" : "DISABLED"));

				case "ghost" | "ghosttapping":
					backend.ClientPrefs.data.ghostTapping = parseState(backend.ClientPrefs.data.ghostTapping, val1);
					consoleHistory.push("[OK]: Ghost note tap processing: " + (backend.ClientPrefs.data.ghostTapping ? "ENABLED" : "DISABLED"));

				case "nsd" | "nosuddendeath":
					@:privateAccess parentState.healthLoss = 0;
					consoleHistory.push("[OK]: Sudden death locks dissolved safely.");

				case "score":
					var num = Std.parseInt(val1);
					if (!Math.isNaN(num)) { @:privateAccess parentState.songScore = num; parentState.updateScore(); }
					consoleHistory.push("[OK]: Dynamic tally score score overridden.");

				case "misses" | "miss":
					var num = Std.parseInt(val1);
					if (!Math.isNaN(num)) { parentState.songMisses = num; parentState.updateScore(); }
					consoleHistory.push("[OK]: Input registry misses set.");

				case "combo":
					var num = Std.parseInt(val1);
					if (!Math.isNaN(num)) { @:privateAccess parentState.combo = num; parentState.updateScore(); }
					consoleHistory.push("[OK]: Combo multiplier set to: " + num);

				case "scrollspeed" | "speed":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num) && num > 0) {
						@:privateAccess {
							parentState.songSpeed = num;
							for (note in parentState.unspawnNotes) if (note != null) Reflect.setField(note, "multSpeed", num);
							for (note in parentState.notes.members) if (note != null) Reflect.setField(note, "multSpeed", num);
						}
						consoleHistory.push("[OK]: Global note lane velocity locked at: " + num);
					}

				case "timescale":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num) && num > 0) {
						flixel.FlxG.timeScale = num;
						consoleHistory.push("[OK]: Timeline delta tick matrix scaled to: " + num + "x");
					}

				case "skip" | "time":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) {
						var targetTime:Float = num * 1000;
						if (targetTime < FlxG.sound.music.length) {
							FlxG.sound.music.time = targetTime;
							if (parentState.vocals != null) parentState.vocals.time = targetTime;
							consoleHistory.push("[OK]: Jumped target song timestamp to: " + num + "s");
						}
					}

				case "chart" | "editor":
					consoleHistory.push("[SYSTEM]: Instantly bootstrapping custom charting workspace grid...");
					isActive = false; this.visible = false;
					backend.MusicBeatState.switchState(new states.editors.ChartingState());

				case "mute":
					var target = val1.toLowerCase();
					if (target == "vocals" || target == "v") { if (parentState.vocals != null) parentState.vocals.volume = 0; }
					else if (target == "inst" || target == "i") { if (FlxG.sound.music != null) FlxG.sound.music.volume = 0; }
					consoleHistory.push("[OK]: Muted selected audio branch array: " + target);

				case "unmute":
					if (parentState.vocals != null) parentState.vocals.volume = 1;
					if (FlxG.sound.music != null) FlxG.sound.music.volume = 1;
					consoleHistory.push("[OK]: All audio channels restored to full scale.");

				case "volume":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) flixel.FlxG.sound.volume = FlxMath.bound(num, 0, 1);
					consoleHistory.push("[OK]: Hardware master volume level forced.");

				case "exit" | "quit":
					consoleHistory.push("[SYSTEM]: Halting game context. Tearing down arrays...");
					backend.MusicBeatState.switchState(new mikolka.vslice.ui.MainMenuState());

				case "crash":
					consoleHistory.push("[SYSTEM]: Forcefully triggering hard memory exception routine error...");
					throw new openfl.errors.Error("Forced debug command exception crash execution mapping.");

				case "shader":
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					var activeCamera:String = (val2 != "") ? val2 : "camGame";
					backend.ShaderDirector.loadShaderFromFile(val1, backend.Mods.currentModDirectory);
					backend.ShaderDirector.applyShaderToCamera(val1, activeCamera, parentState);
					consoleHistory.push("[OK]: Bound GLSL filter asset '" + val1 + "' over -> " + activeCamera);
					#end

				case "bgalpha" | "stagealpha":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) @:privateAccess {
						for (sprite in parentState.members) {
							if (sprite != parentState.boyfriendGroup && sprite != parentState.dadGroup && sprite != parentState.gfGroup && Std.isOfType(sprite, flixel.FlxSprite)) {
								cast(sprite, flixel.FlxSprite).alpha = FlxMath.bound(num, 0, 1);
							}
						}
					}
					consoleHistory.push("[OK]: Static layout visibility adjusted.");

				case "bghide":
					@:privateAccess {
						for (sprite in parentState.members) {
							if (sprite != parentState.boyfriendGroup && sprite != parentState.dadGroup && sprite != parentState.gfGroup && Std.isOfType(sprite, flixel.FlxSprite)) {
								cast(sprite, flixel.FlxSprite).visible = false;
							}
						}
					}
					consoleHistory.push("[OK]: Stage sprites unlinked from screen drawing thread.");

				case "bgshow":
					@:privateAccess {
						for (sprite in parentState.members) {
							if (sprite != parentState.boyfriendGroup && sprite != parentState.dadGroup && sprite != parentState.gfGroup && Std.isOfType(sprite, flixel.FlxSprite)) {
								cast(sprite, flixel.FlxSprite).visible = true;
							}
						}
					}
					consoleHistory.push("[OK]: Stage rendering visibility layers restored.");

				case "bfflip":
					if (parentState.boyfriend != null) parentState.boyfriend.flipX = !parentState.boyfriend.flipX;
					consoleHistory.push("[OK]: Boyfriend horizontal orientation flipped.");

				case "dadflip":
					if (parentState.dad != null) parentState.dad.flipX = !parentState.dad.flipX;
					consoleHistory.push("[OK]: Opponent horizontal orientation flipped.");

				case "camzoom":
					var num = Std.parseFloat(val1);
					if (!Math.isNaN(num)) parentState.defaultCamZoom = num;
					consoleHistory.push("[OK]: Target camera focal view scale frame locked.");

				case "hudhide":
					if (parentState.camHUD != null) parentState.camHUD.visible = false;
					consoleHistory.push("[OK]: HUD display layer drawing task halted.");

				case "hudshow":
					if (parentState.camHUD != null) parentState.camHUD.visible = true;
					consoleHistory.push("[OK]: HUD display layer drawing task resumed.");

				case "downscroll":
					backend.ClientPrefs.data.downScroll = parseState(backend.ClientPrefs.data.downScroll, val1);
					consoleHistory.push("[OK]: DownScroll layout configuration: " + (backend.ClientPrefs.data.downScroll ? "ENABLED" : "DISABLED"));

				case "middlescroll":
					backend.ClientPrefs.data.middleScroll = parseState(backend.ClientPrefs.data.middleScroll, val1);
					consoleHistory.push("[OK]: MiddleScroll lane centralization: " + (backend.ClientPrefs.data.middleScroll ? "ENABLED" : "DISABLED"));

				case "script":
					if (parentState != null) {
						var codeStr:String = rawInstruction.substring(7);
						@:privateAccess parentState.runLuaCode(codeStr);
						consoleHistory.push("[OK]: String payload transferred down to script interpreter layer execution.");
					}

				case "clear":
					consoleHistory = ["[SYSTEM]: Log history buffer cleared."];

				default:
					consoleHistory.push("[ERROR]: Unrecognized instruction identifier '" + primaryCommand + "'. Type 'help'.");
			}
		} catch(e:Dynamic) {
			consoleHistory.push("[CRASH]: Operation layout execution crash -> " + Std.string(e));
		}
	}
}