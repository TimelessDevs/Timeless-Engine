package states.editors;

//so i stopped developing mod editor because of my budget. Maybe i will re-code it and add to the game later.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.text.FlxInputText;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;

class ModEditorState extends backend.MusicBeatState
{
	var blockInputBoxes:Array<FlxInputText> = [];
	var currentTab:String = "Mod";

	var modGroup:FlxTypedGroup<flixel.FlxBasic>;
	var songsGroup:FlxTypedGroup<flixel.FlxBasic>;
	var weeksGroup:FlxTypedGroup<flixel.FlxBasic>;
	var previewsGroup:FlxTypedGroup<flixel.FlxBasic>;
	var charsGroup:FlxTypedGroup<flixel.FlxBasic>;
	var dialoguesGroup:FlxTypedGroup<flixel.FlxBasic>;

	var menuFileBtn:FlxButton;
	var menuEditBtn:FlxButton;
	var menuViewBtn:FlxButton;
	var fileDropdownGroup:FlxTypedGroup<FlxButton>;
	var isFileMenuOpen:Bool = false;

	var rightPanelBg:FlxSprite;
	var infoPanelBg:FlxSprite;
	var infoPanelText:FlxText;

	var modNameInput:FlxInputText;
	var modDescInput:FlxInputText;
	var currentModIndex:Int = 0;
	var installedMods:Array<String> = [];
	var modSelectorText:FlxText;

	var songInputs:Array<FlxInputText> = [];
	var addSongBtn:FlxButton;
	var nextSongY:Int = 30;

	var weekSongsInput:FlxInputText;
	var weekCharDadInput:FlxInputText;
	var weekCharBfInput:FlxInputText;
	var weekCharGfInput:FlxInputText;
	var weekStageInput:FlxInputText;
	var weekDisplayNameInput:FlxInputText;
	var weekScoreNameInput:FlxInputText;
	var weekFileNameInput:FlxInputText;
	var weekLockUnlockInput:FlxInputText;
	var weekDifficultiesInput:FlxInputText;
	var weekTemplateTitleText:FlxText;
	var weekFilesListText:FlxText;
	var currentWeekTemplateIndex:Int = 0;
	var weekTemplates:Array<Dynamic> = [];

	var previewFileNamesMemory:Array<String> = ["", "", ""];
	var previewButtons:Array<FlxButton> = [];
	var previewSpritesOnCard:Array<FlxSprite> = [];
	var currentPreviewCount:Int = 0;

	var charImgInput:FlxInputText;
	var charIconInput:FlxInputText;
	var charVocalsInput:FlxInputText;
	var charAnimLenInput:FlxInputText;
	var charFlipXBtn:FlxButton;
	var charXInput:FlxInputText;
	var charYInput:FlxInputText;
	var charCamXInput:FlxInputText;
	var charCamYInput:FlxInputText;
	var charRInput:FlxInputText;
	var charGInput:FlxInputText;
	var charBInput:FlxInputText;
	var isCharFlipped:Bool = false;

	var dialCharInput:FlxInputText;
	var dialSpeedInput:FlxInputText;
	var dialSoundInput:FlxInputText;
	var dialTextInput:FlxInputText;
	var dialPixelBtn:FlxButton;
	var dialAngryBtn:FlxButton;
	var isDialPixel:Bool = false;
	var isDialAngry:Bool = false;

	var storyModeBg:FlxSprite;
	var storyYellowBar:FlxSprite;
	var storyWeekTitle:FlxSprite;
	var storyCharDad:FlxSprite;
	var storyCharBf:FlxSprite;
	var storyCharGf:FlxSprite;
	var storyTracksTitle:FlxText;
	var storyTracksList:FlxText;
	var storyDiffsGroup:FlxTypedGroup<FlxSprite>;

	var cardBg:FlxSprite;
	var cardIcon:FlxSprite;
	var cardNameText:FlxText;
	var cardDescText:FlxText;
	var cardLine1:FlxSprite;
	var cardCharsText:FlxText;

	var charJsonBytes:openfl.utils.ByteArray = null; var charJsonName:String = ""; var charPngBytes:openfl.utils.ByteArray = null; var charPngName:String = "";
	var jsonBrowser:openfl.net.FileReference; var pngBrowser:openfl.net.FileReference; var xmlBrowser:openfl.net.FileReference; var iconBrowser:openfl.net.FileReference;

	override function create()
	{
		super.create();
		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF1E1E1E;
		add(bg);

		var topMenuBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 40, 0xFF000000);
		add(topMenuBar);

		rightPanelBg = new FlxSprite(FlxG.width - 280, 40).makeGraphic(280, FlxG.height - 40, 0xFF111111);
		add(rightPanelBg);

		infoPanelBg = new FlxSprite(FlxG.width - 550, FlxG.height - 240).makeGraphic(250, 220, 0xFF111111);
		add(infoPanelBg);

