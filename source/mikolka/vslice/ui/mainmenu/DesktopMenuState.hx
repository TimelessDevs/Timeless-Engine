package mikolka.vslice.ui.mainmenu;

import mikolka.vslice.freeplay.FreeplayState;
import options.OptionsState;
import flixel.FlxBasic;
import flixel.effects.FlxFlicker;
import mikolka.vslice.ui.title.TitleState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.util.FlxColor;

#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import mikolka.compatibility.VsliceOptions;
import flixel.FlxObject;

import flixel.FlxG;
import backend.Paths;
import backend.CoolUtil;
import backend.MusicBeatState;
import backend.ClientPrefs;
import flixel.addons.transition.FlxTransitionableState;
import states.editors.MenuEditorState.MenuLayoutIO;
import states.editors.MenuEditorState.MenuFx;
import states.editors.MenuEditorState.MenuItemProps;
import states.editors.MenuEditorState.MenuLayoutData;

@:access(mikolka.vslice.ui.MainMenuState)
class DesktopMenuState extends FlxBasic
{
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	public static var curSelected:Int = 0;
	var selectedSomethin:Bool = false;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var camFollow:FlxObject;
	var host:MainMenuState;

	var layout:MenuLayoutData;
	var itemProps:Array<MenuItemProps> = [];
	var decorBack:FlxTypedGroup<FlxSprite>;
	var decorFront:FlxTypedGroup<FlxSprite>;
	var decorList:Array<{spr:FlxSprite, props:MenuItemProps}> = [];
	var transBg:FlxSprite;
	var lastBeat:Int = -1;
	var beatClock:Float = 0;
	var ptrDown:Bool = false;
	var ptrX:Float = 0;
	var ptrY:Float = 0;
	var ptrTime:Float = 0;
	var lastMX:Float = -1;
	var lastMY:Float = -1;
	var _beatLen:Float = 0;
	var _hitRect:flixel.math.FlxRect = new flixel.math.FlxRect();
	var _boundsRect:flixel.math.FlxRect = new flixel.math.FlxRect();

	/** set to true to trace mouse position / button rects on every click and hover change (for diagnosing hit-test problems) */
	public static var DEBUG_POINTER:Bool = false;
	var _propByName:Map<String, Int> = null;
	/** real mouse available (PC / web). Based on the platform, not on controls.mobileC, so touch-UI on PC still gets hover. */
	var pcPointer:Bool = false;

	/**
	 * Where a sprite is REALLY drawn on screen (position, offset, current frame size and scale).
	 * Hit testing against this keeps the click area glued to the visible button, even after
	 * scale tweens, beat animations or frame swaps (sprite.width/height go stale there).
	 */
	public static function screenRect(s:FlxSprite, out:flixel.math.FlxRect):flixel.math.FlxRect
	{
		var cam = FlxG.camera;
		var sx:Float = Math.abs(s.scale.x);
		var sy:Float = Math.abs(s.scale.y);
		var px:Float = s.x - cam.scroll.x * s.scrollFactor.x - s.offset.x;
		var py:Float = s.y - cam.scroll.y * s.scrollFactor.y - s.offset.y;
		out.x = px + s.origin.x - s.origin.x * sx;
		out.y = py + s.origin.y - s.origin.y * sy;
		out.width = s.frameWidth * sx;
		out.height = s.frameHeight * sy;
		return out;
	}

	/**
	 * "Accept" input. On touch devices controls.ACCEPT can fire for ANY screen tap, which instantly
	 * opened whatever was selected (the first item = Story Mode) no matter where you tapped.
	 * There only a real key / gamepad button counts; taps are handled by the pointer code.
	 */
	public static function acceptPressed(host:MainMenuState):Bool
	{
		if (!host.controls.mobileC)
			return host.controls.ACCEPT;
		if (FlxG.keys.justPressed.ENTER)
			return true;
		#if FLX_GAMEPAD
		var gp = FlxG.gamepads.lastActive;
		if (gp != null && gp.justPressed.A)
			return true;
		#end
		return false;
	}

