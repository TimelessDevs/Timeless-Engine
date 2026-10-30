package states.editors.content;

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
	public var gen:ShaderGen->ShaderLayer->String;
	public var taps:ShaderLayer->Int;

	public function new(id:String, name:String, cat:String, phase:Int, desc:String, params:Array<ParamDef>, gen:ShaderGen->ShaderLayer->String,
			?taps:ShaderLayer->Int)
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

class ShaderLayer
{
	public var uid:Int;
	public var type:String;
	public var enabled:Bool = true;
	public var opacity:Float = 1.0;
	public var vals:Dynamic;

	// mask
	public var maskMode:Int = 0;
	public var mask:Array<Float>;
	public var maskColor:String = '00FF00';
	public var maskInvert:Bool = false;

	// animation thing
	public var animParam:String = '';
	public var animMode:Int = 0;
	public var animSpeed:Float = 1.0;
	public var animAmt:Float = 0.5;
	public var animPhase:Float = 0.0;

	public function new(type:String, uid:Int)
	{
		this.type = type;
		this.uid = uid;
		vals = {};
		mask = [0.5, 0.5, 0.4, 0.2];
		fillDefaults();
	}

	public function def():EffectDef
		return ShaderEffectLib.get(type);

	public function fillDefaults()
	{
		var d = def();
		if (d == null)
			return;
		for (p in d.params)
			if (!Reflect.hasField(vals, p.id))
				Reflect.setField(vals, p.id, p.def);
	}

	public function resetParams()
	{
		var d = def();
		if (d == null)
			return;
		for (p in d.params)
			Reflect.setField(vals, p.id, p.def);
		opacity = 1.0;
	}

	public static function toFloat(v:Dynamic, d:Float = 0):Float
	{
		if (v == null)
			return d;
		var f = Std.parseFloat(Std.string(v));
		return Math.isNaN(f) ? d : f;
	}

	public function getF(id:String):Float
	{
		if (id == 'opacity')
			return opacity;
		var v:Dynamic = Reflect.field(vals, id);
		if (v == null)
		{
			var d = def();
			var p = d != null ? d.param(id) : null;
			return (p != null) ? toFloat(p.def) : 0;
		}
		return toFloat(v);
	}

	public function getI(id:String):Int
		return Std.int(getF(id));

	public function getB(id:String):Bool
	{
		var v:Dynamic = Reflect.field(vals, id);
		return v == true;
	}

	public function getS(id:String):String
	{
		var v:Dynamic = Reflect.field(vals, id);
		return v == null ? '' : Std.string(v);
	}

	public function setV(id:String, v:Dynamic)
		Reflect.setField(vals, id, v);

	public function toJson():Dynamic
	{
		return {
			uid: uid,
			type: type,
			enabled: enabled,
			opacity: opacity,
			vals: vals,
			maskMode: maskMode,
			mask: mask.copy(),
			maskColor: maskColor,
			maskInvert: maskInvert,
			animParam: animParam,
			animMode: animMode,
			animSpeed: animSpeed,
			animAmt: animAmt,
			animPhase: animPhase
		};
	}

	public static function fromJson(o:Dynamic):ShaderLayer
	{
		if (o == null || ShaderEffectLib.get(o.type) == null)
			return null;
		var l = new ShaderLayer(o.type, Std.int(toFloat(o.uid, 1)));
		l.enabled = (o.enabled != false);
		l.opacity = toFloat(o.opacity, 1.0);
		if (o.vals != null)
			for (f in Reflect.fields(o.vals))
				Reflect.setField(l.vals, f, Reflect.field(o.vals, f));
		l.maskMode = Std.int(toFloat(o.maskMode, 0));
		if (o.mask != null)
		{
			var arr:Array<Dynamic> = o.mask;
			for (i in 0...Std.int(Math.min(arr.length, 4)))
				l.mask[i] = toFloat(arr[i], 0);
		}
		if (o.maskColor != null)
			l.maskColor = Std.string(o.maskColor);
		l.maskInvert = (o.maskInvert == true);
		l.animParam = o.animParam != null ? Std.string(o.animParam) : '';
		l.animMode = Std.int(toFloat(o.animMode, 0));
		l.animSpeed = toFloat(o.animSpeed, 1.0);
		l.animAmt = toFloat(o.animAmt, 0.5);
		l.animPhase = toFloat(o.animPhase, 0.0);
		return l;
	}

	public function clone(newUid:Int):ShaderLayer
	{
		var l = fromJson(Json.parse(Json.stringify(toJson())));
		l.uid = newUid;
		return l;
	}
}

class ShaderProject
{
	public var layers:Array<ShaderLayer> = [];
	public var nextUid:Int = 1;

	public var shaderName:String = 'my_shader';
	public var luaName:String = 'my_shader';
	public var modFolder:String = '';
	public var targets:Array<String> = ['dad', 'boyfriend'];
	public var customTargets:String = '';
	public var bake:Bool = false;
	public var atlasAware:Bool = true;

	public function new() {}

	public function addLayer(type:String, at:Int = -1):ShaderLayer
	{
		var l = new ShaderLayer(type, nextUid++);
		if (at < 0 || at >= layers.length)
			layers.push(l);
		else
			layers.insert(at, l);
		return l;
	}

	public function toJson():Dynamic
	{
		return {
			format: 'shader_editor_v1',
			shaderName: shaderName,
			luaName: luaName,
			modFolder: modFolder,
			targets: targets.copy(),
			customTargets: customTargets,
			bake: bake,
			atlasAware: atlasAware,
			layers: [for (l in layers) l.toJson()]
		};
	}

	public function snapshot():String
		return Json.stringify(toJson());

	public static function fromString(s:String):ShaderProject
		return fromJson(Json.parse(s));

	public static function fromJson(o:Dynamic):ShaderProject
	{
		var p = new ShaderProject();
		if (o == null)
			return p;
		if (o.shaderName != null)
			p.shaderName = Std.string(o.shaderName);
		if (o.luaName != null)
			p.luaName = Std.string(o.luaName);
		if (o.modFolder != null)
			p.modFolder = Std.string(o.modFolder);
		if (o.targets != null)
		{
			var t:Array<Dynamic> = o.targets;
			p.targets = [for (x in t) Std.string(x)];
		}
		if (o.customTargets != null)
			p.customTargets = Std.string(o.customTargets);
		p.bake = (o.bake == true);
		p.atlasAware = (o.atlasAware != false);
		if (o.layers != null)
		{
			var arr:Array<Dynamic> = o.layers;
			var maxUid = 0;
			for (lo in arr)
			{
				var l = ShaderLayer.fromJson(lo);
				if (l == null)
					continue;
				p.layers.push(l);
				if (l.uid > maxUid)
					maxUid = l.uid;
			}
			p.nextUid = maxUid + 1;
		}
		return p;
	}
}
