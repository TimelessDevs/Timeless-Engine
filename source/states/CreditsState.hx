package states;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.vslice.ui.MainMenuState;
import objects.AttachedSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Rectangle;

class CreditsState extends MusicBeatState
{
	static inline var SIDE_W:Int = 420;
	static inline var ROW_STEP:Int = 75;
	static inline var CARD_X:Int = 460;
	static inline var CARD_Y:Int = 60;
	static inline var CARD_W:Int = 780;
	static inline var CARD_H:Int = 600;
	static inline var PAD:Int = 40;
	static inline var BANNER_PAD:Int = 16;
	static inline var BANNER_W:Int = 748;
	static inline var BANNER_H:Int = 220;
	static inline var AVATAR:Int = 116;
	static inline var ICON_FIT:Int = 100;
	static inline var AV_X:Int = CARD_X + PAD;
	static inline var AV_Y:Int = CARD_Y + 178;
	static inline var NAME_X:Int = AV_X + AVATAR + 20;
	static inline var NAME_W:Int = CARD_X + CARD_W - PAD - NAME_X;
	static inline var DESC_W:Int = CARD_W - 2 * PAD;
	static inline var DESC_H:Int = 160;
	static inline var CHIP:Int = 40;
	static inline var CHIP_GAP:Int = 10;
	static inline var MAX_LINKS:Int = 8;
	static final SERVICE_ORDER:Array<String> = ['github', 'discord', 'youtube', 'bsky', 'reddit', 'gamebanana', 'instagram', 'ko-fi', 'x'];
	static inline var DEFAULT_COLOR:Int = 0xFF5E5E7A;

	var curSelected:Int = -1;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var creditsStuff:Array<Array<String>> = [];
	var selectable:Array<Bool> = [];
	var rankOf:Array<Int> = [];
	var iconArray:Array<AttachedSprite> = [];
	var iconPaths:Array<String> = [];
	var bannerPaths:Array<String> = [];
	var bannerState:Array<Int> = [];
	var linkUrls:Array<Array<String>> = [];
	var linkKeys:Array<Array<String>> = [];
	var serviceHas:Map<String, Bool> = new Map();
	var linkFocus:Int = 0;
	var prevMouse:Bool = false;
	var selectableCount:Int = 0;
	var hasLink:Bool = false;

	var bg:FlxSprite;
	var intendedColor:FlxColor;
	var accent:FlxColor = FlxColor.WHITE;

	var sidebarBg:FlxSprite;
	var selPill:FlxSprite;
	var sideEdge:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var sideTitle:FlxText;
	var sideCount:FlxText;
	var hoverPill:FlxSprite;
	var backPill:FlxSprite;
	var backText:FlxText;

	var cardGroup:FlxSpriteGroup;
	var fadeParts:Array<FlxSprite> = [];
	var fadeBase:Array<Float> = [];
	var mainCard:FlxSprite;
	var bannerFallback:FlxSprite;
	var bannerPattern:FlxSprite;
	var bannerSpr:FlxSprite;
	var bannerShade:FlxSprite;
	var bannerFrame:FlxSprite;
	var avatarRing:FlxSprite;
	var avatarBack:FlxSprite;
	var bigIcon:FlxSprite;
	var nameText:FlxText;
	var badge:FlxSprite;
	var subTitleText:FlxText;
	var divider:FlxSprite;
	var descText:FlxText;
	var bottomLine:FlxSprite;
	var hintText:FlxText;
	var linkPill:FlxSprite;
	var linkText:FlxText;
	var chipBgs:Array<FlxSprite> = [];
	var chipRings:Array<FlxSprite> = [];
	var chipIcons:Array<FlxSprite> = [];
	var chipLetters:Array<FlxText> = [];

	var cardTween:FlxTween = null;
	var fadeTween:FlxTween = null;
	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Menu", null);
		#end

