package mikolka.vslice.ui;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import mikolka.compatibility.ui.StoryModeHooks;
import mikolka.compatibility.ModsHelper;
import mikolka.vslice.StickerSubState;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
#if !LEGACY_PSYCH
import backend.CacheSystem;
import states.editors.MasterEditorMenu;
import backend.WeekData;
import backend.Highscore;
import objects.MenuItem;
import objects.MenuCharacter;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
#else
import Paths as CacheSystem;
import editors.MasterEditorMenu;
#end

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	private static var lastDifficultyName:String = '';
	public static var curWeek:Int = 0;

	var scoreText:FlxText;
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var txtTracklist:FlxText;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	public var curDifficulty:Int = 1;
	public var curSelectedPartial:Float = 0;
	public var loadedWeeks:Array<WeekData> = [];

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;
	var difficultySelectors:FlxGroup;
	var stickerSubState:StickerSubState;

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;
	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	public function new(?stickers:StickerSubState = null)
	{
		super();
		if (stickers != null) stickerSubState = stickers;
	}

	override function create()
	{
		if (stickerSubState != null)
		{
			openSubState(stickerSubState);
			ModsHelper.clearStoredWithoutStickers();
			stickerSubState.degenStickers();
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		else
			CacheSystem.clearStoredMemory();
		
		CacheSystem.clearUnusedMemory();
		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		PlayState.altInstrumentals = null;
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		final accept:String = controls.mobileC ? "A" : "ACCEPT";
		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			UserErrorSubstate.makeMessage("NO LEVELS ADDED FOR STORY MODE", "\n\nPress " + accept + " to go to the Week Editor Menu.");
			subStateClosed.addOnce(s -> FlxG.switchState(new MasterEditorMenu()));
			return;
		}

		if (curWeek >= WeekData.weeksList.length) curWeek = 0;

		scoreText = new FlxText(10, 10, 0, #if LEGACY_PSYCH 'LEVEL SCORE: ' + lerpScore #else Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]) #end, 36);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = VsliceOptions.ANTIALIASING;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = FreeplayHelpers.weekIsLocked(WeekData.weeksList[i]);
			if ((!isLocked || !weekFile.hiddenUntilUnlocked) && weekFile != null)
			{
				loadedWeeks.push(weekFile);
				ModsHelper.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				itemTargetY += Math.max(weekThing.height, 110) + 10;
				grpWeekText.add(weekThing);
				weekThing.screenCenter(X);

				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.antialiasing = VsliceOptions.ANTIALIASING;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = num;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		ModsHelper.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(FlxG.width - 430, grpWeekText.members[0].y + 10);
		leftArrow.antialiasing = VsliceOptions.ANTIALIASING;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		StoryModeHooks.resetDiffList();
		if (lastDifficultyName == '') lastDifficultyName = StoryModeHooks.DEFAULT_DIFF;
		curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = VsliceOptions.ANTIALIASING;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = VsliceOptions.ANTIALIASING;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 56, 0xFF000000));
		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.05 + 160, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = VsliceOptions.ANTIALIASING;
		tracksSprite.x -= tracksSprite.width / 2;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
		var button = new TouchZone((FlxG.width / 2) - 210, 460, 420, 160, FlxColor.PURPLE);
		var scroll = new ScrollableObject(-0.01, (FlxG.width / 2) - 240, 0, 500, FlxG.height, button);
		scroll.onPartialScroll.add(delta -> changeWeek(delta, false));
		scroll.onFullScroll.add(delta -> changeDifficulty());
		scroll.onFullScrollSnap.add(() -> changeWeek(0, true));
		scroll.onTap.add(() -> selectWeek());
		add(scroll);
		add(button);
		#end

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		if (WeekData.weeksList.length > 0) changeWeek();
		super.closeSubState();
		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
		#end
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		if (intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if (Math.abs(intendedScore - lerpScore) < 10)
				lerpScore = intendedScore;

			scoreText.text = #if LEGACY_PSYCH 'LEVEL SCORE: ${lerpScore}' #else Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]) #end;
		}

		if (!movedBack && !selectedWeek)
		{
			var changeDiff = false;
			if (controls.UI_UP_P)
			{
				changeWeek(-1, true);
				changeDiff = true;
			}

			if (controls.UI_DOWN_P)
			{
				changeWeek(1, true);
				changeDiff = true;
			}

			if (FlxG.mouse.wheel != 0)
			{
				changeWeek(-FlxG.mouse.wheel, true);
				changeDifficulty();
			}

			var holdingUiRight = controls.UI_RIGHT;
			var holdingUiLeft = controls.UI_LEFT;
			var pressedUiLeft = controls.UI_LEFT_P;
			var pressedUiRight = controls.UI_RIGHT_P;
			#if TOUCH_CONTROLS_ALLOWED
			if (TouchUtil.overlaps(leftArrow))
			{
				holdingUiLeft = true;
				pressedUiLeft = TouchUtil.justPressed;
			}
			if (TouchUtil.overlaps(rightArrow))
			{
				holdingUiRight = true;
				pressedUiRight = TouchUtil.justPressed;
			}
			#end

			rightArrow.animation.play(holdingUiRight ? 'press' : 'idle');
			leftArrow.animation.play(holdingUiLeft ? 'press' : 'idle');

			if (pressedUiRight) changeDifficulty(1);
			else if (pressedUiLeft) changeDifficulty(-1);
			else if (changeDiff) changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonX.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
				#if TOUCH_CONTROLS_ALLOWED removeTouchPad(); #end
			}
			else if (controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonY.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				#if TOUCH_CONTROLS_ALLOWED removeTouchPad(); #end
			}
			else if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
		var offY:Float = grpWeekText.members[curWeek].targetY;

		var partialDiff = (curSelectedPartial - curWeek);
		var curItem = grpWeekText.members[curWeek];
		if (partialDiff > 0 && grpWeekText.length > curWeek + 1)
		{
			offY = FlxMath.lerp(curItem.targetY, grpWeekText.members[curWeek + 1].targetY, partialDiff);
		}
		else if (partialDiff < 0 && 0 <= curWeek - 1)
		{
			offY = FlxMath.lerp(grpWeekText.members[curWeek - 1].targetY, curItem.targetY, 1 + partialDiff);
		}

		var currentExpLerp:Float = Math.exp(-elapsed * 10.2);
		for (item in grpWeekText.members)
			item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, currentExpLerp);

		for (lock in grpLocks.members)
		{
			var currentBoundItem = grpWeekText.members[lock.ID];
			lock.y = currentBoundItem.y + (currentBoundItem.height - lock.height) / 2;
		}
	}

	function selectWeek()
	{
		if (!FreeplayHelpers.weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var succsess = StoryModeHooks.prepareWeek(this);
			if (!succsess) return;
			
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				grpWeekText.members[curWeek].isFlashing = true;
				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.animation.play('confirm');
					}
				}
				stopspamming = true;
			}
			StoryModeHooks.moveWeekToPlayState();
		}
		else
			FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;
		if (curDifficulty < 0) curDifficulty = StoryModeHooks.DIFFICULTIES.length - 1;
		if (curDifficulty >= StoryModeHooks.DIFFICULTIES.length) curDifficulty = 0;

		ModsHelper.setDirectoryFromWeek(loadedWeeks[curWeek]);
		var diff:String = StoryModeHooks.getDifficultyString(curDifficulty);

		if (Paths.fileExists('images/menudifficulties/' + Paths.formatToSongPath(diff) + ".xml", BINARY))
		{
			var newFrames = Paths.getSparrowAtlas('menudifficulties/' + Paths.formatToSongPath(diff));
			sprDifficulty.frames = newFrames;
			sprDifficulty.animation.addByPrefix('idle', 'idle0', 24, true);
			if (VsliceOptions.FLASHBANG) sprDifficulty.animation.play('idle');
		}
		else
		{
			var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
			if (sprDifficulty.graphic != newImage) sprDifficulty.loadGraphic(newImage);
		}
		
		sprDifficulty.x = leftArrow.x + 60 + (308 - sprDifficulty.width) / 3;
		sprDifficulty.alpha = 0;
		sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

		FlxTween.cancelTweensOf(sprDifficulty);
		FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	function changeWeek(change:Float = 0, usePrecision:Bool = false):Void
	{
		if (usePrecision)
		{
			if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curWeek = FlxMath.wrap(curWeek + Std.int(change), 0, loadedWeeks.length - 1);
			curSelectedPartial = curWeek;
		}
		else
		{
			curSelectedPartial = FlxMath.bound(curSelectedPartial + change, 0, loadedWeeks.length - 1);
			if (curWeek != Math.round(curSelectedPartial)) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curWeek = Math.round(curSelectedPartial);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		ModsHelper.setDirectoryFromWeek(leWeek);

		txtWeekTitle.text = #if LEGACY_PSYCH leWeek.storyName.toUpperCase() #else Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName).toUpperCase() #end;
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var unlocked:Bool = !FreeplayHelpers.weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members)
		{
			item.alpha = (num == curWeek && unlocked) ? 1.0 : 0.6;
		}

		var assetName:String = leWeek.weekBackground;
		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.visible = true;
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			if (MobileScaleMode.enabled) bgSprite.screenCenter(X);
		}
		PlayState.storyWeek = curWeek;

		StoryModeHooks.loadDifficultiesFromWeek();
		difficultySelectors.visible = unlocked;

		if (StoryModeHooks.DIFFICULTIES.contains(StoryModeHooks.DEFAULT_DIFF))
			curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(StoryModeHooks.DEFAULT_DIFF)));
		else
			curDifficulty = 0;

		var newPos:Int = StoryModeHooks.DIFFICULTIES.indexOf(lastDifficultyName);
		if (newPos > -1) curDifficulty = newPos;
		updateText();
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = stringThing.join('\n').toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}