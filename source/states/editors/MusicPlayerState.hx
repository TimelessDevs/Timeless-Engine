package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.Paths;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import flixel.ui.FlxBar;
import flash.media.Sound;
import openfl.geom.Rectangle;

using StringTools;

typedef TrackInfo = {
	var name:String;
	var folder:String;
	var bpm:Float;
	var playerIcon:String;
	var opponentIcon:String;
}

class MusicPlayerState extends backend.MusicBeatState
{
	private var playlist:Array<TrackInfo> = [];
	private var customPlaylist:Array<TrackInfo> = [];
	private var grpTexts:FlxTypedGroup<FlxText>;
	private var curSelected:Int = 0;

	private var bg:FlxSprite;
	private var neonGrid:FlxSprite;
	private var glassPanel:FlxSprite;
	private var panelBorder:FlxSprite;
	
	private var currentTrackTitle:FlxText;
	private var timeText:FlxText;
	private var bpmText:FlxText;
	private var pitchText:FlxText;
	private var modeText:FlxText;
	private var helpText:FlxText;
	
	private var timeBar:FlxBar;
	private var timeBarBg:FlxSprite;
	
	private var btnCreatePlaylist:FlxSprite;
	private var txtCreatePlaylist:FlxText;
	private var btnShare:FlxSprite;
	private var txtShare:FlxText;
	
	private var playerVocalsTxt:FlxText;
	private var opponentVocalsTxt:FlxText;
	private var instrumentalTxt:FlxText;
	private var volumeTxt:FlxText;
	
	private var iconPlayer:objects.HealthIcon;
	private var iconOpponent:objects.HealthIcon;
	
	private var vocalsPlayer:flixel.sound.FlxSound;
	private var vocalsOpponent:flixel.sound.FlxSound;

	private var isPlaying:Bool = true;
	private var currentPitch:Float = 1.0;
	private var loopMode:Bool = false;
	private var shuffleMode:Bool = false;
	private var customPlaylistMode:Bool = false;
	
	private var playerVocalsEnabled:Bool = true;
	private var opponentVocalsEnabled:Bool = true;
	private var instrumentalEnabled:Bool = true;
	private var currentVolume:Float = 1.0;
	
	private var runtimeTimer:Float = 0;
	private var visualScrollY:Float = 0;
	private var textPulseTimer:Float = 0;
	private var beatInterval:Float = 0;

	private var spectrumBars:Array<FlxSprite> = [];
	private var spectrumGroup:FlxTypedGroup<FlxSprite>;
	private var nextWaveTimer:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Inside the Cyber-Jukebox Juggernaut", null);
		#end

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		vocalsPlayer = new flixel.sound.FlxSound();
		vocalsOpponent = new flixel.sound.FlxSound();
		FlxG.sound.list.add(vocalsPlayer);
		FlxG.sound.list.add(vocalsOpponent);

		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF080112; 
		bg.scrollFactor.set();
		add(bg);

		neonGrid = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		neonGrid.scrollFactor.set();
		add(neonGrid);

		scanAvailableSoundtracks();

		grpTexts = new FlxTypedGroup<FlxText>();
		add(grpTexts);