		persistentUpdate = true;
		prevMouse = FlxG.mouse.visible;
		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		buildSidebar();
		buildCard();

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [
			['Timeless Engine Team'],
			['Timeless',			'timeless',			'Main Programmer, Artist and Head of Timeless Engine',		'https://discord.com/users/1347569284947382272 | https://gamebanana.com/members/5828656',				'5e36c4'],
			[""],
			["Timeless Engine Channels"],
			["	",	"timelessengine",		"Subscribe to our channels",							'https://discord.gg | https://www.youtube.com/channel/@TimelessEngineFNF | https://gamebanana.com/tools/24369 | https://github.com/TimelessDevs/Timeless-Engine',	"2ebcfa"],
			[""],
			["Psych Engine Team"],
			["Shadow Mario",		"shadowmario",		"Main Programmer and Head of Psych Engine",					"https://ko-fi.com/shadowmario",	"444444"],
			["Riveren",				"riveren",			"Main Artist/Animator of Psych Engine",						"https://x.com/riverennn",			"14967B"],
			["bb-panzu",			"bb",				"Ex-Programmer of Psych Engine",							"https://x.com/bbsub3",				"3E813A"],
			[""],
			["Engine Contributors"],
			["crowplexus",			"crowplexus",		"HScript Iris, Input System v3, and Other PRs",				"https://github.com",				"CFCFCF"],
			["Kamizeta",			"kamizeta",			"Creator of Pessy, Psych Engine's mascot.",					"https://instagram.com",			"D21C11"],
			["MaxNeton",			"maxneton",			"Loading Screen Easter Egg Artist/Animator.",				"https://bsky.app/profile/maxneton.bsky.social",	"3C2E4E"],
			["Keoiki",				"keoiki",			"Note Splash Animations and Latin Alphabet",				"https://x.com/Keoiki_",			"D2D2D2"],
			["SqirraRNG",			"sqirra",			"Crash Handler and Base code for\nChart Editor's Waveform",	"https://x.com/gedehari",			"E1843A"],
			["EliteMasterEric",		"mastereric",		"Runtime Shaders support and Other PRs",					"https://x.com/EliteMasterEric",	"FFBD40"],
			["MAJigsaw77",			"majigsaw",			".MP4 Video Loader Library (hxvlc)",						"https://x.com/MAJigsaw77",			"5F5F5F"],
			["Tahir Toprak Karabekiroglu",	"tahir",	"Note Splash Editor and Other PRs",							"https://x.com/TahirKarabekir",		"A04397"],
			["iFlicky",				"flicky",			"Composer of Psync and Tea Time\nAnd some sound effects",	"https://x.com/flicky_i",			"9E29CF"],
			["KadeDev",				"kade",				"Fixed some issues on Chart Editor and Other PRs",			"https://x.com/kade0912	",			"64A250"],
			["superpowers04",		"superpowers04",	"LUA JIT Fork",												"https://x.com/superpowers04",		"B957ED"],
			["CheemsAndFriends",	"cheems",			"Creator of FlxAnimate",									"https://x.com/CheemsnFriendos",	"E1E1E1"],
			[""],
			["The Funkin' Crew Inc"],
			["ninjamuffin99",		"ninjamuffin99",	"Programmer of Friday Night Funkin'",						"https://x.com/ninja_muffin99",		"CF2D2D"],
			["PhantomArcade",		"phantomarcade",	"Animator of Friday Night Funkin'",							"https://x.com/PhantomArcade3K",	"FADC45"],
			["evilsk8r",			"evilsk8r",			"Artist of Friday Night Funkin'",							"https://x.com/evilsk8r",			"5ABD4B"],
			["kawaisprite",			"kawaisprite",		"Composer of Friday Night Funkin'",							"https://x.com/kawaisprite",		"378FC7"],
		];

		for(i in defaultList)
			creditsStuff.push(i);

		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = credit.length > 1;
			selectable.push(isSelectable);

			var optionText:Alphabet = new Alphabet(30, 0, credit[0], !isSelectable);
			if(!isSelectable) optionText.color = FlxColor.WHITE;

			optionText.isMenuItem = false;
			optionText.targetY = i;
			optionText.changeY = true;
			optionText.changeX = false;
			fitOption(optionText, isSelectable);
			optionText.alpha = 0;
			grpOptions.add(optionText);

			if(isSelectable)
			{
				resolveAssets(credit);
				rankOf.push(selectableCount++);
				if(curSelected == -1) curSelected = i;
			}
			else
			{
				iconArray.push(null);
				iconPaths.push(null);
				bannerPaths.push(null);
				bannerState.push(0);
				linkUrls.push([]);
				linkKeys.push([]);
				rankOf.push(-1);
			}

