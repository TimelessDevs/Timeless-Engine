package mobile.states;

import flixel.FlxG;
import flixel.effects.FlxFlicker;
import mikolka.vslice.freeplay.FreeplayState;
import mikolka.vslice.ui.title.TitleState;
import mikolka.funkin.custom.mobile.MobileScaleMode;
import mobile.objects.GridButtons;
import flixel.FlxBasic;
import mikolka.compatibility.VsliceOptions;
import mobile.objects.grid.*;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import flixel.addons.transition.FlxTransitionableState;

@:access(mobile.objects.GridButtons)
class MobileMenuState extends FlxBasic {
	var selectedSomethin:Bool = false;
	var host:MainMenuState;
	var grid:GridButtons;
	var buttonsList:Array<flixel.FlxSprite> = [];

	public function new(host:MainMenuState) {
		super();
		this.host = host;
		host.add(this);
		
		grid = new GridButtons((MobileScaleMode.gameCutoutSize.x/4)+30, 20, 2, Math.floor((MobileScaleMode.gameCutoutSize.x/4)+750));
		host.add(grid);
		
		grid.onItemSelect.add(s -> {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxTransitionableState.skipNextTransIn = false;
			FlxTransitionableState.skipNextTransOut = false;
			selectedSomethin = true;

			if (VsliceOptions.FLASHBANG)
				FlxFlicker.flicker(@:privateAccess host.magenta, 1.1, 0.15, false);

			for (i in 0...buttonsList.length) {
				var btn = buttonsList[i];
				if (btn != null && btn != s) {
					btn.kill();
				}
			}
		});

		var storyBtn = grid.makeButton('story_mode', 0, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new StoryMenuState());
		});
		storyBtn.selectedOffset.set(10, 15);
		buttonsList.push(storyBtn);

		var freeplayBtn = grid.makeButton('freeplay', 0, () -> {
			FlxG.mouse.visible = false;
			host.persistentDraw = true;
			host.persistentUpdate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			host.openSubState(new FreeplayState());
			host.openSubState(new FreeplayState());
			host.subStateOpened.addOnce(state -> {
				grid.revealButtons();
				selectedSomethin = false;
				grid.selectButton();
				for (btn in buttonsList) {
					btn.alpha = 1;
					btn.scale.set(1.0, 1.0);
				}
			});
			if(!host.controls.mobileC) host.subStateClosed.addOnce((x) -> {
				FlxG.mouse.visible = true;
			});
		});
		freeplayBtn.selectedOffset.set(10, 20);
		buttonsList.push(freeplayBtn);

		#if MODS_ALLOWED
		var modsBtn = grid.makeButton('mods', 0, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new ModsMenuState());
		});
		buttonsList.push(modsBtn);
		#end

		var creditsBtn = grid.makeButton('credits', 1, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new CreditsState());
		});
		creditsBtn.selectedOffset.set(150, 10);
		buttonsList.push(creditsBtn);

		#if !switch
		var donateBtn = new GridTileDonate(grid);
		grid.addButton(donateBtn, 1);
		donateBtn.selectedOffset.set(30, 0);
		buttonsList.push(donateBtn);
		#end

		var optionsBtn = new OptionsButton(grid, () -> {
			FlxG.mouse.visible = false;
			@:privateAccess host.goToOptions();
		});
		grid.addButton(optionsBtn, 0);
		optionsBtn.setPosition((MobileScaleMode.gameCutoutSize.x/4)+35, FlxG.height - 200);
		buttonsList.push(optionsBtn);

		for (i in 0...buttonsList.length) {
			var btn = buttonsList[i];
			btn.alpha = 1;
		}

		#if TOUCH_CONTROLS_ALLOWED
		host.addTouchPad('NONE', 'B_C');
		#end

		if(!host.controls.mobileC) {
			FlxG.mouse.visible = true;
			grid.selectButton();
		}
	}

	override function update(elapsed:Float) {
		if (!selectedSomethin)
		{
			final controls = host.controls;

			if (controls.UI_UP_P) grid.changeSelection(0, -1);
			if (controls.UI_DOWN_P) grid.changeSelection(0, 1);
			if (controls.UI_LEFT_P) grid.changeSelection(-1, 0);
			if (controls.UI_RIGHT_P) grid.changeSelection(1, 0);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) {
				selectedSomethin = true;
				grid.confirmCurrentButton();
			}
			if (#if TOUCH_CONTROLS_ALLOWED host.touchPad.buttonC.justPressed || #end#if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1').filter(s -> s != -1)) #else controls.justPressed('debug_1') #end)
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}
		super.update(elapsed);
	}
}