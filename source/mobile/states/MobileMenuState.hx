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
import flixel.text.FlxText;
import flixel.util.FlxColor;

#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.AchievementsMenuState;
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import flixel.addons.transition.FlxTransitionableState;

@:access(mikolka.vslice.ui.MainMenuState)
class MobileMenuState extends FlxBasic {
    var selectedSomethin:Bool = false;
    
    var host:MainMenuState;
	var grid:GridButtons;

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
				FlxFlicker.flicker(host.magenta, 1.1, 0.15, false);
		});

		var debugText:FlxText = new FlxText(40, 40, 0, "", 28);
		debugText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (mikolka.vslice.ui.MainMenuState.globalLayoutMatrix != null) {
			debugText.text = "";
			debugText.color = 0xFF00FF66;
		} else {
			debugText.text = "";
			debugText.color = 0xFFFF0033;
		}
		debugText.scrollFactor.set(0, 0);
		host.add(debugText);

		var storyBtn = grid.makeButton('story_mode', 0, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new StoryMenuState());
		});
		storyBtn.selectedOffset.set(10, 15);
		applyMobileLayoutProperties(storyBtn, 'story_mode');

		var freeplayBtn = grid.makeButton('freeplay', 0, () -> {
			FlxG.mouse.visible = false;
			host.persistentDraw = true;
			host.persistentUpdate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			host.openSubState(new FreeplayState());
			host.subStateOpened.addOnce(state -> {
				grid.revealButtons();
				selectedSomethin = false;
				grid.selectButton();
			});
			if(!host.controls.mobileC) host.subStateClosed.addOnce((x) -> {
				FlxG.mouse.visible = true;
			});
		});
		freeplayBtn.selectedOffset.set(10, 20);
		applyMobileLayoutProperties(freeplayBtn, 'freeplay');

		#if MODS_ALLOWED
		var modsBtn = grid.makeButton('mods', 0, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new ModsMenuState());
		});
		applyMobileLayoutProperties(modsBtn, 'mods');
		#end

		#if ACHIEVEMENTS_ALLOWED
		var awardsBtn = grid.makeButton('awards', 1, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new AchievementsMenuState());
		});
		awardsBtn.selectedOffset.set(70, 15);
		applyMobileLayoutProperties(awardsBtn, 'awards');
		#end

		var creditsBtn = grid.makeButton('credits', 1, () -> {
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new CreditsState());
		});
		creditsBtn.selectedOffset.set(150, 10);
		applyMobileLayoutProperties(creditsBtn, 'credits');

		#if !switch
		var donateBtn = new GridTileDonate(grid);
		grid.addButton(donateBtn, 1);
		donateBtn.selectedOffset.set(30, 0);
		applyMobileLayoutProperties(donateBtn, 'merch');
		#end

		var optionsBtn = new OptionsButton(grid, () -> {
			FlxG.mouse.visible = false;
            host.goToOptions();
		});
		grid.addButton(optionsBtn, 0);
		optionsBtn.setPosition((MobileScaleMode.gameCutoutSize.x/4)+35, FlxG.height - 200);
		applyMobileLayoutProperties(optionsBtn, 'options');

        #if TOUCH_CONTROLS_ALLOWED
		host.addTouchPad('NONE', 'B_C');
		#end

		if(!host.controls.mobileC) {
			FlxG.mouse.visible = true;
			grid.selectButton();
		}
    }

	private function applyMobileLayoutProperties(btn:flixel.FlxSprite, name:String):Void
	{
		var matrix:mikolka.vslice.ui.MainMenuState.MenuLayoutData = mikolka.vslice.ui.MainMenuState.globalLayoutMatrix;
		var checkName:String = name.toLowerCase().trim();
		var hasCustomLayout:Bool = false;

		if (matrix != null && matrix.items != null) {
			for (prop in matrix.items) {
				var jsonName:String = prop.name.toLowerCase().trim();
				if (jsonName == checkName) {
					btn.x = prop.x;
					btn.y = prop.y;
					btn.scale.set(prop.scaleX * matrix.globalScale, prop.scaleY * matrix.globalScale);
					btn.updateHitbox();
					btn.scrollFactor.set(0, 0);
					hasCustomLayout = true;
					break;
				}
			}
		}
	}

    override function update(elapsed:Float) {
        if (!selectedSomethin)
		{
			final controls = host.controls;

			if (controls.UI_UP_P)
				grid.changeSelection(0, -1);

			if (controls.UI_DOWN_P)
				grid.changeSelection(0, 1);
			if (controls.UI_LEFT_P)
				grid.changeSelection(-1, 0);

			if (controls.UI_RIGHT_P)
				grid.changeSelection(1, 0);

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
			if (#if TOUCH_CONTROLS_ALLOWED host.touchPad.buttonC.justPressed || #end#if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1')
				.filter(s -> s != -1)) #else controls.justPressed('debug_1') #end)
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