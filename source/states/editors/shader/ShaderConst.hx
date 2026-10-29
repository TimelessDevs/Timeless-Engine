package states.editors.shader;

import haxe.Json;

using StringTools;

class ShaderConst
{
	public static inline var UV:Int = 0;
	public static inline var SMP:Int = 1;
	public static inline var COL:Int = 2;

	public static final PHASE_TAGS:Array<String> = ['UV', 'SMP', 'COL'];
	public static final PHASE_NAMES:Array<String> = ['UV warp (always runs first)', 'Sampling (chained, runs after UV)', 'Colour (runs in list order)'];

	public static final BLEND_NAMES:Array<String> = [
		'Normal', 'Add', 'Multiply', 'Screen', 'Overlay', 'Soft Light', 'Hard Light', 'Lighten', 'Darken', 'Difference', 'Color Dodge'
	];
	public static final BLEND_FUNCS:Array<String> = [
		'normal', 'add', 'multiply', 'screen', 'overlay', 'softlight', 'hardlight', 'lighten', 'darken', 'difference', 'dodge'
	];

	public static final ANIM_NAMES:Array<String> = ['None', 'Sine', 'Triangle', 'Saw', 'Square', 'Flicker', 'Beat'];

	public static final MASK_NAMES:Array<String> = ['None', 'Radial', 'Linear', 'Luma', 'Noise', 'Color Key', 'Alpha'];
	public static final MASK_LABELS:Array<Array<String>> = [
		[],
		['Center X', 'Center Y', 'Radius', 'Softness'],
		['Angle', 'Position', 'Softness'],
		['Low', 'High'],
		['Scale', 'Threshold', 'Softness', 'Speed'],
		['Tolerance', 'Softness'],
		['Low', 'High']
	];
	public static final MASK_DEFAULTS:Array<Array<Float>> = [
		[],
		[0.5, 0.5, 0.4, 0.2],
		[0.5, 0.5, 0.4, 0.2],
		[0.0, 0.5, 0.2, 0.0],
		[0.3, 0.7, 0.0, 0.0],
		[5.0, 0.5, 0.1, 0.0],
		[0.3, 0.1, 0.0, 0.0],
		[0.0, 1.0, 0.0, 0.0]
	];

	public static final TARGET_IDS:Array<String> = ['dad', 'boyfriend', 'gf', 'opstrums', 'plstrums', 'opnotes', 'plnotes', 'icons'];
	public static final TARGET_NAMES:Array<String> = [
		'Opponent (dad)', 'Player (boyfriend)', 'Girlfriend (gf)', 'Opponent strums', 'Player strums', 'Opponent notes', 'Player notes', 'Health icons'
	];

	public static final MAX_LAYERS:Int = 16;
}

class ParamDef
{
	public var id:String;
	public var label:String;
	public var kind:String;
	public var def:Dynamic;
	public var min:Float = 0;
	public var max:Float = 1;
	public var step:Float = 0.1;
	public var dec:Int = 2;
	public var options:Array<String> = null;
	public var cols:Int = 1;

	public function new(id:String, label:String, kind:String, def:Dynamic)
	{
		this.id = id;
		this.label = label;
		this.kind = kind;
		this.def = def;
	}
}

class EffectDef
{
	public var id:String;
	public var name:String;
	public var cat:String;
	public var phase:Int;
	public var desc:String;
	public var params:Array<ParamDef>;
	public var gen:states.editors.shader.ShaderGen->states.editors.shader.ShaderLayer->String;
	public var taps:states.editors.shader.ShaderLayer->Int;

	public function new(id:String, name:String, cat:String, phase:Int, desc:String, params:Array<ParamDef>, gen:states.editors.shader.ShaderGen->states.editors.shader.ShaderLayer->String, ?taps:states.editors.shader.ShaderLayer->Int)
	{
		this.id = id;
		this.name = name;
		this.cat = cat;
		this.phase = phase;
		this.desc = desc;
		this.params = params;
		this.gen = gen;
		this.taps = taps;
	}

	public function param(pid:String):ParamDef
	{
		for (p in params)
			if (p.id == pid)
				return p;
		return null;
	}
}