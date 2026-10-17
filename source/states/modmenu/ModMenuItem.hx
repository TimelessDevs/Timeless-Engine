package states.modmenu;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import backend.Paths;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;

class ModMenuItem extends FlxSpriteGroup
{
	public static final ITEM_WIDTH:Int = 350;
	public static final ICON_HEIGHT:Int = 96;
	public static final DESC_WIDTH:Int = 216;
	public static final ITEM_WIDTH_PADDING:Int = 24;
	public static var BG_SLIDE_DISTANCE:Float = 14;
	public static var BG_SLIDE_LERP:Float = 20;
	public static var iconStrings:Array<String> = [];

	public var locked:Bool = false;
	public final modId:String;
	public final modTitle:String;
	public final modDescription:String;

	var fallbackModId:String;
	var fallbackTitle:String;
	var fallbackDescription:String;
	var bgOffsetX:Float = 0;
	var bgOffsetY:Float = 0;
	var modIcon:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var background:FlxSprite;

	public var selected(default, set):Bool = false;

	function set_selected(value:Bool):Bool
	{
		this.selected = value;
		return selected;
	}

	public function slideBackgroundFrom(dir:Int):Void
	{
		switch (dir)
		{
			case -1:
				bgOffsetX = 0;
				bgOffsetY = -BG_SLIDE_DISTANCE;
			case 1:
				bgOffsetX = 0;
				bgOffsetY = BG_SLIDE_DISTANCE;
			case -2:
				bgOffsetX = -BG_SLIDE_DISTANCE;
				bgOffsetY = 0;
			case 2:
				bgOffsetX = BG_SLIDE_DISTANCE;
				bgOffsetY = 0;
			default:
				bgOffsetX = 0;
				bgOffsetY = 0;
		}
		background.x = -bgOffsetX;
		background.y = -bgOffsetY;
	}

	public var enabled(default, set):Bool = false;

	function set_enabled(value:Bool):Bool
	{
		this.enabled = value;
		return enabled;
	}

	public var isInFlight(default, null):Bool = false;

	var flightStartX:Float = 0;
	var flightStartY:Float = 0;
	var flightTargetX:Float = 0;
	var flightTargetY:Float = 0;
	var flightElapsed:Float = 0;
	var flightDuration:Float = 0.2;
	var flightEase:Float->Float = FlxEase.quadOut;
	var flightOnComplete:Null<Void->Void> = null;

	public function startFlight(targetX:Float, targetY:Float, duration:Float, ?ease:Float->Float, ?onComplete:Void->Void):Void
	{
		flightStartX = x;
		flightStartY = y;
		flightTargetX = targetX;
		flightTargetY = targetY;
		flightElapsed = 0;
		flightDuration = duration > 0 ? duration : 0.0001;
		flightEase = ease != null ? ease : FlxEase.quadOut;
		flightOnComplete = onComplete;
		isInFlight = true;
	}

	public function finishFlight():Void
	{
		if (!isInFlight)
			return;

		isInFlight = false;
		x = flightTargetX;
		y = flightTargetY;

		var cb = flightOnComplete;
		flightOnComplete = null;

		if (cb != null)
			cb();
	}

	public function cancelFlight():Void
	{
		isInFlight = false;
		flightOnComplete = null;
	}

	function updateFlight(elapsed:Float):Void
	{
		if (!isInFlight)
			return;

		flightElapsed += elapsed;
		var t:Float = flightElapsed / flightDuration;

		if (t >= 1)
		{
			finishFlight();
			return;
		}

		var easedT:Float = flightEase(t);
		x = FlxMath.lerp(flightStartX, flightTargetX, easedT);
		y = FlxMath.lerp(flightStartY, flightTargetY, easedT);
	}

	var flashElapsed:Float = -1;

	static inline final FLASH_DURATION:Float = 0.5;
	static inline final FLASH_START_ALPHA:Float = 1.0;

	var flashTargetAlpha:Float = 0.25;

