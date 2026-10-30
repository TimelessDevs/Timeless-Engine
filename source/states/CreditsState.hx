package states;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import objects.AttachedSprite;
import mikolka.vslice.ui.MainMenuState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var iconArray:Array<AttachedSprite> = [];
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	
	var sidebarBg:FlxSprite;
	var mainCard:FlxSprite;
	var nameText:FlxText;
	var subTitleText:FlxText;
	var bigIcon:FlxSprite;
	var hintText:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Menu", null);
		#end

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		sidebarBg = new FlxSprite(0, 0).makeGraphic(420, FlxG.height, FlxColor.BLACK);
		sidebarBg.alpha = 0.5;
		sidebarBg.scrollFactor.set();
		add(sidebarBg);

		mainCard = new FlxSprite(460, 60).makeGraphic(780, 520, FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRoundRect(mainCard, 0, 0, 780, 520, 25, 25, FlxColor.BLACK);
		mainCard.alpha = 0.45;
		mainCard.scrollFactor.set();
		add(mainCard);

		bigIcon = new FlxSprite(mainCard.x + 40, mainCard.y + 40);
		bigIcon.scrollFactor.set();
		add(bigIcon);

		nameText = new FlxText(bigIcon.x + 180, bigIcon.y + 20, 520, "", 36);
		nameText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.scrollFactor.set();
		add(nameText);

		subTitleText = new FlxText(nameText.x, nameText.y + 50, 520, "", 18);
		subTitleText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFCECECE, LEFT);
		subTitleText.scrollFactor.set();
		add(subTitleText);

		descText = new FlxText(mainCard.x + 40, bigIcon.y + 180, 700, "", 24);
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 1.5;
		descText.scrollFactor.set();
		add(descText);

		hintText = new FlxText(mainCard.x + 40, mainCard.y + mainCard.height - 50, 700, "Press ACCEPT to open link • Press BACK to exit", 16);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, 0x88FFFFFF, LEFT);
		hintText.scrollFactor.set();
		add(hintText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [
			['Timeless Engine Team'],
			['Timeless',			'timeless',			'Main Programmer, artist and Head of Timeless Engine',								 'https://discord.com',									'2ebcfa'],
			[""],
			["Timeless server"],
			["Join our community",	"timelessengine",			"",																"https://discord.gg",			"5e36c4"],
			[""],
			["Psych Engine Team"],
			["Shadow Mario",		"shadowmario",		"Main Programmer and Head of Psych Engine",					"https://ko-fi.com",	"444444"],
			["Riveren",				"riveren",			"Main Artist/Animator of Psych Engine",						"https://x.com",			"14967B"],
			["bb-panzu",			"bb",				"Ex-Programmer of Psych Engine",							"https://x.com",				"3E813A"],
			[""],
			["Engine Contributors"],
			["crowplexus",			"crowplexus",		"HScript Iris, Input System v3, and Other PRs",				"https://github.com",	"CFCFCF"],
			["Kamizeta",			"kamizeta",			"Creator of Pessy, Psych Engine's mascot.",				"https://instagram.com",	"D21C11"],
			["MaxNeton",			"maxneton",			"Loading Screen Easter Egg Artist/Animator.",	"https://bsky.app","3C2E4E"],
			["Keoiki",				"keoiki",			"Note Splash Animations and Latin Alphabet",				"https://x.com_",			"D2D2D2"],
			["SqirraRNG",			"sqirra",			"Crash Handler and Base code for\nChart Editor's Waveform",	"https://x.com",			"E1843A"],
			["EliteMasterEric",		"mastereric",		"Runtime Shaders support and Other PRs",					"https://x.com",	"FFBD40"],
			["MAJigsaw77",			"majigsaw",			".MP4 Video Loader Library (hxvlc)",						"https://x.com",			"5F5F5F"],
			["Tahir Toprak Karabekiroglu",	"tahir",	"Note Splash Editor and Other PRs",							"https://x.com",		"A04397"],
			["iFlicky",				"flicky",			"Composer of Psync and Tea Time\nAnd some sound effects",	"https://x.com",			"9E29CF"],
			["KadeDev",				"kade",				"Fixed some issues on Chart Editor and Other PRs",			"https://x.com",			"64A250"],
			["superpowers04",		"superpowers04",	"LUA JIT Fork",												"https://x.com",		"B957ED"],
			["CheemsAndFriends",	"cheems",			"Creator of FlxAnimate",									"https://x.com",	"E1E1E1"],
			[""],
			["The Funkin' Crew Inc"],
			["ninjamuffin99",		"ninjamuffin99",	"Programmer of Friday Night Funkin'",						"https://x.com",		"CF2D2D"],
			["PhantomArcade",		"phantomarcade",	"Animator of Friday Night Funkin'",							"https://x.com",	"FADC45"],
			["evilsk8r",			"evilsk8r",			"Artist of Friday Night Funkin'",							"https://x.com",			"5ABD4B"],
			["kawaisprite",			"kawaisprite",		"Composer of Friday Night Funkin'",							"https://x.com",		"378FC7"],
		];
		
		for(i in defaultList)
			creditsStuff.push(i);
	
		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(30, 0, credit[0], !isSelectable);
			
			if(!isSelectable) optionText.color = FlxColor.WHITE; 
			
			optionText.isMenuItem = false;
			optionText.targetY = i;
			optionText.changeY = true;
			optionText.changeX = false;
			optionText.setScale(isSelectable ? 0.55 : 0.65);
			optionText.alpha = 0;
			grpOptions.add(optionText);

			if(isSelectable)
			{
				if(credit != null && credit.length > 5) 
					Mods.currentModDirectory = credit[5];

				var str:String = 'credits/missing_icon';
				if(credit != null && credit.length > 0)
				{
					var fileName = 'credits/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if(str.endsWith('-pixel')) icon.antialiasing = false;
				icon.visible = false;
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
			else
			{
				iconArray.push(null);
			}

			FlxTween.tween(optionText, {alpha: isSelectable ? 0.4 : 0.8}, 0.4, {ease: FlxEase.quadOut, startDelay: Math.min(i * 0.03, 0.3)});
		}
		
		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');
		#end
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT && (creditsStuff[curSelected] == null || creditsStuff[curSelected].length > 4)) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		var lerpVal:Float = FlxMath.bound(elapsed * 10, 0, 1);
		for (item in grpOptions.members)
		{
			var targetX:Float = unselectableCheck(grpOptions.members.indexOf(item)) ? 20 : 45;
			if (item.targetY == 0 && !unselectableCheck(grpOptions.members.indexOf(item))) targetX = 65;
			
			item.x = FlxMath.lerp(item.x, targetX, lerpVal);
			item.y = FlxMath.lerp(item.y, (item.targetY * 75) + (FlxG.height * 0.45), lerpVal);
		}

		if (descText != null && hintText != null && mainCard != null) {
			hintText.y = mainCard.y + mainCard.height - 45;
			if (descText.y + descText.height > hintText.y - 20) {
				descText.y = hintText.y - descText.height - 25;
			}
		}

		super.update(elapsed);
	}

	var cardTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		} while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.45, bg.color, intendedColor, {ease: FlxEase.quadOut});
		}

		var lastCategory:String = "Timeless Engine";
		var i:Int = curSelected;
		while (i >= 0) {
			if (unselectableCheck(i)) {
				lastCategory = creditsStuff[i][0];
				break;
			}
			i--;
		}

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				if (item.targetY == 0) {
					item.alpha = 1.0;
					item.color = 0xFF33FFFF;
				} else {
					item.alpha = 0.35;
					item.color = FlxColor.WHITE;
				}
			} else {
				item.alpha = (Math.abs(item.targetY) <= 3) ? 0.7 : 0.2;
				item.color = FlxColor.WHITE;
			}
		}

		var curMod:String = '';
		if(creditsStuff[curSelected].length > 5) curMod = creditsStuff[curSelected][5];
		Mods.currentModDirectory = curMod;

		var str:String = 'credits/missing_icon';
		if(creditsStuff[curSelected][1] != null && creditsStuff[curSelected][1].length > 0)
		{
			var fileName = 'credits/' + creditsStuff[curSelected][1];
			if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
			else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
		}
		bigIcon.loadGraphic(Paths.image(str));
		if(str.endsWith('-pixel')) bigIcon.antialiasing = false;
		else bigIcon.antialiasing = ClientPrefs.data.antialiasing;
		bigIcon.setGraphicSize(140, 150);
		bigIcon.updateHitbox();
		Mods.currentModDirectory = '';
		nameText.text = creditsStuff[curSelected][0];
		subTitleText.text = lastCategory.toUpperCase();
		descText.text = creditsStuff[curSelected][2];

		if (cardTween != null) cardTween.cancel();
		mainCard.x = 490;
		mainCard.alpha = 0;
		bigIcon.alpha = nameText.alpha = subTitleText.alpha = descText.alpha = hintText.alpha = 0;
		
		cardTween = FlxTween.tween(mainCard, {x: 460, alpha: 0.4}, 0.25, {
			ease: FlxEase.backOut,
			onUpdate: function(twn:FlxTween) {
				var progress = mainCard.alpha / 0.4;
				bigIcon.alpha = nameText.alpha = subTitleText.alpha = descText.alpha = progress;
				hintText.alpha = progress * 0.4;
				
				bigIcon.x = mainCard.x + 40;
				nameText.x = bigIcon.x + 180;
				subTitleText.x = nameText.x;
				descText.x = mainCard.x + 40;
				hintText.x = mainCard.x + 40;
			}
		});
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (NativeFileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end NativeFileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = NativeFileSystem.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private inline function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}
