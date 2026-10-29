package states.editors.shader;

import haxe.Json;
import states.editors.shader.ShaderConst;
import states.editors.shader.ShaderEffectLib;
import states.editors.shader.ShaderGen;

using StringTools;

class ShaderLayer
{
	public var uid:Int;
	public var type:String;
	public var enabled:Bool = true;
	public var opacity:Float = 1.0;
	public var vals:Dynamic;

	public var maskMode:Int = 0;
	public var mask:Array<Float>;
	public var maskColor:String = '00FF00';
	public var maskInvert:Bool = false;

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