	public function new(folder:String, iconAssetPath:Null<String> = null, fallbackModId:String = '__unknown_mod__',
			fallbackTitle:String = 'Unknown Mod', fallbackDescription:String = '')
	{
		super();

		this.modId = folder;
		var pack = backend.Mods.getPack(folder);
		this.modTitle = (pack != null && pack.name != null) ? pack.name : fallbackTitle;
		this.modDescription = (pack != null && pack.description != null) ? pack.description : fallbackDescription;

		background = new FlxSprite(0, 0);
		background.makeGraphic(ITEM_WIDTH - ITEM_WIDTH_PADDING, ICON_HEIGHT, FlxColor.WHITE);
		background.alpha = 0;
		add(background);

		modIcon = new FlxSprite(0, 0);
		var pngPath:String = Paths.mods(folder + '/pack.png');
		if (!sys.FileSystem.exists(pngPath)) pngPath = Paths.mods(folder + '/pack-pixel.png');

		if (sys.FileSystem.exists(pngPath)) {
			try {
				modIcon.loadGraphic(openfl.display.BitmapData.fromFile(pngPath));
			} catch(e:Dynamic) {
				modIcon.loadGraphic(Paths.image('unknownMod'));
			}
		} else {
			modIcon.loadGraphic(Paths.image('unknownMod'));
		}
		finishModIcon();

		titleText = new FlxText(0, 0, DESC_WIDTH);
		titleText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE);
		titleText.x = ICON_HEIGHT + 8;
		titleText.text = this.modTitle;
		add(titleText);

		descriptionText = new FlxText(0, 0, DESC_WIDTH);
		descriptionText.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE);
		descriptionText.x = ICON_HEIGHT + 8;
		descriptionText.y = titleText.y + 25;
		descriptionText.text = this.modDescription;
		descriptionText.alpha = 0.7;
		add(descriptionText);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		updateFlight(elapsed);
		updateBackgroundColor();
		updateFlash(elapsed);

		if (bgOffsetX != 0 || bgOffsetY != 0)
		{
			var t = Math.min(1, BG_SLIDE_LERP * elapsed);
			bgOffsetX += (0 - bgOffsetX) * t;
			bgOffsetY += (0 - bgOffsetY) * t;

			if (Math.abs(bgOffsetX) < 0.1)
				bgOffsetX = 0;
			if (Math.abs(bgOffsetY) < 0.1)
				bgOffsetY = 0;

			background.x = -bgOffsetX;
			background.y = -bgOffsetY;
		}
	}

	function updateBackgroundColor():Void
	{
		if (flashElapsed >= 0)
			return;

		if (this.selected)
			background.alpha = 0.25;
		else
			background.alpha = 0;
	}

	public function flashBackground():Void
	{
		flashTargetAlpha = this.selected ? 0.25 : 0;
		background.alpha = FLASH_START_ALPHA;
		flashElapsed = 0;
	}

	function updateFlash(elapsed:Float):Void
	{
		if (flashElapsed < 0)
			return;

		flashElapsed += elapsed;
		var t:Float = flashElapsed / FLASH_DURATION;

		if (t >= 1)
		{
			background.alpha = flashTargetAlpha;
			flashElapsed = -1;
			return;
		}

		var easedT:Float = FlxEase.quintOut(t);
		background.alpha = FlxMath.lerp(FLASH_START_ALPHA, flashTargetAlpha, easedT);
	}

	function loadModIcon(bytes:haxe.io.Bytes):Void
	{
		var future = openfl.utils.ByteArray.loadFromBytes(bytes);

		future.onComplete((openFlBytes:openfl.utils.ByteArray) ->
		{
			if (!exists || members == null || modIcon == null)
				return;
			try
			{
				var bitmapData = openfl.display.BitmapData.fromBytes(openFlBytes);
				if (bitmapData == null)
				{
					useFallbackModIcon();
					return;
				}
				modIcon.loadGraphic(bitmapData);
				finishModIcon();
			}
			catch (error)
			{
				trace('Could not decode the icon for mod ${getModId()}: ${error}');
				useFallbackModIcon();
			}
		});
		future.onError((error) ->
		{
			trace('Could not load the icon for mod ${getModId()}: ${error}');
			useFallbackModIcon();
		});
	}

	function useFallbackModIcon():Void
	{
		if (!exists || members == null)
			return;
		modIcon.loadGraphic(Paths.image('ui/mods/fallback-icon'));
		finishModIcon();
	}

	function finishModIcon():Void
	{
		if (!exists || members == null)
			return;
		if (!members.contains(modIcon))
			add(modIcon);
		modIcon.scrollFactor.set();
		modIcon.antialiasing = true;
		modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
		modIcon.scale.set(modIcon.scale.x, modIcon.scale.y);
		modIcon.updateHitbox();
	}

	public function getModId():String
	{
		return modId;
	}

	public function getModTitle():String
	{
		return modTitle;
	}

	public function getModDescription():String
	{
		return modDescription;
	}

	override public function toString():String
	{
		return 'ModMenuItem(${modId})';
	}
}
