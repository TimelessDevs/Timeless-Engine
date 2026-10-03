package states;

import flixel.FlxG;
import backend.MusicBeatState;
import backend.Song;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

//yeah boyf you can play vs lice levels

using StringTools;

class VSliceLoader extends MusicBeatState
{
	public static var targetSongName:String = "";
	public static var targetDifficulty:String = "normal";
	public static var isStoryMode:Bool = false;

	public static function startSongRouting(song:String, diff:String, story:Bool = false):Void
	{
		targetSongName = song;
		targetDifficulty = diff;
		isStoryMode = story;
		
		backend.MusicBeatState.switchState(new states.VSliceLoader());
	}

	override function create()
	{
		super.create();

		var formattedSong:String = backend.Paths.formatToSongPath(targetSongName);
		var formattedDiff:String = backend.Paths.formatToSongPath(targetDifficulty);
		
		var modFolder:String = 'mods/' + backend.Mods.currentModDirectory + '/songs/' + formattedSong + '/';
		var assetFolder:String = 'assets/songs/' + formattedSong + '/';
		var targetFolder:String = FileSystem.exists(modFolder) ? modFolder : assetFolder;

		var psychJsonPath:String = targetFolder + formattedSong + (formattedDiff == "normal" ? "" : "-" + formattedDiff) + ".json";
		var vsliceJsonPath:String = targetFolder + formattedSong + "-chart.json";

		trace("[ROUTER]: Routing check initiated for song: " + formattedSong + " (" + formattedDiff + ")");

		if (FileSystem.exists(vsliceJsonPath)) 
		{
			trace("[ROUTER]: Found native V-Slice file structure: " + vsliceJsonPath);
			launchV4EnginePipeline(vsliceJsonPath, targetFolder + formattedSong + "-metadata.json");
			return;
		}

		if (FileSystem.exists(psychJsonPath)) 
		{
			try {
				var rawJson:String = File.getContent(psychJsonPath).trim();
				var parsed:Dynamic = Json.parse(rawJson);

				if (parsed != null && Reflect.hasField(parsed, "song")) {
					trace("[ROUTER]: Valid Psych Engine format verified via internal fields structure.");
					launchLegacyEnginePipeline(psychJsonPath);
					return;
				} else if (parsed != null && (Reflect.hasField(parsed, "scrollSpeed") || Reflect.hasField(parsed, "notes"))) {
					trace("[ROUTER]: V-Slice format identified inside a standard named JSON file!");
					launchV4EnginePipeline(psychJsonPath, targetFolder + formattedSong + "-metadata.json");
					return;
				}
			} catch(e:Dynamic) {
				trace("[ROUTER CRASH]: JSON parsing error during routing scan: " + Std.string(e));
			}
		}

		trace("[ROUTER WARNING]: No clear format match found. Falling back to default legacy state engine.");
		launchLegacyEnginePipeline(psychJsonPath);
	}

	private function launchLegacyEnginePipeline(jsonPath:String):Void
	{
		PlayState.storyDifficulty = targetDifficulty;
		PlayState.isStoryMode = isStoryMode;
		
		var formattedSong:String = backend.Paths.formatToSongPath(targetSongName);
		PlayState.SONG = Song.loadFromJson(formattedSong + (targetDifficulty == "normal" ? "" : "-" + targetDifficulty), formattedSong);
		
		backend.MusicBeatState.switchState(new states.PlayState());
	}

	private function launchV4EnginePipeline(chartJsonPath:String, metadataJsonPath:String):Void
	{
		PlayState.storyDifficulty = targetDifficulty;
		PlayState.isStoryMode = isStoryMode;

		try {
			var rawChartData:String = File.getContent(chartJsonPath);
			var rawMetadata:String = FileSystem.exists(metadataJsonPath) ? File.getContent(metadataJsonPath) : "";
			
			trace("[ROUTER LOGIC]: V-Slice initialization block ready. Forwarding engine state context.");
			backend.MusicBeatState.switchState(new states.PlayState());
		} catch(e:Dynamic) {
			trace("[ROUTER CRASH]: Failed to initialize V-Slice routing bridge: " + Std.string(e));
			launchLegacyEnginePipeline(chartJsonPath);
		}
	}

	public static function detectModArchitectureFormat(modName:String):String
	{
		var cleanModName:String = StringTools.trim(modName);
		var modDirectoryPath:String = 'mods/' + cleanModName + '/';
		
		if (!sys.FileSystem.exists(modDirectoryPath)) return "Legacy/Unknown";

		if (sys.FileSystem.exists(modDirectoryPath + "metadata.json") || sys.FileSystem.exists(modDirectoryPath + "pack.json")) {
			return "V-Slice";
		}

		var songsPath:String = modDirectoryPath + "songs/";
		if (sys.FileSystem.exists(songsPath) && sys.FileSystem.isDirectory(songsPath)) {
			try {
				for (songFolder in sys.FileSystem.readDirectory(songsPath)) {
					var fullSongPath:String = songsPath + songFolder + "/";
					if (sys.FileSystem.isDirectory(fullSongPath)) {
						for (file in sys.FileSystem.readDirectory(fullSongPath)) {
							if (file.endsWith("-metadata.json") || file.endsWith("-chart.json")) {
								return "V-Slice";
							}
						}
					}
				}
			} catch(e:Dynamic) {
				trace("[ROUTER RECON CRASH]: Failed to map folder structures: " + Std.string(e));
			}
		}

		return "Psych Engine";
	}
}