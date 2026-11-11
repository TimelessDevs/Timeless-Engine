package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import openfl.display.BitmapData;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

import states.editors.content.Prompt;
import states.editors.content.Prompt.BasePrompt;

import backend.MusicBeatState;
import states.editors.content.*;
import mikolka.funkin.custom.mobile.MobileScaleMode;

using StringTools;

typedef MenuLayoutData =
{
	var items:Array<MenuItemProps>;
	var globalScale:Float;
	var backgroundAlpha:Float;
	@:optional var decor:Array<MenuItemProps>;
	@:optional var bgImage:String;
	@:optional var transBgImage:String;

	@:optional var bpm:Float;

	@:optional var bgSparrow:Bool;
	@:optional var bgAnim:String;
	@:optional var bgBeat:String;
	@:optional var bgEnter:String;

	@:optional var transBgSparrow:Bool;
	@:optional var transBgAnim:String;
	@:optional var transBgEnter:String;
	@:optional var mobilePositions:Bool;
}

typedef MenuItemProps =
{
	var name:String;
	var x:Float;
	var y:Float;
	var scaleX:Float;
	var scaleY:Float;
	@:optional var enabled:Bool;
	@:optional var key:String;
	@:optional var hideOnEnter:Bool;
	@:optional var beatAnim:String;
	@:optional var beatPrefix:String;
	@:optional var enterAnim:String;
	@:optional var enterPrefix:String;
	@:optional var image:String;
	@:optional var sparrow:Bool;
	@:optional var anim:String;
	@:optional var fps:Float;
	@:optional var loop:Bool;
	@:optional var front:Bool;
	@:optional var enterSound:String;
	@:optional var enterSoundVol:Float;
	@:optional var enterMusic:String;
	@:optional var enterMusicVol:Float;
	@:optional var enterMusicStop:Bool;
	@:optional var appear:String;
	@:optional var appearOn:String;
}

class MenuLayoutIO
{
	public static final DEFAULT_BUTTONS:Array<String> = ['story_mode', 'freeplay', 'mods', 'awards', 'credits', 'merch', 'options'];

	public static final TITLE_ITEMS:Array<String> = ['logo', 'enter'];
	public static inline var MENU_FILE:String = 'menu_layout.json';
	public static inline var TITLE_FILE:String = 'title_layout.json';

	static final PROTECTED_IMAGES:Array<String> = [
		'menuBG', 'menuDesat', 'menuBGBlue', 'menuBGMagenta', 'titleLogo', 'titleEnter', 'logoBumpin', 'gfDanceTitle'
	];

	public static function modRoot():String
	{
		var dir:String = backend.Mods.currentModDirectory;
		return (dir == null || dir == '') ? 'mods/' : 'mods/' + dir + '/';
	}

	public static function candidatePaths(file:String = MENU_FILE):Array<String>
	{
		var out:Array<String> = [];
		for (p in [modRoot() + 'menulayouts/' + file, 'mods/menulayouts/' + file, 'assets/shared/menulayouts/' + file])
			if (out.indexOf(p) < 0)
				out.push(p);
		return out;
	}

	public static function findPath(file:String = MENU_FILE):String
	{
		for (p in candidatePaths(file))
			if (FileSystem.exists(p))
				return p;
		return '';
	}

	public static function savePath(file:String = MENU_FILE):String
		return modRoot() + 'menulayouts/' + file;

	public static function layoutName(gameName:String):String
		return (gameName == 'donate') ? 'merch' : gameName;

	public static function atlasName(layoutName:String):String
		return (layoutName == 'merch') ? 'donate' : layoutName;

	public static function hasText(s:String):Bool
		return s != null && StringTools.trim(s) != '';

	public static function bpmOf(d:MenuLayoutData, def:Float):Float
		return (d != null && d.bpm != null && d.bpm > 0) ? d.bpm : def;

	public static function makeItem(name:String, x:Float, y:Float):MenuItemProps
		return {
			name: name,
			x: x,
			y: y,
			scaleX: 0.8,
			scaleY: 0.8,
			enabled: true,
			key: '',
			hideOnEnter: true,
			beatAnim: 'none',
			beatPrefix: '',
			enterAnim: 'flicker',
			enterPrefix: ''
		};

	public static function makeTitleItem(name:String, x:Float, y:Float, beat:String):MenuItemProps
	{
		var it = makeItem(name, x, y);
		it.scaleX = 1;
		it.scaleY = 1;
		it.hideOnEnter = false;
		it.beatAnim = beat;
		return it;
	}

	public static function makeDecor(name:String, sparrow:Bool):MenuItemProps
		return {
			name: name,
			x: 500,
			y: 250,
			scaleX: 1,
			scaleY: 1,
			enabled: true,
			key: '',
			hideOnEnter: false,
			beatAnim: 'none',
			beatPrefix: '',
			enterAnim: 'flicker',
			enterPrefix: '',
			image: '',
			sparrow: sparrow,
			anim: '',
			fps: 24,
			loop: true,
			front: false
		};

	public static function makeDefault():MenuLayoutData
	{
		var d:MenuLayoutData = {
			items: [],
			globalScale: 1.0,
			backgroundAlpha: 1.0,
			decor: [],
			bgImage: '',
			transBgImage: '',
			bpm: MenuFx.BPM
		};
		for (i in 0...DEFAULT_BUTTONS.length)
			d.items.push(makeItem(DEFAULT_BUTTONS[i], 90, 60 + i * 90));
		return d;
	}

	public static function makeDefaultTitle():MenuLayoutData
	{
		var g = MenuFx.loadImage('titleLogo');
		var logoX:Float = (g != null) ? (FlxG.width - g.width) / 2 : 400;
		var enterIt = makeTitleItem('enter', 100, 576, 'none');
		enterIt.enterPrefix = MenuFx.CLASSIC_PRESS;
		return {
			items: [makeTitleItem('logo', logoX, 40, 'tilt'), enterIt],
			globalScale: 1.0,
			backgroundAlpha: 1.0,
			decor: [],
			bgImage: '',
			transBgImage: '',
			bpm: MenuFx.TITLE_BPM
		};
	}

	static function num(v:Dynamic, d:Float):Float
	{
		if (v == null)
			return d;
		var f = Std.parseFloat(Std.string(v));
		return Math.isNaN(f) ? d : f;
	}

	static function fixItem(it:MenuItemProps, isDecor:Bool, title:Bool = false)
	{
		it.x = num(it.x, 0);
		it.y = num(it.y, 0);
		it.scaleX = num(it.scaleX, title ? 1 : 0.8);
		it.scaleY = num(it.scaleY, title ? 1 : 0.8);
		if (it.enabled == null)
			it.enabled = true;
		if (it.key == null)
			it.key = '';
		if (it.hideOnEnter == null)
			it.hideOnEnter = !isDecor && !title;
		if (it.beatAnim == null)
			it.beatAnim = (title && it.name == 'logo') ? 'tilt' : 'none';
		else if (MenuFx.BEAT_IDS.indexOf(it.beatAnim) < 0)
			it.beatAnim = 'none';
		if (it.beatPrefix == null)
			it.beatPrefix = '';
		if (it.enterAnim == null || MenuFx.ENTER_IDS.indexOf(it.enterAnim) < 0)
			it.enterAnim = 'flicker';
		if (it.enterPrefix == null)
			it.enterPrefix = (title && it.name == 'enter') ? MenuFx.CLASSIC_PRESS : '';
		if (it.image == null)
			it.image = '';
		if (it.sparrow == null)
			it.sparrow = false;
		if (it.anim == null)
			it.anim = '';
		it.fps = num(it.fps, 24);
		if (it.loop == null)
			it.loop = true;
		if (it.front == null)
			it.front = false;
		if (it.enterSound == null)
			it.enterSound = '';
		it.enterSoundVol = Math.max(0, Math.min(1, num(it.enterSoundVol, 1)));
		if (it.enterMusic == null)
			it.enterMusic = '';
		it.enterMusicVol = Math.max(0, Math.min(1, num(it.enterMusicVol, 0.7)));
		if (it.enterMusicStop == null)
			it.enterMusicStop = false;
		if (it.appear == null || MenuFx.APPEAR_IDS.indexOf(it.appear) < 0)
			it.appear = 'always';
		if (it.appearOn == null)
			it.appearOn = '';
	}

	public static function normalize(d:MenuLayoutData, title:Bool = false):MenuLayoutData
	{
		if (d == null || d.items == null)
			return title ? makeDefaultTitle() : makeDefault();
		var defBpm:Float = title ? MenuFx.TITLE_BPM : MenuFx.BPM;
		d.globalScale = num(d.globalScale, 1.0);
		d.backgroundAlpha = num(d.backgroundAlpha, 1.0);
		d.bpm = num(d.bpm, defBpm);
		if (d.bpm <= 0)
			d.bpm = defBpm;
		if (d.decor == null)
			d.decor = [];
		if (d.bgImage == null)
			d.bgImage = '';
		if (d.transBgImage == null)
			d.transBgImage = '';
		if (d.bgSparrow == null)
			d.bgSparrow = false;
		if (d.bgAnim == null)
			d.bgAnim = '';
		if (d.bgBeat == null)
			d.bgBeat = '';
		if (d.bgEnter == null)
			d.bgEnter = '';
		if (d.transBgSparrow == null)
			d.transBgSparrow = false;
		if (d.transBgAnim == null)
			d.transBgAnim = '';
		if (d.transBgEnter == null)
			d.transBgEnter = '';
		if (d.mobilePositions == null)
			d.mobilePositions = true;
		for (it in d.items)
			fixItem(it, false, title);
		for (it in d.decor)
			fixItem(it, true, title);
		if (title)
		{

			for (n in TITLE_ITEMS)
			{
				var found = false;
				for (it in d.items)
					if (it.name == n)
						found = true;
				if (!found)
					for (di in makeDefaultTitle().items)
						if (di.name == n)
							d.items.push(di);
			}
		}
		return d;
	}

	public static function parse(json:String, title:Bool = false):MenuLayoutData
		return normalize(Json.parse(json), title);

	public static function loadFile(file:String = MENU_FILE):MenuLayoutData
	{
		var p = findPath(file);
		if (p == '')
			return null;
		try
		{
			return parse(File.getContent(p), file == TITLE_FILE);
		}
		catch (e:Dynamic)
		{
			trace('[MenuLayout] could not read ' + p + ': ' + e);
			return null;
		}
	}

	public static function loadTitle():MenuLayoutData
		return loadFile(TITLE_FILE);

	static function r2(v:Float):Float
		return Math.round(v * 100) / 100;

	static function saveItem(it:MenuItemProps, isDecor:Bool, title:Bool):Dynamic
	{
		var o:Dynamic = {name: it.name, x: r2(it.x), y: r2(it.y), scaleX: r2(it.scaleX), scaleY: r2(it.scaleY)};
		if (!isDecor && it.enabled == false)
			o.enabled = false;
		if (!isDecor && hasText(it.key))
			o.key = it.key;

		if (title || it.hideOnEnter != !isDecor)
			o.hideOnEnter = it.hideOnEnter;
		if (title || it.beatAnim != 'none')
		{
			o.beatAnim = it.beatAnim;
			if (it.beatAnim == 'sparrow' && hasText(it.beatPrefix))
				o.beatPrefix = it.beatPrefix;
		}
		if (!isDecor && it.enterAnim != 'flicker')
			o.enterAnim = it.enterAnim;

		if (title && it.name == 'enter')
			o.enterPrefix = it.enterPrefix;
		else if (hasText(it.enterPrefix))
			o.enterPrefix = it.enterPrefix;
		if (hasText(it.enterSound))
		{
			o.enterSound = it.enterSound;
			if (it.enterSoundVol != 1)
				o.enterSoundVol = r2(it.enterSoundVol);
		}
		if (hasText(it.enterMusic))
		{
			o.enterMusic = it.enterMusic;
			if (it.enterMusicVol != 0.7)
				o.enterMusicVol = r2(it.enterMusicVol);
		}
		if (it.enterMusicStop == true)
			o.enterMusicStop = true;
		if (it.appear != 'always')
		{
			o.appear = it.appear;
			if (hasText(it.appearOn))
				o.appearOn = it.appearOn;
		}
		if (isDecor)
		{
			o.image = it.image;
			if (it.sparrow)
			{
				o.sparrow = true;
				if (hasText(it.anim))
					o.anim = it.anim;
				if (it.fps != 24)
					o.fps = it.fps;
				if (!it.loop)
					o.loop = false;
			}
			if (it.front)
				o.front = true;
		}
		return o;
	}

	public static function toSave(d:MenuLayoutData, title:Bool = false):Dynamic
	{
		var o:Dynamic = {
			items: [for (it in d.items) saveItem(it, false, title)],
			globalScale: r2(d.globalScale),
			backgroundAlpha: r2(d.backgroundAlpha),
			bpm: r2(d.bpm)
		};
		if (d.decor.length > 0)
			o.decor = [for (it in d.decor) saveItem(it, true, title)];
		if (hasText(d.bgImage))
			o.bgImage = d.bgImage;
		if (!title && hasText(d.transBgImage))
			o.transBgImage = d.transBgImage;
		if (!title && d.mobilePositions == false)
			o.mobilePositions = false;
		if (hasText(d.bgImage) && d.bgSparrow == true)
		{
			o.bgSparrow = true;
			if (hasText(d.bgAnim))
				o.bgAnim = d.bgAnim;
			if (hasText(d.bgBeat))
				o.bgBeat = d.bgBeat;
			if (hasText(d.bgEnter))
				o.bgEnter = d.bgEnter;
		}
		if (!title && hasText(d.transBgImage) && d.transBgSparrow == true)
		{
			o.transBgSparrow = true;
			if (hasText(d.transBgAnim))
				o.transBgAnim = d.transBgAnim;
			if (hasText(d.transBgEnter))
				o.transBgEnter = d.transBgEnter;
		}
		return o;
	}