	public function new(host:MainMenuState) {
		super();
		this.host = host;
		host.add(this);
		pcPointer = !FlxG.onMobile;

		layout = MenuLayoutIO.loadFile();
		if (layout == null)
		{
			var m:Dynamic = mikolka.vslice.ui.MainMenuState.globalLayoutMatrix;
			if (m != null && m.items != null)
				layout = MenuLayoutIO.normalize(cast m);
		}
		if (layout != null)
			_beatLen = 60000 / MenuLayoutIO.bpmOf(layout, MenuFx.BPM);
		applyLayoutToButtonList();

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		if (host.bg != null)
		{
			if (layout != null)
			{
				MenuFx.applyBackground(host.bg, layout, false);
				host.bg.alpha = layout.backgroundAlpha;
			}
			host.bg.scrollFactor.set(0, yScroll);
			host.bg.updateHitbox();
			host.bg.screenCenter();
		}

		if (host.magenta != null)
		{
			host.magenta.scrollFactor.set(0, yScroll);
			host.magenta.updateHitbox();
			host.magenta.screenCenter();
		}

		if (layout != null && MenuLayoutIO.hasText(layout.transBgImage))
		{
			transBg = new FlxSprite();
			if (MenuFx.applyBackground(transBg, layout, true))
			{
				transBg.scrollFactor.set(0, yScroll);
				transBg.screenCenter();
				transBg.alpha = 0;
				var at = host.members.indexOf(host.bg);
				if (at >= 0)
					host.insert(at + 1, transBg);
				else
					host.add(transBg);
			}
			else
				transBg = null;
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		host.add(camFollow);

		decorBack = new FlxTypedGroup<FlxSprite>();
		host.add(decorBack);

		menuItems = new FlxTypedGroup<FlxSprite>();
		host.add(menuItems);

		decorFront = new FlxTypedGroup<FlxSprite>();
		host.add(decorFront);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite;
			var props:MenuItemProps = itemProps[i];

			menuItem = new FlxSprite(0, 0);
			menuItem.antialiasing = VsliceOptions.ANTIALIASING;
			var atlas = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			if (atlas != null)
			{
				menuItem.frames = atlas;
				menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
				menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
				playAnim(menuItem, 'idle');
			}
			else
				menuItem.makeGraphic(360, 110, 0xFF444466);
			MenuFx.setupAnims(menuItem, props, optionShit[i]);
			menuItems.add(menuItem);

			if (props != null)
			{
				menuItem.x = props.x;
				menuItem.y = props.y;
				menuItem.scrollFactor.set(0, 0);
				menuItem.scale.set(props.scaleX * layout.globalScale, props.scaleY * layout.globalScale);
				menuItem.updateHitbox();
			}
			else
			{
				var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
				menuItem.y = (i * 140) + offset;

				var scr:Float = (optionShit.length - 4) * 0.135;
				if (optionShit.length < 6)
					scr = 0;
				menuItem.scrollFactor.set(0, scr);
				menuItem.updateHitbox();
				menuItem.screenCenter(X);
			}

			menuItem.alpha = 1;
		}

		if (layout != null)
		{
			for (p in layout.decor)
			{
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

		if (curSelected >= optionShit.length || curSelected < 0)
			curSelected = 0;
		FlxG.camera.follow(camFollow, null, 0.06);
		changeItem();

		FlxG.mouse.visible = pcPointer;

		#if TOUCH_CONTROLS_ALLOWED
		if (host.controls.mobileC)
			host.addTouchPad('NONE', 'B_C');
		else
			host.addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	function playAnim(spr:FlxSprite, name:String)
	{
		if (spr != null && spr.animation != null && spr.animation.exists(name))
			spr.animation.play(name);
	}

	function padC():Bool
	{
		#if TOUCH_CONTROLS_ALLOWED
		return host.touchPad != null && host.touchPad.buttonC != null && host.touchPad.buttonC.justPressed;
		#else
		return false;
		#end
	}

	function padHeld():Bool
	{
		#if TOUCH_CONTROLS_ALLOWED
		if (host.touchPad == null)
			return false;
		return (host.touchPad.buttonB != null && host.touchPad.buttonB.pressed) || (host.touchPad.buttonC != null && host.touchPad.buttonC.pressed)
			|| (host.touchPad.buttonA != null && host.touchPad.buttonA.pressed);
		#else
		return false;
		#end
	}

	function pointerPad():Float
		return host.controls.mobileC ? 36 : 10;

	function hitItem(px:Float, py:Float):Int
	{
		var best:Int = -1;
		var bestD:Float = 1e12;
		var pad = pointerPad();
		var members = menuItems.members;
		for (i in 0...members.length)
		{
			var it = members[i];
			if (it == null || !it.alive || !it.visible)
				continue;
			screenRect(it, _hitRect);
			var l = _hitRect.x;
			var t = _hitRect.y;
			var r = l + _hitRect.width;
			var b = t + _hitRect.height;
			var hx = it.x - FlxG.camera.scroll.x * it.scrollFactor.x;
			var hy = it.y - FlxG.camera.scroll.y * it.scrollFactor.y;
			if (hx < l) l = hx;
			if (hy < t) t = hy;
			if (hx + it.width > r) r = hx + it.width;
			if (hy + it.height > b) b = hy + it.height;
			it.getScreenBounds(_boundsRect, FlxG.camera);
			if (_boundsRect.x < l) l = _boundsRect.x;
			if (_boundsRect.y < t) t = _boundsRect.y;
			if (_boundsRect.right > r) r = _boundsRect.right;
			if (_boundsRect.bottom > b) b = _boundsRect.bottom;
			if (DEBUG_POINTER && FlxG.mouse.justPressed)
				trace('[menu] item $i ${optionShit[i]} rect=($l,$t)-($r,$b) pointer=($px,$py)');
			if (px < l - pad || px > r + pad || py < t - pad || py > b + pad)
				continue;
			var dx = (l + r) / 2 - px;
			var dy = (t + b) / 2 - py;
			var d = dx * dx + dy * dy;
			if (px >= l && px <= r && py >= t && py <= b)
				d -= 1e9;
			if (d < bestD)
			{
				bestD = d;
				best = i;
			}
		}
		return best;
	}

	function pollPointer(elapsed:Float)
	{
		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;
		var movedNow = (lastMX >= 0) && (mx != lastMX || my != lastMY);
		lastMX = mx;
		lastMY = my;

		if (pcPointer && movedNow)
		{
			var over = hitItem(mx, my);
			if (over >= 0 && over != curSelected)
				changeItem(over - curSelected);
		}

		if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)
		{
			if (DEBUG_POINTER)
				trace('[menu] press at ($mx,$my) -> item ${hitItem(mx, my)}, padHeld=${padHeld()}, mouse.visible=${FlxG.mouse.visible}');
			ptrDown = !padHeld();
			ptrX = mx;
			ptrY = my;
			ptrTime = 0;
		}
		if (ptrDown)
			ptrTime += elapsed;
		if ((FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) && ptrDown)
		{
			ptrDown = false;
			var moved = Math.abs(mx - ptrX) + Math.abs(my - ptrY);
			if (moved <= 28 && ptrTime <= 0.8)
			{
				var hit = hitItem(ptrX, ptrY);
				if (hit >= 0)
				{
					if (hit != curSelected)
						changeItem(hit - curSelected);
					acceptSelected();
				}
			}
		}
	}

	/** index of the layout entry for a game item (names are normalised once, not on every lookup) */
	function propIndex(gameName:String):Int
	{
		if (layout == null)
			return -1;
		if (_propByName == null)
		{
			_propByName = new Map<String, Int>();
			for (i in 0...layout.items.length)
			{
				var k = layout.items[i].name.toLowerCase().trim();
				if (!_propByName.exists(k))
					_propByName.set(k, i);
			}
		}
		var r:Null<Int> = _propByName.get(MenuLayoutIO.layoutName(gameName).toLowerCase().trim());
		return r == null ? -1 : r;
	}

	function propsFor(gameName:String):MenuItemProps
	{
		var i = propIndex(gameName);
		return i < 0 ? null : layout.items[i];
	}

	function applyLayoutToButtonList()
	{
		if (layout != null)
		{
			var keep = optionShit.filter(n ->
			{
				var p = propsFor(n);
				return p == null || p.enabled != false;
			});
			if (keep.length > 0)
			{
				var ranked = [for (i in 0...keep.length) {name: keep[i], key: layoutIndex(keep[i]), idx: i}];
				ranked.sort((a, b) -> (a.key != b.key) ? a.key - b.key : a.idx - b.idx);
				optionShit = [for (r in ranked) r.name];
			}
		}
		itemProps = [for (n in optionShit) propsFor(n)];
	}

	function layoutIndex(gameName:String):Int
	{
		var i = propIndex(gameName);
		return i < 0 ? 9999 : i;
	}

	function baseScaleX(i:Int):Float
		return (itemProps[i] != null) ? itemProps[i].scaleX * layout.globalScale : 1.0;

	function baseScaleY(i:Int):Float
		return (itemProps[i] != null) ? itemProps[i].scaleY * layout.globalScale : 1.0;

	private function applyLayoutOrFallback(item:FlxSprite, name:String, index:Int):Void
	{
		var p = (index >= 0 && index < itemProps.length) ? itemProps[index] : null;
		if (p != null)
		{
			item.x = p.x;
			item.y = p.y;
		}
		else
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			item.x = 0;
			item.y = (index * 140) + offset;
			item.screenCenter(X);
		}
	}

	function keepsBeating(p:MenuItemProps):Bool
		return p.beatAnim == 'sparrow' && !MenuLayoutIO.hasText(p.enterPrefix);

	function tickBeat(elapsed:Float)
	{
		if (layout == null)
			return;
		var t:Float;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			t = FlxG.sound.music.time;
		else
		{
			beatClock += elapsed * 1000;
			t = beatClock;
		}
		var b = Math.floor(t / _beatLen);
		if (b == lastBeat)
			return;
		lastBeat = b;
		if (layout.bgSparrow == true && MenuLayoutIO.hasText(layout.bgBeat) && (!selectedSomethin || !MenuLayoutIO.hasText(layout.bgEnter)))
			MenuFx.playOnce(host.bg, 'beat', 'main');
		for (i in 0...menuItems.members.length)
		{
			var item = menuItems.members[i];
			var p = itemProps[i];
			if (p == null || item == null || p.beatAnim == 'none')
				continue;
			if (selectedSomethin && !keepsBeating(p))
				continue;
			var sel = (i == curSelected);
			MenuFx.beat(item, p, baseScaleX(i) * (sel ? 1.1 : 1.0), baseScaleY(i) * (sel ? 1.1 : 1.0), b, sel ? 'selected' : 'idle');
		}
		for (d in decorList)
		{
			if (d.props.beatAnim == 'none')
				continue;
			if (selectedSomethin && !keepsBeating(d.props))
				continue;
			MenuFx.beat(d.spr, d.props, d.props.scaleX, d.props.scaleY, b, 'main');
		}
	}

	function pollBind()
	{
		if (layout == null || !FlxG.keys.pressed.ANY)
			return;
		var hit = MenuLayoutIO.pollKeys(itemProps);
		if (hit < 0)
			return;
		if (hit != curSelected)
			changeItem(hit - curSelected);
		acceptSelected();
	}

	function showTransBg()
	{
		if (transBg == null)
			return;
		FlxTween.cancelTweensOf(transBg);
		FlxTween.tween(transBg, {alpha: 1}, MenuFx.TRANS_FADE);
		if (layout.transBgSparrow == true && MenuLayoutIO.hasText(layout.transBgEnter))
			MenuFx.playOnce(transBg, 'enter', '');
	}

	function hideTransBg()
	{
		if (transBg == null)
			return;
		FlxTween.cancelTweensOf(transBg);
		FlxTween.tween(transBg, {alpha: 0}, MenuFx.TRANS_FADE);
		MenuFx.resetSheet(transBg);
	}

	function hideOthers(chosen:String)
	{
		for (i in 0...menuItems.members.length)
		{
			if (i == curSelected)
				continue;
			var p = itemProps[i];
			if (p == null || p.hideOnEnter != false)
				MenuFx.hide(menuItems.members[i]);
		}
		for (d in decorList)
		{
			if (MenuFx.decorEnter(d.spr, d.props, chosen))
				continue;
			if (d.props.hideOnEnter == true)
				MenuFx.hide(d.spr);
			else
				MenuFx.playEnterAnim(d.spr, d.props);
		}
		if (layout != null && layout.bgSparrow == true && MenuLayoutIO.hasText(layout.bgEnter))
			MenuFx.playOnce(host.bg, 'enter', '');
	}

	function restoreAll()
	{
		for (i in 0...menuItems.members.length)
		{
			var it = menuItems.members[i];
			if (it == null)
				continue;
			FlxTween.cancelTweensOf(it);
			FlxTween.cancelTweensOf(it.scale);
			it.revive();
			it.alpha = 1;
			it.visible = true;
			it.angle = 0;
			it.scale.set(baseScaleX(i), baseScaleY(i));
			it.updateHitbox();
			applyLayoutOrFallback(it, optionShit[i], i);
		}
		for (d in decorList)
		{
			FlxTween.cancelTweensOf(d.spr);
			FlxTween.cancelTweensOf(d.spr.scale);
			d.spr.revive();
			d.spr.visible = MenuFx.startsVisible(d.props);
			MenuFx.place(d.spr, d.props);
			MenuFx.resetSheet(d.spr);
		}
		if (layout != null && layout.bgSparrow == true)
			MenuFx.resetSheet(host.bg);
		selectedSomethin = false;
	}

	function acceptSelected()
	{
		if (curSelected < 0 || curSelected >= optionShit.length)
			return;
		var chosen = optionShit[curSelected];
		var props = (curSelected < itemProps.length) ? itemProps[curSelected] : null;
		MenuFx.playEnterSound(props);
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		if (chosen == 'donate')
		{
			CoolUtil.browserLoad('https://needlejuicerecords.com');
			return;
		}
		selectedSomethin = true;
		MenuFx.playEnterMusic(props);

		if (VsliceOptions.FLASHBANG && host.magenta != null)
			FlxFlicker.flicker(host.magenta, 1.1, 0.15, false);

		showTransBg();
		hideOthers(chosen);

		var item = (curSelected < menuItems.members.length) ? menuItems.members[curSelected] : null;
		var go = function() openTarget(chosen);
		if (item == null)
			go();
		else if (props == null)
			FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker) go());
		else
			MenuFx.enter(item, props, go);
	}

	function openTarget(name:String)
	{
		if (name != 'freeplay')
			FlxG.mouse.visible = false;
		switch (name)
		{
			case 'story_mode':
				MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay':
				{
					host.persistentDraw = true;
					host.persistentUpdate = false;
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					host.openSubState(new FreeplayState());
					host.subStateOpened.addOnce(state ->
					{
						restoreAll();
						changeItem(0);
					});
					host.subStateClosed.addOnce(state ->
					{
						hideTransBg();
						if (pcPointer)
							FlxG.mouse.visible = true;
					});
				}

			#if MODS_ALLOWED
			case 'mods':
				MusicBeatState.switchState(new ModsMenuState());
			#end

			case 'credits':
				MusicBeatState.switchState(new CreditsState());
			case 'options':
				host.goToOptions();
		}
	}

	override function update(elapsed:Float)
	{
		tickBeat(elapsed);

		if (!selectedSomethin)
		{
			pollBind();
		}

		if (!selectedSomethin)
		{
			pollPointer(elapsed);
		}
		else
			ptrDown = false;

		if (!selectedSomethin)
		{
			if (host.controls.UI_UP_P)
				changeItem(-1);

			if (host.controls.UI_DOWN_P)
				changeItem(1);

			if (pcPointer && FlxG.mouse.wheel != 0)
				changeItem(FlxG.mouse.wheel > 0 ? -1 : 1);

			if (host.controls.BACK)
			{
				if (FlxG.sound.music != null) {
					FlxG.sound.music.fadeOut(0.6, 0.0);
				}
				if (TitleState.titleMenuMusic != null) {
					TitleState.titleMenuMusic.fadeIn(0.6, 0.0, 0.7);
				}

				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new mikolka.vslice.ui.title.TitleState());
			}

			if (acceptPressed(host))
				acceptSelected();

			if (padC() || #if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1')
				.filter(s -> s != -1)) #else host.controls.justPressed('debug_1') #end)
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		if (menuItems == null || menuItems.length == 0)
			return;
		if (huh != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		var prevItem = menuItems.members[curSelected];
		if (prevItem != null) {
			playAnim(prevItem, 'idle');
			prevItem.updateHitbox();
			applyLayoutOrFallback(prevItem, optionShit[curSelected], curSelected);

			FlxTween.cancelTweensOf(prevItem.scale);
			FlxTween.tween(prevItem.scale, {x: baseScaleX(curSelected), y: baseScaleY(curSelected)}, 0.15, {ease: FlxEase.quadOut});
		}

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		var item = menuItems.members[curSelected];
		if (item == null)
			return;
		playAnim(item, 'selected');
		item.centerOffsets();
		applyLayoutOrFallback(item, optionShit[curSelected], curSelected);

		item.scale.set(baseScaleX(curSelected), baseScaleY(curSelected));
		FlxTween.cancelTweensOf(item.scale);
		FlxTween.tween(item.scale, {x: baseScaleX(curSelected) * 1.1, y: baseScaleY(curSelected) * 1.1}, 0.25, {ease: FlxEase.backOut});

		if (camFollow != null)
		{
			var mp = item.getGraphicMidpoint();
			camFollow.setPosition(mp.x, mp.y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
			mp.put();
		}
	}
}
