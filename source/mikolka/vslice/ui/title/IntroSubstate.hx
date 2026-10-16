package mikolka.vslice.ui.title;

import mikolka.compatibility.VsliceOptions;
import flixel.group.FlxGroup;

class IntroSubstate extends MusicBeatSubstate
{
	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;
	var curWacky:Array<String> = [];
	var wackyImage:FlxSprite;
	private var sickBeats:Int = 0;

	public function new()
	{
		super();
		var textData = getIntroTextShit();
		if (textData.length > 0)
			curWacky = FlxG.random.getObject(textData);
		else
			curWacky = ["Friday Night Funkin'", "Timeless Engine"];
	}

	override function create()
	{
		super.create();
		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52);

		if (FlxG.random.bool(1))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_classic'));
		}
		else if (FlxG.random.bool(30))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_animated'), true, 600);
			ngSpr.animation.add('idle', [0, 1], 4);
			ngSpr.animation.play('idle');
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.55));
			ngSpr.y += 25;
		}
		else
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		}
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = VsliceOptions.FLASHBANG;
		ngSpr.visible = false;

		add(credGroup);
		add(ngSpr);
	}

	override function beatHit()
	{
		super.beatHit();
		sickBeats++;
		switch (sickBeats)
		{
			case 2:
				createCoolText(['Funkin Crew Inc', 'Shadow Mario', 'Timeless']);
			case 4:
				addMoreText('present');
			case 5:
				deleteCoolText();
			case 6:
				createCoolText(['Not associated', 'with'], -40);
			case 8:
				addMoreText('newgrounds', -40);
				ngSpr.visible = true;
			case 9:
				deleteCoolText();
				ngSpr.visible = false;
			case 10:
				createCoolText([curWacky[0]]);
			case 12:
				if (curWacky.length > 1) addMoreText(curWacky[1]);
			case 13:
				deleteCoolText();
			case 14:
				addMoreText('Friday');
			case 15:
				addMoreText('Night');
			case 16:
				addMoreText('Funkin');
		}
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if (textArray == null) return;
		for (i in 0...textArray.length)
		{
			#if !LEGACY_PSYCH
			HapticUtil.vibrate(0, Constants.DEFAULT_VIBRATION_DURATION);
			#end

			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;

			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		if (textGroup == null || credGroup == null) return;
		while (textGroup.members.length > 0)
		{
			var member = textGroup.members[0];
			if (member != null)
			{
				credGroup.remove(member, true);
				textGroup.remove(member, true);
			}
			else
			{
				textGroup.members.shift();
			}
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var firstArray:Array<String> = [];
		#if (MODS_ALLOWED && !LEGACY_PSYCH)
		firstArray = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = NativeFileSystem.getContent(Paths.txt('introText'));
		if (fullText != null && fullText.length > 0)
			firstArray = fullText.split('\n');
		#end
		
		var swagGoodArray:Array<Array<String>> = [];
		for (i in firstArray)
		{
			if (i != null && i.trim().length > 0)
			{
				swagGoodArray.push(i.trim().split('--'));
			}
		}
		return swagGoodArray;
	}
}