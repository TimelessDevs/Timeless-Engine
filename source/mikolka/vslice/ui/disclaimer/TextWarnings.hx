package mikolka.vslice.ui.disclaimer;

import flixel.FlxState;

class OutdatedState extends WarningState
{
	public function new(newVersion:String, nextState:FlxState)
	{
		final bro:String = #if mobile 'kiddo' #else 'bro' #end;
		final escape:String = (controls.mobileC) ? 'B' : 'ESCAPE';

		var guh = "Hi " + bro + ", looks like you're running an\noutdated version of Timeless Engine (" + MainMenuState.TimelessEngineVersion + "),\nplease update to " + newVersion + "!\nPress " + escape + " to proceed anyway.\n\nThank you for using the Engine!";
		
		super(guh, () -> {
			CoolUtil.browserLoad("https://github.com/timelessdevs/timeless-engine");
			if (onExit != null) onExit();
		}, onExit, nextState);
	}
}

class FlashingState extends WarningState
{
	public function new(nextState:FlxState)
	{
		final enter:String = controls.mobileC ? 'A' : 'ENTER';
		final escape:String = controls.mobileC ? 'B' : 'ESCAPE';
		
		var text = "Hey, watch out!\nThis Mod contains some flashing lights!\nPress " + escape + " to disable them now or go to Options Menu.\nPress " + enter + " to ignore this message.\nYou've been warned!";
		
		super(text, () -> {
			#if LEGACY_PSYCH
			ClientPrefs.flashing = true;
			#else
			ClientPrefs.data.flashing = true;
			#end
			ClientPrefs.saveSettings();
		}, () -> {
			#if LEGACY_PSYCH
			ClientPrefs.flashing = false;
			#else
			ClientPrefs.data.flashing = false;
			#end
			ClientPrefs.saveSettings();
		}, nextState);
	}
}