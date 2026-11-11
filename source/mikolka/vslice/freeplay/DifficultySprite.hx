package mikolka.vslice.freeplay;

import mikolka.compatibility.VsliceOptions;
import flixel.graphics.FlxGraphic;
import mikolka.compatibility.funkin.FunkinPath as Paths;

class DifficultySprite extends FlxSprite
{
	public var difficultyId:String;

	public var hasValidTexture = true;
	public var difficultyColor:FlxColor;
	public var widthOffset:Float = 0;

	static var _colorCache:Map<String, FlxColor> = new Map<String, FlxColor>();

	public function new(diffId:String)
	{
		super();
		difficultyId = diffId;

		var tex:FlxGraphic = null;
		var usedFallbackText:Bool = false;
		if (Paths.exists('images/freeplay/freeplayDifficulties/freeplay' + diffId + ".xml"))
		{
			frames = Paths.getSparrowAtlas('freeplay/freeplayDifficulties/freeplay' + diffId,false);
			animation.addByPrefix('idle', 'idle0', 24, true);
			widthOffset = (frames.frames[0].frame.width / 2) - 20;
			if (VsliceOptions.FLASHBANG)
				this.animation.play('idle');
		}
		else
		{
			tex = Paths.noGpuImage('freeplay/freeplayDifficulties/freeplay' + diffId);
			if (tex != null) widthOffset = (tex.width / 2) - 20;
			if (tex == null)
			{
				tex = Paths.noGpuImage('menudifficulties/' + diffId);
				if (tex != null)
					widthOffset = (tex.width / 2) - 80;
			}

			if (tex == null)
			{
				usedFallbackText = true;
				var grpFallbackDifficulty = new FlxText(70, 90, 250, difficultyId);
				grpFallbackDifficulty.setFormat("VCR OSD Mono", 60, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				grpFallbackDifficulty.borderSize = 2;
				@:privateAccess
				grpFallbackDifficulty.regenGraphic();
				@:privateAccess
				tex = grpFallbackDifficulty.graphic;
				widthOffset = (tex.width / 2) - 55;
			}

			this.loadGraphic(tex);
		}

		try
		{
			var gkey:String = (graphic != null && !usedFallbackText) ? graphic.key : null;
			if (gkey != null && _colorCache.exists(gkey))
				difficultyColor = _colorCache.get(gkey);
			else
			{
				difficultyColor = hasValidTexture ? CoolUtil.dominantColor(this) : FlxColor.GRAY;
				if (gkey != null) _colorCache.set(gkey, difficultyColor);
			}
		}
		catch (x)
		{
			trace('Failed to get prime color for $diffId: ${x.message}');
			difficultyColor = FlxColor.GRAY;
		}
		x = -((width / 2) - 106);
	}
}