	public static function pollKeys(props:Array<MenuItemProps>):Int
	{
		for (i in 0...props.length)
		{
			var p = props[i];
			if (p == null || p.enabled == false || !hasText(p.key))
				continue;
			var key:FlxKey = FlxKey.fromString(p.key);
			if (key != FlxKey.NONE && FlxG.keys.checkStatus(key, JUST_PRESSED))
				return i;
		}
		return -1;
	}

	public static function imagesOf(d:Dynamic, out:Map<String, Bool>)
	{
		if (d == null)
			return;
		for (n in [d.bgImage, d.transBgImage])
			if (n != null && hasText(Std.string(n)))
				out.set(StringTools.trim(Std.string(n)), true);
		var dec:Array<Dynamic> = d.decor;
		if (dec != null)
			for (it in dec)
				if (it != null && it.image != null && hasText(Std.string(it.image)))
					out.set(StringTools.trim(Std.string(it.image)), true);
	}

	public static function usedOnDisk():Map<String, Bool>
	{
		var out = new Map<String, Bool>();
		var roots:Array<String> = ['mods/'];
		try
		{
			for (m in FileSystem.readDirectory('mods'))
				if (FileSystem.isDirectory('mods/' + m))
					roots.push('mods/' + m + '/');
		}
		catch (e:Dynamic) {}
		for (r in roots)
			for (f in [MENU_FILE, TITLE_FILE])
			{
				var p = r + 'menulayouts/' + f;
				if (!FileSystem.exists(p))
					continue;
				try
				{
					imagesOf(Json.parse(File.getContent(p)), out);
				}
				catch (e:Dynamic) {}
			}
		return out;
	}

	public static function isProtectedImage(name:String):Bool
	{
		if (!hasText(name) || name.indexOf('\\') >= 0 || name.indexOf('..') >= 0)
			return true;
		if (name.indexOf('/') >= 0)
			return !(name.startsWith(MenuFx.IMPORT_FOLDER + '/') && name.indexOf('/', MenuFx.IMPORT_FOLDER.length + 1) < 0);
		if (PROTECTED_IMAGES.indexOf(name) >= 0)
			return true;
		for (d in ['assets/images/', 'assets/shared/images/', 'assets/preload/images/'])
			if (FileSystem.exists(d + name + '.png'))
				return true;
		return false;
	}

	public static function deleteImageFiles(name:String):Int
	{
		var removed = 0;
		for (dir in MenuFx.imageDirs())
		{
			var png = dir + name + '.png';
			try
			{
				if (!FileSystem.exists(png) || FileSystem.isDirectory(png))
					continue;
				FileSystem.deleteFile(png);
				removed++;
				var xml = dir + name + '.xml';
				if (FileSystem.exists(xml))
				{
					FileSystem.deleteFile(xml);
					removed++;
				}
			}
			catch (e:Dynamic)
			{
				trace('[MenuLayout] could not delete ' + png + ': ' + e);
			}
		}
		return removed;
	}
}

class MenuFx
{
	public static inline var BPM:Float = 102;
	public static inline var TITLE_BPM:Float = 104;
	public static inline var BG_SCALE:Float = 1.175;
	public static inline var TRANS_FADE:Float = 0.4;

	public static inline var CLASSIC_PRESS:String = 'ENTER PRESSED';

	public static final BEAT_IDS:Array<String> = ['none', 'bounce', 'swing', 'tilt', 'sparrow'];
	public static final BEAT_NAMES:Array<String> = ['None', 'Bounce', 'Swing', 'Tilt (title logo)', 'Sparrow animation'];
	public static inline var IMPORT_FOLDER:String = 'menulayout';
	public static final APPEAR_IDS:Array<String> = ['always', 'before', 'after'];
	public static final APPEAR_NAMES:Array<String> = ['Always visible', 'Only before Enter', 'Only after Enter'];
	public static final ENTER_IDS:Array<String> = ['flicker', 'none', 'fade', 'zoom'];
	public static final ENTER_NAMES:Array<String> = ['Flicker (default)', 'None', 'Fade out', 'Zoom out'];

	public static function imageDirs():Array<String>
	{
		var a = MenuLayoutIO.modRoot() + 'images/';
		return (a == 'mods/images/') ? [a] : [a, 'mods/images/'];
	}

	public static function loadImage(name:String):FlxGraphic
	{
		if (!MenuLayoutIO.hasText(name))
			return null;
		name = StringTools.trim(name);
		var g:FlxGraphic = null;
		try
		{
			g = backend.Paths.image(name);
		}
		catch (e:Dynamic) {}
		if (g != null)
			return g;
		for (dir in imageDirs())
		{
			var f = dir + name + '.png';
			if (!FileSystem.exists(f))
				continue;
			var cached = FlxG.bitmap.get(f);
			if (cached != null)
				return cached;
			try
			{
				return FlxG.bitmap.add(BitmapData.fromFile(f), false, f);
			}
			catch (e:Dynamic) {}
		}
		return null;
	}

	public static function loadAtlas(name:String):FlxAtlasFrames
	{
		if (!MenuLayoutIO.hasText(name))
			return null;
		name = StringTools.trim(name);
		var frames:FlxAtlasFrames = null;
		try
		{
			frames = backend.Paths.getSparrowAtlas(name);
		}
		catch (e:Dynamic) {}
		if (frames != null)
			return frames;
		for (dir in imageDirs())
		{
			var xml = dir + name + '.xml';
			var g = FileSystem.exists(xml) ? loadImage(name) : null;
			if (g == null)
				continue;
			try
			{
				return FlxAtlasFrames.fromSparrow(g, File.getContent(xml));
			}
			catch (e:Dynamic) {}
		}
		return null;
	}

	public static function loadBackground(spr:FlxSprite, image:String, scaleFactor:Float = BG_SCALE):Bool
	{
		var g = loadImage(image);
		if (spr == null || g == null)
			return false;
		spr.loadGraphic(g);
		spr.setGraphicSize(Std.int(spr.width * scaleFactor));
		spr.updateHitbox();
		spr.screenCenter();
		return true;
	}

	static function pick(s:String, fallback:String):String
		return MenuLayoutIO.hasText(s) ? StringTools.trim(s) : fallback;

	public static function setupAnims(spr:FlxSprite, p:MenuItemProps, fallbackName:String)
	{
		if (spr == null || p == null || spr.frames == null)
			return;
		if (p.beatAnim == 'sparrow')
			spr.animation.addByPrefix('beat', pick(p.beatPrefix, fallbackName + ' beat'), 24, false);

		if (MenuLayoutIO.hasText(p.enterPrefix))
			spr.animation.addByPrefix('enter', StringTools.trim(p.enterPrefix), 24, false);
	}

	public static function makeDecor(p:MenuItemProps):FlxSprite
	{
		var spr:FlxSprite = null;
		if (MenuLayoutIO.hasText(p.image))
		{
			if (p.sparrow)
			{
				var frames = loadAtlas(p.image);
				if (frames != null)
				{
					spr = new FlxSprite();
					spr.frames = frames;
					if (MenuLayoutIO.hasText(p.anim))
					{
						spr.animation.addByPrefix('main', StringTools.trim(p.anim), Std.int(p.fps), p.loop);
						if (spr.animation.exists('main'))
							spr.animation.play('main');
					}
					setupAnims(spr, p, StringTools.trim(p.anim));
				}
			}
			else
			{
				var g = loadImage(p.image);
				if (g != null)
					spr = new FlxSprite().loadGraphic(g);
			}
		}
		if (spr == null)
		{
			var t = new FlxText(0, 0, 0, '[' + p.name + ']\n' + (MenuLayoutIO.hasText(p.image) ? 'not found: ' + p.image : 'no image set'), 24);
			t.setFormat(backend.Paths.font('vcr.ttf'), 24, 0xFFFFAA33, LEFT, OUTLINE, FlxColor.BLACK);
			spr = t;
		}
		spr.antialiasing = backend.ClientPrefs.data.antialiasing;
		return spr;
	}

	public static function place(spr:FlxSprite, p:MenuItemProps)
	{
		spr.scale.set(p.scaleX, p.scaleY);
		spr.updateHitbox();
		spr.setPosition(p.x, p.y);
		spr.angle = 0;
		spr.alpha = 1;
	}

	public static function beat(spr:FlxSprite, p:MenuItemProps, rsx:Float, rsy:Float, beatIndex:Int, restAnim:String)
	{
		if (spr == null || p == null || !spr.alive || !spr.visible)
			return;
		switch (p.beatAnim)
		{
			case 'bounce':
				FlxTween.cancelTweensOf(spr.scale);
				spr.scale.set(rsx * 1.12, rsy * 1.12);
				FlxTween.tween(spr.scale, {x: rsx, y: rsy}, 0.28, {ease: FlxEase.quadOut});
			case 'swing':
				FlxTween.cancelTweensOf(spr, ['angle']);
				spr.angle = (beatIndex % 2 == 0) ? -5 : 5;
				FlxTween.tween(spr, {angle: 0}, 0.35, {ease: FlxEase.backOut});
			case 'tilt':
				FlxTween.cancelTweensOf(spr.scale);
				FlxTween.cancelTweensOf(spr, ['angle']);
				var a:Float = FlxG.random.float(7.5, 11.5);
				spr.scale.set(rsx * 0.9, rsy * 0.9);
				spr.angle = (beatIndex % 2 == 0) ? -a : a;
				FlxTween.tween(spr.scale, {x: rsx, y: rsy}, 0.46, {ease: FlxEase.expoOut});
				FlxTween.tween(spr, {angle: 0}, 0.69, {ease: FlxEase.expoOut});
			case 'sparrow':
				if (restAnim != '' && spr.animation.exists('beat'))
				{
					spr.animation.play('beat', true);
					spr.animation.finishCallback = function(n:String)
					{
						spr.animation.finishCallback = null;
						if (spr.animation.exists(restAnim))
							spr.animation.play(restAnim);
					};
				}
			default:
		}
	}

	public static function playOnce(spr:FlxSprite, anim:String, back:String):Bool
	{
		if (spr == null || spr.animation == null || !spr.animation.exists(anim))
			return false;
		spr.animation.play(anim, true);
		spr.animation.finishCallback = function(n:String)
		{
			spr.animation.finishCallback = null;
			if (back != '' && spr.animation.exists(back))
				spr.animation.play(back);
		};
		return true;
	}

	public static function playEnterAnim(spr:FlxSprite, p:MenuItemProps):Bool
	{
		if (p == null || !MenuLayoutIO.hasText(p.enterPrefix))
			return false;
		return playOnce(spr, 'enter', '');
	}

	public static function resetSheet(spr:FlxSprite)
	{
		if (spr == null || spr.animation == null)
			return;
		if (spr.animation.exists('main'))
			spr.animation.play('main', true);
		else if (spr.animation.exists('beat') || spr.animation.exists('enter'))
			spr.animation.frameIndex = 0;
	}

	public static function applyBackground(spr:FlxSprite, d:MenuLayoutData, trans:Bool, scaleFactor:Float = BG_SCALE):Bool
	{
		if (spr == null || d == null)
			return false;
		var image:String = trans ? d.transBgImage : d.bgImage;
		if (!MenuLayoutIO.hasText(image))
			return false;
		var sheet:Bool = trans ? (d.transBgSparrow == true) : (d.bgSparrow == true);
		if (sheet)
		{
			var frames = loadAtlas(image);
			if (frames != null)
			{
				spr.frames = frames;
				spr.antialiasing = backend.ClientPrefs.data.antialiasing;
				var anim:String = trans ? d.transBgAnim : d.bgAnim;
				var beatP:String = trans ? '' : d.bgBeat;
				var enterP:String = trans ? d.transBgEnter : d.bgEnter;
				if (MenuLayoutIO.hasText(anim))
					spr.animation.addByPrefix('main', StringTools.trim(anim), 24, true);
				if (MenuLayoutIO.hasText(beatP))
					spr.animation.addByPrefix('beat', StringTools.trim(beatP), 24, false);
				if (MenuLayoutIO.hasText(enterP))
					spr.animation.addByPrefix('enter', StringTools.trim(enterP), 24, false);
				if (spr.animation.exists('main'))
					spr.animation.play('main');
				else
					spr.animation.frameIndex = 0;
				spr.scale.set(scaleFactor, scaleFactor);
				spr.updateHitbox();
				spr.screenCenter();
				return true;
			}
		}
		return loadBackground(spr, image, scaleFactor);
	}