			FlxTween.tween(optionText, {alpha: isSelectable ? 0.4 : 0.8}, 0.4, {ease: FlxEase.quadOut, startDelay: Math.min(i * 0.03, 0.3)});
		}

		bg.color = colorOf(curSelected);
		intendedColor = bg.color;
		changeSelection();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');
		#end
		super.create();
	}

	function buildSidebar()
	{
		sidebarBg = new FlxSprite(0, 0).makeGraphic(SIDE_W, FlxG.height, FlxColor.BLACK);
		sidebarBg.alpha = 0.55;
		sidebarBg.scrollFactor.set();
		add(sidebarBg);

		selPill = new FlxSprite(14, FlxG.height * 0.45 - 8).makeGraphic(SIDE_W - 28, 56, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(selPill, 0, 0, SIDE_W - 28, 56, 24, 24, FlxColor.WHITE);
		selPill.alpha = 0.22;
		selPill.scrollFactor.set();
		add(selPill);

		hoverPill = new FlxSprite(14, 0).makeGraphic(SIDE_W - 28, 56, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(hoverPill, 0, 0, SIDE_W - 28, 56, 24, 24, FlxColor.WHITE);
		hoverPill.alpha = 0.1;
		hoverPill.visible = false;
		hoverPill.scrollFactor.set();
		add(hoverPill);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var topFade:FlxSprite = makeGradient(SIDE_W, 130, 0.92, 0, 1);
		add(topFade);
		var bottomFade:FlxSprite = makeGradient(SIDE_W, 130, 0, 0.92, 1);
		bottomFade.y = FlxG.height - 130;
		add(bottomFade);

		sideEdge = new FlxSprite(SIDE_W - 2, 0).makeGraphic(2, FlxG.height, FlxColor.WHITE);
		sideEdge.alpha = 0.55;
		sideEdge.scrollFactor.set();
		add(sideEdge);

		sideTitle = new FlxText(30, 26, SIDE_W - 60, "CREDITS", 32);
		sideTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sideTitle.borderSize = 2;
		sideTitle.scrollFactor.set();
		add(sideTitle);

		sideCount = new FlxText(30, FlxG.height - 46, SIDE_W - 60, "", 18);
		sideCount.setFormat(Paths.font("vcr.ttf"), 18, 0xFFB8B8B8, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sideCount.scrollFactor.set();
		add(sideCount);

		backPill = new FlxSprite(SIDE_W - 108, 28).makeGraphic(84, 32, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(backPill, 0, 0, 84, 32, 32, 32, FlxColor.WHITE);
		backPill.alpha = 0.25;
		backPill.scrollFactor.set();
		add(backPill);

		backText = new FlxText(backPill.x, backPill.y + 6, 84, "BACK", 18);
		backText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		backText.scrollFactor.set();
		add(backText);

		scrollTrack = new FlxSprite(SIDE_W - 14, 130).makeGraphic(4, FlxG.height - 260, FlxColor.WHITE);
		scrollTrack.alpha = 0.12;
		scrollTrack.scrollFactor.set();
		add(scrollTrack);

		scrollThumb = new FlxSprite(SIDE_W - 14, 130).makeGraphic(4, 34, FlxColor.WHITE);
		scrollThumb.scrollFactor.set();
		add(scrollThumb);
	}

	function reg(s:FlxSprite, a:Float = 1):FlxSprite
	{
		s.scrollFactor.set();
		cardGroup.add(s);
		fadeParts.push(s);
		fadeBase.push(a);
		s.alpha = a;
		return s;
	}

	function buildCard()
	{
		cardGroup = new FlxSpriteGroup();
		cardGroup.scrollFactor.set();
		add(cardGroup);

		var bx:Int = CARD_X + BANNER_PAD;
		var by:Int = CARD_Y + BANNER_PAD;

		mainCard = reg(new FlxSprite(CARD_X, CARD_Y).makeGraphic(CARD_W, CARD_H, FlxColor.TRANSPARENT, true), 0.62);
		FlxSpriteUtil.drawRoundRect(mainCard, 0, 0, CARD_W, CARD_H, 28, 28, 0x55FFFFFF);
		FlxSpriteUtil.drawRoundRect(mainCard, 2, 2, CARD_W - 4, CARD_H - 4, 26, 26, 0xFF0D0D14);

		bannerFallback = reg(new FlxSprite(bx, by).makeGraphic(BANNER_W, BANNER_H, FlxColor.WHITE));

		bannerPattern = reg(new FlxSprite(bx, by).makeGraphic(BANNER_W, BANNER_H, FlxColor.TRANSPARENT, true));
		var sx:Int = -BANNER_H;
		while (sx < BANNER_W)
		{
			FlxSpriteUtil.drawLine(bannerPattern, sx, BANNER_H, sx + BANNER_H, 0, {thickness: 10, color: 0x16FFFFFF});
			sx += 36;
		}

		bannerSpr = reg(new FlxSprite(bx, by));
		bannerSpr.visible = false;

		bannerShade = reg(makeGradient(BANNER_W, BANNER_H, 0, 0.78, 1.6));
		bannerShade.setPosition(bx, by);

		bannerFrame = reg(new FlxSprite(bx, by).makeGraphic(BANNER_W, BANNER_H, FlxColor.TRANSPARENT, true), 0.9);
		FlxSpriteUtil.drawRect(bannerFrame, 0, 0, BANNER_W, BANNER_H, FlxColor.TRANSPARENT, {thickness: 6, color: FlxColor.WHITE});

		avatarRing = reg(new FlxSprite(AV_X, AV_Y).makeGraphic(AVATAR, AVATAR, FlxColor.TRANSPARENT, true));
		FlxSpriteUtil.drawRoundRect(avatarRing, 0, 0, AVATAR, AVATAR, 30, 30, FlxColor.WHITE);

		avatarBack = reg(new FlxSprite(AV_X + 5, AV_Y + 5).makeGraphic(AVATAR - 10, AVATAR - 10, FlxColor.TRANSPARENT, true));
		FlxSpriteUtil.drawRoundRect(avatarBack, 0, 0, AVATAR - 10, AVATAR - 10, 22, 22, 0xFF14141C);

		bigIcon = reg(new FlxSprite(AV_X, AV_Y));

		nameText = cast reg(new FlxText(NAME_X, CARD_Y + 244, NAME_W, "", 36));
		nameText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 2;

		badge = reg(new FlxSprite(NAME_X, CARD_Y + 296));
		subTitleText = cast reg(new FlxText(NAME_X + 14, CARD_Y + 300, NAME_W - 28, "", 14));
		subTitleText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);

		divider = reg(new FlxSprite(CARD_X + PAD, CARD_Y + 340).makeGraphic(DESC_W, 2, FlxColor.WHITE), 0.45);

		descText = cast reg(new FlxText(CARD_X + PAD, CARD_Y + 356, DESC_W, "", 24));
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 1.5;

		bottomLine = reg(new FlxSprite(CARD_X + PAD, CARD_Y + 548).makeGraphic(DESC_W, 1, FlxColor.WHITE), 0.2);

		hintText = cast reg(new FlxText(CARD_X + PAD, CARD_Y + 566, DESC_W, "", 16), 0.55);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);

		for (k in 0...MAX_LINKS)
		{
			var chipBg:FlxSprite = reg(new FlxSprite(0, CARD_Y + 554).makeGraphic(CHIP, CHIP, FlxColor.TRANSPARENT, true));
			FlxSpriteUtil.drawRoundRect(chipBg, 0, 0, CHIP, CHIP, 14, 14, FlxColor.WHITE);
			var chipRing:FlxSprite = reg(new FlxSprite().makeGraphic(CHIP + 8, CHIP + 8, FlxColor.TRANSPARENT, true));
			FlxSpriteUtil.drawRoundRect(chipRing, 2, 2, CHIP + 4, CHIP + 4, 16, 16, FlxColor.TRANSPARENT, {thickness: 3, color: FlxColor.WHITE});
			var chipIcon:FlxSprite = reg(new FlxSprite());
			var chipLetter:FlxText = cast reg(new FlxText(0, 0, CHIP, "", 22));
			chipLetter.setFormat(Paths.font("vcr.ttf"), 22, 0xFF222230, CENTER);
			chipBg.visible = chipRing.visible = chipIcon.visible = chipLetter.visible = false;
			chipBgs.push(chipBg);
			chipRings.push(chipRing);
			chipIcons.push(chipIcon);
			chipLetters.push(chipLetter);
		}

		linkPill = reg(new FlxSprite(0, CARD_Y + 516));
		linkText = cast reg(new FlxText(0, CARD_Y + 520, 0, "", 16));
		linkText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
	}

	function makeGradient(w:Int, h:Int, a0:Float, a1:Float, pw:Float):FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		for (y in 0...h)
		{
			var a:Float = a0 + (a1 - a0) * Math.pow(y / (h - 1), pw);
			s.pixels.fillRect(new Rectangle(0, y, w, 1), FlxColor.fromRGBFloat(0, 0, 0, a));
		}
		s.dirty = true;
		s.scrollFactor.set();
		return s;
	}

	function drawPill(spr:FlxSprite, w:Int, h:Int, color:FlxColor)
	{
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(spr, 0, 0, w, h, h, h, color);
	}

	function fitText(t:FlxText, str:String, maxW:Float, maxH:Float, startSize:Int, minSize:Int)
	{
		t.fieldWidth = maxW;
		var s:Int = startSize;
		t.size = s;
		t.text = str;
		while (t.height > maxH && s > minSize)
		{
			s -= 2;
			t.size = s;
		}
		if (t.height > maxH)
		{
			var cut:String = str;
			while (cut.length > 1 && t.height > maxH)
			{
				cut = cut.substr(0, cut.length - 1);
				var e:Int = cut.length;
				while (e > 0 && cut.charCodeAt(e - 1) <= 32) e--;
				t.text = cut.substr(0, e) + '...';
			}
		}
	}

	function alphabetWidth(a:Alphabet):Float
	{
		var l:Float = 1e9;
		var r:Float = -1e9;
		for (m in a.members)
		{
			if (m == null) continue;
			var w:Float = m.frameWidth * m.scale.x;
			var x0:Float = m.x - m.offset.x + (m.frameWidth - w) / 2;
			l = Math.min(l, x0);
			r = Math.max(r, x0 + w);
		}
		return (r > l) ? r - l : 0;
	}

	function fitOption(a:Alphabet, isSelectable:Bool)
	{
		var base:Float = isSelectable ? 0.55 : 0.65;
		var maxW:Float = isSelectable ? SIDE_W - 85 : SIDE_W - 40;
		a.setScale(base);
		var w:Float = alphabetWidth(a);
		if (w > maxW) a.setScale(Math.max(0.28, base * maxW / w));
	}

	function parseLinks(raw:String):Array<String>
	{
		var out:Array<String> = [];
		if (raw == null) return out;
		for (p in ~/[\s|]+/g.split(raw))
			if (p != '') out.push(p);
		return out;
	}

	function serviceKey(url:String):String
	{
		var h:String = hostOf(url).toLowerCase();
		if (h.startsWith('www.')) h = h.substr(4);
		var colon:Int = h.indexOf(':');
		if (colon >= 0) h = h.substr(0, colon);
		var parts:Array<String> = h.split('.');
		var k:String = (parts.length >= 2) ? parts[parts.length - 2] : parts[0];
		return switch (k)
		{
			case 'youtu': 'youtube';
			case 'discordapp': 'discord';
			case 'bsky': 'bsky';
			default: k;
		}
	}

	function sortLinks(urls:Array<String>):Array<String>
	{
		var buckets:Array<Array<String>> = [for (o in SERVICE_ORDER) []];
		var rest:Array<String> = [];
		for (u in urls)
		{
			var idx:Int = SERVICE_ORDER.indexOf(serviceKey(u));
			if (idx >= 0) buckets[idx].push(u);
			else rest.push(u);
		}
		var out:Array<String> = [];
		for (b in buckets) out = out.concat(b);
		out = out.concat(rest);
		return out.slice(0, MAX_LINKS);
	}

	function prettyUrl(url:String):String
	{
		var u:String = url.trim();
		var i:Int = u.indexOf('://');
		if (i >= 0) u = u.substr(i + 3);
		if (u.startsWith('www.')) u = u.substr(4);
		while (u.endsWith('/')) u = u.substr(0, u.length - 1);
		return (u.length > 34) ? u.substr(0, 33) + '...' : u;
	}

	function serviceIconPath(key:String):String
	{
		var candidates:Array<String> = switch (key)
		{
			case 'ko-fi': ['ko-fi-icon', 'ko-fi'];
			case 'x': ['x', 'twitter'];
			case 'gamebanana': ['gamebanana', 'gamebanana-icon'];
			case 'youtube': ['youtube', 'youtube-icon'];
			case 'bsky': ['bluesky', 'bluesky-icon'];
			case 'reddit': ['reddit', 'reddit-icon'];
			case 'instagram': ['instagram', 'instagram-icon'];
			case 'discord': ['discord', 'discord-icon'];
			case 'github': ['github', 'github-icon'];
			default: [key, key + '-icon'];
		};
		for (candidate in candidates)
			if (Paths.fileExists('images/credits/services/$candidate.png', IMAGE))
				return candidate;
		return null;
	}

	function hasServiceIcon(key:String):Bool
	{
		if (!serviceHas.exists(key))
			serviceHas.set(key, serviceIconPath(key) != null);
		return serviceHas.get(key);
	}

	function hostOf(url:String):String
	{
		var u:String = url.trim();
		var i:Int = u.indexOf('://');
		if (i >= 0) u = u.substr(i + 3);
		var j:Int = u.indexOf('/');
		if (j >= 0) u = u.substr(0, j);
		return u;
	}

	function colorOf(i:Int):FlxColor
	{
		var c:Array<String> = creditsStuff[i];
		return (c.length > 4 && c[4] != null && c[4].trim() != '') ? CoolUtil.colorFromString(c[4].trim()) : FlxColor.fromInt(DEFAULT_COLOR);
	}

	function resolveAssets(credit:Array<String>)
	{
		Mods.currentModDirectory = (credit.length > 5) ? credit[5] : '';
		var icon:String = 'credits/missing_icon';
		var banner:String = null;
		var id:String = (credit.length > 1 && credit[1] != null) ? credit[1].trim() : '';
		if (id != '')
		{
			var f:String = 'credits/' + id;
			if (Paths.fileExists('images/$f.png', IMAGE)) icon = f;
			else if (Paths.fileExists('images/$f-pixel.png', IMAGE)) icon = f + '-pixel';

			var b:String = 'credits/banners/' + id;
			if (Paths.fileExists('images/$b.png', IMAGE)) banner = b;
			else if (Paths.fileExists('images/$b-pixel.png', IMAGE)) banner = b + '-pixel';
		}
		var sprite:AttachedSprite = new AttachedSprite(icon);
		if (icon.endsWith('-pixel')) sprite.antialiasing = false;
		sprite.visible = false;
		iconArray.push(sprite);
		add(sprite);
		Mods.currentModDirectory = '';

		iconPaths.push(icon);
		bannerPaths.push(banner);
		bannerState.push(0);

		var urls:Array<String> = sortLinks((credit.length > 3) ? parseLinks(credit[3]) : []);
		linkUrls.push(urls);
		linkKeys.push([for (u in urls) serviceKey(u)]);
	}

	function applyAccent(c:FlxColor)
	{
		var a:FlxColor = c;
		var lum:Float = 0.299 * a.red + 0.587 * a.green + 0.114 * a.blue;
		if (lum < 90) a = a.getLightened(0.4);
		accent = a;
		avatarRing.color = a;
		bannerFrame.color = a;
		divider.color = a;
		selPill.color = a;
		sideEdge.color = a;
		scrollThumb.color = a;
		bannerFallback.color = a.getDarkened(0.45);
	}

	function loadAvatar(path:String)
	{
		bigIcon.loadGraphic(Paths.image(path));
		bigIcon.antialiasing = path.endsWith('-pixel') ? false : ClientPrefs.data.antialiasing;
		var s:Float = Math.min(ICON_FIT / bigIcon.frameWidth, ICON_FIT / bigIcon.frameHeight);
		bigIcon.scale.set(s, s);
		bigIcon.updateHitbox();
		bigIcon.x = AV_X + (AVATAR - bigIcon.width) / 2;
		bigIcon.y = AV_Y + (AVATAR - bigIcon.height) / 2;
	}

	function bannerDivisor(w:Int, h:Int):Int
	{
		if (w > BANNER_W * 4 || h > BANNER_H * 4) return 0;
		var d:Int = 1;
		while (w > BANNER_W && h > BANNER_H && w % 2 == 0 && h % 2 == 0)
		{
			w = Std.int(w / 2);
			h = Std.int(h / 2);
			d *= 2;
		}
		return (w == BANNER_W && h == BANNER_H) ? d : 0;
	}

	function loadBanner(idx:Int)
	{
		var path:String = bannerPaths[idx];
		var g:FlxGraphic = null;
		if (path != null && bannerState[idx] >= 0)
		{
			g = Paths.image(path);
			if (g == null || bannerDivisor(g.width, g.height) == 0)
			{
				if (g != null) trace('[Credits] banner "$path" is ${g.width}x${g.height}: allowed sizes are 748x220, 1496x440, 2992x880');
				bannerState[idx] = -1;
				g = null;
			}
		}
		var has:Bool = g != null;
		bannerFallback.visible = bannerPattern.visible = !has;
		bannerSpr.visible = has;
		if (!has) return;

		bannerSpr.loadGraphic(g);
		bannerSpr.antialiasing = path.endsWith('-pixel') ? false : ClientPrefs.data.antialiasing;
		var s:Float = BANNER_W / bannerSpr.frameWidth;
		bannerSpr.scale.set(s, s);
		bannerSpr.updateHitbox();
		bannerSpr.setPosition(CARD_X + BANNER_PAD, CARD_Y + BANNER_PAD);
	}

	function refreshChips()
	{
		var n:Int = linkUrls[curSelected].length;
		for (k in 0...n)
		{
			var on:Bool = (k == linkFocus);
			chipRings[k].visible = on;
			chipBgs[k].color = on ? 0xFFFFFFFF : 0xFFC9C9D4;
		}
		linkPill.visible = linkText.visible = (n > 0);
		if (n == 0) return;

		var label:String = prettyUrl(linkUrls[curSelected][linkFocus]);
		linkText.text = label;
		var lw:Int = Std.int(linkText.textField.textWidth) + 28;
		drawPill(linkPill, lw, 26, accent.getDarkened(0.45));
		var cx:Float = chipBgs[linkFocus].x + CHIP / 2;
		linkPill.x = Math.min(cx - lw / 2, CARD_X + CARD_W - PAD - lw + cardGroup.x);
		linkText.x = linkPill.x + 14;
	}

	function moveLink(d:Int)
	{
		var n:Int = linkUrls[curSelected].length;
		if (n < 2) return;
		linkFocus = FlxMath.wrap(linkFocus + d, 0, n - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
		refreshChips();
	}

	function openLink(k:Int)
	{
		var urls:Array<String> = linkUrls[curSelected];
		if (k >= 0 && k < urls.length)
			CoolUtil.browserLoad(urls[k]);
	}

	function leave()
	{
		if (quitting) return;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		FlxG.mouse.visible = prevMouse;
		MusicBeatState.switchState(new MainMenuState());
		quitting = true;
	}

	function handleMouse()
	{
		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;
		var click:Bool = FlxG.mouse.justPressed;

		if (FlxG.mouse.wheel != 0 && creditsStuff.length > 1)
			changeSelection(FlxG.mouse.wheel > 0 ? -1 : 1);

		var overBack:Bool = mx >= backPill.x && mx <= backPill.x + backPill.width && my >= backPill.y && my <= backPill.y + backPill.height;
		backPill.alpha = overBack ? 0.5 : 0.25;
		if (overBack && click)
		{
			leave();
			return;
		}

		var hoverRow:Int = -1;
		if (mx < SIDE_W && my > 100 && my < FlxG.height - 70)
		{
			for (i in 0...grpOptions.members.length)
			{
				if (!selectable[i]) continue;
				if (Math.abs(my - (grpOptions.members[i].y + grpOptions.members[i].height / 2)) <= 36)
				{
					hoverRow = i;
					break;
				}
			}
		}
		if (hoverRow >= 0 && hoverRow != curSelected)
		{
			hoverPill.visible = true;
			hoverPill.y = grpOptions.members[hoverRow].y - 8;
			if (click) changeSelection(hoverRow - curSelected);
		}
		else
			hoverPill.visible = false;

		var n:Int = linkUrls[curSelected].length;
		for (k in 0...n)
		{
			var b:FlxSprite = chipBgs[k];
			if (mx >= b.x && mx <= b.x + CHIP && my >= b.y && my <= b.y + CHIP)
			{
				if (k != linkFocus)
				{
					linkFocus = k;
					refreshChips();
				}
				if (click) openLink(k);
				break;
			}
		}
	}

	function setCardAlpha(v:Float)
	{
		for (i in 0...fadeParts.length)
			fadeParts[i].alpha = fadeBase[i] * v;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
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

			if (hasLink)
			{
				if (controls.UI_LEFT_P) moveLink(-1);
				if (controls.UI_RIGHT_P) moveLink(1);
				if (controls.ACCEPT) openLink(linkFocus);
			}
			if (controls.BACK)
				leave();
			else
				handleMouse();
		}

		var lerpVal:Float = FlxMath.bound(elapsed * 10, 0, 1);
		var rowY:Float = FlxG.height * 0.45;
		for (i in 0...grpOptions.members.length)
		{
			var item:Alphabet = grpOptions.members[i];
			var targetX:Float = selectable[i] ? (item.targetY == 0 ? 65 : 45) : 20;
			item.x = FlxMath.lerp(item.x, targetX, lerpVal);
			item.y = FlxMath.lerp(item.y, (item.targetY * ROW_STEP) + rowY + 20 - item.height / 2, lerpVal);
		}

		if (curSelected >= 0 && selectableCount > 0)
		{
			var travel:Float = scrollTrack.height - scrollThumb.height;
			var t:Float = (selectableCount > 1) ? rankOf[curSelected] / (selectableCount - 1) : 0;
			scrollThumb.y = FlxMath.lerp(scrollThumb.y, scrollTrack.y + travel * t, lerpVal);
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		var step:Int = (change < 0) ? -1 : 1;
		curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		while(!selectable[curSelected])
			curSelected = FlxMath.wrap(curSelected + step, 0, creditsStuff.length - 1);

		var c:Array<String> = creditsStuff[curSelected];

		var newColor:FlxColor = colorOf(curSelected);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.45, bg.color, intendedColor, {ease: FlxEase.quadOut});
		}
		applyAccent(newColor);

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
			if(selectable[num]) {
				if (item.targetY == 0) {
					item.alpha = 1.0;
					item.color = FlxColor.WHITE;
				} else {
					item.alpha = 0.4;
					item.color = FlxColor.WHITE;
				}
			} else {
				item.alpha = (Math.abs(item.targetY) <= 3) ? 0.7 : 0.2;
				item.color = FlxColor.WHITE;
			}
		}

		sideCount.text = (rankOf[curSelected] + 1) + ' / ' + selectableCount;

		if (cardTween != null) cardTween.cancel();
		if (fadeTween != null) fadeTween.cancel();
		cardGroup.x = 0;

		Mods.currentModDirectory = (c.length > 5) ? c[5] : '';
		loadAvatar(iconPaths[curSelected]);
		loadBanner(curSelected);
		Mods.currentModDirectory = '';

		fitText(nameText, c[0], NAME_W, 48, 36, 16);

		var cat:String = (lastCategory == null) ? '' : lastCategory.toUpperCase();
		badge.visible = subTitleText.visible = (cat != '');
		if (cat != '')
		{
			fitText(subTitleText, cat, NAME_W - 28, 22, 14, 10);
			drawPill(badge, Std.int(subTitleText.textField.textWidth) + 28, 24, accent.getDarkened(0.35));
		}

		fitText(descText, (c.length > 2 && c[2] != null) ? c[2] : '', DESC_W, DESC_H, 24, 14);

		var urls:Array<String> = linkUrls[curSelected];
		var n:Int = urls.length;
		hasLink = n > 0;
		linkFocus = 0;
		var chipsW:Int = (n > 0) ? n * CHIP + (n - 1) * CHIP_GAP : 0;
		var chipX:Int = CARD_X + CARD_W - PAD - chipsW;
		for (k in 0...MAX_LINKS)
		{
			chipIcons[k].visible = chipLetters[k].visible = false;
			if (k >= n)
			{
				chipBgs[k].visible = chipRings[k].visible = false;
				continue;
			}
			var bx:Int = chipX + k * (CHIP + CHIP_GAP);
			var by:Int = CARD_Y + 554;
			chipBgs[k].visible = true;
			chipBgs[k].setPosition(bx, by);
			chipRings[k].setPosition(bx - 4, by - 4);
			var key:String = linkKeys[curSelected][k];
			if (hasServiceIcon(key))
			{
				var ic:FlxSprite = chipIcons[k];
				ic.loadGraphic(Paths.image('credits/services/' + serviceIconPath(key)));
				ic.antialiasing = ClientPrefs.data.antialiasing;
				var sc:Float = Math.min(28 / ic.frameWidth, 28 / ic.frameHeight);
				ic.scale.set(sc, sc);
				ic.updateHitbox();
				ic.setPosition(bx + (CHIP - ic.width) / 2, by + (CHIP - ic.height) / 2);
				ic.visible = true;
			}
			else
			{
				var lt:FlxText = chipLetters[k];
				lt.text = key.charAt(0).toUpperCase();
				lt.setPosition(bx, by + 8);
				lt.visible = true;
			}
		}
		refreshChips();

		var accept:String = controls.mobileC ? 'A' : 'ENTER';
		var back:String = controls.mobileC ? 'B' : 'ESC';
		var hint:String = (hasLink ? '$accept open link   ' : '') + ((n > 1 && !controls.mobileC) ? 'LEFT/RIGHT pick   ' : '') + '$back exit' + (controls.mobileC ? '' : '   SHIFT scroll x3');
		fitText(hintText, hint, DESC_W - ((n > 0) ? chipsW + 24 : 0), 22, 16, 10);

		cardGroup.x = 30;
		setCardAlpha(0);
		cardTween = FlxTween.tween(cardGroup, {x: 0}, 0.28, {ease: FlxEase.backOut});
		fadeTween = FlxTween.num(0, 1, 0.22, {ease: FlxEase.quadOut}, setCardAlpha);
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
