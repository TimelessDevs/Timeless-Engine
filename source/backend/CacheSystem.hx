package backend;

import openfl.utils.AssetCache;
import flixel.util.FlxStringUtil;
import flixel.system.FlxAssets;
import openfl.media.Sound;
import openfl.Assets;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.system.System;
import flixel.graphics.FlxGraphic;

typedef ImageLine =
{
	size:Int,
	text:String
};

@:access(openfl.display.BitmapData)
@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
class CacheSystem
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var currentTrackedSounds:Map<String, Sound> = new Map<String, Sound>();
	
	public static var localTrackedAssets:Map<String, Bool> = new Map<String, Bool>();
	public static var dumpExclusions:Array<String> = ['music/freakyMenu.${Paths.SOUND_EXT}'];

	private static var _pathCache:Map<String, String> = new Map<String, String>();

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static function clearUnusedMemory()
	{
		var purgedGraphics:Int = 0;

		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.exists(key) && !dumpExclusions.contains(key))
			{
				var lowerKey:String = key.toLowerCase();
				if (lowerKey.contains("images/characters") || lowerKey.contains("char") || lowerKey.contains("animate") || lowerKey.contains("animation"))
				{
					continue;
				}

				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if (graphic != null)
				{
					if (graphic.bitmap != null) {
						graphic.bitmap.dispose();
						#if !flash
						graphic.bitmap.disposeImage();
						#end
					}
					
					flixel.FlxG.bitmap.remove(graphic);
					graphic.destroy();
					purgedGraphics++;
				}
				currentTrackedAssets.remove(key);
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.exists(key) && !dumpExclusions.contains(key))
			{
				var snd:Sound = currentTrackedSounds.get(key);
				if (snd != null)
				{
					try {
						snd.close(); 
					} catch(e:Dynamic) {}
				}
				currentTrackedSounds.remove(key);
			}
		}

		try {
			openfl.utils.Assets.cache.clear("images");
			openfl.utils.Assets.cache.clear("songs");
			openfl.utils.Assets.cache.clear("music");
			
			flixel.FlxG.bitmap.reset();
		} catch(e:Dynamic) {}

		#if cpp
		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.compact();
		cpp.vm.Gc.run(true);
		#end

		if (purgedGraphics > 0) {
			trace("[TIMELESS CORE PURGE]: Wiped " + purgedGraphics + " assets. VRAM/RAM synced.");
		}
	}

	#if debug
	public static function cacheStatus():String
	{
		var str = new StringBuf();
		str.add('-- Cache dump start --\n');
		str.add('( openfl caches are ${openfl.utils.Assets.cache.enabled})\n');
		var totalMemory = 0;

		str.add("-- Managed bitmaps --\n");
		var entries:Array<ImageLine> = [];
		
		for (key in FlxG.bitmap._cache.keys())
		{
			var texture = FlxG.bitmap._cache.get(key);
			var inStored = currentTrackedAssets.exists(key) ? "S" : "-";
			var inLocal = localTrackedAssets.exists(key) ? "L" : "-";
			var memory = texture?.bitmap?.image?.data?.byteLength ?? 0;
			entries.push({
				size: memory,
				text: '[ $inStored $inLocal ](${FlxStringUtil.formatBytes(memory)}) $key'
			});
			totalMemory += memory;
		}
		entries.sort((x, y) -> cast y.size - x.size);
		for (entry in entries)
		{
			str.add(entry.text + "\n");
		}
		str.add('Total: ${FlxStringUtil.formatBytes(totalMemory)}\n');

		str.add("-- Managed sounds --\n");
		totalMemory = 0;
		for (key in currentTrackedSounds.keys())
		{
			var snd = currentTrackedSounds.get(key);
			var inLocal = localTrackedAssets.exists(key) ? "L" : "-";
			var memory = snd.bytesLoaded;
			str.add('[ $inLocal ](${FlxStringUtil.formatBytes(memory)}}/${FlxStringUtil.formatBytes(snd.bytesTotal)}) $key\n');
			totalMemory += memory;
		}
		str.add('Total: ${FlxStringUtil.formatBytes(totalMemory)}\n');

		str.add("-- OPENFL sounds --\n");
		totalMemory = 0;
		for (key in currentTrackedSounds.keys())
		{
			var snd = currentTrackedSounds.get(key);
			var memory = (snd != null && snd.__buffer != null && snd.__buffer.data != null) ? snd.__buffer.data.length : 0;
			str.add(' (${FlxStringUtil.formatBytes(memory)}) $key\n');
			totalMemory += memory;
		}
		str.add('Total: ${FlxStringUtil.formatBytes(totalMemory)}\n-- END --');
		return str.toString();
	}
	#end

	public static function clearStoredMemory()
	{
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(FlxG.bitmap.get(key));
			}
		}

		localTrackedAssets = new Map<String, Bool>();
		#if !html5 
		openfl.Assets.cache.clear("songs"); 
		#end
	}

	public static function loadBitmap(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.set(key, true);
			return currentTrackedAssets.get(key);
		}
		var bitmap = __loadBitmap(key, parentFolder);
		return cacheBitmap(key, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null) return null;

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			#if ATSC_SUPPORT
			if (!Std.isOfType(bitmap.__texture, openfl.display3D.textures.ASTCTexture))
			{
			#end
				bitmap.getSurface();
				bitmap.disposeImage();
				bitmap.image.data = null;
				bitmap.image = null;
				bitmap.readable = true;
			#if ATSC_SUPPORT
			}
			#end
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.set(key, true);
		return graph;
	}

	public static function loadSound(file:String, ?beepOnNull:Bool = true, requestName:String = ""):Sound
	{
		if (file == null || file.length == 0) return flixel.system.FlxAssets.getSound('flixel/sounds/beep');

		if (currentTrackedSounds.exists(file))
		{
			localTrackedAssets.set(file, true);
			return currentTrackedSounds.get(file);
		}

		if (mikolka.funkin.custom.NativeFileSystem.exists(file))
		{
			try {
				if (file.contains("songs") || file.contains("music") || file.contains("stayFunky") || file.contains("freakyMenu")) {
					var streamSound:Sound = openfl.media.Sound.fromFile(file);
					if (streamSound != null)
					{
						currentTrackedSounds.set(file, streamSound);
						localTrackedAssets.set(file, true);
						return streamSound;
					}
				}
				
				var normalSound:Sound = openfl.Assets.getSound(file);
				if (normalSound != null) {
					currentTrackedSounds.set(file, normalSound);
					localTrackedAssets.set(file, true);
					return normalSound;
				}
			} catch(e:Dynamic) {
				trace("[TIMELESS AUDIO CORE WARN]: Failed to parse asset -> " + file + " | " + e);
			}
		}

		if (beepOnNull)
		{
			var fallbackBeep = flixel.system.FlxAssets.getSound('flixel/sounds/beep');
			if (fallbackBeep != null) return fallbackBeep;
		}
		return null;
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Map<FlxGraphic, Bool> = new Map<FlxGraphic, Bool>();
		
		function checkForGraphics(spr:Dynamic)
		{
			if (spr == null) return;
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if (grp != null)
				{
					for (i in 0...grp.length)
					{
						checkForGraphics(grp[i]);
					}
					return;
				}
			} catch(e:Dynamic) {}

			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if (gfx != null)
				{
					protectedGfx.set(gfx, true);
				}
			} catch(e:Dynamic) {}
		}

		var currentMembers = FlxG.state.members;
		for (i in 0...currentMembers.length)
		{
			checkForGraphics(currentMembers[i]);
		}

		if (FlxG.state.subState != null)
		{
			var subMembers = FlxG.state.subState.members;
			for (i in 0...subMembers.length)
			{
				checkForGraphics(subMembers[i]);
			}
		}

		for (key in currentTrackedAssets.keys())
		{
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if (!protectedGfx.exists(graphic))
				{
					destroyGraphic(graphic);
					currentTrackedAssets.remove(key);
				}
			}
		}
	}

	private static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null)
		{
			if (graphic.bitmap != null)
			{
				if (graphic.bitmap.__texture != null)
				{
					graphic.bitmap.__texture.dispose();
				}
				graphic.bitmap.dispose();
				#if !flash
				graphic.bitmap.disposeImage();
				#end
			}
			FlxG.bitmap.remove(graphic);
			graphic.destroy();
		}
	}

	private static function __loadBitmap(key:String, ?parentFolder:String = null):BitmapData
	{
		var intarnalFile = Path.withoutExtension(key);
		var file:String = getTexturePath(intarnalFile, parentFolder);
		var bitmap = mikolka.funkin.custom.NativeFileSystem.getBitmap(file);
		if (bitmap == null)
		{
			trace('Bitmap not found: $file | key: $key');
		}
		return bitmap;
	}

	private static function getTexturePath(file:String, ?parentfolder:String):String
	{
		var cacheKey:String = file + "_" + (parentfolder != null ? parentfolder : "null") + "_" + Paths.currentLevel;
		if (_pathCache.exists(cacheKey))
		{
			return _pathCache.get(cacheKey);
		}

		function astcGetSharedPath(path:String) {
			#if ATSC_SUPPORT
			if (backend.Native.isASTCSupported()) {
				var assetPath = Paths.getSharedPath('$path.astc');
				if (mikolka.funkin.custom.NativeFileSystem.exists(assetPath)) return assetPath;
			}
			#end
			return Paths.getSharedPath('$path.png');
		}

		function astcGetFolderPath(f:String, folder:String) {
			#if ATSC_SUPPORT
			if (backend.Native.isASTCSupported()) {
				var assetPath = Paths.getFolderPath('$f.astc', folder);
				if (mikolka.funkin.custom.NativeFileSystem.exists(assetPath)) return assetPath;
			}
			#end
			return Paths.getFolderPath('$f.png', folder);
		}

		#if MODS_ALLOWED
		function astcModFolders(path:String) {
			#if ATSC_SUPPORT
			if (backend.Native.isASTCSupported()) {
				var assetPath = Paths.modFolders('$path.astc');
				if (mikolka.funkin.custom.NativeFileSystem.exists(assetPath)) return assetPath;
			}
			#end
			return Paths.modFolders('$path.png');
		}

		var customFile:String = (parentfolder != null) ? '$parentfolder/$file' : file;

		if (Paths.currentLevel != null && Paths.currentLevel != 'shared')
		{
			var levelPath = astcModFolders('${Paths.currentLevel}/$customFile');
			if (mikolka.funkin.custom.NativeFileSystem.exists(levelPath)) {
				_pathCache.set(cacheKey, levelPath);
				return levelPath;
			}
		}

		var modded:String = astcModFolders(customFile);
		if (mikolka.funkin.custom.NativeFileSystem.exists(modded)) {
			_pathCache.set(cacheKey, modded);
			return modded;
		}
		#end

		if (parentfolder == "mobile") {
			var path = astcGetSharedPath('mobile/$file');
			_pathCache.set(cacheKey, path);
			return path;
		}

		if (parentfolder != null) {
			var path = astcGetFolderPath(file, parentfolder);
			_pathCache.set(cacheKey, path);
			return path;
		}

		if (Paths.currentLevel != null && Paths.currentLevel != 'shared')
		{
			var levelPath = astcGetFolderPath(file, Paths.currentLevel);
			if (mikolka.funkin.custom.NativeFileSystem.exists(levelPath)) {
				_pathCache.set(cacheKey, levelPath);
				return levelPath;
			}
		}

		var finalPath = astcGetSharedPath(file);
		_pathCache.set(cacheKey, finalPath);
		return finalPath;
	}
}