package options;
import options.Option;

class TimelessSubState extends BaseOptionsMenu {
    public function new() {
        title = Language.getPhrase("vslice_menu","T-Engine settings");
        rpcTitle = "P-Slice settings menu";
        var option:Option = new Option('Mod Previews',
			'If checked, allows the game to display Mod Previews',
			'modPreviews',
			BOOL);
		addOption(option);

        super();
    }
}