		for (i in 0...playlist.length) {
			var trackText:FlxText = new FlxText(60, 0, 550, playlist[i].name.toLowerCase(), 36);
			trackText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF0D021A);
			trackText.ID = i;
			grpTexts.add(trackText);
		}

		panelBorder = new FlxSprite(658, 108).makeGraphic(574, 504, FlxColor.TRANSPARENT);
		panelBorder.scrollFactor.set();
		flixel.util.FlxSpriteUtil.drawRoundRect(panelBorder, 0, 0, 574, 504, 24, 24, 0xFFBF55EC);
		add(panelBorder);

		glassPanel = new FlxSprite(660, 110).makeGraphic(570, 500, FlxColor.TRANSPARENT); 
		glassPanel.scrollFactor.set();
		flixel.util.FlxSpriteUtil.drawRoundRect(glassPanel, 0, 0, 570, 500, 20, 20, 0xCC130924);
		add(glassPanel);

		btnCreatePlaylist = new FlxSprite(510, 30).makeGraphic(210, 50, FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRect(btnCreatePlaylist, 0, 0, 210, 50, FlxColor.TRANSPARENT, {color: 0xFFBF55EC, thickness: 4});
		add(btnCreatePlaylist);

		txtCreatePlaylist = new FlxText(510, 42, 210, "FAVORITES MODE", 18);
		txtCreatePlaylist.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center", flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txtCreatePlaylist);

		btnShare = new FlxSprite(1020, 30).makeGraphic(130, 50, FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRect(btnShare, 0, 0, 130, 50, FlxColor.TRANSPARENT, {color: 0xFFBF55EC, thickness: 4});
		add(btnShare);

		txtShare = new FlxText(1020, 42, 130, "ADD TO FAV", 18);
		txtShare.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center", flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txtShare);

		currentTrackTitle = new FlxText(680, 135, 530, "SOUNDTRACK", 32);
		currentTrackTitle.setFormat(Paths.font("vcr.ttf"), 32, 0xFFBF55EC, "center", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF4A0E4E);
		add(currentTrackTitle);

		timeText = new FlxText(680, 235, 250, "00:00 / 00:00", 22);
		timeText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFE8DAEF, "left");
		add(timeText);

		bpmText = new FlxText(680, 265, 250, "BPM: 0.0", 18);
		bpmText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFD2B4DE, "left");
		add(bpmText);

		pitchText = new FlxText(680, 285, 250, "SPEED: 1.00x", 18);
		pitchText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFD2B4DE, "left");
		add(pitchText);

		modeText = new FlxText(680, 305, 250, "MODE: ALL SONGS", 18);
		modeText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF00FF66, "left");
		add(modeText);

		playerVocalsTxt = new FlxText(680, 335, 400, "Player vocals: enabled", 18);
		playerVocalsTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "left");
		add(playerVocalsTxt);

		opponentVocalsTxt = new FlxText(680, 360, 400, "Opponent vocals: enabled", 18);
		opponentVocalsTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "left");
		add(opponentVocalsTxt);

		instrumentalTxt = new FlxText(680, 385, 400, "Instrumental: enabled", 18);
		instrumentalTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "left");
		add(instrumentalTxt);

		volumeTxt = new FlxText(680, 420, 500, "VOLUME: 1.0", 28);
		volumeTxt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, "left", flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(volumeTxt);

		helpText = new FlxText(658, 625, 574, "[W/S] Nav | [Arrows] Skip 10s | [Click Timebar] Seek\n[Q/E] Pitch | [L] Loop | [H] Shuffle | [R] Reset Track\n[Space] press to pause/unpause | [1/2/3] Toggle stems", 12);
		helpText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFBF55EC, "center", flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.visible = false;
		add(helpText);

		timeBarBg = new FlxSprite(680, 195).makeGraphic(530, 24, 0xFF2C163F);
		add(timeBarBg);

		timeBar = new FlxBar(682, 197, LEFT_TO_RIGHT, 526, 20, this, 'trackTimeProgress', 0, 100);
		timeBar.createFilledBar(0xFF2C163F, 0xFFBF55EC);
		add(timeBar);

		iconOpponent = new objects.HealthIcon('dad', false);
		iconOpponent.setPosition(930, 260);
		add(iconOpponent);

		iconPlayer = new objects.HealthIcon('bf', true);
		iconPlayer.setPosition(1050, 260);
		iconPlayer.scale.x = -1;
		add(iconPlayer);

		spectrumGroup = new FlxTypedGroup<FlxSprite>();
		add(spectrumGroup);

		for (i in 0...16) {
			var bar = new FlxSprite(680 + (i * 33), 460).makeGraphic(25, 140, 0xFFBF55EC);
			bar.scrollFactor.set();
			bar.origin.y = bar.height;
			spectrumGroup.add(bar);
			spectrumBars.push(bar);
		}

		#if mobile
		touchPad = new mobile.objects.TouchPad("FULL", "A_B_C_D_E");
		add(touchPad);
		#end

		changeTrackSelection(0);
		playSelectedTrackAudio();

		super.create();
	}

	public var trackTimeProgress(get, null):Float;
	private function get_trackTimeProgress():Float {
		if (FlxG.sound.music != null && FlxG.sound.music.length > 0)
			return (FlxG.sound.music.time / FlxG.sound.music.length) * 100;
		return 0;
	}

	private function scanAvailableSoundtracks():Void
	{
		playlist.clear();
		playlist.push({name: "freaky menu", folder: "freakyMenu", bpm: 102, playerIcon: "bf", opponentIcon: "dad"});

		var songsPath:String = "assets/songs/";
		if (FileSystem.exists(songsPath)) {
			for (folder in FileSystem.readDirectory(songsPath)) {
				if (FileSystem.isDirectory(songsPath + folder)) {
					var meta = getTrackMetaInfo(folder);
					playlist.push({
						name: folder.replace('-', ' '), 
						folder: folder,
						bpm: meta.bpm,
						playerIcon: meta.p1,
						opponentIcon: meta.p2
					});
				}
			}
		}
	}

	private function changeTrackSelection(change:Int = 0):Void
	{
		var currentList = customPlaylistMode ? customPlaylist : playlist;
		if (currentList.length == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, currentList.length - 1);
		
		var track = currentList[curSelected];
		currentTrackTitle.text = track.name.toUpperCase();
		
		var calculatedBPM:Float = track.bpm * currentPitch;
		bpmText.text = "BPM: " + FlxMath.roundDecimal(calculatedBPM, 0);
		beatInterval = (60 / calculatedBPM) * 1000;

		currentTrackTitle.scale.set(1.3, 1.3);
		currentTrackTitle.angle = change > 0 ? 12 : -12;
		FlxTween.tween(currentTrackTitle.scale, {x: 1.0, y: 1.0}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(currentTrackTitle, {angle: 0}, 0.4, {ease: FlxEase.elasticOut});

		remove(iconPlayer); remove(iconOpponent);
		iconPlayer = new objects.HealthIcon(track.playerIcon, true);
		iconPlayer.setPosition(1050, 260);
		iconPlayer.scale.x = -1;
		add(iconPlayer);

		iconOpponent = new objects.HealthIcon(track.opponentIcon, false);
		iconOpponent.setPosition(930, 260);
		add(iconOpponent);

		if (txtShare != null) {
			txtShare.text = customPlaylistMode ? "REMOVE FAV" : "ADD TO FAV";
		}
	}

	private function playSelectedTrackAudio():Void
	{
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		vocalsPlayer.stop();
		vocalsOpponent.stop();

		var currentList = customPlaylistMode ? customPlaylist : playlist;
		if (currentList.length == 0) return;

		var track = currentList[curSelected];
		var songFolder:String = 'assets/songs/' + track.folder;
		var audioExts:Array<String> = ['.ogg', '.wav', '.mp3'];
		
		if (track.folder == "freakyMenu") {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), instrumentalEnabled ? currentVolume : 0);
		} else {
			var instFound:Bool = false;
			for (ext in audioExts) {
				var checkPath:String = songFolder + '/Inst' + ext;
				if (sys.FileSystem.exists(checkPath)) {
					FlxG.sound.playMusic(Sound.fromFile(checkPath), instrumentalEnabled ? currentVolume : 0);
					instFound = true;
					break;
				}
			}
			if (!instFound) FlxG.sound.playMusic(Paths.inst(track.folder), instrumentalEnabled ? currentVolume : 0);
			
			var sharedVocFound:Bool = false;
			var splitVocFound:Bool = false;

			for (ext in audioExts) {
				if (sys.FileSystem.exists(songFolder + '/Voices-Player' + ext) || sys.FileSystem.exists(songFolder + '/Voices-Opponent' + ext)) {
					splitVocFound = true;
					break;
				}
			}

			if (!splitVocFound) {
				for (ext in audioExts) {
					var checkPath:String = songFolder + '/Voices' + ext;
					if (sys.FileSystem.exists(checkPath)) {
						vocalsPlayer.loadEmbedded(Sound.fromFile(checkPath));
						sharedVocFound = true;
						break;
					}
				}
				if (!sharedVocFound) {
					var fallbackVoc = Paths.voices(track.folder);
					if (fallbackVoc != null) {
						vocalsPlayer.loadEmbedded(fallbackVoc);
						sharedVocFound = true;
					}
				}
			} else {
				for (ext in audioExts) {
					var checkPath:String = songFolder + '/Voices-Player' + ext;
					if (sys.FileSystem.exists(checkPath)) { vocalsPlayer.loadEmbedded(Sound.fromFile(checkPath)); break; }
				}
				for (ext in audioExts) {
					var checkPath:String = songFolder + '/Voices-Opponent' + ext;
					if (sys.FileSystem.exists(checkPath)) { vocalsOpponent.loadEmbedded(Sound.fromFile(checkPath)); break; }
				}
			}

			if (!splitVocFound && sharedVocFound) {
				playerVocalsTxt.text = "Vocals: " + (playerVocalsEnabled ? "enabled" : "disabled");
				opponentVocalsTxt.text = "";
			} else {
				playerVocalsTxt.text = "Player vocals: " + (playerVocalsEnabled ? "enabled" : "disabled");
				opponentVocalsTxt.text = "Opponent vocals: " + (opponentVocalsEnabled ? "enabled" : "disabled");
			}

			if(vocalsPlayer.active) { vocalsPlayer.volume = playerVocalsEnabled ? currentVolume : 0; vocalsPlayer.play(); }
			if(vocalsOpponent.active) { vocalsOpponent.volume = opponentVocalsEnabled ? currentVolume : 0; vocalsOpponent.play(); }
		}
		
		if (FlxG.sound.music != null) {
			FlxG.sound.music.pitch = currentPitch;
			vocalsPlayer.pitch = currentPitch;
			vocalsOpponent.pitch = currentPitch;
			isPlaying = true;
			backend.Conductor.bpm = track.bpm;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		runtimeTimer += elapsed;
		textPulseTimer += elapsed * 5;
		nextWaveTimer += elapsed * 12;

		if (FlxG.sound.music != null && FlxG.sound.music.playing) {
			backend.Conductor.songPosition = FlxG.sound.music.time;
			
			if(vocalsPlayer.active && Math.abs(vocalsPlayer.time - FlxG.sound.music.time) > 20) vocalsPlayer.time = FlxG.sound.music.time;
			if(vocalsOpponent.active && Math.abs(vocalsOpponent.time - FlxG.sound.music.time) > 20) vocalsOpponent.time = FlxG.sound.music.time;

			for (i in 0...spectrumBars.length) {
				var wave:Float = Math.sin(nextWaveTimer + (i * 0.7)) * 40;
				var soundPulse:Float = 0;
				if (vocalsPlayer.active && vocalsPlayer.playing) soundPulse += Math.abs(Math.sin(vocalsPlayer.time * 0.01));
				if (vocalsOpponent.active && vocalsOpponent.playing) soundPulse += Math.abs(Math.cos(vocalsOpponent.time * 0.01));
				
				var targetHeight:Float = Math.max(10, 35 + (wave * (soundPulse > 0 ? soundPulse : 0.45)));
				spectrumBars[i].scale.y = FlxMath.lerp(spectrumBars[i].scale.y, targetHeight / 140, FlxMath.bound(elapsed * 15, 0, 1));
			}
		} else {
			for (bar in spectrumBars)
				bar.scale.y = FlxMath.lerp(bar.scale.y, 10 / 140, FlxMath.bound(elapsed * 8, 0, 1));
		}

		var currentList = customPlaylistMode ? customPlaylist : playlist;
		visualScrollY = FlxMath.lerp(visualScrollY, curSelected * 70, FlxMath.bound(elapsed * 10, 0, 1));
		
		for (txt in grpTexts.members) {
			txt.y = (FlxG.height / 2) - visualScrollY + (txt.ID * 70) - 40;
			
			if (currentList.length > txt.ID && txt.ID == curSelected) {
				txt.text = "> " + currentList[txt.ID].name.toUpperCase() + " <";
				txt.color = 0xFFBF55EC;
				txt.alpha = 1.0;
				var pulse:Float = 1.0 + (Math.sin(textPulseTimer) * 0.03);
				txt.scale.set(pulse, pulse);
			} else if (currentList.length > txt.ID) {
				txt.text = currentList[txt.ID].name.toLowerCase();
				txt.color = FlxColor.WHITE;
				txt.scale.set(1.0, 1.0);
				txt.alpha = FlxMath.bound(1.0 - (Math.abs(txt.ID - curSelected) * 0.3), 0.1, 0.8);
			} else {
				txt.text = "";
			}
		}
		if (FlxG.mouse.pressed && FlxG.mouse.x >= timeBarBg.x && FlxG.mouse.x <= (timeBarBg.x + timeBarBg.width) &&
			FlxG.mouse.y >= timeBarBg.y && FlxG.mouse.y <= (timeBarBg.y + timeBarBg.height))
		{
			if (FlxG.sound.music != null && FlxG.sound.music.length > 0) {
				var clickRatio = (FlxG.mouse.x - timeBarBg.x) / timeBarBg.width;
				var targetTime = FlxG.sound.music.length * clickRatio;
				FlxG.sound.music.time = targetTime;
				if(vocalsPlayer.active) vocalsPlayer.time = targetTime;
				if(vocalsOpponent.active) vocalsOpponent.time = targetTime;
			}
		}

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(btnCreatePlaylist)) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			customPlaylistMode = !customPlaylistMode;
			curSelected = 0;
			modeText.text = customPlaylistMode ? "MODE: FAVORITES" : "MODE: ALL SONGS";
			modeText.color = customPlaylistMode ? 0xFFFF58B4 : 0xFF00FF66;
			
			grpTexts.clear();
			var currentList = customPlaylistMode ? customPlaylist : playlist;
			for (i in 0...currentList.length) {
				var trackText:FlxText = new FlxText(60, 0, 550, currentList[i].name.toLowerCase(), 36);
				trackText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF0D021A);
				trackText.ID = i;
				grpTexts.add(trackText);
			}
			changeTrackSelection(0);
		}
			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(btnShare)) {
			var currentList = customPlaylistMode ? customPlaylist : playlist;
			if (currentList.length > curSelected) {
				var track = currentList[curSelected];

				if (!customPlaylistMode) {
					if (!customPlaylist.contains(track)) {
						customPlaylist.push(track);
						FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
						txtShare.color = 0xFF00FF66;
						FlxTween.tween(txtShare, {color: FlxColor.WHITE}, 0.4);
					}
				} else {
					customPlaylist.remove(track);
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);

					grpTexts.clear();
					for (i in 0...customPlaylist.length) {
						var trackText:FlxText = new FlxText(60, 0, 550, customPlaylist[i].name.toLowerCase(), 36);
						trackText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF0D021A);
						trackText.ID = i;
						grpTexts.add(trackText);
					}
					changeTrackSelection(0);
				}
			}
		}

		if (FlxG.sound.music != null) {
			var curTime:String = flixel.util.FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, true);
			var totalTime:String = flixel.util.FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true);
			timeText.text = curTime + " / " + totalTime;
		}

		if (iconPlayer != null) iconPlayer.scale.x = FlxMath.lerp(iconPlayer.scale.x, -1.0, FlxMath.bound(elapsed * 12, 0, 1));
		if (iconPlayer != null) iconPlayer.scale.y = FlxMath.lerp(iconPlayer.scale.y, 1.0, FlxMath.bound(elapsed * 12, 0, 1));
		if (iconOpponent != null) iconOpponent.scale.x = FlxMath.lerp(iconOpponent.scale.x, 1.0, FlxMath.bound(elapsed * 12, 0, 1));
		if (iconOpponent != null) iconOpponent.scale.y = FlxMath.lerp(iconOpponent.scale.y, 1.0, FlxMath.bound(elapsed * 12, 0, 1));

		drawDynamicNeonGrid();

		helpText.visible = FlxG.keys.pressed.F1;

		var navUp = FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP #if mobile || touchPad.buttonUp.justPressed #end;
		var navDown = FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN #if mobile || touchPad.buttonDown.justPressed #end;
		var actionAccept = FlxG.keys.justPressed.ENTER #if mobile || touchPad.buttonA.justPressed #end;
		
		if (FlxG.keys.justPressed.SPACE) {
			if (isPlaying) {
				if(FlxG.sound.music != null) FlxG.sound.music.pause();
				vocalsPlayer.pause(); vocalsOpponent.pause();
			} else {
				if(FlxG.sound.music != null) FlxG.sound.music.resume();
				vocalsPlayer.resume(); vocalsOpponent.resume();
			}
			isPlaying = !isPlaying;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.R) {
			if (FlxG.sound.music != null) FlxG.sound.music.time = 0;
			vocalsPlayer.time = 0; vocalsOpponent.time = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
		}

		var skipLeft = FlxG.keys.justPressed.LEFT #if mobile || touchPad.buttonLeft.justPressed #end;
		var skipRight = FlxG.keys.justPressed.RIGHT #if mobile || touchPad.buttonRight.justPressed #end;

		#if mobile
		if (FlxG.mouse.justPressed && FlxG.mouse.x < 640) {
			for (txt in grpTexts.members) {
				if (txt != null && txt.visible && FlxG.mouse.overlaps(txt)) {
					if (txt.ID == curSelected) {
						playSelectedTrackAudio();
					} else {
						changeTrackSelection(txt.ID - curSelected);
					}
					break;
				}
			}
		}

		if (mobile.backend.SwipeUtil.swipeUp) changeTrackSelection(1);
		if (mobile.backend.SwipeUtil.swipeDown) changeTrackSelection(-1);

		if (touchPad.buttonD.justPressed) {
			currentPitch = FlxMath.bound(currentPitch - 0.05, 0.5, 2.0);
			if(FlxG.sound.music != null) FlxG.sound.music.pitch = currentPitch;
			vocalsPlayer.pitch = currentPitch; vocalsOpponent.pitch = currentPitch;
			pitchText.text = "SPEED: " + FlxMath.roundDecimal(currentPitch, 2) + "x";
			bpmText.text = "BPM: " + FlxMath.roundDecimal(currentList[curSelected].bpm * currentPitch, 0);
		}
		if (touchPad.buttonE.justPressed) {
			currentPitch = FlxMath.bound(currentPitch + 0.05, 0.5, 2.0);
			if(FlxG.sound.music != null) FlxG.sound.music.pitch = currentPitch;
			vocalsPlayer.pitch = currentPitch; vocalsOpponent.pitch = currentPitch;
			pitchText.text = "SPEED: " + FlxMath.roundDecimal(currentPitch, 2) + "x";
			bpmText.text = "BPM: " + FlxMath.roundDecimal(currentList[curSelected].bpm * currentPitch, 0);
		}

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(instrumentalTxt)) {
				instrumentalEnabled = !instrumentalEnabled;
				instrumentalTxt.text = "Instrumental: " + (instrumentalEnabled ? "enabled" : "disabled");
				if(FlxG.sound.music != null) FlxG.sound.music.volume = instrumentalEnabled ? currentVolume : 0;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}
			else if (FlxG.mouse.overlaps(opponentVocalsTxt) && opponentVocalsTxt.text != "") {
				opponentVocalsEnabled = !opponentVocalsEnabled;
				opponentVocalsTxt.text = "Opponent vocals: " + (opponentVocalsEnabled ? "enabled" : "disabled");
				vocalsOpponent.volume = opponentVocalsEnabled ? currentVolume : 0;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}
			else if (FlxG.mouse.overlaps(playerVocalsTxt)) {
				playerVocalsEnabled = !playerVocalsEnabled;
				if (opponentVocalsTxt.text == "") {
					playerVocalsTxt.text = "Vocals: " + (playerVocalsEnabled ? "enabled" : "disabled");
				} else {
					playerVocalsTxt.text = "Player vocals: " + (playerVocalsEnabled ? "enabled" : "disabled");
				}
				vocalsPlayer.volume = playerVocalsEnabled ? currentVolume : 0;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}
		}
		#end

		if (navUp) changeTrackSelection(-1);
		if (navDown) changeTrackSelection(1);
		if (actionAccept) playSelectedTrackAudio();

		if (skipLeft) {
			if (FlxG.sound.music != null) {
				var t = Math.max(0, FlxG.sound.music.time - 10000);
				FlxG.sound.music.time = t; vocalsPlayer.time = t; vocalsOpponent.time = t;
			}
		}
		if (skipRight) {
			if (FlxG.sound.music != null) {
				var t = Math.min(FlxG.sound.music.length - 1, FlxG.sound.music.time + 10000);
				FlxG.sound.music.time = t; vocalsPlayer.time = t; vocalsOpponent.time = t;
			}
		}

		if (FlxG.keys.justPressed.ONE #if mobile || touchPad.buttonB.justPressed #end) {
			instrumentalEnabled = !instrumentalEnabled;
			instrumentalTxt.text = "Instrumental: " + (instrumentalEnabled ? "enabled" : "disabled");
			if(FlxG.sound.music != null) FlxG.sound.music.volume = instrumentalEnabled ? currentVolume : 0;
		}
		if (FlxG.keys.justPressed.TWO #if mobile || touchPad.buttonC.justPressed #end) {
			opponentVocalsEnabled = !opponentVocalsEnabled;
			opponentVocalsTxt.text = "Opponent vocals: " + (opponentVocalsEnabled ? "enabled" : "disabled");
			vocalsOpponent.volume = opponentVocalsEnabled ? currentVolume : 0;
		}
		if (FlxG.keys.justPressed.THREE #if mobile || touchPad.buttonD.justPressed #end) {
			playerVocalsEnabled = !playerVocalsEnabled;
			playerVocalsTxt.text = "Player vocals: " + (playerVocalsEnabled ? "enabled" : "disabled");
			vocalsPlayer.volume = playerVocalsEnabled ? currentVolume : 0;
		}

		if (FlxG.keys.justPressed.MINUS) {
			currentVolume = FlxMath.bound(currentVolume - 0.1, 0, 1);
			volumeTxt.text = "VOLUME: " + FlxMath.roundDecimal(currentVolume, 1);
			if(FlxG.sound.music != null && instrumentalEnabled) FlxG.sound.music.volume = currentVolume;
			if(playerVocalsEnabled) vocalsPlayer.volume = currentVolume;
			if(opponentVocalsEnabled) vocalsOpponent.volume = currentVolume;
		}
		if (FlxG.keys.justPressed.PLUS #if mobile || touchPad.buttonE.justPressed #end) {
			currentVolume = FlxMath.bound(currentVolume + 0.1, 0, 1);
			volumeTxt.text = "VOLUME: " + FlxMath.roundDecimal(currentVolume, 1);
			if(FlxG.sound.music != null && instrumentalEnabled) FlxG.sound.music.volume = currentVolume;
			if(playerVocalsEnabled) vocalsPlayer.volume = currentVolume;
			if(opponentVocalsEnabled) vocalsOpponent.volume = currentVolume;
		}
		if (FlxG.keys.justPressed.Q) {
			currentPitch = FlxMath.bound(currentPitch - 0.05, 0.5, 2.0);
			if(FlxG.sound.music != null) FlxG.sound.music.pitch = currentPitch;
			vocalsPlayer.pitch = currentPitch; vocalsOpponent.pitch = currentPitch;
			pitchText.text = "SPEED: " + FlxMath.roundDecimal(currentPitch, 2) + "x";
			bpmText.text = "BPM: " + FlxMath.roundDecimal(currentList[curSelected].bpm * currentPitch, 0);
		}
		if (FlxG.keys.justPressed.E) {
			currentPitch = FlxMath.bound(currentPitch + 0.05, 0.5, 2.0);
			if(FlxG.sound.music != null) FlxG.sound.music.pitch = currentPitch;
			vocalsPlayer.pitch = currentPitch; vocalsOpponent.pitch = currentPitch;
			pitchText.text = "SPEED: " + FlxMath.roundDecimal(currentPitch, 2) + "x";
			bpmText.text = "BPM: " + FlxMath.roundDecimal(currentList[curSelected].bpm * currentPitch, 0);
		}

		if (FlxG.keys.justPressed.L) {
			loopMode = !loopMode; shuffleMode = false;
			modeText.text = loopMode ? "MODE: LOOP TRACK" : "MODE: NORMAL";
			modeText.color = loopMode ? 0xFFFFD700 : 0xFF00FF66;
		}
		if (FlxG.keys.justPressed.H) {
			shuffleMode = !shuffleMode; loopMode = false;
			modeText.text = shuffleMode ? "MODE: SHUFFLE" : "MODE: NORMAL";
			modeText.color = shuffleMode ? 0xFF00FFFF : 0xFF00FF66;
		}

		if (FlxG.sound.music != null && FlxG.sound.music.time >= FlxG.sound.music.length - 50) {
			if (loopMode) {
				FlxG.sound.music.time = 0;
			} else if (shuffleMode) {
				changeTrackSelection(FlxG.random.int(1, currentList.length - 1));
				playSelectedTrackAudio();
			} else {
				changeTrackSelection(1);
				playSelectedTrackAudio();
			}
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			vocalsPlayer.stop(); vocalsOpponent.stop();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1.0);
			backend.MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}
	}

	override function beatHit()
	{
		super.beatHit();
		
		if(iconPlayer != null && iconOpponent != null) {
			iconPlayer.scale.set(-1.25, 1.25);
			iconOpponent.scale.set(1.25, 1.25);
			
			panelBorder.scale.set(1.015, 1.015);
			FlxTween.tween(panelBorder.scale, {x: 1.0, y: 1.0}, 0.12, {ease: FlxEase.cubeOut});
		}
	}

	private function drawDynamicNeonGrid():Void
	{
		neonGrid.pixels.fillRect(new openfl.geom.Rectangle(0, 0, FlxG.width, FlxG.height), 0x00000000);
		var gridSpacing = 40;
		var scalePulse = 1.0 + (Math.sin(runtimeTimer * 4) * 0.02);
		
		for (x in 0...Std.int(FlxG.width / gridSpacing)) {
			var lineX = Std.int((x * gridSpacing) * scalePulse);
			if (lineX > 640 && lineX < 1240) {
				neonGrid.pixels.fillRect(new openfl.geom.Rectangle(lineX, 110, 1, 495), 0x22BF55EC);
			}
		}
	}

	private function getTrackMetaInfo(songFolder:String):{bpm:Float, p1:String, p2:String}
	{
		var defaultMeta = {bpm: 125.0, p1: "bf", p2: "dad"};
		var formattedFolder:String = Paths.formatToSongPath(songFolder);
		
		var potentialPaths:Array<String> = [
			'assets/shared/data/' + formattedFolder + '/' + formattedFolder + '-normal.json',
			'assets/shared/data/' + formattedFolder + '/' + formattedFolder + '.json',
			'assets/shared/data/' + formattedFolder + '/metadata.json'
		];

		#if MODS_ALLOWED
		try {
			if (sys.FileSystem.exists('mods/')) {
				for (mod in sys.FileSystem.readDirectory('mods/')) {
					if (sys.FileSystem.isDirectory('mods/' + mod)) {
						potentialPaths.push('mods/' + mod + '/data/' + formattedFolder + '/' + formattedFolder + '-normal.json');
						potentialPaths.push('mods/' + mod + '/data/' + formattedFolder + '/' + formattedFolder + '.json');
						potentialPaths.push('mods/' + mod + '/data/' + formattedFolder + '/metadata.json');
					}
				}
			}
			potentialPaths.push('mods/data/' + formattedFolder + '/' + formattedFolder + '-normal.json');
			potentialPaths.push('mods/data/' + formattedFolder + '/' + formattedFolder + '.json');
		} catch(e:Dynamic) {}
		#end

		var finalPath:String = "";
		for (path in potentialPaths) {
			if (sys.FileSystem.exists(path) && !sys.FileSystem.isDirectory(path)) {
				finalPath = path;
				break;
			}
		}

		if (finalPath != "") {
			try {
				var content:String = sys.io.File.getContent(finalPath);
				var parsed = haxe.Json.parse(content);
				
				if (parsed != null) {
					var targetBPM:Float = 125.0;
					var charP1:String = "bf";
					var charP2:String = "dad";

					if (parsed.playData != null && parsed.timeChanges != null) {
						if (parsed.timeChanges[0] != null && parsed.timeChanges[0].bpm != null)
							targetBPM = cast(parsed.timeChanges[0].bpm, Float);
						if (parsed.playData.characters != null) {
							charP1 = parsed.playData.characters.player ?? "bf";
							charP2 = parsed.playData.characters.opponent ?? "dad";
						}
					}
					else if (parsed.song != null) {
						var songData = parsed.song;
						targetBPM = songData.bpm != null ? cast(songData.bpm, Float) : 125.0;
						charP1 = songData.player1 != null ? songData.player1 : "bf";
						charP2 = songData.player2 != null ? songData.player2 : "dad";
					}

					var playerIconName:String = charP1;
					var opponentIconName:String = charP2;
					
					var p1CharPath = 'assets/characters/' + charP1 + '.json';
					if (sys.FileSystem.exists(p1CharPath)) {
						var charJson = haxe.Json.parse(sys.io.File.getContent(p1CharPath));
						if (charJson.healthicon != null) playerIconName = charJson.healthicon;
					}
					
					var p2CharPath = 'assets/characters/' + charP2 + '.json';
					if (sys.FileSystem.exists(p2CharPath)) {
						var charJson = haxe.Json.parse(sys.io.File.getContent(p2CharPath));
						if (charJson.healthicon != null) opponentIconName = charJson.healthicon;
					}

					return {bpm: targetBPM, p1: playerIconName, p2: opponentIconName};
				}
			} catch(e:Dynamic) {
				trace("[TIMELESS METADATA CRASH]: Failed to extract structural BPM values.");
			}
		}
		return defaultMeta;
	}
}