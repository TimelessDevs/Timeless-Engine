package mobile.input;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import haxe.ds.Map;

class MobileInputManager extends FlxTypedSpriteGroup<TouchButton>
{
	public var trackedButtons:Map<MobileInputID, TouchButton> = new Map<MobileInputID, TouchButton>();

	public function new()
	{
		super();
		updateTrackedButtons();
	}

	public inline function buttonPressed(button:MobileInputID):Bool
	{
		if (button == MobileInputID.NONE) return false;
		var btn = trackedButtons.get(button);
		return (btn != null) ? btn.pressed : false;
	}

	public inline function buttonJustPressed(button:MobileInputID):Bool
	{
		if (button == MobileInputID.NONE) return false;
		var btn = trackedButtons.get(button);
		return (btn != null) ? btn.justPressed : false;
	}

	public inline function buttonJustReleased(button:MobileInputID):Bool
	{
		if (button == MobileInputID.NONE) return false;
		var btn = trackedButtons.get(button);
		return (btn != null) ? btn.justReleased : false;
	}

	public inline function buttonReleased(button:MobileInputID):Bool
	{
		if (button == MobileInputID.NONE) return false;
		var btn = trackedButtons.get(button);
		return (btn != null) ? btn.released : false;
	}

	public function anyPressed(buttonsArray:Array<MobileInputID>):Bool
	{
		if (buttonsArray == null) return false;
		for (id in buttonsArray)
		{
			if (id == MobileInputID.NONE) continue;
			var btn = trackedButtons.get(id);
			if (btn != null && btn.pressed) return true;
		}
		return false;
	}

	public function anyJustPressed(buttonsArray:Array<MobileInputID>):Bool
	{
		if (buttonsArray == null) return false;
		for (id in buttonsArray)
		{
			if (id == MobileInputID.NONE) continue;
			var btn = trackedButtons.get(id);
			if (btn != null && btn.justPressed) return true;
		}
		return false;
	}

	public function anyJustReleased(buttonsArray:Array<MobileInputID>):Bool
	{
		if (buttonsArray == null) return false;
		for (id in buttonsArray)
		{
			if (id == MobileInputID.NONE) continue;
			var btn = trackedButtons.get(id);
			if (btn != null && btn.justReleased) return true;
		}
		return false;
	}

	public function anyReleased(buttonsArray:Array<MobileInputID>):Bool
	{
		if (buttonsArray == null) return false;
		for (id in buttonsArray)
		{
			if (id == MobileInputID.NONE) continue;
			var btn = trackedButtons.get(id);
			if (btn != null && btn.released) return true;
		}
		return false;
	}

	public function checkStatus(button:MobileInputID, state:ButtonsStates = JUST_PRESSED):Bool
	{
		switch (button)
		{
			case MobileInputID.ANY:
				for (id in trackedButtons.keys())
					if (checkStatusUnsafe(id, state)) return true;
			case MobileInputID.NONE:
				return false;
			default:
				if (trackedButtons.exists(button))
					return checkStatusUnsafe(button, state);
		}
		return false;
	}

	function checkButtonArrayState(Buttons:Array<MobileInputID>, state:ButtonsStates = JUST_PRESSED):Bool
	{
		if (Buttons == null) return false;
		for (button in Buttons)
			if (checkStatus(button, state)) return true;
		return false;
	}

	function checkStatusUnsafe(button:MobileInputID, state:ButtonsStates = JUST_PRESSED):Bool
	{
		var btn = trackedButtons.get(button);
		if (btn == null) return false;
		return switch (state)
		{
			case RELEASED: btn.released;
			case JUST_RELEASED: btn.justReleased;
			case PRESSED: btn.pressed;
			case JUST_PRESSED: btn.justPressed;
		}
	}

	public function updateTrackedButtons()
	{
		trackedButtons.clear();
		forEachExists(function(button:TouchButton)
		{
			if (button.IDs != null)
			{
				for (id in button.IDs)
				{
					if (!trackedButtons.exists(id))
						trackedButtons.set(id, button);
				}
			}
		});
	}
}

enum ButtonsStates
{
	PRESSED;
	JUST_PRESSED;
	RELEASED;
	JUST_RELEASED;
}