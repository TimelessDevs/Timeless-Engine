package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import psychhx.HScript; // Подключаем твою текущую обертку hscript-improved
import sys.FileSystem;
import sys.io.File;

class ScriptState extends backend.MusicBeatState
{
	public var scriptName:String;
	public var hscript:HScript = null;

	public function new(scriptName:String)
	{
		super();
		this.scriptName = scriptName;
	}

	override function create()
	{
		// Ищем кастомный Haxe-экран в папке скриптов мода
		var path:String = 'mods/' + Mods.currentModDirectory + '/states/' + scriptName + '.hx';
		if (!FileSystem.exists(path)) {
			path = 'assets/states/' + scriptName + '.hx';
		}

		if (FileSystem.exists(path))
		{
			try {
				hscript = new HScript(null, path);
				
				// Прокидываем базовые утилиты, чтобы мододел мог рисовать интерфейсы
				hscript.set("add", add);
				hscript.set("remove", remove);
				hscript.set("FlxG", flixel.FlxG);
				hscript.set("FlxSprite", flixel.FlxSprite);
				hscript.set("FlxText", flixel.text.FlxText);
				hscript.set("FlxColor", flixel.util.FlxColor);
				hscript.set("Paths", backend.Paths);
				hscript.set("this", this);
				
				// Позволяем возвращаться в стандартное Главное Меню одной командой
				hscript.set("goBackToMainMenu", function() {
					backend.MusicBeatState.switchState(new states.MainMenuState());
				});

				if (hscript.exists("onCreate")) {
					hscript.call("onCreate");
				}
				trace("[SCRIPT STATE]: Successfully initialized custom state screen -> " + scriptName);
			} catch(e:Dynamic) {
				trace("[SCRIPT STATE CRASH]: Failed to parse custom state: " + e);
				backend.MusicBeatState.switchState(new states.MainMenuState()); // Безопасный фоллбэк при ошибках
			}
		} else {
			trace("[SCRIPT STATE ERROR]: Hx script state file not found at " + path);
			backend.MusicBeatState.switchState(new states.MainMenuState());
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// Позволяем скрипту обрабатывать покадровые обновления и ввод с клавиатуры/мыши
		if (hscript != null && hscript.exists("onUpdate")) {
			hscript.call("onUpdate", [elapsed]);
		}
	}

	override function destroy()
	{
		if (hscript != null) {
			hscript.destroy();
		}
		super.destroy();
	}
}