		infoPanelText = new FlxText(FlxG.width - 540, FlxG.height - 230, 230, "", 14);
		infoPanelText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFFFFF, "left");
		add(infoPanelText);

		modGroup = new FlxTypedGroup<flixel.FlxBasic>();
		songsGroup = new FlxTypedGroup<flixel.FlxBasic>();
		weeksGroup = new FlxTypedGroup<flixel.FlxBasic>();
		previewsGroup = new FlxTypedGroup<flixel.FlxBasic>();
		charsGroup = new FlxTypedGroup<flixel.FlxBasic>();
		dialoguesGroup = new FlxTypedGroup<flixel.FlxBasic>();
		
		add(modGroup); add(songsGroup); add(weeksGroup); 
		add(previewsGroup); add(charsGroup); add(dialoguesGroup);

		setupTopMenuButtons();
		setupCentralCard();

		scanInstalledModsList();
		setupModTabFields();
		setupSongsTabFields();
		setupWeeksTabFields();
		setupPreviewsTabFields();
		setupCharactersTabFields();
		setupDialoguesTabFields();

		toggleFpsCounter(false);

		switchTab("Mod");
	}

	function setupTopMenuButtons()
	{
		menuFileBtn = new FlxButton(5, 7, "File", function() { toggleFileDropdown(); });
		menuFileBtn.makeGraphic(60, 26, 0xFF222222); menuFileBtn.label.setFormat(null, 12, 0xFFFFFFFF, "center"); add(menuFileBtn);

		menuEditBtn = new FlxButton(70, 7, "Edit Layout", function() { switchTab("Songs"); });
		menuEditBtn.makeGraphic(90, 26, 0xFF222222); menuEditBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); add(menuEditBtn);

		menuViewBtn = new FlxButton(165, 7, "Tabs", function() { isFileMenuOpen = false; fileDropdownGroup.visible = false; });
		menuViewBtn.makeGraphic(60, 26, 0xFF222222); menuViewBtn.label.setFormat(null, 12, 0xFFFFFFFF, "center"); add(menuViewBtn);

		fileDropdownGroup = new FlxTypedGroup<FlxButton>();
		add(fileDropdownGroup);
		fileDropdownGroup.visible = false;

		var dropLabels:Array<String> = ["Mod Setup", "Songs Layout", "Weeks Config", "Previews", "Characters", "Dialogues"];
		var dropTabs:Array<String> = ["Mod", "Songs", "Weeks", "Previews", "Characters", "Dialogues"];

		for (i in 0...dropLabels.length) {
			var btn = new FlxButton(5, 35 + (i * 28), dropLabels[i], function() {
				switchTab(dropTabs[i]);
				fileDropdownGroup.visible = false;
				isFileMenuOpen = false;
			});
			btn.makeGraphic(130, 26, 0xFF1A1A1A);
			btn.label.setFormat(null, 11, 0xFFFFFFFF, "left");
			fileDropdownGroup.add(btn);
		}
	}

	function toggleFileDropdown()
	{
		isFileMenuOpen = !isFileMenuOpen;
		fileDropdownGroup.visible = isFileMenuOpen;
	}

	function switchTab(tab:String)
	{
		currentTab = tab;

		modGroup.visible = (tab == "Mod");
		songsGroup.visible = (tab == "Songs");
		weeksGroup.visible = (tab == "Weeks");
		previewsGroup.visible = (tab == "Previews");
		charsGroup.visible = (tab == "Characters");
		dialoguesGroup.visible = (tab == "Dialogues");
	}

	function updateInfoPanelDataString()
	{
		if (infoPanelText != null) {
			var activeFolder = (installedMods.length > 0) ? installedMods[currentModIndex] : "none";
			infoPanelText.text = "Information\n\nModding IDE\nActive: " + activeFolder + "\nTracks: " + songInputs.length + "\n"
				+ "Template ID: " + (weekTemplates.length > 0 ? "MyWeek" + (currentWeekTemplateIndex + 1) : "MyWeek1") + "\n\n"
				+ "Press F1 for Help";
		}
	}

	function setupCentralCard()
	{
		cardBg = new FlxSprite(45, 45);
		cardBg.makeGraphic(875, 545, 0x00000000);
		add(cardBg);
		flixel.util.FlxSpriteUtil.drawRoundRect(cardBg, 0, 0, 875, 545, 25, 25, 0xFF311B92);

		var cardBorder = new FlxSprite(45, 45);
		cardBorder.makeGraphic(875, 545, 0x00000000);
		add(cardBorder);
		flixel.util.FlxSpriteUtil.drawRoundRect(cardBorder, 0, 0, 875, 545, 25, 25, 0x00000000, {color: 0xFF000000, thickness: 5});

		cardIcon = new FlxSprite(70, 70);
		cardIcon.makeGraphic(120, 120, 0xFFFFFFFF);
		add(cardIcon);

		cardNameText = new FlxText(210, 100, 680, "MY AWESOME MOD", 44);
		cardNameText.setFormat(Paths.font("vcr.ttf"), 44, 0xFFFFFFFF, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(cardNameText);

		cardLine1 = new FlxSprite(45, 210).makeGraphic(875, 6, 0xFFE040FB);
		add(cardLine1);

		cardDescText = new FlxText(70, 235, 825, "This is my custom mod description.", 22);
		cardDescText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFFFFF, "left");
		add(cardDescText);

		cardCharsText = new FlxText(70, 320, 825, "characters:\n(no characters found)", 32);
		cardCharsText.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, "left", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF000000);
		cardCharsText.borderSize = 2.5;
		add(cardCharsText);

		storyModeBg = new FlxSprite(45, 45);
		storyModeBg.makeGraphic(875, 545, 0xFF000000);
		add(storyModeBg);

		storyYellowBar = new FlxSprite(45, 260).makeGraphic(875, 140, 0xFFF9C901);
		add(storyYellowBar);

		storyWeekTitle = new FlxSprite(350, 480);
		storyWeekTitle.makeGraphic(260, 80, 0x00000000);
		add(storyWeekTitle);

		storyCharDad = new FlxSprite(100, 80);
		storyCharDad.makeGraphic(100, 150, 0x00000000);
		add(storyCharDad);

		storyCharBf = new FlxSprite(420, 80);
		storyCharBf.makeGraphic(100, 150, 0x00000000);
		add(storyCharBf);

		storyCharGf = new FlxSprite(680, 100);
		storyCharGf.makeGraphic(100, 150, 0x00000000);
		add(storyCharGf);

		storyTracksTitle = new FlxText(80, 310, 200, "TRACKS", 24);
		storyTracksTitle.setFormat(Paths.font("vcr.ttf"), 24, 0xFFE57373, "center", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(storyTracksTitle);

		storyTracksList = new FlxText(80, 350, 200, "", 16);
		storyTracksList.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "center", flixel.text.FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(storyTracksList);

		storyDiffsGroup = new FlxTypedGroup<FlxSprite>();
		add(storyDiffsGroup);
	}

	function scanInstalledModsList()
	{
		installedMods = [];
		if (sys.FileSystem.exists('mods/')) {
			var dirs = sys.FileSystem.readDirectory('mods/');
			for (dir in dirs) {
				if (sys.FileSystem.isDirectory('mods/' + dir) && dir != 'menulayouts' && dir != 'previews') {
					installedMods.push(dir);
				}
			}
		}
		if (installedMods.length == 0) installedMods.push("no-mods-found");
	}

	function setupModTabFields()
	{
		var startY:Int = 55;
		var selLabel = new FlxText(FlxG.width - 270, startY, 260, "📁 Active Mod Target folder:", 10);
		selLabel.color = 0xFFB0BEC5; modGroup.add(selLabel);

		var prevModBtn = new FlxButton(FlxG.width - 270, startY + 16, "<", function() { cycleActiveModFolder(-1); });
		prevModBtn.makeGraphic(35, 22, 0xFF333333); prevModBtn.label.setFormat(null, 12, 0xFFFFFFFF, "center"); modGroup.add(prevModBtn);

		modSelectorText = new FlxText(FlxG.width - 230, startY + 20, 180, installedMods[currentModIndex], 11);
		modSelectorText.setFormat(Paths.font("vcr.ttf"), 11, 0xFFFFF59D, "center"); modGroup.add(modSelectorText);

		var nextModBtn = new FlxButton(FlxG.width - 45, startY + 16, ">", function() { cycleActiveModFolder(1); });
		nextModBtn.makeGraphic(35, 22, 0xFF333333); nextModBtn.label.setFormat(null, 12, 0xFFFFFFFF, "center"); modGroup.add(nextModBtn);

		var addModBtn = new FlxButton(FlxG.width - 270, startY + 44, "Add Mod (Copy Folder)", function() { startModFolderImport(); });
		addModBtn.makeGraphic(260, 24, 0xFF424242); addModBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center"); modGroup.add(addModBtn);
		
		startY += 78;

		var nameLabel = new FlxText(FlxG.width - 270, startY, 260, "Mod Name (Title text):", 10); nameLabel.color = 0xFFECEFF1; modGroup.add(nameLabel);
		modNameInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "My Awesome Mod", 11); modGroup.add(modNameInput); blockInputBoxes.push(modNameInput);
		startY += 48;

		var descLabel = new FlxText(FlxG.width - 270, startY, 260, "Mod Description (Pack string):", 10); descLabel.color = 0xFFECEFF1; modGroup.add(descLabel);
		modDescInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "This is my custom mod description.", 11); modGroup.add(modDescInput); blockInputBoxes.push(modDescInput);
		startY += 48;

		var createBtn = new FlxButton(FlxG.width - 270, startY, "Create Mod Structure", function() { createNewModStructure(modNameInput.text, modDescInput.text); });
		createBtn.makeGraphic(260, 24, 0xFF424242); createBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); modGroup.add(createBtn);
		startY += 34;

		var addCharBtn = new FlxButton(FlxG.width - 270, startY, "Add Character (Import files)", function() { startCharacterImportChain(); });
		addCharBtn.makeGraphic(260, 24, 0xFF424242); addCharBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); modGroup.add(addCharBtn);
		startY += 34;

		var addIconBtn = new FlxButton(FlxG.width - 270, startY, "Add Icon (pack.png asset)", function() { startModIconImport(); });
		addIconBtn.makeGraphic(260, 24, 0xFF424242); addIconBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); modGroup.add(addIconBtn);
		
		loadSelectedModDataMetaData();
	}

	function cycleActiveModFolder(dir:Int)
	{
		currentModIndex += dir;
		if (currentModIndex >= installedMods.length) currentModIndex = 0;
		if (currentModIndex < 0) currentModIndex = installedMods.length - 1;
		
		modSelectorText.text = installedMods[currentModIndex];
		loadSelectedModDataMetaData();
	}

	function loadSelectedModDataMetaData()
	{
		var activeFolder = installedMods[currentModIndex];
		if (activeFolder == "no-mods-found" || activeFolder == "") return;

		var packPath = 'mods/' + activeFolder + '/pack.json';
		var iconPath = 'mods/' + activeFolder + '/pack.png';

		if (sys.FileSystem.exists(packPath)) {
			try {
				var json = haxe.Json.parse(sys.io.File.getContent(packPath));
				modNameInput.text = (json.name != null) ? json.name : activeFolder;
				modDescInput.text = (json.description != null) ? json.description : "";
			} catch(e:Dynamic) {}
		} else {
			modNameInput.text = activeFolder;
			modDescInput.text = "";
		}

		if (sys.FileSystem.exists(iconPath)) {
			try {
				var bytes = sys.io.File.getBytes(iconPath);
				var loader = new openfl.display.Loader();
				loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE, function(e) {
					cardIcon.pixels = cast(loader.content, openfl.display.Bitmap).bitmapData;
					cardIcon.setGraphicSize(120, 120); cardIcon.updateHitbox();
				});
				loader.loadBytes(bytes);
			} catch(e:Dynamic) {}
		} else {
			cardIcon.makeGraphic(120, 120, 0xFFFFFFFF);
		}

		updateCardCharactersList();
	}

	function setupSongsTabFields()
	{
		var songsLabel = new FlxText(FlxG.width - 270, 55, 260, "🎵 Configure Mod Tracks Layout:", 11); songsLabel.color = 0xFFECEFF1; songsGroup.add(songsLabel);

		var firstSongInput = new FlxInputText(FlxG.width - 270, 76, 215, "test-song", 11);
		songsGroup.add(firstSongInput); blockInputBoxes.push(firstSongInput); songInputs.push(firstSongInput);

		addSongBtn = new FlxButton(FlxG.width - 45, 76, "+", function() {
			if (songInputs.length < 14) {
				var newSongInput = new FlxInputText(FlxG.width - 270, 76 + nextSongY, 215, "new-song", 11);
				songsGroup.add(newSongInput); blockInputBoxes.push(newSongInput); songInputs.push(newSongInput);
				addSongBtn.y = newSongInput.y;
				nextSongY += 30;
			}
		});
		addSongBtn.makeGraphic(35, 20, 0xFF444444); addSongBtn.label.setFormat(null, 12, 0xFFFFFFFF, "center"); songsGroup.add(addSongBtn);
	}

	function setupWeeksTabFields()
	{
		var startY:Int = 110;
		
		var weekSelectorLabel = new FlxText(FlxG.width - 270, 55, 260, "📅 Active Edit Template:", 10);
		weekSelectorLabel.color = 0xFFB0BEC5;
		weeksGroup.add(weekSelectorLabel);

		var prevWeekBtn = new FlxButton(FlxG.width - 270, 72, "<", function() { cycleActiveWeekTemplate(-1); });
		prevWeekBtn.makeGraphic(30, 20, 0xFF424242);
		prevWeekBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center");
		weeksGroup.add(prevWeekBtn);

		weekTemplateTitleText = new FlxText(FlxG.width - 235, 74, 120, "MyWeek", 11);
		weekTemplateTitleText.setFormat(Paths.font("vcr.ttf"), 11, 0xFFFFF59D, "center");
		weeksGroup.add(weekTemplateTitleText);

		var nextWeekBtn = new FlxButton(FlxG.width - 110, 72, ">", function() { cycleActiveWeekTemplate(1); });
		nextWeekBtn.makeGraphic(30, 20, 0xFF424242);
		nextWeekBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center");
		weeksGroup.add(nextWeekBtn);

		var createWeekBtn = new FlxButton(FlxG.width - 75, 72, "New Week", function() { createNewWeekTemplateSlot(); });
		createWeekBtn.makeGraphic(65, 20, 0xFF445544);
		createWeekBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center");
		weeksGroup.add(createWeekBtn);

		var fieldsLabels:Array<String> = [
			"Tracks (comma separated list):",
			"Characters (Dad / BF / GF fields):",
			"Background Asset / Stage Name:",
			"Story Menu Title Image (*.png):",
			"Week Name (Score Reset Menu ID):",
			"Week File Asset Name (.json):",
			"Unlock Lock condition (e.g: tutorial):",
			"Week Custom Difficulties list:"
		];

		var textFieldsRef:Array<FlxInputText> = [];

		var t1 = new FlxInputText(FlxG.width - 270, 0, 260, "bopeebo, fresh, dadbattle", 10); weekSongsInput = t1;
		var t2 = new FlxInputText(FlxG.width - 270, 0, 80, "dad", 10); weekCharDadInput = t2;
		var t3 = new FlxInputText(FlxG.width - 270, 0, 230, "stage", 10); weekStageInput = t3;
		var t4 = new FlxInputText(FlxG.width - 270, 0, 230, "week1", 10); weekDisplayNameInput = t4;
		var t5 = new FlxInputText(FlxG.width - 270, 0, 260, "Custom Week", 10); weekScoreNameInput = t5;
		var t6 = new FlxInputText(FlxG.width - 270, 0, 260, "week1", 10); weekFileNameInput = t6;
		var t7 = new FlxInputText(FlxG.width - 270, 0, 260, "tutorial", 10); weekLockUnlockInput = t7;
		var t8 = new FlxInputText(FlxG.width - 270, 0, 260, "Easy, Normal, Hard", 10); weekDifficultiesInput = t8;

		textFieldsRef = [t1, t2, t3, t4, t5, t6, t7, t8];
		
		weekCharBfInput = new FlxInputText(FlxG.width - 185, 0, 80, "bf", 10);
		weekCharGfInput = new FlxInputText(FlxG.width - 100, 0, 90, "gf", 10);

		for (i in 0...fieldsLabels.length) {
			var label = new FlxText(FlxG.width - 270, startY, 260, fieldsLabels[i], 10);
			label.color = 0xFFB0BEC5;
			weeksGroup.add(label);
			
			var input = textFieldsRef[i];
			input.y = startY + 16;
			weeksGroup.add(input);
			blockInputBoxes.push(input);

			if (i == 1) {
				weekCharBfInput.y = startY + 16; weeksGroup.add(weekCharBfInput); blockInputBoxes.push(weekCharBfInput);
				weekCharGfInput.y = startY + 16; weeksGroup.add(weekCharGfInput); blockInputBoxes.push(weekCharGfInput);
			}
			
			if (i == 2) {
				var loadBgBtn = new FlxButton(FlxG.width - 35, startY + 16, "File", function() { browseForMenuBackgroundAsset(); });
				loadBgBtn.makeGraphic(25, 18, 0xFF555555);
				loadBgBtn.label.setFormat(null, 8, 0xFFFFFFFF, "center");
				weeksGroup.add(loadBgBtn);
			}
			
			if (i == 3) {
				var loadTitleBtn = new FlxButton(FlxG.width - 35, startY + 16, "File", function() { browseForStoryMenuTitleAsset(); });
				loadTitleBtn.makeGraphic(25, 18, 0xFF555555);
				loadTitleBtn.label.setFormat(null, 8, 0xFFFFFFFF, "center");
				weeksGroup.add(loadTitleBtn);
			}
			
			startY += 45;
		}

		var saveWeekBtn = new FlxButton(FlxG.width - 270, startY + 5, "Save Week Config", function() { saveWeekConfigData(); });
		saveWeekBtn.makeGraphic(260, 24, 0xFF556655);
		saveWeekBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center");
		weeksGroup.add(saveWeekBtn);
		
		startY += 34;

		var existLabel = new FlxText(FlxG.width - 270, startY, 260, "Saved configs inside this mod:", 10);
		existLabel.color = 0xFF90A4AE;
		weeksGroup.add(existLabel);
		
		weekFilesListText = new FlxText(FlxG.width - 270, startY + 15, 260, "(none)", 10);
		weekFilesListText.setFormat(Paths.font("vcr.ttf"), 10, 0xFFCFD8DC, "left");
		weeksGroup.add(weekFilesListText);

		loadCurrentModWeekFilesList();
		loadCurrentWeekTemplateFields();
	}

	function cycleActiveWeekTemplate(dir:Int)
	{
		if (weekTemplates.length == 0) return;
		currentWeekTemplateIndex += dir;
		if (currentWeekTemplateIndex >= weekTemplates.length) currentWeekTemplateIndex = 0;
		if (currentWeekTemplateIndex < 0) currentWeekTemplateIndex = weekTemplates.length - 1;
		
		weekTemplateTitleText.text = weekTemplates[currentWeekTemplateIndex].slotName;
		loadCurrentWeekTemplateFields();
	}

	function createNewWeekTemplateSlot()
	{
		var nextNum:Int = weekTemplates.length + 1;
		var newSlotName:String = "MyWeek" + nextNum;
		
		var newTemplate = {
			slotName: newSlotName,
			songs: "bopeebo, fresh, dadbattle",
			dad: "dad",
			bf: "bf",
			gf: "gf",
			stage: "stage",
			titleImg: "week1",
			weekName: "Custom Week " + nextNum,
			fileName: "week" + nextNum,
			lockCondition: "tutorial",
			diffs: "Easy, Normal, Hard"
		};
		
		weekTemplates.push(newTemplate);
		currentWeekTemplateIndex = weekTemplates.length - 1;
		weekTemplateTitleText.text = newSlotName;
		loadCurrentWeekTemplateFields();
	}

	function saveFieldsToCurrentTemplateMemory()
	{
		if (weekTemplates.length == 0 || currentWeekTemplateIndex >= weekTemplates.length) return;
		var t = weekTemplates[currentWeekTemplateIndex];
		t.songs = weekSongsInput.text;
		t.dad = weekCharDadInput.text;
		t.bf = weekCharBfInput.text;
		t.gf = weekCharGfInput.text;
		t.stage = weekStageInput.text;
		t.titleImg = weekDisplayNameInput.text;
		t.weekName = weekScoreNameInput.text;
		t.fileName = weekFileNameInput.text;
		t.lockCondition = weekLockUnlockInput.text;
		t.diffs = weekDifficultiesInput.text;
	}

	function loadCurrentWeekTemplateFields()
	{
		if (weekTemplates.length == 0 || currentWeekTemplateIndex >= weekTemplates.length) return;
		if (weekSongsInput == null) return;
		
		var t = weekTemplates[currentWeekTemplateIndex];
		weekSongsInput.text = t.songs;
		weekCharDadInput.text = t.dad;
		weekCharBfInput.text = t.bf;
		weekCharGfInput.text = t.gf;
		weekStageInput.text = t.stage;
		weekDisplayNameInput.text = t.titleImg;
		weekScoreNameInput.text = t.weekName;
		weekFileNameInput.text = t.fileName;
		weekLockUnlockInput.text = t.lockCondition;
		weekDifficultiesInput.text = t.diffs;
	}

	function loadCurrentModWeekFilesList()
	{
		if (weekFilesListText == null) return;
		var activeFolder = installedMods[currentModIndex];
		if (activeFolder == "no-mods-found" || activeFolder == "") return;

		var path:String = 'mods/' + activeFolder + '/weeks/';
		var found:Array<String> = [];

		if (sys.FileSystem.exists(path)) {
			var files = sys.FileSystem.readDirectory(path);
			for (f in files) {
				if (f.toLowerCase().indexOf(".json") != -1) {
					found.push(f);
				}
			}
		}
		
		if (found.length > 0) {
			weekFilesListText.text = found.join("\n");
		} else {
			weekFilesListText.text = "(none found)";
		}
	}

	function browseForMenuBackgroundAsset()
	{
		var browser = new openfl.net.FileReference();
		browser.addEventListener(openfl.events.Event.SELECT, function(e) {
			browser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				var activeFolder = installedMods[currentModIndex];
				var modPath:String = 'mods/' + activeFolder + '/';
				var dest:String = modPath + 'images/menubackgrounds/';
				try {
					if (!sys.FileSystem.exists(dest)) sys.FileSystem.createDirectory(dest);
					sys.io.File.saveBytes(dest + browser.name, browser.data);
					
					var nameNoExt:String = browser.name.substr(0, browser.name.length - 4);
					weekStageInput.text = nameNoExt;
					saveFieldsToCurrentTemplateMemory();
					
					var loader = new openfl.display.Loader();
					loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE, function(info) {
						storyModeBg.pixels = cast(loader.content, openfl.display.Bitmap).bitmapData;
						storyModeBg.setGraphicSize(885, 545);
						storyModeBg.updateHitbox();
					});
					loader.loadBytes(browser.data);
					
					flixel.FlxG.sound.play(Paths.sound('confirmMenu'));
				} catch(err:Dynamic) {}
			});
			browser.load();
		});
		browser.browse([new openfl.net.FileFilter("Images (*.png)", "*.png")]);
	}

	function browseForStoryMenuTitleAsset()
	{
		var browser = new openfl.net.FileReference();
		browser.addEventListener(openfl.events.Event.SELECT, function(e) {
			browser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				var activeFolder = installedMods[currentModIndex];
				var modPath:String = 'mods/' + activeFolder + '/';
				var dest:String = modPath + 'images/storymenu/';
				try {
					if (!sys.FileSystem.exists(dest)) sys.FileSystem.createDirectory(dest);
					sys.io.File.saveBytes(dest + browser.name, browser.data);
					
					var nameNoExt:String = browser.name.substr(0, browser.name.length - 4);
					weekDisplayNameInput.text = nameNoExt;
					saveFieldsToCurrentTemplateMemory();
					
					var loader = new openfl.display.Loader();
					loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE, function(info) {
						storyWeekTitle.pixels = cast(loader.content, openfl.display.Bitmap).bitmapData;
						storyWeekTitle.setGraphicSize(260);
						storyWeekTitle.updateHitbox();
					});
					loader.loadBytes(browser.data);
					
					flixel.FlxG.sound.play(Paths.sound('confirmMenu'));
				} catch(err:Dynamic) {}
			});
			browser.load();
		});
		browser.browse([new openfl.net.FileFilter("Images (*.png)", "*.png")]);
	}

	function setupPreviewsTabFields()
	{
		var previewsLabel = new FlxText(FlxG.width - 270, 55, 260, "📷 Mod Screen Previews (Max 3):", 12);
		previewsLabel.color = 0xFFECEFF1;
		previewsGroup.add(previewsLabel);
		spawnNewPreviewButton();
	}

	function spawnNewPreviewButton()
	{
		if (currentPreviewCount >= 3) return;
		var index:Int = currentPreviewCount;

		var pBtn = new FlxButton(FlxG.width - 270, 85 + (index * 38), "Select Preview Image " + (index + 1), function() { openPreviewBrowser(index); });
		pBtn.makeGraphic(260, 24, 0xFF4E5D4E);
		pBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center");
		previewsGroup.add(pBtn);
		previewButtons.push(pBtn);
		currentPreviewCount++;
	}

	function openPreviewBrowser(index:Int)
	{
		var browser = new openfl.net.FileReference();
		browser.browse([new openfl.net.FileFilter("Images (*.png; *.jpg)", "*.png;*.jpg")]);
		browser.addEventListener(openfl.events.Event.SELECT, function(e) {
			browser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				var rawBytes = browser.data;
				var loader = new openfl.display.Loader();
				loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE, function(infoEvent) {
					var bmpData:openfl.display.BitmapData = cast(loader.content, openfl.display.Bitmap).bitmapData;
					if (bmpData.height < 360 || bmpData.width > 2560 || bmpData.height > 1440) {
						flixel.FlxG.sound.play(Paths.sound('cancelMenu')); return;
					}
					var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
					var previewPath:String = 'mods/' + folderName + '/previews/';
					try {
						if (!sys.FileSystem.exists(previewPath)) sys.FileSystem.createDirectory(previewPath);
						
						if (previewFileNamesMemory[index] != null && previewFileNamesMemory[index] != "") {
							var oldFile:String = previewPath + previewFileNamesMemory[index];
							if (sys.FileSystem.exists(oldFile)) sys.FileSystem.deleteFile(oldFile);
						}
						
						sys.io.File.saveBytes(previewPath + browser.name, rawBytes);
						previewFileNamesMemory[index] = browser.name;

						if (previewSpritesOnCard[index] != null) {
							previewSpritesOnCard[index].kill();
							remove(previewSpritesOnCard[index]);
							previewSpritesOnCard[index].destroy();
						}

						var prevSprite = new FlxSprite(65 + (index * 275), 370);
						prevSprite.makeGraphic(250, 140, 0x00000000);

						var scaledBmp = new openfl.display.BitmapData(250, 140, true, 0x00000000);
						var matrix = new openfl.geom.Matrix();
						matrix.scale(250 / bmpData.width, 140 / bmpData.height);
						scaledBmp.draw(bmpData, matrix, null, null, null, true);

						flixel.util.FlxSpriteUtil.drawRoundRect(prevSprite, 0, 0, 250, 140, 15, 15, 0xFFFFFFFF);
						prevSprite.pixels.copyPixels(scaledBmp, scaledBmp.rect, new openfl.geom.Point(0, 0), prevSprite.pixels, new openfl.geom.Point(0, 0), true);
						add(prevSprite);
						previewSpritesOnCard[index] = prevSprite;

						previewButtons[index].label.text = browser.name;
						previewButtons[index].color = 0xFF5D4E4E;
						flixel.FlxG.sound.play(Paths.sound('confirmMenu'));

						if (index + 1 == previewButtons.length && previewButtons.length < 3) spawnNewPreviewButton();
					} catch(err:Dynamic) {}
				});
				loader.loadBytes(rawBytes);
			});
			browser.load();
		});
	}

	function setupCharactersTabFields()
	{
		var startY:Int = 55;

		var l1 = new FlxText(FlxG.width - 270, startY, 260, "Image file name (asset):", 10); l1.color = 0xFFB0BEC5; charsGroup.add(l1);
		charImgInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "characters/BOYFRIEND", 10); charsGroup.add(charImgInput); blockInputBoxes.push(charImgInput);
		startY += 48;

		var l2 = new FlxText(FlxG.width - 270, startY, 260, "Health icon name:", 10); l2.color = 0xFFB0BEC5; charsGroup.add(l2);
		charIconInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "bf", 10); charsGroup.add(charIconInput); blockInputBoxes.push(charIconInput);
		startY += 48;

		var l3 = new FlxText(FlxG.width - 270, startY, 260, "Vocals File Postfix:", 10); l3.color = 0xFFB0BEC5; charsGroup.add(l3);
		charVocalsInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "", 10); charsGroup.add(charVocalsInput); blockInputBoxes.push(charVocalsInput);
		startY += 48;

		var l4 = new FlxText(FlxG.width - 270, startY, 260, "Sing Anim length:", 10); l4.color = 0xFFB0BEC5; charsGroup.add(l4);
		charAnimLenInput = new FlxInputText(FlxG.width - 270, startY + 16, 115, "4", 10); charsGroup.add(charAnimLenInput); blockInputBoxes.push(charAnimLenInput);

		charFlipXBtn = new FlxButton(FlxG.width - 145, startY + 16, "Flip X: OFF", function() {
			isCharFlipped = !isCharFlipped;
			charFlipXBtn.label.text = "Flip X: " + (isCharFlipped ? "ON" : "OFF");
		});
		charFlipXBtn.makeGraphic(135, 20, 0xFF333333); charFlipXBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center"); charsGroup.add(charFlipXBtn);
		startY += 52;

		var l5 = new FlxText(FlxG.width - 270, startY, 260, "Character X / Y Position:", 10); l5.color = 0xFFB0BEC5; charsGroup.add(l5);
		charXInput = new FlxInputText(FlxG.width - 270, startY + 16, 125, "0", 10); charsGroup.add(charXInput); blockInputBoxes.push(charXInput);
		charYInput = new FlxInputText(FlxG.width - 135, startY + 16, 125, "350", 10); charsGroup.add(charYInput); blockInputBoxes.push(charYInput);
		startY += 52;

		var l6 = new FlxText(FlxG.width - 270, startY, 260, "Camera X / Y Offset:", 10); l6.color = 0xFFB0BEC5; charsGroup.add(l6);
		charCamXInput = new FlxInputText(FlxG.width - 270, startY + 16, 125, "0", 10); charsGroup.add(charCamXInput); blockInputBoxes.push(charCamXInput);
		charCamYInput = new FlxInputText(FlxG.width - 135, startY + 16, 125, "0", 10); charsGroup.add(charCamYInput); blockInputBoxes.push(charCamYInput);
		startY += 52;

		var l7 = new FlxText(FlxG.width - 270, startY, 260, "Health Bar Color R / G / B:", 10); l7.color = 0xFFB0BEC5; charsGroup.add(l7);
		charRInput = new FlxInputText(FlxG.width - 270, startY + 16, 80, "49", 10); charsGroup.add(charRInput); blockInputBoxes.push(charRInput);
		charGInput = new FlxInputText(FlxG.width - 180, startY + 16, 80, "176", 10); charsGroup.add(charGInput); blockInputBoxes.push(charGInput);
		charBInput = new FlxInputText(FlxG.width - 90, startY + 16, 80, "209", 10); charsGroup.add(charBInput); blockInputBoxes.push(charBInput);
		startY += 58;

		var saveCharBtn = new FlxButton(FlxG.width - 270, startY, "Import Character JSON", function() { startCharacterImportChain(); });
		saveCharBtn.makeGraphic(260, 24, 0xFF424242); saveCharBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); charsGroup.add(saveCharBtn);
		startY += 30;

		var saveConfigBtn = new FlxButton(FlxG.width - 270, startY, "Save Character Config", function() { saveCharacterConfigData(); });
		saveConfigBtn.makeGraphic(260, 24, 0xFF3A4D3A); saveConfigBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); charsGroup.add(saveConfigBtn);
	}

	function saveCharacterConfigData()
	{
		var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
		var charPath:String = 'mods/' + folderName + '/characters/';
		var charJsonData = {
			animations: [], image: charImgInput.text, healthicon: charIconInput.text, vocals_file: charVocalsInput.text, sing_duration: Std.parseFloat(charAnimLenInput.text),
			flip_x: isCharFlipped, position: [Std.parseFloat(charXInput.text), Std.parseFloat(charYInput.text)], camera_position: [Std.parseFloat(charCamXInput.text), Std.parseFloat(charCamYInput.text)],
			healthbar_colors: [Std.parseInt(charRInput.text), Std.parseInt(charGInput.text), Std.parseInt(charBInput.text)]
		};
		try {
			if (!sys.FileSystem.exists(charPath)) sys.FileSystem.createDirectory(charPath);
			sys.io.File.saveContent(charPath + charIconInput.text.toLowerCase() + '.json', haxe.Json.stringify(charJsonData, null, "\t"));
			flixel.FlxG.sound.play(Paths.sound('confirmMenu')); updateCardCharactersList();
		} catch(e:Dynamic) {}
	}

	function setupDialoguesTabFields()
	{
		var startY:Int = 55;

		var l1 = new FlxText(FlxG.width - 270, startY, 260, "Character Asset ID:", 10); l1.color = 0xFFB0BEC5; dialoguesGroup.add(l1);
		dialCharInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "bf", 10); dialoguesGroup.add(dialCharInput); blockInputBoxes.push(dialCharInput);
		startY += 55;

		var l2 = new FlxText(FlxG.width - 270, startY, 260, "Interval / Speed (ms):", 10); l2.color = 0xFFB0BEC5; dialoguesGroup.add(l2);
		dialSpeedInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "0.05", 10); dialoguesGroup.add(dialSpeedInput); blockInputBoxes.push(dialSpeedInput);
		startY += 55;

		var l3 = new FlxText(FlxG.width - 270, startY, 260, "Sound file name asset:", 10); l3.color = 0xFFB0BEC5; dialoguesGroup.add(l3);
		dialSoundInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "", 10); dialoguesGroup.add(dialSoundInput); blockInputBoxes.push(dialSoundInput);
		startY += 55;

		var l4 = new FlxText(FlxG.width - 270, startY, 260, "Dialogue Text string:", 10); l4.color = 0xFFB0BEC5; dialoguesGroup.add(l4);
		dialTextInput = new FlxInputText(FlxG.width - 270, startY + 16, 260, "coolswag", 10); dialoguesGroup.add(dialTextInput); blockInputBoxes.push(dialTextInput);
		startY += 60;

		dialPixelBtn = new FlxButton(FlxG.width - 270, startY, "Use pixel: OFF", function() {
			isDialPixel = !isDialPixel;
			dialPixelBtn.label.text = "Use pixel: " + (isDialPixel ? "ON" : "OFF");
		});
		dialPixelBtn.makeGraphic(125, 24, 0xFF424242); dialPixelBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center"); dialoguesGroup.add(dialPixelBtn);

		dialAngryBtn = new FlxButton(FlxG.width - 135, startY, "Angry Box: OFF", function() {
			isDialAngry = !isDialAngry;
			dialAngryBtn.label.text = "Angry Box: " + (isDialAngry ? "ON" : "OFF");
		});
		dialAngryBtn.makeGraphic(125, 24, 0xFF424242); dialAngryBtn.label.setFormat(null, 10, 0xFFFFFFFF, "center"); dialoguesGroup.add(dialAngryBtn);
		startY += 55;

		var saveDialBtn = new FlxButton(FlxG.width - 270, startY, "Save Dialogue Line", function() { saveDialogueLineData(); });
		saveDialBtn.makeGraphic(260, 30, 0xFF3A4D3A); saveDialBtn.label.setFormat(null, 11, 0xFFFFFFFF, "center"); dialoguesGroup.add(saveDialBtn);
	}

	function saveDialogueLineData()
	{
		var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
		var dialPath:String = 'mods/' + folderName + '/data/';
		var dialogueJsonData = {
			dialogue: [
				{expression: "talk", text: dialTextInput.text, boxState: (isDialAngry ? "angry" : "normal"), speed: Std.parseFloat(dialSpeedInput.text), character: dialCharInput.text, sound: dialSoundInput.text, pixel: isDialPixel}
			]
		};
		try {
			if (!sys.FileSystem.exists(dialPath)) sys.FileSystem.createDirectory(dialPath);
			sys.io.File.saveContent(dialPath + 'dialogue.json', haxe.Json.stringify(dialogueJsonData, null, "\t"));
			flixel.FlxG.sound.play(Paths.sound('confirmMenu'));
		} catch(e:Dynamic) {}
	}

	function startModFolderImport() {}

	function updateCardCharactersList()
	{
		if (cardCharsText == null || modNameInput == null) return;
		var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
		var charPath:String = 'mods/' + folderName + '/characters/';
		var charList:Array<String> = [];
		if (sys.FileSystem.exists(charPath)) {
			var files = sys.FileSystem.readDirectory(charPath);
			for (file in files) {
				if (file.toLowerCase().indexOf(".json") != -1) charList.push(file.substr(0, file.length - 5));
			}
		}
		cardCharsText.text = (charList.length > 0) ? "characters:\n" + charList.join(", ") : "characters:\n(no characters found)";
	}

	function createNewModStructure(name:String, desc:String) 
	{
		var folderName:String = name.toLowerCase().split(" ").join("-");
		var rootPath:String = 'mods/' + folderName + '/';
		try {
			if (!sys.FileSystem.exists(rootPath)) sys.FileSystem.createDirectory(rootPath);
			var rootFolders = ['characters', 'custom_events', 'custom_notetypes', 'data', 'images', 'menulayouts', 'music', 'previews', 'registry', 'scripts', 'shaders', 'songs', 'stages', 'videos', 'weeks'];
			for (f in rootFolders) if (!sys.FileSystem.exists(rootPath + f + '/')) sys.FileSystem.createDirectory(rootPath + f + '/');
			var imageFolders = ['achievements', 'characters', 'dialogue', 'icons', 'menubackgrounds', 'menucharacters', 'noteSkins', 'noteSplashes', 'storymenu'];
			for (f in imageFolders) if (!sys.FileSystem.exists(rootPath + 'images/' + f + '/')) sys.FileSystem.createDirectory(rootPath + 'images/' + f + '/');
			
			for (input in songInputs) {
				if (input.text != "" && input.text != "new-song" && input.text != "test-song") {
					var track:String = input.text.toLowerCase();
					if (!sys.FileSystem.exists(rootPath + 'songs/' + track + '/')) sys.FileSystem.createDirectory(rootPath + 'songs/' + track + '/');
					if (!sys.FileSystem.exists(rootPath + 'data/' + track + '/')) {
						sys.FileSystem.createDirectory(rootPath + 'data/' + track + '/');
						var dummyChart = {song: {song: track, notes: [], bpm: 100.0, needsVoices: true, player1: "bf", player2: "dad", stage: "stage", speed: 2.2}};
						sys.io.File.saveContent(rootPath + 'data/' + track + '/' + track + '.json', haxe.Json.stringify(dummyChart, null, "\t"));
					}
				}
			}
			var packJson = { name: name, description: desc, restartMod: false };
			sys.io.File.saveContent(rootPath + 'pack.json', haxe.Json.stringify(packJson, null, "\t"));
			flixel.FlxG.sound.play(Paths.sound('confirmMenu')); scanInstalledModsList(); updateCardCharactersList();
		} catch(e:Dynamic) {}
	}

	function startCharacterImportChain() {
		jsonBrowser = new openfl.net.FileReference();
		jsonBrowser.addEventListener(openfl.events.Event.SELECT, function(e) {
			jsonBrowser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				charJsonBytes = jsonBrowser.data; charJsonName = jsonBrowser.name; browseForCharacterPng();
			});
			jsonBrowser.load();
		});
		jsonBrowser.browse([new openfl.net.FileFilter("JSON", "*.json")]);
	}

	function browseForCharacterPng() {
		pngBrowser = new openfl.net.FileReference();
		pngBrowser.addEventListener(openfl.events.Event.SELECT, function(e) {
			pngBrowser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				charPngBytes = pngBrowser.data; charPngName = pngBrowser.name; browseForCharacterXml();
			});
			pngBrowser.load();
		});
		pngBrowser.browse([new openfl.net.FileFilter("PNG", "*.png")]);
	}

	function browseForCharacterXml() {
		xmlBrowser = new openfl.net.FileReference();
		xmlBrowser.addEventListener(openfl.events.Event.SELECT, function(e) {
			xmlBrowser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
				var modPath:String = 'mods/' + folderName + '/';
				try {
					var charJsonPath:String = modPath + 'characters/';
					var charAssetPath:String = modPath + 'images/characters/';
					if (!sys.FileSystem.exists(charJsonPath)) sys.FileSystem.createDirectory(charJsonPath);
					if (!sys.FileSystem.exists(charAssetPath)) sys.FileSystem.createDirectory(charAssetPath);
					sys.io.File.saveBytes(charJsonPath + charJsonName, charJsonBytes);
					sys.io.File.saveBytes(charAssetPath + charPngName, charPngBytes);
					sys.io.File.saveBytes(charAssetPath + xmlBrowser.name, xmlBrowser.data);
					flixel.FlxG.sound.play(Paths.sound('confirmMenu')); updateCardCharactersList();
				} catch(err:Dynamic) {}
			});
			xmlBrowser.load();
		});
		xmlBrowser.browse([new openfl.net.FileFilter("XML", "*.xml")]);
	}

	function startModIconImport() {
		iconBrowser = new openfl.net.FileReference();
		iconBrowser.addEventListener(openfl.events.Event.SELECT, function(e) {
			iconBrowser.addEventListener(openfl.events.Event.COMPLETE, function(v) {
				var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
				var modPath:String = 'mods/' + folderName + '/';
				try {
					if (!sys.FileSystem.exists(modPath)) sys.FileSystem.createDirectory(modPath);
					sys.io.File.saveBytes(modPath + 'pack.png', iconBrowser.data);
					var loader = new openfl.display.Loader();
					loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE, function(info) {
						cardIcon.pixels = cast(loader.content, openfl.display.Bitmap).bitmapData;
						cardIcon.setGraphicSize(120, 120); cardIcon.updateHitbox();
					});
					loader.loadBytes(iconBrowser.data);
					flixel.FlxG.sound.play(Paths.sound('confirmMenu'));
				} catch(err:Dynamic) {}
			});
			iconBrowser.load();
		});
		iconBrowser.browse([new openfl.net.FileFilter("PNG Image", "*.png")]);
	}

	function saveWeekConfigData()
	{
		var folderName:String = modNameInput.text.toLowerCase().split(" ").join("-");
		var weekPath:String = 'mods/' + folderName + '/weeks/';
		var songsArray:Array<Dynamic> = [];
		var rawSongs:Array<String> = weekSongsInput.text.split(",");
		for (s in rawSongs) {
			if (s != "") songsArray.push([s, weekCharDadInput.text]);
		}
		var weekJsonData = {
			songs: songsArray,
			weekCharacters: [weekCharDadInput.text, weekCharBfInput.text, weekCharGfInput.text],
			weekBackground: weekStageInput.text,
			storyName: weekDisplayNameInput.text,
			weekName: weekScoreNameInput.text,
			freeplayColor: 0xFFF9C901,
			startUnlocked: (weekLockUnlockInput.text == "tutorial" || weekLockUnlockInput.text == ""),
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: weekDifficultiesInput.text
		};
		try {
			if (!sys.FileSystem.exists(weekPath)) sys.FileSystem.createDirectory(weekPath);
			sys.io.File.saveContent(weekPath + weekFileNameInput.text.toLowerCase() + '.json', haxe.Json.stringify(weekJsonData, null, "\t"));
			flixel.FlxG.sound.play(Paths.sound('confirmMenu'));
			loadCurrentModWeekFilesList();
		} catch(e:Dynamic) {}
	}

	function updateLiveStoryModePreviewScreen()
	{
		if (currentTab != "Weeks") return;
		var activeFolder = (installedMods.length > 0) ? installedMods[currentModIndex] : "";
		if (activeFolder == "no-mods-found" || activeFolder == "") return;

		var bgAsset = weekStageInput.text;
		var titleAsset = weekDisplayNameInput.text;
		var dadChar = weekCharDadInput.text;
		var bfChar = weekCharBfInput.text;
		var gfChar = weekCharGfInput.text;

		var bgPath:String = 'mods/' + activeFolder + '/images/menubackgrounds/' + bgAsset + '.png';
		if (bgAsset != "" && sys.FileSystem.exists(bgPath) && storyModeBg != null) {
			try {
				storyModeBg.pixels = openfl.display.BitmapData.fromFile(bgPath);
				storyModeBg.setGraphicSize(885, 545);
				storyModeBg.updateHitbox();
			} catch(e:Dynamic) {}
		} else {
			if (storyModeBg != null) storyModeBg.makeGraphic(885, 545, 0xFF311B92);
		}

		var titlePath:String = 'mods/' + activeFolder + '/images/storymenu/' + titleAsset + '.png';
		if (titleAsset != "" && sys.FileSystem.exists(titlePath) && storyWeekTitle != null) {
			try {
				storyWeekTitle.pixels = openfl.display.BitmapData.fromFile(titlePath);
				storyWeekTitle.setGraphicSize(260);
				storyWeekTitle.updateHitbox();
			} catch(e:Dynamic) {}
		} else {
			if (storyWeekTitle != null) storyWeekTitle.makeGraphic(100, 50, 0x00000000);
		}

		if (dadChar != "" && dadChar != "dad" && storyCharDad != null) {
			var dadPath:String = 'mods/' + activeFolder + '/images/menucharacters/' + dadChar + '.png';
			if (sys.FileSystem.exists(dadPath)) {
				try {
					storyCharDad.pixels = openfl.display.BitmapData.fromFile(dadPath);
					storyCharDad.setGraphicSize(120);
					storyCharDad.updateHitbox();
				} catch(e:Dynamic) {}
			} else {
				storyCharDad.makeGraphic(100, 150, 0x00000000);
			}
		}

		if (bfChar != "" && bfChar != "bf" && storyCharBf != null) {
			var bfPath = 'mods/' + activeFolder + '/images/menucharacters/' + bfChar + '.png';
			if (sys.FileSystem.exists(bfPath)) {
				try {
					storyCharBf.pixels = openfl.display.BitmapData.fromFile(bfPath);
					storyCharBf.setGraphicSize(130);
					storyCharBf.updateHitbox();
				} catch(e:Dynamic) {}
			} else {
				storyCharBf.makeGraphic(100, 150, 0x00000000);
			}
		}

		if (gfChar != "" && gfChar != "gf" && storyCharGf != null) {
			var gfPath:String = 'mods/' + activeFolder + '/images/menucharacters/' + gfChar + '.png';
			if (sys.FileSystem.exists(gfPath)) {
				try {
					storyCharGf.pixels = openfl.display.BitmapData.fromFile(gfPath);
					storyCharGf.setGraphicSize(120);
					storyCharGf.updateHitbox();
				} catch(e:Dynamic) {}
			} else {
				storyCharGf.makeGraphic(100, 150, 0x00000000);
			}
		}

		if (storyTracksList != null && weekSongsInput != null) {
			var rawSongs:Array<String> = weekSongsInput.text.split(",");
			var cleanSongs:Array<String> = [];
			for (s in rawSongs) {
				var trimmed = s;
				while (trimmed.length > 0 && trimmed.charCodeAt(0) <= 32) trimmed = trimmed.substr(1);
				while (trimmed.length > 0 && trimmed.charCodeAt(trimmed.length - 1) <= 32) trimmed = trimmed.substr(0, trimmed.length - 1);
				if (trimmed != "") cleanSongs.push(trimmed.toUpperCase());
			}
			storyTracksList.text = cleanSongs.join("\n");
		}

		if (storyDiffsGroup != null && weekDifficultiesInput != null) {
			storyDiffsGroup.clear();
			var diffList:Array<String> = weekDifficultiesInput.text.split(",");
			var startDiffY:Int = 300;
			for (d in diffList) {
				var name = d;
				while (name.length > 0 && name.charCodeAt(0) <= 32) name = name.substr(1);
				while (name.length > 0 && name.charCodeAt(name.length - 1) <= 32) name = name.substr(0, name.length - 1);
				name = name.toLowerCase();
				if (name == "") continue;
				
				var diffSprite = new FlxSprite(580, startDiffY);
				var customPath = 'mods/' + activeFolder + '/images/menudifficulties/' + name + '.png';
				if (sys.FileSystem.exists(customPath)) {
					diffSprite.pixels = openfl.display.BitmapData.fromFile(customPath);
				} else {
					var globalPath = 'assets/images/menudifficulties/' + name + '.png';
					if (sys.FileSystem.exists(globalPath)) diffSprite.pixels = openfl.display.BitmapData.fromFile(globalPath);
					else diffSprite.makeGraphic(120, 30, 0x00000000);
				}
				diffSprite.setGraphicSize(140);
				diffSprite.updateHitbox();
				storyDiffsGroup.add(diffSprite);
				startDiffY += 45;
			}
		}
		updateCardCharactersList();
	}

	function toggleFpsCounter(visible:Bool)
	{
		if (openfl.Lib.current.stage != null) {
			var fpsChild = openfl.Lib.current.stage.getChildAt(0);
			if (fpsChild != null && Type.getClassName(Type.getClass(fpsChild)).indexOf("FPS") != -1) {
				fpsChild.visible = visible;
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (cardNameText != null && modNameInput != null && currentTab == "Mod") {
			cardNameText.text = (modNameInput.text != "") ? modNameInput.text.toUpperCase() : "NAME";
		}
		if (cardDescText != null && modDescInput != null && currentTab == "Mod") {
			cardDescText.text = (modDescInput.text != "") ? modDescInput.text : "Description";
		}

		var typing:Bool = false;
		for (box in blockInputBoxes) {
			if (box != null && box.hasFocus) { typing = true; break; }
		}
		FlxG.keys.enabled = !typing;

		if (!typing) {
			if (FlxG.keys.justPressed.ONE) switchTab("Mod");
			if (FlxG.keys.justPressed.TWO) switchTab("Songs");
			if (FlxG.keys.justPressed.THREE) switchTab("Weeks");
			if (FlxG.keys.justPressed.FOUR) switchTab("Previews");
			if (FlxG.keys.justPressed.FIVE) switchTab("Characters");
			if (FlxG.keys.justPressed.SIX) switchTab("Dialogues");

			if (FlxG.keys.justPressed.ESCAPE) {
				toggleFpsCounter(true);
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
			}
		}

		if (currentTab == "Weeks") {
			saveFieldsToCurrentTemplateMemory();
			updateLiveStoryModePreviewScreen();
		}

		updateInfoPanelDataString();

		for (i in 0...previewSpritesOnCard.length) {
			if (previewSpritesOnCard[i] != null) {
				previewSpritesOnCard[i].visible = (currentTab == "Mod" || currentTab == "Previews");
			}
		}
		
		var modViewVis:Bool = (currentTab == "Mod");
		var previewsVis:Bool = (currentTab == "Previews");
		var weeksViewVis:Bool = (currentTab == "Weeks");
		var charsViewVis:Bool = (currentTab == "Characters");
		var dialsViewVis:Bool = (currentTab == "Dialogues");

		if (cardBg != null) cardBg.visible = (modViewVis || previewsVis || charsViewVis || dialsViewVis);
		if (cardIcon != null) cardIcon.visible = modViewVis;
		if (cardNameText != null) cardNameText.visible = modViewVis;
		if (cardLine1 != null) cardLine1.visible = modViewVis;
		if (cardDescText != null) cardDescText.visible = modViewVis;
		if (cardCharsText != null) cardCharsText.visible = modViewVis;

		if (storyModeBg != null) storyModeBg.visible = weeksViewVis;
		if (storyWeekTitle != null) storyWeekTitle.visible = weeksViewVis;
		if (storyCharDad != null) storyCharDad.visible = weeksViewVis;
		if (storyCharBf != null) storyCharBf.visible = weeksViewVis;
		if (storyCharGf != null) storyCharGf.visible = weeksViewVis;
		if (storyYellowBar != null) storyYellowBar.visible = weeksViewVis;
		if (storyTracksTitle != null) storyTracksTitle.visible = weeksViewVis;
		if (storyTracksList != null) storyTracksList.visible = weeksViewVis;
		if (storyDiffsGroup != null) storyDiffsGroup.visible = weeksViewVis;
	}
}