	public static function enter(spr:FlxSprite, p:MenuItemProps, onDone:Void->Void)
	{
		var done = false;
		var finish = function()
		{
			if (done)
				return;
			done = true;
			if (onDone != null)
				onDone();
		};

		if (p != null && MenuLayoutIO.hasText(p.enterPrefix) && spr.animation != null && spr.animation.exists('enter'))
		{
			spr.animation.play('enter', true);
			spr.animation.finishCallback = function(n:String)
			{
				spr.animation.finishCallback = null;
				finish();
			};
			new FlxTimer().start(2.5, function(t:FlxTimer) finish());
			return;
		}
		var cb = function(t:FlxTween) finish();
		switch (p == null ? 'flicker' : p.enterAnim)
		{
			case 'none':
				finish();
			case 'fade':
				FlxTween.tween(spr, {alpha: 0}, 0.5, {onComplete: cb});
			case 'zoom':
				FlxTween.tween(spr.scale, {x: spr.scale.x * 1.8, y: spr.scale.y * 1.8}, 0.6, {ease: FlxEase.quadIn});
				FlxTween.tween(spr, {alpha: 0}, 0.6, {onComplete: cb});
			default:
				FlxFlicker.flicker(spr, 1, 0.06, false, false, function(f:FlxFlicker) finish());
		}
	}

	static function sameName(a:String, b:String):Bool
		return MenuLayoutIO.layoutName(StringTools.trim(a)).toLowerCase() == MenuLayoutIO.layoutName(StringTools.trim(b)).toLowerCase();

	public static function matchesTrigger(p:MenuItemProps, chosen:String):Bool
	{
		if (p == null || !MenuLayoutIO.hasText(p.appearOn))
			return true;
		return MenuLayoutIO.hasText(chosen) && sameName(p.appearOn, chosen);
	}

	public static function startsVisible(p:MenuItemProps):Bool
		return p == null || p.appear != 'after';

	public static function show(spr:FlxSprite)
	{
		if (spr == null)
			return;
		FlxTween.cancelTweensOf(spr);
		spr.revive();
		spr.visible = true;
		spr.alpha = 0;
		FlxTween.tween(spr, {alpha: 1}, 0.25);
	}

	public static function decorEnter(spr:FlxSprite, p:MenuItemProps, chosen:String):Bool
	{
		if (spr == null || p == null || !matchesTrigger(p, chosen))
			return false;
		if (p.appear == 'after')
		{
			show(spr);
			playEnterAnim(spr, p);
			return true;
		}
		if (p.appear == 'before')
		{
			hide(spr);
			return true;
		}
		return false;
	}

	public static function playSound(name:String, vol:Float)
	{
		if (!MenuLayoutIO.hasText(name))
			return;
		try
		{
			var snd = backend.Paths.sound(StringTools.trim(name));
			if (snd != null)
				FlxG.sound.play(snd, vol);
		}
		catch (e:Dynamic) {}
	}

	public static function playMusic(name:String, vol:Float):Bool
	{
		if (!MenuLayoutIO.hasText(name))
			return false;
		try
		{
			var mus = backend.Paths.music(StringTools.trim(name));
			if (mus == null)
				return false;
			FlxG.sound.playMusic(mus, vol);
			return true;
		}
		catch (e:Dynamic) {}
		return false;
	}

	public static function playEnterSound(p:MenuItemProps, fallback:String = 'confirmMenu')
	{
		if (p != null && MenuLayoutIO.hasText(p.enterSound))
			playSound(p.enterSound, (p.enterSoundVol == null) ? 1 : p.enterSoundVol);
		else
			playSound(fallback, 1);
	}

	public static function playEnterMusic(p:MenuItemProps)
	{
		if (p == null)
			return;
		if (MenuLayoutIO.hasText(p.enterMusic))
		{
			playMusic(p.enterMusic, (p.enterMusicVol == null) ? 0.7 : p.enterMusicVol);
			return;
		}
		if (p.enterMusicStop == true && FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.6, 0);
	}

	public static function hide(spr:FlxSprite)
	{
		if (spr == null || !spr.alive)
			return;
		FlxTween.tween(spr, {alpha: 0}, 0.25, {onComplete: function(t:FlxTween) spr.kill()});
	}
}

class MenuPane
{
	public var group:Dynamic;
	public var objs:Array<Dynamic> = [];

	public function new(group:Dynamic)
		this.group = group;

	public function add(o:Dynamic):Dynamic
	{
		group.add(o);
		objs.push(o);
		return o;
	}

	public function clear()
	{
		for (o in objs)
		{
			group.remove(o, true);
			o.destroy();
		}
		objs = [];
	}
}

class MenuEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	static inline var MAX_DECOR:Int = 12;
	static inline var LEFT_W:Int = 212;
	static inline var RX:Int = 226;
	static inline var RW:Int = 364;
	static final OBJ_TABS:Array<String> = ['Place', 'Animate', 'On Enter'];
	static final TAB_NAMES:Array<String> = ['Main Menu', 'Title Menu'];
	static final RESERVED_KEYS:Array<FlxKey> = [
		FlxKey.ESCAPE, FlxKey.ENTER, FlxKey.E, FlxKey.S, FlxKey.DELETE, FlxKey.LEFT, FlxKey.RIGHT, FlxKey.UP, FlxKey.DOWN, FlxKey.F1, FlxKey.CONTROL,
		FlxKey.SHIFT
	];

	var layouts:Array<MenuLayoutData> = [null, null];
	var sels:Array<Int> = [0, 0];
	var dirtyTabs:Array<Bool> = [false, false];
	var tab:Int = 0;
	var layout:MenuLayoutData;
	var sel:Int = 0;
	var uiSuppress:Bool = false;
	var pendingDelete:Array<String> = [];
	var createdFiles:Array<String> = [];

	var camUI:FlxCamera;
	var menuBgSpr:FlxSprite;
	var transSpr:FlxSprite;
	var decorBack:FlxTypedGroup<FlxSprite>;
	var btnGroup:FlxTypedGroup<FlxSprite>;
	var decorFront:FlxTypedGroup<FlxSprite>;
	var sprites:Array<FlxSprite> = [];
	var hitOrder:Array<Int> = [];
	var selEdges:Array<FlxSprite> = [];
	var selCache:Array<Float> = [0, 0, 0, 0];
	var selShown:Bool = false;
	var hideHint:FlxText;
	var hintTimer:Float = 0;

	var box:PsychUIBox;
	var panes:Array<MenuPane>;
	var pane:MenuPane;
	var outputTxt:FlxText;
	var outputAlpha:Float = 0;
	var tipBg:FlxSprite;
	var fullTipText:FlxText;
	var ignoreClickForThisFrame:Bool = false;
	var uiVisible:Bool = true;
	var uiKey:FlxKey = FlxKey.TAB;
	var pendPanel:Bool = false;
	var pendCanvas:Bool = false;
	var canvasTimer:Float = -1;
	var showTrans:Bool = false;
	var stX:PsychUINumericStepper;
	var stY:PsychUINumericStepper;
	var stSc:PsychUINumericStepper;
	var bpmInfo:FlxText;
	var dds:Array<{dd:PsychUIDropDownMenu, y:Int, idx:Int}> = [];
	var pickDialog:Dynamic;

	var sheetBox:PsychUIBox;
	var sheetPane:MenuPane;
	var sheetFor:Int = -1;
	var sheetTimer:Float = -1;
	var pendSheet:Bool = false;

	var padHold:Float = 0;
	var padRepeat:Float = 0;

	var dragging:Bool = false;
	var dragOffX:Float = 0;
	var dragOffY:Float = 0;
	var capturingKey:Bool = false;
	var captureForUi:Bool = false;
	var lastBeat:Int = -1;
	var beatClock:Float = 0;

	var page:Int = 0;
	var objTab:Int = 0;
	var layoutHistory:Array<String> = [];
	var histIdx:Int = -1;
	var histTimer:Float = -1;
	var restoring:Bool = false;
	var snapSize:Int = 0;
	var mouseLock:Bool = false;
	var padPress:Bool = false;
	var panelBack:FlxSprite;
	var sheetBack:FlxSprite;
	var musicChanged:Bool = false;

	override function create()
	{
		persistentUpdate = false;
		FlxG.mouse.visible = !mobile();
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);

		#if DISCORD_ALLOWED
        DiscordClient.changePresence('Menu Editor');
        #end

		initPsychCamera();
		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.color = 0xFF303030;
		add(bg);

		layouts[0] = MenuLayoutIO.loadFile();
		if (layouts[0] == null)
			layouts[0] = MenuLayoutIO.makeDefault();
		layouts[1] = MenuLayoutIO.loadTitle();
		if (layouts[1] == null)
			layouts[1] = MenuLayoutIO.makeDefaultTitle();
		layout = layouts[0];
		loadUiKey();

		menuBgSpr = new FlxSprite();
		menuBgSpr.scrollFactor.set();
		add(menuBgSpr);
		transSpr = new FlxSprite();
		transSpr.scrollFactor.set();
		transSpr.alpha = 0;
		add(transSpr);
		refreshBackgrounds();

		decorBack = new FlxTypedGroup<FlxSprite>();
		btnGroup = new FlxTypedGroup<FlxSprite>();
		decorFront = new FlxTypedGroup<FlxSprite>();
		add(decorBack);
		add(btnGroup);
		add(decorFront);
		for (i in 0...4)
		{
			var e = new FlxSprite().makeGraphic(1, 1, 0xFFBF55EC);
			e.scrollFactor.set();
			selEdges.push(e);
			add(e);
		}
		buildCanvas();

		hideHint = new FlxText(0, FlxG.height - 60, FlxG.width, '', 20);
		hideHint.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		hideHint.scrollFactor.set();
		hideHint.alpha = 0;
		add(hideHint);

		var off:Float = (MobileScaleMode.gameCutoutSize.x / 2.5);
		panelBack = new FlxSprite(FlxG.width - 620 - off, 30).makeGraphic(600, 650, 0xFF1A1A22);
		panelBack.scrollFactor.set();
		panelBack.cameras = [camUI];
		add(panelBack);
		box = new PsychUIBox(FlxG.width - 620 - off, 30, 600, 650, TAB_NAMES);
		box.scrollFactor.set();
		box.cameras = [camUI];
		add(box);
		panes = [for (t in TAB_NAMES) new MenuPane(tabMenu(box, t))];
		pane = panes[0];

		sheetBack = new FlxSprite(20 + off, 90).makeGraphic(330, 340, 0xFF1A1A22);
		sheetBack.scrollFactor.set();
		sheetBack.cameras = [camUI];
		sheetBack.visible = false;
		add(sheetBack);
		sheetBox = new PsychUIBox(20 + off, 90, 330, 340, ['Background spritesheet']);
		sheetBox.scrollFactor.set();
		sheetBox.cameras = [camUI];
		sheetBox.visible = sheetBox.active = false;
		add(sheetBox);
		sheetPane = new MenuPane(tabMenu(sheetBox, 'Background spritesheet'));

		outputTxt = new FlxText(25, FlxG.height - 50, FlxG.width - 50, '', 20);
		outputTxt.borderSize = 2;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.scrollFactor.set();
		outputTxt.cameras = [camUI];
		add(outputTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 300, 'Press ${(controls.mobileC) ? 'F' : 'F1'} for Help', 20);
		tipText.cameras = [camUI];
		tipText.setFormat(null, 16, FlxColor.WHITE, LEFT);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		fullTipText = new FlxText(0, 0, FlxG.width - 200);
		fullTipText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		fullTipText.cameras = [camUI];
		fullTipText.scrollFactor.set();
		fullTipText.visible = fullTipText.active = false;
		add(fullTipText);
		refreshHelp();

		#if TOUCH_CONTROLS_ALLOWED

		addTouchPad('LEFT_FULL', 'CHART_EDITOR');
		#end

		var savedSnap:Dynamic = FlxG.save.data.menuEditorSnap;
		snapSize = (savedSnap != null) ? Std.int(savedSnap) : 0;
		pushHistory();

		pendPanel = true;
		super.create();
	}

	function showOutput(message:String, isError:Bool = false)
	{
		trace(message);
		outputTxt.text = message;
		outputTxt.y = FlxG.height - outputTxt.height - 30;
		outputAlpha = 4;
		if (isError)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			outputTxt.color = FlxColor.RED;
		}
		else
			outputTxt.color = FlxColor.WHITE;
	}

	function keyName(k:FlxKey):String
	{
		var n = FlxKey.toStringMap.get(k);
		return (n == null) ? '?' : n;
	}

	function refreshHelp()
	{
		if (controls.mobileC)
		{
			fullTipText.text = [
				"Touch + Drag - Move (a drag never presses panel buttons)",
				"Undo / Redo / Save / Exit - buttons at the bottom of the panel",
				"Arrows - Nudge (hold Y = x10)",
				"Up2 / Down2 - Previous / Next object",
				"X - Show / Hide the selected object",
				"D - Remove a custom picture",
				"",
				"C - Hide / Show the UI",
				"G - Show the enter background",
				"A - Save",
				"V - Exit",
				"F - Help",
				"Z - Hide / Show these buttons"
			].join('\n');
			fullTipText.screenCenter();
			return;
		}
		fullTipText.text = [
			"Left Click + Drag - Move (a drag never presses panel buttons)",
			"Arrow Keys - Nudge (Shift = x10)",
			"Ctrl + Z / Ctrl + Y - Undo / Redo",
			"Ctrl + D - Duplicate the selected picture",
			"E - Show / Hide the selected object",
			"Delete - Remove a custom picture (its file is deleted on save)",
			"",
			keyName(uiKey) + " - Hide / Show the UI (the key can be changed in the panel)",
			"Ctrl + S - Save",
			"Esc - Exit"
		].join('\n');
		fullTipText.screenCenter();
	}

	function toggleHelp()
	{
		var vis:Bool = !fullTipText.visible;
		tipBg.visible = tipBg.active = fullTipText.visible = fullTipText.active = vis;
	}

	function loadUiKey()
	{
		var s:String = FlxG.save.data.menuEditorUiKey;
		var k:FlxKey = (s != null) ? FlxKey.fromString(s) : FlxKey.NONE;
		uiKey = (k != FlxKey.NONE && RESERVED_KEYS.indexOf(k) < 0) ? k : FlxKey.TAB;
	}

	function setUiKey(k:FlxKey)
	{
		if (RESERVED_KEYS.indexOf(k) >= 0)
		{
			showOutput(keyName(k) + ' is already used by the editor, pick another key.', true);
			return;
		}
		uiKey = k;
		FlxG.save.data.menuEditorUiKey = keyName(k);
		FlxG.save.flush();
		refreshHelp();
		showOutput('The UI is now hidden / shown with ' + keyName(k));
	}

	function tabMenu(b:PsychUIBox, name:String):Dynamic
	{
		var t = b.getTab(name);
		return (t != null && t.menu != null) ? t.menu : b;
	}

	function syncBoxes()
	{
		if (box == null || sheetBox == null || panelBack == null || sheetBack == null)
			return;
		var sheetOn = sheetFor >= 0;
		box.visible = uiVisible;
		panelBack.visible = uiVisible;
		sheetBox.visible = uiVisible && sheetOn;
		sheetBack.visible = uiVisible && sheetOn;
		box.active = uiVisible && !mouseLock;
		sheetBox.active = uiVisible && sheetOn && !mouseLock;
	}

	function toggleUI()
	{
		uiVisible = !uiVisible;
		camUI.visible = uiVisible;
		syncBoxes();
		hideHint.text = 'UI hidden - press ' + keyName(uiKey) + ' to show';
		hintTimer = uiVisible ? 0 : 3;
	}

	function isDirty():Bool
		return dirtyTabs[0] || dirtyTabs[1];

	function isTitle():Bool
		return tab == 1;

	function tryExit()
	{
		if (isDirty())
			openSubState(new Prompt('There are unsaved changes. Exit anyway?', exitEditor));
		else
			exitEditor();
	}

	function exitEditor()
	{

		try
		{
			purgeImages(createdFiles, false);
		}
		catch (e:Dynamic) {}
		if (musicChanged)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
		persistentUpdate = false;
		FlxG.mouse.visible = false;
		ClientPrefs.toggleVolumeKeys(true);
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new MasterEditorMenu());
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		switch (id)
		{
			case PsychUIButton.CLICK_EVENT, PsychUIDropDownMenu.CLICK_EVENT, PsychUIBox.CLICK_EVENT:
				ignoreClickForThisFrame = true;
		}
	}

	override function closeSubState()
	{
		ClientPrefs.toggleVolumeKeys(true);
		super.closeSubState();
		FlxG.mouse.visible = !mobile();
		syncBoxes();
	}

	function switchTab(i:Int)
	{
		if (i < 0 || i >= TAB_NAMES.length || i == tab)
			return;
		closeSheet();
		page = 0;
		sels[tab] = sel;
		panes[tab].clear();
		tab = i;
		layout = layouts[tab];
		sel = Std.int(Math.min(sels[tab], objCount() - 1));
		capturingKey = false;
		dragging = false;
		showTrans = false;
		lastBeat = -1;
		pane = panes[tab];
		refreshBackgrounds();
		pendCanvas = pendPanel = true;
	}

	function objCount():Int
		return layout.items.length + layout.decor.length;

	function isDecor(i:Int):Bool
		return i >= layout.items.length;

	function obj(i:Int):MenuItemProps
	{
		if (i < 0 || i >= objCount())
			return null;
		return (i < layout.items.length) ? layout.items[i] : layout.decor[i - layout.items.length];
	}

	function curObj():MenuItemProps
		return obj(sel);

	function curSprite():FlxSprite
		return (sel >= 0 && sel < sprites.length) ? sprites[sel] : null;

	function isOn(p:MenuItemProps):Bool
		return p.enabled != false;

	function prettyName(n:String):String
	{
		if (n == 'enter' && isTitle())
			return 'Press Enter';
		n = n.replace('_', ' ');
		return n.charAt(0).toUpperCase() + n.substr(1);
	}

	function addAnimAny(spr:FlxSprite, anim:String, prefixes:Array<String>)
	{
		for (p in prefixes)
		{
			spr.animation.addByPrefix(anim, p, 24, true);
			if (spr.animation.exists(anim))
				return;
		}
	}

	function textFallback(label:String):FlxText
	{
		var t = new FlxText(0, 0, 0, label, 48);
		t.setFormat(Paths.font('vcr.ttf'), 48, 0xFFBF55EC, LEFT, OUTLINE, 0xFF2A0A33);
		t.borderSize = 3;
		return t;
	}

	function makeButtonSprite(p:MenuItemProps):FlxSprite
	{
		if (isTitle())
			return makeTitleSprite(p);
		var an = MenuLayoutIO.atlasName(p.name);
		var frames = MenuFx.loadAtlas('mainmenu/menu_' + an);
		if (frames == null)
			return textFallback(p.name.toUpperCase());
		var spr = new FlxSprite();
		spr.frames = frames;
		spr.antialiasing = ClientPrefs.data.antialiasing;
		addAnimAny(spr, 'idle', [an + ' basic', 'menu_' + an + ' idle']);
		if (spr.animation.exists('idle'))
			spr.animation.play('idle');
		else
			spr.animation.frameIndex = 0;
		MenuFx.setupAnims(spr, p, an);
		return spr;
	}

	function makeTitleSprite(p:MenuItemProps):FlxSprite
	{
		var spr:FlxSprite = null;
		if (p.name == 'logo')
		{
			var g = MenuFx.loadImage('titleLogo');
			if (g != null)
				spr = new FlxSprite().loadGraphic(g);
		}
		else
		{
			var frames = MenuFx.loadAtlas('titleEnter');
			if (frames != null)
			{
				spr = new FlxSprite();
				spr.frames = frames;
				addAnimAny(spr, 'idle', ['ENTER IDLE', 'Press Enter to Begin']);
				if (spr.animation.exists('idle'))
					spr.animation.play('idle');
				else
					spr.animation.frameIndex = 0;
				MenuFx.setupAnims(spr, p, 'ENTER');
			}
		}
		if (spr == null)
			return textFallback(p.name == 'logo' ? 'LOGO' : 'PRESS ENTER');
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}

	function buildCanvas()
	{
		for (g in [decorBack, btnGroup, decorFront])
		{
			for (s in g.members)
				if (s != null)
				{
					FlxTween.cancelTweensOf(s);
					FlxTween.cancelTweensOf(s.scale);
					s.destroy();
				}
			g.clear();
		}
		sprites = [];
		var back:Array<Int> = [];
		var mid:Array<Int> = [];
		var front:Array<Int> = [];
		for (i in 0...objCount())
		{
			var p = obj(i);
			var spr:FlxSprite;
			if (isDecor(i))
			{
				spr = MenuFx.makeDecor(p);
				if (p.front)
				{
					decorFront.add(spr);
					front.push(i);
				}
				else
				{
					decorBack.add(spr);
					back.push(i);
				}
			}
			else
			{
				spr = makeButtonSprite(p);
				btnGroup.add(spr);
				mid.push(i);
			}
			spr.ID = i;
			sprites.push(spr);
		}
		hitOrder = back.concat(mid).concat(front);
		applyAll();
		selShown = false;
	}

	function previewChosen():String
	{
		var p = curObj();
		return (p != null && !isDecor(sel)) ? p.name : '';
	}

	function applyObj(i:Int)
	{
		if (i < 0 || i >= sprites.length || sprites[i] == null)
			return;
		var p = obj(i);
		if (p == null)
			return;
		var s = sprites[i];
		if (isDecor(i))
		{
			MenuFx.place(s, p);
			var hit = showTrans && MenuFx.matchesTrigger(p, previewChosen());
			if (p.appear == 'after')
				s.alpha = hit ? 1 : 0.4;
			else if (p.appear == 'before' && hit)
				s.alpha = 0.15;
		}
		else
		{
			s.scale.set(p.scaleX * layout.globalScale, p.scaleY * layout.globalScale);
			s.updateHitbox();
			s.setPosition(p.x, p.y);
			s.angle = 0;
			s.alpha = 1;
		}
		if (!isOn(p))
			s.alpha = 0.25;
	}

	function applyAll()
	{
		for (i in 0...sprites.length)
			applyObj(i);
	}

	function refreshBackgrounds()
	{
		var title = isTitle();
		if (!MenuFx.applyBackground(menuBgSpr, layout, false, title ? 1.0 : MenuFx.BG_SCALE))
		{
			if (title)
			{

				menuBgSpr.makeGraphic(1, 1, FlxColor.BLACK);
				menuBgSpr.scale.set(FlxG.width, FlxG.height);
				menuBgSpr.updateHitbox();
				menuBgSpr.setPosition(0, 0);
			}
			else
			{
				var g = Paths.image('menuBG');
				if (g == null)
					g = Paths.image('menuDesat');
				if (g != null)
				{
					menuBgSpr.loadGraphic(g);
					menuBgSpr.antialiasing = ClientPrefs.data.antialiasing;
					menuBgSpr.setGraphicSize(Std.int(menuBgSpr.width * MenuFx.BG_SCALE));
					menuBgSpr.updateHitbox();
					menuBgSpr.screenCenter();
				}
				else
				{
					menuBgSpr.makeGraphic(1, 1, 0xFF303030);
					menuBgSpr.scale.set(FlxG.width, FlxG.height);
					menuBgSpr.updateHitbox();
					menuBgSpr.setPosition(0, 0);
				}
			}
		}
		menuBgSpr.alpha = layout.backgroundAlpha;
		transSpr.visible = !title;
		if (title || !MenuFx.applyBackground(transSpr, layout, true))
			transSpr.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		transSpr.alpha = showTrans ? 1 : 0;
	}

	function updateSelection()
	{
		var s = curSprite();
		var show = (s != null && uiVisible);
		if (!show)
		{
			if (selShown || selEdges[0].visible)
				for (e in selEdges)
					e.visible = false;
			selShown = false;
			return;
		}

		if (selShown && selCache[0] == s.x && selCache[1] == s.y && selCache[2] == s.width && selCache[3] == s.height)
			return;
		selShown = true;
		selCache = [s.x, s.y, s.width, s.height];
		var x = s.x - 3;
		var y = s.y - 3;
		var w = s.width + 6;
		var h = s.height + 6;
		var edge = [[x, y, w, 2.0], [x, y + h - 2, w, 2.0], [x, y, 2.0, h], [x + w - 2, y, 2.0, h]];
		for (i in 0...4)
		{
			var e = selEdges[i];
			e.visible = true;
			e.scale.set(edge[i][2], edge[i][3]);
			e.updateHitbox();
			e.setPosition(edge[i][0], edge[i][1]);
		}
	}

	function selectObj(i:Int)
	{
		if (i < 0 || i >= objCount() || i == sel)
			return;
		sel = i;
		page = 0;
		capturingKey = false;
		selShown = false;
		pendPanel = true;
		if (showTrans)
			applyAll();
	}

	function edited()
	{
		dirtyTabs[tab] = true;
		if (!restoring)
			histTimer = 0.45;
	}

	function addDecor(sparrow:Bool)
	{
		if (layout.decor.length >= MAX_DECOR)
		{
			showOutput('Up to ' + MAX_DECOR + ' custom pictures.', true);
			return;
		}
		layout.decor.push(MenuLayoutIO.makeDecor((sparrow ? 'atlas' : 'image') + (layout.decor.length + 1), sparrow));
		sel = objCount() - 1;
		edited();
		pendCanvas = pendPanel = true;
	}

	function removeObj(i:Int)
	{
		if (!isDecor(i))
		{
			showOutput('Buttons cannot be removed: untick "Show" instead.', true);
			return;
		}
		var p = obj(i);
		if (p == null)
			return;
		var hadFile = MenuLayoutIO.hasText(p.image);
		queueDelete(p.image);
		layout.decor.splice(i - layout.items.length, 1);
		if (sel >= objCount())
			sel = objCount() - 1;
		edited();
		pendCanvas = pendPanel = true;
		if (hadFile)
			showOutput('Removed. The image file is deleted from images/menulayout when you save.');
	}

	function moveButton(i:Int, dir:Int)
	{
		var j = i + dir;
		if (isDecor(i) || j < 0 || j >= layout.items.length)
			return;
		var t = layout.items[i];
		layout.items[i] = layout.items[j];
		layout.items[j] = t;
		sel = j;
		edited();
		pendCanvas = pendPanel = true;
	}

	function nudge(dx:Float, dy:Float)
	{
		var p = curObj();
		if (p == null)
			return;
		p.x += dx;
		p.y += dy;
		applyObj(sel);
		edited();
		syncSelected();
	}

	function syncSelected()
	{
		var p = curObj();
		if (p == null || stX == null)
			return;
		uiSuppress = true;
		stX.value = FlxMath.roundDecimal(p.x, 1);
		stY.value = FlxMath.roundDecimal(p.y, 1);
		stSc.value = FlxMath.roundDecimal(p.scaleX, 2);
		uiSuppress = false;
	}

	function handleKeyCapture()
	{
		if (FlxG.keys.justPressed.ESCAPE)
		{
			capturingKey = false;
			pendPanel = true;
			return;
		}
		var k = FlxG.keys.firstJustPressed();
		if (k == FlxKey.NONE)
			return;
		var name = FlxKey.toStringMap.get(k);
		if (name == null)
			return;
		capturingKey = false;
		pendPanel = true;
		if (captureForUi)
		{
			captureForUi = false;
			setUiKey(k);
			return;
		}
		var p = curObj();
		if (p == null)
			return;
		p.key = name;
		edited();
		showOutput(name + ' now opens ' + p.name);
	}

	function ensureDir(path:String)
	{
		var cur = path.startsWith('/') ? '/' : '';
		for (part in path.split('/'))
		{
			if (part == '')
				continue;
			cur += ((cur == '' || cur.endsWith('/')) ? '' : '/') + part;
			if (!FileSystem.exists(cur))
				FileSystem.createDirectory(cur);
		}
	}

	function importPng(src:String):String
	{
		src = src.replace('\\', '/');
		var file = src.substr(src.lastIndexOf('/') + 1);
		var base = file.substr(0, file.length - 4);
		var srcDir = src.substr(0, src.lastIndexOf('/') + 1);
		var srcXml = src.substr(0, src.length - 4) + '.xml';

		for (d in MenuFx.imageDirs())
		{
			var folder = d + MenuFx.IMPORT_FOLDER + '/';
			if (srcDir == folder || srcDir.endsWith('/' + folder))
				return MenuFx.IMPORT_FOLDER + '/' + base;
			if (srcDir == d || srcDir.endsWith('/' + d))
				return base;
		}

		var dir = MenuFx.imageDirs()[0] + MenuFx.IMPORT_FOLDER + '/';
		ensureDir(dir);
		var name = base;
		var n = 1;
		while (FileSystem.exists(dir + name + '.png') && FileSystem.stat(dir + name + '.png').size != FileSystem.stat(src).size)
			name = base + '_' + (n++);

		var rel = MenuFx.IMPORT_FOLDER + '/' + name;
		if (!FileSystem.exists(dir + name + '.png') && createdFiles.indexOf(rel) < 0)
			createdFiles.push(rel);
		File.copy(src, dir + name + '.png');
		if (FileSystem.exists(srcXml))
			File.copy(srcXml, dir + name + '.xml');
		return rel;
	}

	function importAudio(src:String, kind:String):String
	{
		src = src.replace('\\', '/');
		var file = src.substr(src.lastIndexOf('/') + 1);
		var base = file.substr(0, file.length - 4);
		var srcDir = src.substr(0, src.lastIndexOf('/') + 1);
		var root = MenuLayoutIO.modRoot() + kind + '/';
		var folder = root + MenuFx.IMPORT_FOLDER + '/';
		if (srcDir == folder || srcDir.endsWith('/' + folder))
			return MenuFx.IMPORT_FOLDER + '/' + base;
		if (srcDir == root || srcDir.endsWith('/' + root))
			return base;
		ensureDir(folder);
		var name = base;
		var n = 1;
		while (FileSystem.exists(folder + name + '.ogg') && FileSystem.stat(folder + name + '.ogg').size != FileSystem.stat(src).size)
			name = base + '_' + (n++);
		File.copy(src, folder + name + '.ogg');
		return MenuFx.IMPORT_FOLDER + '/' + name;
	}

	function pngDirs():Array<String>
	{
		var dirs:Array<String> = ['mods/menu_import/'];
		for (d in MenuFx.imageDirs())
		{
			dirs.push(d + MenuFx.IMPORT_FOLDER + '/');
			dirs.push(d);
		}
		return dirs;
	}

	function pickFile(exts:Array<String>, title:String, importer:String->String, dirs:Array<String>, onPicked:String->Void)
	{
		#if (windows || mac || linux)
		var fd = new lime.ui.FileDialog();
		pickDialog = fd;
		fd.onSelect.add(function(path:String)
		{
			pickDialog = null;
			try
			{
				var lower = path.toLowerCase();
				var ok = false;
				for (e in exts)
					if (lower.endsWith('.' + e))
						ok = true;
				if (!ok)
				{
					showOutput('Please choose a .' + exts.join(' / .') + ' file.', true);
					return;
				}
				var name = importer(path);
				onPicked(name);
				showOutput('Using ' + name);
			}
			catch (e:Dynamic)
			{
				showOutput('Could not copy the file: ' + e, true);
			}
		});
		fd.onCancel.add(function() pickDialog = null);
		fd.browse(OPEN, exts.join(';'), null, title);
		#else
		pickFileList(exts, title, importer, dirs, onPicked);
		#end
	}

	function pickPng(onPicked:String->Void)
		pickFile(['png'], 'Choose a PNG image', importPng, pngDirs(), onPicked);

	function pickAudio(kind:String, onPicked:String->Void)
		pickFile(['ogg'], 'Choose an OGG file', function(path:String) return importAudio(path, kind), [
			'mods/menu_import/',
			MenuLayoutIO.modRoot() + kind + '/' + MenuFx.IMPORT_FOLDER + '/',
			MenuLayoutIO.modRoot() + kind + '/'
		], onPicked);

	function pickPngList(onPicked:String->Void)
		pickFileList(['png'], 'Choose a PNG', importPng, pngDirs(), onPicked);

	function pickFileList(exts:Array<String>, title:String, importer:String->String, dirs:Array<String>, onPicked:String->Void)
	{
		var labels:Array<String> = [];
		var paths:Array<String> = [];
		try
		{
			ensureDir('mods/menu_import/');
		}
		catch (e:Dynamic) {}
		for (d in dirs)
		{
			try
			{
				if (!FileSystem.exists(d) || !FileSystem.isDirectory(d))
					continue;
				var names = FileSystem.readDirectory(d).filter(function(f:String)
				{
					var low = f.toLowerCase();
					for (e in exts)
						if (low.endsWith('.' + e))
							return true;
					return false;
				});
				names.sort(function(a:String, b:String) return (a.toLowerCase() < b.toLowerCase()) ? -1 : 1);
				for (f in names)
				{
					labels.push((d == 'mods/menu_import/' ? '[import] ' : '') + f);
					paths.push(d + f);
				}
			}
			catch (e:Dynamic) {}
		}
		if (labels.length == 0)
		{
			showOutput('No .' + exts.join(' / .') + ' file found. Copy it into mods/menu_import/ with your file manager first.', true);
			return;
		}
		var maxItems:Int = Std.int(Math.min(7, labels.length));
		var radioGrp:PsychUIRadioGroup = new PsychUIRadioGroup(0, 0, labels, 25, maxItems, false, 300);
		radioGrp.checked = 0;
		var hei:Float = radioGrp.height + 160;
		openSubState(new BasePrompt(460, hei, title, function(state:BasePrompt)
		{
			var close:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
			close.cameras = state.cameras;
			state.add(close);

			radioGrp.screenCenter(X);
			radioGrp.y = state.bg.y + 80;
			radioGrp.cameras = state.cameras;
			state.add(radioGrp);

			var ok:PsychUIButton = new PsychUIButton(0, radioGrp.y + radioGrp.height + 20, 'Use this file', function()
			{
				var idx = radioGrp.checked;
				state.close();
				if (idx < 0 || idx >= paths.length)
					return;
				try
				{
					var name = importer(paths[idx]);
					onPicked(name);
					showOutput('Using ' + name);
				}
				catch (e:Dynamic)
				{
					showOutput('Could not copy the file: ' + e, true);
				}
			});
			ok.screenCenter(X);
			ok.cameras = state.cameras;
			state.add(ok);
		}));
	}

	function pickBackground(enterBg:Bool)
	{
		pickPng(function(name:String)
		{
			if (enterBg)
			{
				queueDelete(layout.transBgImage);
				layout.transBgImage = name;
				showTrans = true;
			}
			else
			{
				queueDelete(layout.bgImage);
				layout.bgImage = name;
			}
			edited();
			refreshBackgrounds();
			pendPanel = true;
		});
	}

	function clearBackground(enterBg:Bool)
	{
		if (enterBg)
		{
			queueDelete(layout.transBgImage);
			layout.transBgImage = '';
		}
		else
		{
			queueDelete(layout.bgImage);
			layout.bgImage = '';
		}
		edited();
		refreshBackgrounds();
		pendPanel = true;
	}

	function pickPicture()
	{
		var p = curObj();
		if (p == null || !isDecor(sel))
			return;
		pickPng(function(name:String)
		{
			queueDelete(p.image);
			p.image = name;
			edited();
			pendCanvas = pendPanel = true;
		});
	}

	function queueDelete(name:String)
	{
		if (!MenuLayoutIO.hasText(name))
			return;
		name = StringTools.trim(name);
		if (pendingDelete.indexOf(name) < 0)
			pendingDelete.push(name);
	}

	function purgeImages(names:Array<String>, includeMemory:Bool):Int
	{
		if (names.length == 0)
			return 0;
		var used = MenuLayoutIO.usedOnDisk();
		if (includeMemory)
			for (l in layouts)
				MenuLayoutIO.imagesOf(l, used);
		var removed = 0;
		for (n in names)
			if (!used.exists(n) && !MenuLayoutIO.isProtectedImage(n))
				removed += MenuLayoutIO.deleteImageFiles(n);
		return removed;
	}

	function mobile():Bool
		return controls != null && controls.mobileC;

	function rowH():Int
		return mobile() ? 30 : 26;

	function ctlH():Int
		return mobile() ? 30 : 22;

	function lbl(x:Int, y:Int, text:String, size:Int = 12, w:Int = 280, color:FlxColor = FlxColor.WHITE):FlxText
	{
		var t = new FlxText(x, y, w, text, size);
		t.color = color;
		pane.add(t);
		return t;
	}

	function cap(x:Int, y:Int, text:String, w:Int = 285):FlxText
		return lbl(x, y, text, 10, w, 0xFF9A9A9A);

	function header(x:Int, y:Int, w:Int, text:String, size:Int = 16)
	{
		lbl(x, y, text, size, w);
		pane.add(new FlxSprite(x, y + size + 6).makeGraphic(w, 1, 0xFF606060));
	}

	function btn(x:Int, y:Int, label:String, cb:Void->Void, w:Int = 80, h:Int = 0):PsychUIButton
	{
		var b:PsychUIButton = new PsychUIButton(x, y, label, cb, w, (h > 0) ? h : ctlH());
		pane.add(b);
		return b;
	}

	function mark(b:PsychUIButton, on:Bool, color:Int = 0xFF2F6FB0)
	{
		if (b == null || !on)
			return;
		b.normalStyle.bgColor = color;
		b.normalStyle.textColor = FlxColor.WHITE;
	}

	function mkStep(x:Int, y:Int, label:String, val:Float, step:Float, min:Float, max:Float, dec:Int, onSet:Float->Void, wid:Int = 75):PsychUINumericStepper
	{
		lbl(x, y - 15, label, 10, wid + 30);
		var st:PsychUINumericStepper = new PsychUINumericStepper(x, y, step, val, min, max, dec, wid);
		st.onValueChange = function()
		{
			if (uiSuppress)
				return;
			onSet(st.value);
			applyObj(sel);
			edited();
			syncSelected();
		};
		pane.add(st);
		return st;
	}

	function valStep(x:Int, y:Int, label:String, val:Float, step:Float, min:Float, max:Float, dec:Int, wid:Int, onSet:Float->Void, dirty:Bool = true):PsychUINumericStepper
	{
		if (label != '')
			lbl(x, y - 15, label, 10, wid + 60);
		var st:PsychUINumericStepper = new PsychUINumericStepper(x, y, step, val, min, max, dec, wid);
		st.onValueChange = function()
		{
			if (uiSuppress)
				return;
			onSet(st.value);
			if (dirty)
				edited();
		};
		pane.add(st);
		return st;
	}

	function mkInput(x:Int, y:Int, w:Int, val:String, onSet:String->Void)
	{
		var inp:PsychUIInputText = new PsychUIInputText(x, y, w, (val == null) ? '' : val, 8);
		inp.onChange = function(old:String, cur:String)
		{
			if (!uiSuppress)
				onSet(cur);
		};
		pane.add(inp);
	}

	function mkDrop(x:Int, y:Int, w:Int, list:Array<String>, idx:Int, onPick:Int->Void)
	{
		dds.push({
			dd: new PsychUIDropDownMenu(x, y, list, function(id:Int, l:String)
			{
				if (!uiSuppress)
					onPick(id);
			}, w),
			y: y,
			idx: idx
		});
	}

	function mkCheck(x:Int, y:Int, text:String, w:Int, val:Bool, onSet:Bool->Void):PsychUICheckBox
	{
		var cb:PsychUICheckBox = null;
		cb = new PsychUICheckBox(x, y, text, w, function()
		{
			if (!uiSuppress && cb != null)
				onSet(cb.checked);
		});
		cb.checked = val;
		pane.add(cb);
		return cb;
	}

	function buildPanel()
	{
		pane.clear();
		uiSuppress = true;
		stX = stY = stSc = null;
		bpmInfo = null;
		dds = [];

		pane.add(new FlxSprite(LEFT_W + 8, 8).makeGraphic(1, 572, 0xFF4A4A4A));
		buildList();
		switch (page)
		{
			case 1:
				buildBackgroundPage();
			case 2:
				buildSettingsPage();
			default:
				buildObjectPage();
		}
		buildBottomBar();

		dds.sort(function(a, b) return b.y - a.y);
		for (o in dds)
		{
			pane.add(o.dd);
			o.dd.selectedIndex = o.idx;
		}
		uiSuppress = false;
	}

	function buildBottomBar()
	{
		var y = 590;
		pane.add(new FlxSprite(0, y - 6).makeGraphic(600, 1, 0xFF4A4A4A));
		btn(10, y, 'Undo', undo, 64);
		btn(78, y, 'Redo', redo, 64);
		var saveBtn:PsychUIButton = btn(RX, y, 'Save  (Ctrl+S)', saveLayout, 150);
		saveBtn.normalStyle.bgColor = FlxColor.GREEN;
		saveBtn.normalStyle.textColor = FlxColor.WHITE;
		btn(RX + 158, y, 'Exit', tryExit, 90);
		btn(RX + 254, y, 'Help', toggleHelp, 70);
	}

	function listRow(i:Int, y:Int, isItem:Bool)
	{
		var p = obj(i);
		if (p == null)
			return;
		var bh = rowH() - 2;
		var label = prettyName(p.name);
		var maxc = isItem ? 9 : 13;
		if (label.length > maxc)
			label = label.substr(0, maxc - 1) + '.';
		if (isItem)
		{
			var eye:PsychUIButton = btn(10, y, isOn(p) ? 'ON' : 'off', function()
			{
				p.enabled = !isOn(p);
				applyObj(i);
				edited();
				pendPanel = true;
			}, 34, bh);
			eye.normalStyle.bgColor = isOn(p) ? 0xFF2E7D32 : 0xFF444444;
			eye.normalStyle.textColor = FlxColor.WHITE;
		}
		var nameBtn:PsychUIButton = btn(isItem ? 48 : 10, y, label, function()
		{
			page = 0;
			if (i != sel)
				selectObj(i);
			pendPanel = true;
		}, isItem ? 94 : 132, bh);
		nameBtn.text.alignment = LEFT;
		nameBtn.normalStyle.textColor = isOn(p) ? FlxColor.WHITE : 0xFF777777;
		mark(nameBtn, i == sel && page == 0);
		if (isItem)
		{
			btn(146, y, '^', function() moveButton(i, -1), 24, bh);
			btn(174, y, 'v', function() moveButton(i, 1), 24, bh);
		}
		else
		{
			btn(146, y, 'Cp', function() duplicateObj(i), 24, bh);
			var rm:PsychUIButton = btn(174, y, 'X', function() removeObj(i), 24, bh);
			rm.normalStyle.bgColor = FlxColor.RED;
			rm.normalStyle.textColor = FlxColor.WHITE;
		}
	}

	function navButton(y:Int, label:String, target:Int)
	{
		var b:PsychUIButton = btn(10, y, label, function()
		{
			page = (page == target) ? 0 : target;
			pendPanel = true;
		}, LEFT_W - 10);
		mark(b, page == target);
	}

	function buildList()
	{
		var title = isTitle();
		var nb = layout.items.length;
		var rh = rowH();

		header(10, 6, LEFT_W - 10, title ? 'ELEMENTS' : 'BUTTONS', 14);
		var y = 32;
		for (i in 0...nb)
		{
			listRow(i, y, true);
			y += rh;
		}
		y += 6;
		header(10, y, LEFT_W - 10, 'PICTURES', 14);
		y += 26;
		if (layout.decor.length == 0)
		{
			cap(10, y, 'none yet - add one below', LEFT_W - 10);
			y += 18;
		}
		for (j in 0...layout.decor.length)
		{
			listRow(nb + j, y, false);
			y += rh;
		}
		y += 4;
		var half = Std.int((LEFT_W - 16) / 2);
		btn(10, y, '+ Image', function() addDecor(false), half);
		btn(10 + half + 6, y, '+ Sheet', function() addDecor(true), half);
		y += ctlH() + 10;
		navButton(y, 'Background', 1);
		y += ctlH() + 6;
		navButton(y, 'Settings', 2);
	}

	function objKind(p:MenuItemProps, decor:Bool, title:Bool):String
		return decor ? (p.sparrow ? 'Custom sparrow atlas' : 'Custom picture') : (title ? 'Title screen element' : 'Menu button');

	function buildObjectPage()
	{
		var p = curObj();
		if (p == null)
		{
			lbl(RX, 20, 'Nothing selected. Pick something in the list.', 14, RW);
			return;
		}
		var decor = isDecor(sel);
		var title = isTitle();
		var tw = Std.int((RW - 8) / 3);
		for (k in 0...3)
		{
			var b:PsychUIButton = btn(RX + k * (tw + 4), 6, OBJ_TABS[k], function()
			{
				objTab = k;
				pendPanel = true;
			}, tw);
			mark(b, k == objTab);
		}
		var y0 = 6 + ctlH() + 12;
		lbl(RX, y0, prettyName(p.name), 18, RW);
		cap(RX, y0 + 24, objKind(p, decor, title), RW);
		switch (objTab)
		{
			case 1:
				buildAnimateTab(p, decor, title, y0 + 48);
			case 2:
				buildEnterTab(p, decor, title, y0 + 48);
			default:
				buildPlaceTab(p, decor, title, y0 + 48);
		}
	}

	function buildPlaceTab(p:MenuItemProps, decor:Bool, title:Bool, y0:Int)
	{
		var sw = 100;
		var gap = 122;
		stX = mkStep(RX, y0 + 16, 'X:', p.x, 1, -3000, 4000, 1, function(v) p.x = v, sw);
		stY = mkStep(RX + gap, y0 + 16, 'Y:', p.y, 1, -3000, 4000, 1, function(v) p.y = v, sw);
		stSc = mkStep(RX + gap * 2, y0 + 16, 'Scale:', p.scaleX, 0.01, 0.05, 8, 2, function(v)
		{
			p.scaleX = v;
			p.scaleY = v;
		}, sw);
		var y = y0 + 16 + ctlH() + 12;
		var bw = Std.int((RW - 12) / 3);
		btn(RX, y, 'Center X', function() centerSelected(true, false), bw);
		btn(RX + bw + 6, y, 'Center Y', function() centerSelected(false, true), bw);
		btn(RX + (bw + 6) * 2, y, 'Reset scale', resetScale, bw);
		y += ctlH() + 14;

		if (!decor)
		{
			mkCheck(RX, y, 'Visible', RW, isOn(p), function(v)
			{
				p.enabled = v;
				applyObj(sel);
				edited();
				pendPanel = true;
			});
			y += 30;
		}
		mkCheck(RX, y, decor ? 'Hide when another state is entered' : (title ? 'Fade out when Enter is pressed' : 'Hide when another button is chosen'), RW, p.hideOnEnter, function(v)
		{
			p.hideOnEnter = v;
			edited();
		});
		y += 34;

		if (decor)
		{
			btn(RX, y, 'Choose PNG...', pickPicture, 150);
			cap(RX + 160, y + 4, MenuLayoutIO.hasText(p.image) ? p.image + '.png' : 'no image', RW - 160);
			y += ctlH() + 10;
			mkCheck(RX, y, 'Sparrow atlas (.png + .xml)', RW, p.sparrow, function(v)
			{
				p.sparrow = v;
				edited();
				pendCanvas = pendPanel = true;
			});
			y += 30;
			if (p.sparrow)
			{
				lbl(RX, y, 'Animation name (prefix):', 11, 220);
				lbl(RX + 230, y, 'FPS:', 11, 90);
				mkInput(RX, y + 15, 220, p.anim, function(s)
				{
					p.anim = s;
					edited();
					canvasTimer = 0.5;
				});
				valStep(RX + 230, y + 15, '', p.fps, 1, 1, 120, 0, 90, function(v)
				{
					p.fps = v;
					canvasTimer = 0.4;
				});
				y += 15 + ctlH() + 10;
				mkCheck(RX, y, 'Loop', 120, p.loop, function(v)
				{
					p.loop = v;
					edited();
					canvasTimer = 0.2;
				});
				y += 30;
			}
			mkCheck(RX, y, 'Front layer (drawn above the buttons)', RW, p.front, function(v)
			{
				p.front = v;
				edited();
				pendCanvas = true;
			});
		}
		else if (!title)
		{
			lbl(RX, y, mobile() ? 'Key bind (needs a keyboard):' : 'Key bind:', 11, RW);
			y += 16;
			if (capturingKey && !captureForUi)
				lbl(RX, y + 4, 'Press a key...  (Esc cancels)', 13, RW, 0xFF00FF66);
			else
			{
				lbl(RX, y + 4, MenuLayoutIO.hasText(p.key) ? p.key : '(none)', 14, 120);
				btn(RX + 130, y, 'Set', function()
				{
					capturingKey = true;
					captureForUi = false;
					pendPanel = true;
				}, 90);
				btn(RX + 226, y, 'Clear', function()
				{
					p.key = '';
					edited();
					pendPanel = true;
				}, 90);
			}
		}
	}

	function buildAnimateTab(p:MenuItemProps, decor:Bool, title:Bool, y0:Int)
	{
		var y = y0;
		var ddw = 170;
		lbl(RX, y, 'Beat hit animation:', 12, RW);
		var by = y + 16;
		if (p.beatAnim == 'sparrow')
		{
			lbl(RX + ddw + 10, y, 'Animation name:', 11, RW - ddw - 10);
			mkInput(RX + ddw + 10, by, RW - ddw - 10, p.beatPrefix, function(s)
			{
				p.beatPrefix = s;
				edited();
				canvasTimer = 0.5;
			});
		}
		mkDrop(RX, by, ddw, MenuFx.BEAT_NAMES, Std.int(Math.max(0, MenuFx.BEAT_IDS.indexOf(p.beatAnim))), function(id)
		{
			p.beatAnim = MenuFx.BEAT_IDS[id];
			edited();
			pendCanvas = pendPanel = true;
		});
		y = by + 50;

		var atlasEnter:Bool = (!decor && !title) || (decor && p.sparrow) || (title && p.name == 'enter');
		if (!decor && !title)
		{
			lbl(RX, y, 'Enter animation:', 12, RW);
			var ey = y + 16;
			lbl(RX + ddw + 10, y, 'Enter anim (atlas):', 11, RW - ddw - 10);
			mkInput(RX + ddw + 10, ey, RW - ddw - 10, p.enterPrefix, function(s)
			{
				p.enterPrefix = s;
				edited();
				canvasTimer = 0.5;
			});
			mkDrop(RX, ey, ddw, MenuFx.ENTER_NAMES, Std.int(Math.max(0, MenuFx.ENTER_IDS.indexOf(p.enterAnim))), function(id)
			{
				p.enterAnim = MenuFx.ENTER_IDS[id];
				edited();
				pendCanvas = pendPanel = true;
			});
			y = ey + 50;
		}
		else if (atlasEnter)
		{
			lbl(RX, y, 'Enter anim (atlas):', 12, RW);
			mkInput(RX, y + 16, 240, p.enterPrefix, function(s)
			{
				p.enterPrefix = s;
				edited();
				canvasTimer = 0.5;
			});
			y += 50;
		}
		cap(RX, y, (decor ? 'Animations of an atlas: names are prefixes from its .xml.' : (title ? 'The logo and the text already have their own animations.' : 'The enter animation plays on the chosen button.')) + (atlasEnter ? ' Enter anim empty = nothing is played, so the beat hit animation keeps running.' : ''), RW);
	}

	function pickSoundFor(p:MenuItemProps)
		pickAudio('sounds', function(n:String)
		{
			p.enterSound = n;
			edited();
			pendPanel = true;
		});

	function pickMusicFor(p:MenuItemProps)
		pickAudio('music', function(n:String)
		{
			p.enterMusic = n;
			edited();
			pendPanel = true;
		});

	function buildEnterTab(p:MenuItemProps, decor:Bool, title:Bool, y0:Int)
	{
		var y = y0;
		if (decor)
		{
			lbl(RX, y, 'Character swap - when is this picture visible?', 12, RW);
			var cur = Std.int(Math.max(0, MenuFx.APPEAR_IDS.indexOf(p.appear)));
			mkDrop(RX, y + 16, 220, MenuFx.APPEAR_NAMES, cur, function(id)
			{
				p.appear = MenuFx.APPEAR_IDS[id];
				edited();
				applyAll();
				pendPanel = true;
			});
			y += 56;
			if (p.appear != 'always')
			{
				lbl(RX, y, 'Changes when this is chosen:', 12, RW);
				var names:Array<String> = [title ? 'Enter pressed' : 'Any button'];
				var ids:Array<String> = [''];
				for (it in layout.items)
				{
					names.push(prettyName(it.name));
					ids.push(it.name);
				}
				var at = ids.indexOf(p.appearOn);
				mkDrop(RX, y + 16, 220, names, (at < 0) ? 0 : at, function(id)
				{
					p.appearOn = ids[id];
					edited();
					applyAll();
				});
				y += 56;
			}
			cap(RX, y, 'Make one character "Only before Enter" and another one "Only after Enter" with the same trigger: the character changes when that button is chosen. Use "Preview" on the Background page to see it here.', RW);
			return;
		}

		lbl(RX, y, 'Sound when chosen (empty = the default sound):', 11, RW);
		mkInput(RX, y + 16, RW - 176, p.enterSound, function(s)
		{
			p.enterSound = s;
			edited();
		});
		btn(RX + RW - 170, y + 14, 'Pick...', function() pickSoundFor(p), 82);
		btn(RX + RW - 84, y + 14, 'Test', function() testSound(p), 82);
		y += 16 + ctlH() + 24;
		valStep(RX, y, 'Sound volume:', p.enterSoundVol, 0.05, 0, 1, 2, 100, function(v) p.enterSoundVol = v);
		y += ctlH() + 24;

		lbl(RX, y, 'Music when chosen (empty = keep playing):', 11, RW);
		mkInput(RX, y + 16, RW - 176, p.enterMusic, function(s)
		{
			p.enterMusic = s;
			edited();
		});
		btn(RX + RW - 170, y + 14, 'Pick...', function() pickMusicFor(p), 82);
		btn(RX + RW - 84, y + 14, 'Test', function() testMusic(p), 82);
		y += 16 + ctlH() + 24;
		valStep(RX, y, 'Music volume:', p.enterMusicVol, 0.05, 0, 1, 2, 100, function(v) p.enterMusicVol = v);
		mkCheck(RX + 130, y, 'Stop the menu music', RW - 130, p.enterMusicStop, function(v)
		{
			p.enterMusicStop = v;
			edited();
		});
		y += ctlH() + 14;
		btn(RX, y, 'Back to the menu music', restoreMenuMusic, 190);
		y += ctlH() + 12;
		cap(RX, y, 'Files go to sounds/menulayout and music/menulayout (.ogg), the name is what Paths.sound / Paths.music load. Custom music replaces the music that is playing.', RW);
	}

	function bgBlock(y:Int, title:String, current:String, emptyText:String, enterBg:Bool):Int
	{
		lbl(RX, y, title, 13, RW);
		var by = y + 18;
		var sheet:Bool = enterBg ? (layout.transBgSparrow == true) : (layout.bgSparrow == true);
		btn(RX, by, 'Choose...', function() pickBackground(enterBg), 130);
		btn(RX + 136, by, 'Clear', function() clearBackground(enterBg), 80);
		btn(RX + 222, by, 'Sheet...', function() openSheet(enterBg), 100);
		cap(RX, by + ctlH() + 4, MenuLayoutIO.hasText(current) ? current + '.png' + (sheet ? '  [sheet]' : '') : emptyText, RW);
		return by + ctlH() + 26;
	}

	function buildBackgroundPage()
	{
		var title = isTitle();
		lbl(RX, 8, 'BACKGROUND', 18, RW);
		var y = 44;
		y = bgBlock(y, title ? 'Background' : 'Main background', layout.bgImage, 'default (the game background)', false);
		if (!title)
			y = bgBlock(y + 6, 'Enter background (fades in when a button is chosen)', layout.transBgImage, 'none', true);
		valStep(RX, y + 20, 'Background opacity:', layout.backgroundAlpha, 0.05, 0, 1, 2, 110, function(v)
		{
			layout.backgroundAlpha = v;
			menuBgSpr.alpha = v;
		});
		y += 20 + ctlH() + 18;
		if (!title)
		{
			mkCheck(RX, y, 'Preview "after Enter" (enter background, characters)', RW, showTrans, function(v)
			{
				showTrans = v;
				setTransPreview(v);
			});
			y += 32;
		}
		cap(RX, y, 'Pictures are copied to images/menulayout (the folder is created when needed).', RW);
	}

	function updateBpmInfo()
	{
		if (bpmInfo != null)
			bpmInfo.text = '1 beat = ' + Std.int(60000 / MenuLayoutIO.bpmOf(layout, isTitle() ? MenuFx.TITLE_BPM : MenuFx.BPM)) + ' ms';
	}

	function buildSettingsPage()
	{
		var title = isTitle();
		lbl(RX, 8, 'SETTINGS', 18, RW);
		var y = 56;
		valStep(RX, y, title ? 'Element scale:' : 'Button scale:', layout.globalScale, 0.01, 0.2, 3, 2, 100, function(v)
		{
			layout.globalScale = v;
			applyAll();
		});
		valStep(RX + 130, y, 'Snap to grid (px, 0 = off):', snapSize, 1, 0, 100, 0, 100, function(v)
		{
			snapSize = Std.int(v);
			FlxG.save.data.menuEditorSnap = snapSize;
			FlxG.save.flush();
		}, false);
		y += ctlH() + 34;

		var defBpm:Float = title ? MenuFx.TITLE_BPM : MenuFx.BPM;
		valStep(RX, y, 'BPM:', MenuLayoutIO.bpmOf(layout, defBpm), 1, 20, 400, 1, 100, function(v)
		{
			layout.bpm = v;
			updateBpmInfo();
		});
		btn(RX + 130, y, 'Default (' + defBpm + ')', function()
		{
			layout.bpm = defBpm;
			edited();
			pendPanel = true;
		}, 130);
		bpmInfo = cap(RX, y + ctlH() + 4, '', RW);
		updateBpmInfo();
		cap(RX, y + ctlH() + 20, 'BPM should match the music (' + (title ? 'the title screen' : 'freakyMenu') + ' uses ' + defBpm + '). Beat animations are timed with it.', RW);
		y += ctlH() + 58;

		if (!title)
		{
			mkCheck(RX, y, 'Use these button positions on phones', RW, layout.mobilePositions != false, function(v)
			{
				layout.mobilePositions = v;
				edited();
			});
			cap(RX, y + 24, 'Off = phones keep their grid of buttons (the rest of the layout still applies).', RW);
			y += 52;
		}

		if (mobile())
			lbl(RX, y, 'Touch button C hides / shows the UI.', 11, RW);
		else
		{
			lbl(RX, y + 4, 'Hide UI key:', 11, 90);
			if (capturingKey && captureForUi)
				lbl(RX + 95, y + 4, 'Press a key... (Esc cancels)', 11, 250, 0xFF00FF66);
			else
			{
				lbl(RX + 95, y + 2, keyName(uiKey), 14, 110);
				btn(RX + 215, y, 'Change', function()
				{
					capturingKey = true;
					captureForUi = true;
					pendPanel = true;
				}, 100);
			}
		}
		y += ctlH() + 28;
		btn(RX, y, 'Revert all unsaved changes...', function() openSubState(new Prompt('Discard every unsaved change?', revertAll)), 220);
	}

	function snapTo(v:Float):Float
		return (snapSize > 1) ? Math.round(v / snapSize) * snapSize : v;

	function centerSelected(cx:Bool, cy:Bool)
	{
		var p = curObj();
		var s = curSprite();
		if (p == null || s == null)
			return;
		if (cx)
			p.x = (FlxG.width - s.width) / 2;
		if (cy)
			p.y = (FlxG.height - s.height) / 2;
		applyObj(sel);
		edited();
		syncSelected();
	}

	function resetScale()
	{
		var p = curObj();
		if (p == null)
			return;
		var v:Float = (isDecor(sel) || isTitle()) ? 1 : 0.8;
		p.scaleX = v;
		p.scaleY = v;
		applyObj(sel);
		edited();
		pendPanel = true;
	}

	function duplicateObj(i:Int)
	{
		var src = obj(i);
		if (src == null || !isDecor(i))
			return;
		if (layout.decor.length >= MAX_DECOR)
		{
			showOutput('Up to ' + MAX_DECOR + ' custom pictures.', true);
			return;
		}
		var c:MenuItemProps = cast Reflect.copy(src);
		var prefix = (src.sparrow == true) ? 'atlas' : 'image';
		var n = layout.decor.length + 1;
		var taken = function(name:String):Bool
		{
			for (d in layout.decor)
				if (d.name == name)
					return true;
			return false;
		};
		while (taken(prefix + n))
			n++;
		c.name = prefix + n;
		c.x += 30;
		c.y += 30;
		layout.decor.push(c);
		sel = objCount() - 1;
		edited();
		pendCanvas = pendPanel = true;
	}

	function testSound(p:MenuItemProps)
	{
		if (p == null)
			return;
		if (!MenuLayoutIO.hasText(p.enterSound))
		{
			showOutput('Nothing to test: the default confirm sound is used.');
			return;
		}
		MenuFx.playSound(p.enterSound, p.enterSoundVol);
	}

	function testMusic(p:MenuItemProps)
	{
		if (p == null)
			return;
		if (!MenuLayoutIO.hasText(p.enterMusic))
		{
			showOutput('No music chosen.');
			return;
		}
		if (MenuFx.playMusic(p.enterMusic, p.enterMusicVol))
			musicChanged = true;
		else
			showOutput('Music "' + p.enterMusic + '" was not found.', true);
	}

	function restoreMenuMusic()
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
		musicChanged = false;
	}

	function snapshot():String
		return Json.stringify([MenuLayoutIO.toSave(layouts[0], false), MenuLayoutIO.toSave(layouts[1], true)]);

	function pushHistory()
	{
		var s = snapshot();
		if (histIdx >= 0 && layoutHistory[histIdx] == s)
			return;
		layoutHistory = layoutHistory.slice(0, histIdx + 1);
		layoutHistory.push(s);
		if (layoutHistory.length > 40)
			layoutHistory.shift();
		histIdx = layoutHistory.length - 1;
	}

	function restoreHistory()
	{
		var arr:Array<Dynamic> = Json.parse(layoutHistory[histIdx]);
		restoring = true;
		layouts[0] = MenuLayoutIO.normalize(cast arr[0], false);
		layouts[1] = MenuLayoutIO.normalize(cast arr[1], true);
		layout = layouts[tab];
		sel = Std.int(Math.max(0, Math.min(sel, objCount() - 1)));
		dirtyTabs[0] = dirtyTabs[1] = true;
		histTimer = -1;
		closeSheet();
		refreshBackgrounds();
		pendCanvas = pendPanel = true;
		restoring = false;
	}

	function undo()
	{
		if (histTimer >= 0)
		{
			histTimer = -1;
			pushHistory();
		}
		if (histIdx <= 0)
		{
			showOutput('Nothing to undo.');
			return;
		}
		histIdx--;
		restoreHistory();
		showOutput('Undone.');
	}

	function redo()
	{
		if (histIdx < 0 || histIdx >= layoutHistory.length - 1)
		{
			showOutput('Nothing to redo.');
			return;
		}
		histIdx++;
		restoreHistory();
		showOutput('Redone.');
	}

	function revertAll()
	{
		layouts[0] = MenuLayoutIO.loadFile();
		if (layouts[0] == null)
			layouts[0] = MenuLayoutIO.makeDefault();
		layouts[1] = MenuLayoutIO.loadTitle();
		if (layouts[1] == null)
			layouts[1] = MenuLayoutIO.makeDefaultTitle();
		layout = layouts[tab];
		sel = Std.int(Math.max(0, Math.min(sel, objCount() - 1)));
		dirtyTabs = [false, false];
		pendingDelete = [];
		layoutHistory = [];
		histIdx = -1;
		histTimer = -1;
		pushHistory();
		closeSheet();
		refreshBackgrounds();
		pendCanvas = pendPanel = true;
		showOutput('Everything is back to the saved version.');
	}

	function saveLayout()
	{

		var list:Array<Int> = [for (i in 0...layouts.length) if (dirtyTabs[i]) i];
		if (list.length == 0)
			list = [tab];
		var saved:Array<String> = [];
		try
		{
			for (i in list)
			{
				var path = MenuLayoutIO.savePath(i == 1 ? MenuLayoutIO.TITLE_FILE : MenuLayoutIO.MENU_FILE);
				ensureDir(path.substr(0, path.lastIndexOf('/') + 1));
				File.saveContent(path, Json.stringify(MenuLayoutIO.toSave(layouts[i], i == 1), null, '\t'));
				dirtyTabs[i] = false;
				saved.push(path);
			}
		}
		catch (e:Dynamic)
		{
			showOutput('Save failed (check storage permissions): ' + e, true);
			return;
		}

		var removed = 0;
		try
		{
			removed = purgeImages(pendingDelete, true);
		}
		catch (e:Dynamic) {}
		pendingDelete = [];
		FlxG.sound.play(Paths.sound('confirmMenu'));
		showOutput('Saved: ' + saved.join(', ') + (removed > 0 ? '  |  deleted ' + removed + ' unused image file(s)' : ''));
	}

	function overBox():Bool
	{
		if (!uiVisible || !box.visible)
			return false;
		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;
		if (sheetBox.visible && mx >= sheetBox.x && mx <= sheetBox.x + sheetBox.width && my >= sheetBox.y && my <= sheetBox.y + sheetBox.height)
			return true;
		return mx >= box.x && mx <= box.x + box.width && my >= box.y && my <= box.y + box.height;
	}

	function objAt(mx:Float, my:Float):Int
	{
		var k = hitOrder.length - 1;
		while (k >= 0)
		{
			var i = hitOrder[k];
			var s = (i < sprites.length) ? sprites[i] : null;
			if (s != null && mx >= s.x && mx <= s.x + s.width && my >= s.y && my <= s.y + s.height)
				return i;
			k--;
		}
		return -1;
	}

	function handleMouse()
	{
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;
		var overUi = overBox();
		var blocked = ignoreClickForThisFrame || overUi || fullTipText.visible || capturingKey || padBusy();

		if (FlxG.mouse.justPressed && !overUi && !ignoreClickForThisFrame)
		{
			mouseLock = true;
			padPress = padBusy();
		}

		if (FlxG.mouse.justPressed && !blocked)
		{
			var hit = objAt(mx, my);
			if (hit >= 0)
			{
				selectObj(hit);
				var s = curSprite();
				if (s != null)
				{
					dragging = true;
					dragOffX = mx - s.x;
					dragOffY = my - s.y;
				}
			}
		}
		if (dragging && FlxG.mouse.pressed)
		{
			var p = curObj();
			if (p != null)
			{
				p.x = snapTo(mx - dragOffX);
				p.y = snapTo(my - dragOffY);
				applyObj(sel);
				edited();
				syncSelected();
			}
		}
		if (FlxG.mouse.justReleased)
			dragging = false;
	}

	function tickBeat(elapsed:Float)
	{
		if (dragging)
			return;
		var t:Float;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			t = FlxG.sound.music.time;
		else
		{
			beatClock += elapsed * 1000;
			t = beatClock;
		}
		var bpm:Float = MenuLayoutIO.bpmOf(layout, isTitle() ? MenuFx.TITLE_BPM : MenuFx.BPM);
		var b = Math.floor(t / (60000 / bpm));
		if (b == lastBeat)
			return;
		lastBeat = b;
		if (layout.bgSparrow == true && MenuLayoutIO.hasText(layout.bgBeat))
			MenuFx.playOnce(menuBgSpr, 'beat', 'main');
		for (i in 0...sprites.length)
		{
			var p = obj(i);
			if (p == null || !isOn(p) || p.beatAnim == 'none')
				continue;
			var g = isDecor(i) ? 1.0 : layout.globalScale;
			MenuFx.beat(sprites[i], p, p.scaleX * g, p.scaleY * g, b, isDecor(i) ? 'main' : 'idle');
		}
	}

	override function update(elapsed:Float)
	{
		syncBoxes();
		#if TOUCH_CONTROLS_ALLOWED
		if (mobile() && touchPad != null)
			touchPad.active = !(mouseLock && !padPress);
		#end

		var shown:String = box.selectedName;
		if (shown != null && shown != TAB_NAMES[tab])
			switchTab(TAB_NAMES.indexOf(shown));

		if (pendCanvas)
		{
			pendCanvas = false;
			buildCanvas();
		}
		if (pendPanel)
		{
			pendPanel = false;
			buildPanel();
		}
		if (pendSheet)
		{
			pendSheet = false;
			buildSheet();
		}
		ClientPrefs.toggleVolumeKeys(PsychUIInputText.focusOn == null);
		outputAlpha = Math.max(0, outputAlpha - elapsed);
		super.update(elapsed);

		if (canvasTimer >= 0)
		{
			canvasTimer -= elapsed;
			if (canvasTimer < 0)
				pendCanvas = true;
		}

		if (sheetTimer >= 0)
		{
			sheetTimer -= elapsed;
			if (sheetTimer < 0)
				refreshBackgrounds();
		}

		var typing:Bool = PsychUIInputText.focusOn != null;
		if (!typing)
			handleKeys();
		#if TOUCH_CONTROLS_ALLOWED
		if (!typing)
			handleTouchPad(elapsed);
		#end
		if (!typing || FlxG.mouse.justPressed)
			handleMouse();

		if (histTimer >= 0 && !FlxG.mouse.pressed)
		{
			histTimer -= elapsed;
			if (histTimer < 0)
				pushHistory();
		}

		tickBeat(elapsed);
		updateSelection();

		if (hintTimer > 0)
		{
			hintTimer -= elapsed;
			hideHint.alpha = Math.min(1, hintTimer);
		}
		else if (hideHint.alpha != 0)
			hideHint.alpha = 0;

		outputTxt.alpha = outputAlpha;
		outputTxt.visible = (outputAlpha > 0);
		ignoreClickForThisFrame = false;
		if (!FlxG.mouse.pressed)
			mouseLock = false;
	}

	function setTransPreview(v:Bool)
	{
		showTrans = v;
		applyAll();
		transSpr.alpha = v ? 1 : 0;
		if (v && layout.transBgSparrow == true && MenuLayoutIO.hasText(layout.transBgEnter))
			MenuFx.playOnce(transSpr, 'enter', '');
		else
			MenuFx.resetSheet(transSpr);
	}

	function openSheet(enterBg:Bool)
	{
		sheetFor = enterBg ? 1 : 0;
		syncBoxes();
		buildSheet();
	}

	function closeSheet()
	{
		sheetFor = -1;
		if (sheetPane != null)
			sheetPane.clear();
		if (sheetBox != null)
			sheetBox.visible = sheetBox.active = false;
		syncBoxes();
	}

	function buildSheet()
	{
		sheetPane.clear();
		if (sheetFor < 0)
			return;
		uiSuppress = true;
		var enterBg = (sheetFor == 1);
		var image:String = enterBg ? layout.transBgImage : layout.bgImage;
		var text = function(y:Int, str:String, size:Int = 12, color:FlxColor = FlxColor.WHITE)
		{
			var tx = new FlxText(10, y, 305, str, size);
			tx.color = color;
			sheetPane.add(tx);
		};
		var input = function(y:Int, val:String, onSet:String->Void)
		{
			var inp:PsychUIInputText = new PsychUIInputText(10, y, 300, val, 8);
			inp.onChange = function(old:String, cur:String)
			{
				if (uiSuppress)
					return;
				onSet(cur);
				edited();
				sheetTimer = 0.5;
			};
			sheetPane.add(inp);
		};
		text(8, enterBg ? 'ENTER BACKGROUND' : 'BACKGROUND', 16);
		text(32, MenuLayoutIO.hasText(image) ? image + '.png' : 'no image chosen yet', 10, 0xFF9A9A9A);

		var y = 60;
		if (!MenuLayoutIO.hasText(image))
		{
			text(y, 'Choose a background image first, then come back here.');
			y += 40;
		}
		else
		{
			var sheet:Bool = enterBg ? (layout.transBgSparrow == true) : (layout.bgSparrow == true);
			var cb:PsychUICheckBox = null;
			cb = new PsychUICheckBox(10, y, 'This background is a spritesheet (.png + .xml)', 300, function()
			{
				if (uiSuppress)
					return;
				if (enterBg)
					layout.transBgSparrow = cb.checked;
				else
					layout.bgSparrow = cb.checked;
				edited();
				refreshBackgrounds();
				pendSheet = true;
			});
			cb.checked = sheet;
			sheetPane.add(cb);
			y += 34;
			if (sheet)
			{
				text(y, 'Animation (loops):', 11);
				input(y + 15, enterBg ? layout.transBgAnim : layout.bgAnim, function(s)
				{
					if (enterBg)
						layout.transBgAnim = s;
					else
						layout.bgAnim = s;
				});
				y += 48;
				if (!enterBg)
				{
					text(y, 'Beat hit animation:', 11);
					input(y + 15, layout.bgBeat, function(s) layout.bgBeat = s);
					y += 48;
				}
				text(y, 'Enter anim:', 11);
				input(y + 15, enterBg ? layout.transBgEnter : layout.bgEnter, function(s)
				{
					if (enterBg)
						layout.transBgEnter = s;
					else
						layout.bgEnter = s;
				});
				y += 48;
				text(y, enterBg ? 'Plays when the enter background appears.' : 'Plays when another state is entered.', 10, 0xFF9A9A9A);
				text(y + 14, 'Leave Enter anim EMPTY and nothing is tried: the beat hit animation then keeps running.', 10, 0xFF9A9A9A);
				y += 44;
			}
		}
		sheetPane.add(new PsychUIButton(10, 300, 'Close', closeSheet, 100));
		uiSuppress = false;
	}

	function padBusy():Bool
	{
		#if TOUCH_CONTROLS_ALLOWED
		if (controls.mobileC && touchPad != null)
			return touchPad.buttonLeft.pressed || touchPad.buttonRight.pressed || touchPad.buttonUp.pressed || touchPad.buttonDown.pressed
				|| touchPad.buttonUp2.pressed || touchPad.buttonDown2.pressed || touchPad.buttonA.pressed || touchPad.buttonC.pressed
				|| touchPad.buttonD.pressed || touchPad.buttonF.pressed || touchPad.buttonG.pressed || touchPad.buttonV.pressed
				|| touchPad.buttonX.pressed || touchPad.buttonY.pressed || touchPad.buttonZ.pressed;
		#end
		return false;
	}

	#if TOUCH_CONTROLS_ALLOWED
	function handleTouchPad(elapsed:Float)
	{
		if (!controls.mobileC || touchPad == null)
			return;
		var tp = touchPad;

		if (tp.buttonF.justPressed)
		{
			toggleHelp();
			tp.forEachAlive(function(button:TouchButton)
			{
				if (button.tag != 'F')
					button.visible = !button.visible;
			});
			return;
		}
		if (fullTipText.visible)
			return;
		if (tp.buttonZ.justPressed)
		{
			tp.forEachAlive(function(button:TouchButton)
			{
				if (button.tag != 'Z' && button.tag != 'LEFT' && button.tag != 'RIGHT' && button.tag != 'UP' && button.tag != 'DOWN')
					tp.buttonUp2.visible = tp.buttonDown2.visible = button.visible = !button.visible;
			});
			return;
		}
		if (capturingKey)
			return;

		if (tp.buttonC.justPressed)
		{
			toggleUI();
			return;
		}
		if (tp.buttonA.justPressed)
			saveLayout();
		else if (tp.buttonV.justPressed)
		{
			tryExit();
			return;
		}
		else if (tp.buttonX.justPressed)
		{
			var p = curObj();
			if (p != null && !isDecor(sel) && !isTitle())
			{
				p.enabled = !isOn(p);
				applyObj(sel);
				edited();
				pendPanel = true;
			}
		}
		else if (tp.buttonD.justPressed)
			removeObj(sel);
		else if (tp.buttonG.justPressed && !isTitle())
		{
			showTrans = !showTrans;
			setTransPreview(showTrans);
			pendPanel = true;
		}
		else if (tp.buttonUp2.justPressed)
			selectObj((sel - 1 + objCount()) % Std.int(Math.max(1, objCount())));
		else if (tp.buttonDown2.justPressed)
			selectObj((sel + 1) % Std.int(Math.max(1, objCount())));

		var dx:Float = 0;
		var dy:Float = 0;
		if (tp.buttonLeft.justPressed)
			dx--;
		if (tp.buttonRight.justPressed)
			dx++;
		if (tp.buttonUp.justPressed)
			dy--;
		if (tp.buttonDown.justPressed)
			dy++;
		if (tp.buttonLeft.pressed || tp.buttonRight.pressed || tp.buttonUp.pressed || tp.buttonDown.pressed)
		{
			padHold += elapsed;
			if (padHold > 0.35)
			{
				padRepeat -= elapsed;
				if (padRepeat <= 0)
				{
					padRepeat = 0.04;
					if (tp.buttonLeft.pressed)
						dx--;
					if (tp.buttonRight.pressed)
						dx++;
					if (tp.buttonUp.pressed)
						dy--;
					if (tp.buttonDown.pressed)
						dy++;
				}
			}
		}
		else
		{
			padHold = 0;
			padRepeat = 0;
		}
		if (dx != 0 || dy != 0)
		{
			var m:Float = tp.buttonY.pressed ? 10 : 1;
			nudge(dx * m, dy * m);
		}
	}
	#end

	function handleKeys()
	{
		var jp = FlxG.keys.justPressed;
		if (capturingKey)
		{
			handleKeyCapture();
			return;
		}
		if (jp.F1)
		{
			toggleHelp();
			return;
		}
		if (fullTipText.visible)
		{
			if (jp.ESCAPE)
				toggleHelp();
			return;
		}
		if (FlxG.keys.checkStatus(uiKey, JUST_PRESSED))
		{
			toggleUI();
			return;
		}
		if (FlxG.keys.pressed.CONTROL)
		{
			if (jp.S)
				saveLayout();
			else if (jp.Z)
				undo();
			else if (jp.Y)
				redo();
			else if (jp.D)
				duplicateObj(sel);
			return;
		}
		if (jp.E)
		{
			var p = curObj();
			if (p != null && !isDecor(sel))
			{
				p.enabled = !isOn(p);
				applyObj(sel);
				edited();
				pendPanel = true;
			}
		}
		else if (jp.DELETE)
			removeObj(sel);
		else if (jp.ESCAPE #if mobile || FlxG.android.justPressed.BACK #end)
		{
			tryExit();
			return;
		}

		var m:Float = FlxG.keys.pressed.SHIFT ? 10 : 1;
		if (jp.LEFT)
			nudge(-m, 0);
		if (jp.RIGHT)
			nudge(m, 0);
		if (jp.UP)
			nudge(0, -m);
		if (jp.DOWN)
			nudge(0, m);
	}
}
