package mobile.states;

import flixel.FlxG;
import flixel.effects.FlxFlicker;
import mikolka.vslice.freeplay.FreeplayState;
import mikolka.vslice.ui.title.TitleState;
import mikolka.funkin.custom.mobile.MobileScaleMode;
import mobile.objects.GridButtons;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import mikolka.compatibility.VsliceOptions;
import mobile.objects.grid.*;
import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.CoolUtil;
import states.editors.MenuEditorState.MenuLayoutIO;
import states.editors.MenuEditorState.MenuFx;
import states.editors.MenuEditorState.MenuItemProps;
import states.editors.MenuEditorState.MenuLayoutData;

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
	var buttonNames:Array<String> = [];
	var actions:Map<String, Void->Void> = new Map();

	var layout:MenuLayoutData;
	var propsList:Array<MenuItemProps> = [];
	var decorBack:FlxTypedGroup<FlxSprite>;
	var decorFront:FlxTypedGroup<FlxSprite>;
	var decorList:Array<{spr:FlxSprite, props:MenuItemProps}> = [];
	var transBg:FlxSprite;
	var lastBeat:Int = -1;
	var beatClock:Float = 0;
	var freeMode:Bool = false;
	var ptrDown:Bool = false;
	var ptrX:Float = 0;
	var ptrY:Float = 0;
	var ptrTime:Float = 0;
	var _beatLen:Float = 0;
	var _hitRect:flixel.math.FlxRect = new flixel.math.FlxRect();
	var _propByName:Map<String, Int> = null;

	public function new(host:MainMenuState) {
		super();
		this.host = host;
		host.add(this);

		layout = MenuLayoutIO.loadFile();
		if (layout == null)
		{
			var m:Dynamic = mikolka.vslice.ui.MainMenuState.globalLayoutMatrix;
			if (m != null && m.items != null)
				layout = MenuLayoutIO.normalize(cast m);
		}

		if (layout != null && layout.mobilePositions != false)
		{
			freeMode = true;
			FlxG.mouse.visible = false;
			new DesktopMenuState(host);
			active = false; // the desktop-style menu does everything, this object has nothing left to update
			return;
		}
		if (layout != null)
			_beatLen = 60000 / MenuLayoutIO.bpmOf(layout, MenuFx.BPM);
		setupBackgrounds();

		decorBack = new FlxTypedGroup<FlxSprite>();
		host.add(decorBack);

		grid = new GridButtons((MobileScaleMode.gameCutoutSize.x/4)+30, 20, 2, Math.floor((MobileScaleMode.gameCutoutSize.x/4)+750));
		host.add(grid);

		decorFront = new FlxTypedGroup<FlxSprite>();
		host.add(decorFront);
		setupDecor();

		grid.onItemSelect.add(s -> {
			beginTransition(s);
		});

		if (shown('story_mode')) {
			var storyAct = () -> {
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new StoryMenuState());
			};
			var storyBtn = grid.makeButton('story_mode', 0, storyAct);
			storyBtn.selectedOffset.set(10, 15);
			register('story_mode', storyBtn, storyAct);
		}

		if (shown('freeplay')) {
			var freeplayAct = () -> {
				FlxG.mouse.visible = false;
				host.persistentDraw = true;
				host.persistentUpdate = false;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				host.openSubState(new FreeplayState()); // was opened twice (two full freeplay states built per tap)
				host.subStateOpened.addOnce(state -> {
					grid.revealButtons();
					selectedSomethin = false;
					grid.selectButton();
					for (btn in buttonsList) {
						btn.alpha = 1;
						btn.scale.set(1.0, 1.0);
					}
					restoreDecor();
				});
				host.subStateClosed.addOnce(state -> hideTransBg());
				if(!host.controls.mobileC) host.subStateClosed.addOnce((x) -> {
					FlxG.mouse.visible = true;
				});
			};
			var freeplayBtn = grid.makeButton('freeplay', 0, freeplayAct);
			freeplayBtn.selectedOffset.set(10, 20);
			register('freeplay', freeplayBtn, freeplayAct);
		}

		#if MODS_ALLOWED
		if (shown('mods')) {
			var modsAct = () -> {
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new ModsMenuState());
			};
			var modsBtn = grid.makeButton('mods', 0, modsAct);
			register('mods', modsBtn, modsAct);
		}
		#end

		if (shown('credits')) {
			var creditsAct = () -> {
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new CreditsState());
			};
			var creditsBtn = grid.makeButton('credits', 1, creditsAct);
			creditsBtn.selectedOffset.set(150, 10);
			register('credits', creditsBtn, creditsAct);
		}

		#if !switch
		if (shown('donate')) {
			var donateBtn = new GridTileDonate(grid);
			grid.addButton(donateBtn, 1);
			donateBtn.selectedOffset.set(30, 0);
			register('donate', donateBtn, null);
		}
		#end

		if (shown('options')) {
			var optionsAct = () -> {
				FlxG.mouse.visible = false;
				@:privateAccess host.goToOptions();
			};
			var optionsBtn = new OptionsButton(grid, optionsAct);
			grid.addButton(optionsBtn, 0);
			optionsBtn.setPosition((MobileScaleMode.gameCutoutSize.x/4)+35, FlxG.height - 200);
			register('options', optionsBtn, optionsAct);
		}

		propsList = [for (n in buttonNames) propsFor(n)];
		for (i in 0...buttonsList.length) {
			var btn = buttonsList[i];
			if (btn != null)
				btn.alpha = 1;
		}

		#if TOUCH_CONTROLS_ALLOWED
		host.addTouchPad('NONE', 'B_C');
		#end

		if(!host.controls.mobileC) {
			FlxG.mouse.visible = true;
			grid.selectButton();
		}
		else
			FlxG.mouse.visible = false;
	}

	function register(name:String, tile:flixel.FlxSprite, action:Void->Void) {
		buttonsList.push(tile);
		buttonNames.push(name);
		if (action != null)
			actions.set(name, action);
	}

	function propsFor(gameName:String):MenuItemProps {
		if (layout == null)
			return null;
		if (_propByName == null) {
			_propByName = new Map<String, Int>();
			for (i in 0...layout.items.length) {
				var k = layout.items[i].name.toLowerCase().trim();
				if (!_propByName.exists(k))
					_propByName.set(k, i);
			}
		}
		var r:Null<Int> = _propByName.get(MenuLayoutIO.layoutName(gameName).toLowerCase().trim());
		return r == null ? null : layout.items[r];
	}

	function shown(gameName:String):Bool {
		var p = propsFor(gameName);
		return p == null || p.enabled != false;
	}

	function setupBackgrounds() {
		if (layout == null)
			return;
		var bgSpr:FlxSprite = @:privateAccess host.bg;
		if (bgSpr != null) {
			MenuFx.applyBackground(bgSpr, layout, false);
			bgSpr.alpha = layout.backgroundAlpha;
		}
		if (MenuLayoutIO.hasText(layout.transBgImage)) {
			transBg = new FlxSprite();
			if (MenuFx.applyBackground(transBg, layout, true)) {
				transBg.scrollFactor.set(0, 0);
				transBg.screenCenter();
				transBg.alpha = 0;
				var at = (bgSpr != null) ? host.members.indexOf(bgSpr) : -1;
				if (at >= 0)
					host.insert(at + 1, transBg);
				else
					host.add(transBg);
			}
			else
				transBg = null;
		}
	}

	function setupDecor() {
		if (layout == null)
			return;
		for (p in layout.decor) {
			if (p.enabled == false)
				continue;
			var spr = MenuFx.makeDecor(p);
			spr.scrollFactor.set(0, 0);
			MenuFx.place(spr, p);
			spr.visible = MenuFx.startsVisible(p);
			(p.front == true ? decorFront : decorBack).add(spr);
			decorList.push({spr: spr, props: p});
		}
	}

	function restoreDecor() {
		for (d in decorList) {
			FlxTween.cancelTweensOf(d.spr);
			FlxTween.cancelTweensOf(d.spr.scale);
			d.spr.revive();
			d.spr.visible = MenuFx.startsVisible(d.props);
			MenuFx.place(d.spr, d.props);
			MenuFx.resetSheet(d.spr);
		}
		if (layout != null && layout.bgSparrow == true)
			MenuFx.resetSheet(@:privateAccess host.bg);
	}

	function showTransBg() {
		if (transBg == null)
			return;
		FlxTween.cancelTweensOf(transBg);
		FlxTween.tween(transBg, {alpha: 1}, MenuFx.TRANS_FADE);
		if (layout != null && layout.transBgSparrow == true && MenuLayoutIO.hasText(layout.transBgEnter))
			MenuFx.playOnce(transBg, 'enter', '');
	}

	function hideTransBg() {
		if (transBg == null)
			return;
		FlxTween.cancelTweensOf(transBg);
		FlxTween.tween(transBg, {alpha: 0}, MenuFx.TRANS_FADE);
		MenuFx.resetSheet(transBg);
	}

	function beginTransition(chosen:Dynamic) {
		var chosenIdx:Int = buttonsList.indexOf(chosen);
		var chosenName:String = (chosenIdx >= 0 && chosenIdx < buttonNames.length) ? buttonNames[chosenIdx] : '';
		var chosenProps:MenuItemProps = (chosenIdx >= 0 && chosenIdx < propsList.length) ? propsList[chosenIdx] : null;
		MenuFx.playEnterSound(chosenProps);
		MenuFx.playEnterMusic(chosenProps);
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		selectedSomethin = true;

		var mag:FlxSprite = @:privateAccess host.magenta;
		if (VsliceOptions.FLASHBANG && mag != null)
			FlxFlicker.flicker(mag, 1.1, 0.15, false);

		showTransBg();

		for (i in 0...buttonsList.length) {
			var btn = buttonsList[i];
			if (btn != null && btn != chosen) {
				var p = (i < propsList.length) ? propsList[i] : null;
				if (p == null || p.hideOnEnter != false)
					btn.kill();
			}
		}
		for (d in decorList) {
			if (MenuFx.decorEnter(d.spr, d.props, chosenName))
				continue;
			if (d.props.hideOnEnter == true)
				MenuFx.hide(d.spr);
			else
				MenuFx.playEnterAnim(d.spr, d.props);
		}
		if (layout != null && layout.bgSparrow == true && MenuLayoutIO.hasText(layout.bgEnter))
			MenuFx.playOnce(@:privateAccess host.bg, 'enter', '');
	}

	function triggerButton(idx:Int) {
		if (idx < 0 || idx >= buttonNames.length || selectedSomethin)
			return;
		var name = buttonNames[idx];
		if (name == 'donate') {
			CoolUtil.browserLoad('https://needlejuicerecords.com');
			return;
		}
		var act = actions.get(name);
		if (act == null)
			return;
		beginTransition(buttonsList[idx]);
		act();
	}

	function keepsBeating(p:MenuItemProps):Bool
		return p.beatAnim == 'sparrow' && !MenuLayoutIO.hasText(p.enterPrefix);

	function tickBeat(elapsed:Float) {
		if (layout == null)
			return;
		var t:Float;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			t = FlxG.sound.music.time;
		else {
			beatClock += elapsed * 1000;
			t = beatClock;
		}
		var b = Math.floor(t / _beatLen);
		if (b == lastBeat)
			return;
		lastBeat = b;
		if (layout.bgSparrow == true && MenuLayoutIO.hasText(layout.bgBeat) && (!selectedSomethin || !MenuLayoutIO.hasText(layout.bgEnter)))
			MenuFx.playOnce(@:privateAccess host.bg, 'beat', 'main');
		if (!selectedSomethin) {
			for (i in 0...buttonsList.length) {
				var btn = buttonsList[i];
				var p = (i < propsList.length) ? propsList[i] : null;
				if (btn == null || p == null || p.beatAnim == 'none' || p.beatAnim == 'sparrow')
					continue;
				MenuFx.beat(btn, p, btn.scale.x, btn.scale.y, b, '');
			}
		}
		for (d in decorList) {
			if (d.props.beatAnim == 'none')
				continue;
			if (selectedSomethin && !keepsBeating(d.props))
				continue;
			MenuFx.beat(d.spr, d.props, d.props.scaleX, d.props.scaleY, b, 'main');
		}
	}

	function padHeld():Bool {
		#if TOUCH_CONTROLS_ALLOWED
		if (host.touchPad == null)
			return false;
		return (host.touchPad.buttonB != null && host.touchPad.buttonB.pressed) || (host.touchPad.buttonC != null && host.touchPad.buttonC.pressed);
		#else
		return false;
		#end
	}

	function padC():Bool {
		#if TOUCH_CONTROLS_ALLOWED
		return host.touchPad != null && host.touchPad.buttonC != null && host.touchPad.buttonC.justPressed;
		#else
		return false;
		#end
	}

	function tapTarget(px:Float, py:Float):Int {
		var pad:Float = 36;
		var best:Int = -1;
		var bestD:Float = 1e12;
		for (i in 0...buttonsList.length) {
			var b = buttonsList[i];
			if (b == null || !b.alive || !b.visible)
				continue;
			// real drawn bounds (sprite.width/height go stale after scale tweens / frame swaps)
			DesktopMenuState.screenRect(b, _hitRect);
			var l = _hitRect.x;
			var t = _hitRect.y;
			var r = l + _hitRect.width;
			var bt = t + _hitRect.height;
			if (px >= l && px <= r && py >= t && py <= bt)
				return -2;
			if (px < l - pad || px > r + pad || py < t - pad || py > bt + pad)
				continue;
			var dx = (l + r) / 2 - px;
			var dy = (t + bt) / 2 - py;
			var d = dx * dx + dy * dy;
			if (d < bestD) {
				bestD = d;
				best = i;
			}
		}
		return best;
	}

	function pollTaps(elapsed:Float) {
		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;
		if (FlxG.mouse.justPressed) {
			ptrDown = !padHeld();
			ptrX = mx;
			ptrY = my;
			ptrTime = 0;
		}
		if (ptrDown)
			ptrTime += elapsed;
		if (FlxG.mouse.justReleased && ptrDown) {
			ptrDown = false;
			var moved = Math.abs(mx - ptrX) + Math.abs(my - ptrY);
			if (moved <= 28 && ptrTime <= 0.8) {
				var hit = tapTarget(ptrX, ptrY);
				if (hit >= 0)
					triggerButton(hit);
			}
		}
	}

	override function update(elapsed:Float) {
		if (freeMode || grid == null) {
			super.update(elapsed);
			return;
		}
		tickBeat(elapsed);

		if (!selectedSomethin)
		{
			final controls = host.controls;

			if (layout != null && FlxG.keys.pressed.ANY) {
				var hit = MenuLayoutIO.pollKeys(propsList);
				if (hit >= 0) {
					triggerButton(hit);
					super.update(elapsed);
					return;
				}
			}

			if (controls.mobileC)
				pollTaps(elapsed);

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

			// controls.ACCEPT fires on any screen tap on touch devices -> always opened the selected (first) item
			if (DesktopMenuState.acceptPressed(host)) {
				selectedSomethin = true;
				grid.confirmCurrentButton();
			}
			if (padC() || #if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1').filter(s -> s != -1)) #else controls.justPressed('debug_1') #end)
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
