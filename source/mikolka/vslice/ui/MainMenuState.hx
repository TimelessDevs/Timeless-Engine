package mikolka.vslice.ui;

import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.ui.title.TitleState;
import mikolka.compatibility.ModsHelper;
import options.OptionsState;

using StringTools;

typedef MenuLayoutData = {
	var items:Array<MenuItemProps>;
	var globalScale:Float;
	var backgroundAlpha:Float;
}

typedef MenuItemProps = {
	var name:String;
	var x:Float;
	var y:Float;
	var scaleX:Float;
	var scaleY:Float;
}

class MainMenuState extends MusicBeatState
{
	public var cheatBuffer:String = "";

	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '0.0.4';
	#else
	public static var psychEngineVersion:String = '0.0.4';
	#end
	public static var pSliceVersion:String = '0.0.4';
	public static var funkinVersion:String = '0.7.6';

	var bg:FlxSprite;
	var magenta:FlxSprite;

	var stickerSubState:Bool;

	public static var currentMenuMusic:String = '';

	public function new(?stickers:Bool = false)
	{
		super();
		stickerSubState = stickers;
	}

	private function loadTimelessMenuLayout():MenuLayoutData
	{
		// Перестроено под жесткую иерархию папок menulayouts
		var pathsToScan:Array<String> = [
			'assets/shared/menulayouts/menu_layout.json',
			'mods/' + backend.Mods.currentModDirectory + '/menulayouts/menu_layout.json'
		];

		var validPath:String = "";
		for (path in pathsToScan) {
			if (sys.FileSystem.exists(path)) {
				validPath = path;
				break;
			}
		}

		if (validPath != "") {
			try {
				var content:String = sys.io.File.getContent(validPath);
				var parsedData:MenuLayoutData = haxe.Json.parse(content);
				trace("[LAYOUT SUCCESS]: Loaded matrix path -> " + validPath);
				return parsedData;
			} catch(e:Dynamic) {
				trace("[LAYOUT CRASH]: Path structural metadata error: " + validPath + " -> " + Std.string(e));
			}
		}

		return null;
	}

	override function create()
	{
		if(stickerSubState) ModsHelper.clearStoredWithoutStickers();
		else CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();
		#if (debug && !LEGACY_PSYCH)
		FlxG.console.registerFunction("dumpCache",CacheSystem.cacheStatus); 
		FlxG.console.registerFunction("dumpSystem",backend.Native.buildSystemInfo);
		#end
		
		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Main Menu", null);
		#end

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80);
		if (backend.ClientPrefs.data.timelessMenuBG) {
				bg.loadGraphic(Paths.image('TimelessBG'));
		} else {
				bg.loadGraphic(Paths.image('menuBG'));
		}
		bg.antialiasing = VsliceOptions.ANTIALIASING;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80);
		if (backend.ClientPrefs.data.timelessMenuBG) {
				magenta.loadGraphic(Paths.image('TimelessBG'));
		} else {
				magenta.loadGraphic(Paths.image('menuDesat'));
		}
		magenta.antialiasing = VsliceOptions.ANTIALIASING;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFFD719B;
		add(magenta);

		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "Timeless Engine " + psychEngineVersion, 12);
		var fnfVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'v${funkinVersion} (V-slice ${pSliceVersion})', 12);

		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();
		add(psychVer);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			MainMenuHooks.unlockFriday();

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		// Вызываем наш структурированный метод поиска разметки
		var layout:MenuLayoutData = loadTimelessMenuLayout();

		if (layout != null) {
			var localButtons:Array<String> = ['story_mode', 'freeplay', 'mods', 'credits', 'options'];

			if (members != null) {
				for (member in members) {
					if (member != null && Std.isOfType(member, flixel.FlxSprite)) {
						var item:flixel.FlxSprite = cast member;
						
						if (item.graphic != null && item.graphic.key != null) {
							var key:String = item.graphic.key.toLowerCase();
							for (buttonName in localButtons) {
								if (key.indexOf('menu_' + buttonName) != -1) {
									// Перебираем элементы внутри загруженного пакета MenuLayoutData
									for (prop in layout.items) {
										if (prop.name == buttonName) {
											item.x = prop.x;
											item.y = prop.y;
											
											item.scale.set(prop.scaleX * layout.globalScale, prop.scaleY * layout.globalScale);
											item.updateHitbox();
											break;
										}
									}
								}
							}
						}
					}
				}
			}
		}

		super.create();
		#if TOUCH_CONTROLS_ALLOWED
		if (controls.mobileC)
			new mobile.states.MobileMenuState(this);
		else
		#end
		new DesktopMenuState(this);
	}

	function goToOptions()
	{
		MusicBeatState.switchState(new OptionsState());
		#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;
			#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
		}
	}

	override function update(elapsed:Float)
	{
			if (FlxG.keys.justPressed.ANY) {
					for (key in flixel.input.keyboard.FlxKey.fromStringMap.keys()) {
							if (FlxG.keys.checkStatus(flixel.input.keyboard.FlxKey.fromStringMap.get(key), JUST_PRESSED)) {
									var lastKey:String = key.toLowerCase();
									if (lastKey.length == 1) {
											cheatBuffer += lastKey;
							
											if (cheatBuffer.length > 20) 
													cheatBuffer = cheatBuffer.substring(cheatBuffer.length - 2);
									}
							}
					}
			}

			if (FlxG.sound.music.volume < 0.8)
				FlxG.sound.music.volume += 0.5 * elapsed;

			super.update(elapsed);
	}
}