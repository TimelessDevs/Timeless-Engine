package objects;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import states.PlayState;
import objects.Note;
import objects.StrumNote;

class Strumline extends FlxTypedGroup<flixel.FlxBasic>
{
	public var strums:FlxTypedGroup<StrumNote>;
	public var notes:FlxTypedGroup<Note>;
	
	public var isPlayer:Bool = false;
	public var totalColumns:Int = 4;

	public function new(isPlayer:Bool)
	{
		super();
		this.isPlayer = isPlayer;

		strums = new FlxTypedGroup<StrumNote>();
		notes = new FlxTypedGroup<Note>();

		add(strums);
		add(notes);
	}

	public function generateArrows(strumX:Float, strumY:Float, playerNum:Int):Void
	{
		final isHitboxArrowMode = backend.ClientPrefs.data.extraHints == "ARROWS" && backend.ClientPrefs.data.middleScroll;
		final isPixel:Bool = PlayState.isPixelStage;

		for (i in 0...totalColumns)
		{
			var targetAlpha:Float = 1;
			if (playerNum < 1)
			{
				if (!backend.ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if (backend.ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumX, strumY, i, playerNum);
			babyArrow.downScroll = backend.ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (playerNum == 1)
			{
				if (isHitboxArrowMode)
				{
					var playerArrowScale = isPixel ? 1.2 * PlayState.daPixelZoom : 0.8;
					babyArrow.scale.set(playerArrowScale, playerArrowScale);
					babyArrow.updateHitbox();
					babyArrow.x -= 25;
					if (i > 1) babyArrow.x += 30;
					else babyArrow.x -= 30;
				}
				else if (!backend.ClientPrefs.data.middleScroll)
				{
					babyArrow.x += (FlxG.width - FlxG.initialWidth) / 2;
				}
			}
			else
			{
				if (backend.ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{
						babyArrow.x = FlxG.width - 310 - 168 - 100;
						if (isHitboxArrowMode) babyArrow.x += 40;
					}
					else if (isHitboxArrowMode) babyArrow.x -= 90;
				}
			}

			strums.add(babyArrow);
			babyArrow.playerPosition();
			babyArrow.x += i * Note.swagWidth;
		}
	}

	public function updateStrumlineLogic(elapsed:Float, songSpeed:Float, playbackRate:Float, noteKillOffset:Float):Void
	{
		var pState = PlayState.instance;
		if (pState == null || pState.notes == null || pState.notes.length == 0) return;

		var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;

		pState.notes.forEachAlive(function(daNote:Note)
		{
			if (daNote == null || daNote.mustPress != isPlayer) return;

			var strum:StrumNote = strums.members[daNote.noteData];
			if (strum == null) return;

			daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

			if (!isPlayer && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
			{
				@:privateAccess pState.opponentNoteHit(daNote);
			}

			if (daNote.isSustainNote && strum.sustainReduce)
			{
				daNote.clipToStrumNote(strum);
			}

			if (backend.Conductor.songPosition - daNote.strumTime > noteKillOffset)
			{
				if (isPlayer && !pState.cpuControlled && !daNote.ignoreNote && !pState.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				{
					@:privateAccess pState.noteMiss(daNote);
				}

				daNote.visible = false;
				daNote.active = false;
				@:privateAccess pState.invalidateNote(daNote);
			}
		});
	}
}