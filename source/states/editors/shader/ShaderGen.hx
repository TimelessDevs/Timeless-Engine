package states.editors.content;

using StringTools;

typedef UniformEntry =
{
	var name:String;
	var type:String;
	var v:Dynamic;
	var desc:String;
}

typedef GenResult =
{
	var glsl:String;
	var uniforms:Array<UniformEntry>;
	var usesTime:Bool;
	var usesBeat:Bool;
	var usesFrame:Bool;
	var warnings:Array<String>;
	var samples:Int;
	var layerCount:Int;
	var lines:Int;
}

private typedef Helper =
{
	var token:String;
	var code:String;
}

class ShaderGen
{
	public var proj:ShaderProject;
	public var bake:Bool;
	public var uniforms:Array<UniformEntry> = [];
	public var warnings:Array<String> = [];
	public var curSmp:Int = 0;
	public var finalSmp:Int = 0;

	var declared:Map<String, Bool> = new Map();
	var decls:Array<String> = [];

	public function new(proj:ShaderProject, bake:Bool)
	{
		this.proj = proj;
		this.bake = bake;
	}

	public static function r5(v:Float):Float
		return Math.round(v * 100000) / 100000;

	public static function fmt(v:Float):String
	{
		if (Math.isNaN(v) || !Math.isFinite(v))
			v = 0;
		var s = Std.string(r5(v));
		if (s.indexOf('.') < 0 && s.indexOf('e') < 0)
			s += '.0';
		return (v < 0) ? '(' + s + ')' : s;
	}

	public static function parseHex(h:String):Array<Float>
	{
		h = (h == null) ? '' : h.trim();
		if (h.startsWith('#'))
			h = h.substr(1);
		if (h.length != 6 || !~/^[0-9a-fA-F]{6}$/.match(h))
			h = 'FFFFFF';
		var n:Int = Std.parseInt('0x' + h);
		return [((n >> 16) & 0xFF) / 255.0, ((n >> 8) & 0xFF) / 255.0, (n & 0xFF) / 255.0];
	}

	public function uname(L:ShaderLayer, id:String):String
		return 'u_L' + L.uid + '_' + id;

	function reg(name:String, type:String, v:Dynamic, desc:String)
	{
		if (declared.exists(name))
			return;
		declared.set(name, true);
		decls.push('uniform ' + type + ' ' + name + ';');
		uniforms.push({
			name: name,
			type: type,
			v: v,
			desc: desc
		});
	}

	function descOf(L:ShaderLayer, id:String):String
	{
		var d = L.def();
		var pd = (d != null) ? d.param(id) : null;
		return 'Layer ' + L.uid + ' (' + (d != null ? d.name : '?') + '): ' + (pd != null ? pd.label : id);
	}

	public function uf(L:ShaderLayer, id:String, v:Float):String
	{
		if (bake)
			return fmt(v);
		var n = uname(L, id);
		reg(n, 'float', v, descOf(L, id));
		return n;
	}

	public function uc(L:ShaderLayer, id:String, hex:String):String
	{
		var rgb = parseHex(hex);
		if (bake)
			return 'vec3(' + fmt(rgb[0]) + ', ' + fmt(rgb[1]) + ', ' + fmt(rgb[2]) + ')';
		var n = uname(L, id);
		reg(n, 'vec3', [r5(rgb[0]), r5(rgb[1]), r5(rgb[2])], descOf(L, id));
		return n;
	}

	public function p(L:ShaderLayer, id:String):String
	{
		var base = uf(L, id, L.getF(id));
		if (L.animMode > 0 && L.animParam == id)
			return '(' + base + ' + ' + uf(L, 'aamt', L.animAmt) + ' * ' + waveExpr(L) + ')';
		return base;
	}

	public function c(L:ShaderLayer, id:String):String
		return uc(L, id, L.getS(id));

	public function e(L:ShaderLayer, id:String):Int
		return L.getI(id);

	public function b(L:ShaderLayer, id:String):Bool
		return L.getB(id);

	public function tex(L:ShaderLayer, id:String):String
	{
		var path = L.getS(id).trim();
		if (path == '')
		{
			warnings.push('Layer ' + L.uid + ': no image set, the layer was skipped.');
			return null;
		}
		var n = uname(L, id);
		reg(n, 'sampler2D', path, descOf(L, id) + ' (image)');
		return n;
	}

	public function bl(L:ShaderLayer, id:String, base:String, top:String):String
		return 'fx_bl_' + ShaderConst.BLEND_FUNCS[Std.int(Math.max(0, Math.min(L.getI(id), ShaderConst.BLEND_FUNCS.length - 1)))] + '(' + base + ', ' + top + ')';

	public function sp():String
		return 'fx_s' + (curSmp - 1);

	public function src():String
		return 'fx_s' + finalSmp;

	function waveExpr(L:ShaderLayer):String
	{
		if (L.animMode == 6)
			return 'u_beat';
		var t = '(u_time * ' + uf(L, 'aspd', L.animSpeed) + ' + ' + uf(L, 'aph', L.animPhase) + ')';
		return switch (L.animMode)
		{
			case 1: 'sin(' + t + ' * 6.2831853)';
			case 2: '(abs(fract(' + t + ') * 2.0 - 1.0) * 2.0 - 1.0)';
			case 3: '(fract(' + t + ') * 2.0 - 1.0)';
			case 4: '(step(0.5, fract(' + t + ')) * 2.0 - 1.0)';
			case 5: '(fx_hash(vec2(floor(' + t + ' * 8.0), 3.7)) * 2.0 - 1.0)';
			default: '0.0';
		}
	}

	function maskExpr(L:ShaderLayer, loc:String, rgb:String, a:String):String
	{
		if (L.maskMode <= 0)
			return null;
		var m = function(i:Int):String return uf(L, 'm' + i, L.mask[i - 1]);
		var ex:String = switch (L.maskMode)
		{
			case 1: '(1.0 - smoothstep(' + m(3) + ' - max(' + m(4) + ', 0.001), ' + m(3) + ', length(' + loc + ' - vec2(' + m(1) + ', ' + m(2) + '))))';
			case 2: 'smoothstep(' + m(2) + ' - max(' + m(3) + ', 0.001), ' + m(2) + ' + max(' + m(3) + ', 0.001), dot(' + loc + ' - 0.5, vec2(cos(radians(' + m(1)
					+ ')), sin(radians(' + m(1) + ')))) + 0.5)';
			case 3: 'smoothstep(' + m(1) + ', max(' + m(2) + ', ' + m(1) + ' + 0.001), dot(' + rgb + ', vec3(0.299, 0.587, 0.114)))';
			case 4: 'smoothstep(' + m(2) + ' - max(' + m(3) + ', 0.001), ' + m(2) + ' + max(' + m(3) + ', 0.001), fx_noise(' + loc + ' * ' + m(1) + ' + vec2(u_time * '
					+ m(4) + ')))';
			case 5: '(1.0 - smoothstep(' + m(1) + ', ' + m(1) + ' + max(' + m(2) + ', 0.001), distance(' + rgb + ', ' + uc(L, 'mcol', L.maskColor) + ')))';
			case 6: 'smoothstep(' + m(1) + ', max(' + m(2) + ', ' + m(1) + ' + 0.001), ' + a + ')';
			default: null;
		}
		if (ex == null)
			return null;
		return L.maskInvert ? '(1.0 - ' + ex + ')' : ex;
	}

	function kExpr(L:ShaderLayer, loc:String, rgb:String, a:String):String
	{
		var op = p(L, 'opacity');
		var mk = maskExpr(L, loc, rgb, a);
		return (mk == null) ? op : op + ' * ' + mk;
	}

	static function indent(code:String, n:Int):String
	{
		var pad = StringTools.lpad('', ' ', n);
		var out = new StringBuf();
		for (line in code.split('\n'))
		{
			if (line.trim() == '')
				continue;
			out.add(pad + line.trim() + '\n');
		}
		return out.toString();
	}

	static function label(L:ShaderLayer):String
	{
		var d = L.def();
		return 'L' + L.uid + ' ' + ((d != null) ? d.name : L.type);
	}

	static final HELPERS:Array<Helper> = [
		{
			token: 'fx_hash(',
			code: 'float fx_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
	p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
'
		},
		{
			token: 'fx_noise(',
			code: 'float fx_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fx_hash(i);
	float b = fx_hash(i + vec2(1.0, 0.0));
	float c = fx_hash(i + vec2(0.0, 1.0));
	float d = fx_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
'
		},
		{
			token: 'fx_fbm(',
			code: 'float fx_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * fx_noise(p);
		p = p * 2.0 + vec2(17.0, 31.0);
		a *= 0.5;
	}
	return v / 0.9375;
}
'
		},
		{
			token: 'fx_hue(',
			code: 'vec3 fx_hue(vec3 c, float deg) {
	float a = radians(deg);
	float cs = cos(a);
	float sn = sin(a);
	return vec3(
		dot(c, vec3(0.213 + cs * 0.787 - sn * 0.213, 0.715 - cs * 0.715 - sn * 0.715, 0.072 - cs * 0.072 + sn * 0.928)),
		dot(c, vec3(0.213 - cs * 0.213 + sn * 0.143, 0.715 + cs * 0.285 + sn * 0.140, 0.072 - cs * 0.072 - sn * 0.283)),
		dot(c, vec3(0.213 - cs * 0.213 - sn * 0.787, 0.715 - cs * 0.715 + sn * 0.715, 0.072 + cs * 0.928 + sn * 0.072)));
}
'
		},
		{
			token: 'fx_hsv(',
			code: 'vec3 fx_hsv(float h, float s, float v) {
	vec3 k = clamp(abs(mod(vec3(h * 6.0) + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return v * mix(vec3(1.0), k, s);
}
'
		},
		{
			token: 'fx_bayer2(',
			code: 'float fx_bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x / 2.0 + a.y * a.y * 0.75);
}
'
		},
		{
			token: 'fx_bayer4(',
			code: 'float fx_bayer4(vec2 a) {
	return fx_bayer2(0.5 * a) * 0.25 + fx_bayer2(a);
}
'
		},
		{
			token: 'fx_ht(',
			code: 'float fx_ht(vec2 pix, float size, float ang, float dark, float soft) {
	float ca = cos(radians(ang));
	float sa = sin(radians(ang));
	vec2 r = vec2(ca * pix.x + sa * pix.y, -sa * pix.x + ca * pix.y) / max(size, 1.0);
	vec2 cell = fract(r) - 0.5;
	float rad = sqrt(clamp(dark, 0.0, 1.0)) * 0.7071;
	return 1.0 - smoothstep(rad - soft, rad + soft, length(cell));
}
'
		},
		{
			token: 'fx_under(',
			code: 'void fx_under(vec3 col, float ca) {
	ca = clamp(ca, 0.0, 1.0);
	float na = fx_a + ca * (1.0 - fx_a);
	if (na > 0.0001) fx_rgb = (fx_rgb * fx_a + col * ca * (1.0 - fx_a)) / na;
	fx_a = na;
}
'
		}
	];

	static final BLENDS:Array<Helper> = [
		{token: 'fx_bl_normal(', code: 'vec3 fx_bl_normal(vec3 b, vec3 t) { return t; }\n'},
		{token: 'fx_bl_add(', code: 'vec3 fx_bl_add(vec3 b, vec3 t) { return b + t; }\n'},
		{token: 'fx_bl_multiply(', code: 'vec3 fx_bl_multiply(vec3 b, vec3 t) { return b * t; }\n'},
		{token: 'fx_bl_screen(', code: 'vec3 fx_bl_screen(vec3 b, vec3 t) { return 1.0 - (1.0 - b) * (1.0 - t); }\n'},
		{
			token: 'fx_bl_overlay(',
			code: 'vec3 fx_bl_overlay(vec3 b, vec3 t) { return mix(2.0 * b * t, 1.0 - 2.0 * (1.0 - b) * (1.0 - t), step(0.5, b)); }\n'
		},
		{
			token: 'fx_bl_softlight(',
			code: 'vec3 fx_bl_softlight(vec3 b, vec3 t) { vec3 bb = max(b, vec3(0.0)); return mix(2.0 * bb * t + bb * bb * (1.0 - 2.0 * t), sqrt(bb) * (2.0 * t - 1.0) + 2.0 * bb * (1.0 - t), step(0.5, t)); }\n'
		},
		{
			token: 'fx_bl_hardlight(',
			code: 'vec3 fx_bl_hardlight(vec3 b, vec3 t) { return mix(2.0 * b * t, 1.0 - 2.0 * (1.0 - b) * (1.0 - t), step(0.5, t)); }\n'
		},
		{token: 'fx_bl_lighten(', code: 'vec3 fx_bl_lighten(vec3 b, vec3 t) { return max(b, t); }\n'},
		{token: 'fx_bl_darken(', code: 'vec3 fx_bl_darken(vec3 b, vec3 t) { return min(b, t); }\n'},
		{token: 'fx_bl_difference(', code: 'vec3 fx_bl_difference(vec3 b, vec3 t) { return abs(b - t); }\n'},
		{token: 'fx_bl_dodge(', code: 'vec3 fx_bl_dodge(vec3 b, vec3 t) { return b / max(vec3(1.0) - t, vec3(0.001)); }\n'}
	];



	public static function build(proj:ShaderProject, bake:Bool):GenResult
		return new ShaderGen(proj, bake).run();

	function run():GenResult
	{
		var uvL:Array<ShaderLayer> = [];
		var smpL:Array<ShaderLayer> = [];
		var colL:Array<ShaderLayer> = [];
		var count = 0;
		for (l in proj.layers)
		{
			var d = l.def();
			if (!l.enabled || d == null)
				continue;
			count++;
			switch (d.phase)
			{
				case ShaderConst.UV: uvL.push(l);
				case ShaderConst.SMP: smpL.push(l);
				default: colL.push(l);
			}
		}


		var funcs = new StringBuf();
		var kDecl = new StringBuf();
		var kAssign = new StringBuf();
		var n = 0;
		var chain = 1;
		for (L in smpL)
		{
			curSmp = n + 1;
			var code = L.def().gen(this, L);
			if (code == null || code == '')
				continue;
			n++;
			funcs.add('// ' + label(L) + '\n');
			funcs.add('vec4 fx_s' + n + '(vec2 p) {\n');
			funcs.add('\tvec4 prev = fx_s' + (n - 1) + '(p);\n');
			funcs.add('\tvec4 res = prev;\n');
			funcs.add(indent(code, 4));
			funcs.add('\treturn mix(prev, res, fx_k' + n + ');\n}\n\n');
			kDecl.add('float fx_k' + n + ';\n');
			kAssign.add('\tfx_k' + n + ' = ' + kExpr(L, 'loc', 'fx_s0(uv).rgb', 'fx_s0(uv).a') + ';\n');
			var t = (L.def().taps != null) ? L.def().taps(L) : 2;
			chain *= (t + 1);
		}
		finalSmp = n;


		var uvCode = new StringBuf();
		for (L in uvL)
		{
			var code = L.def().gen(this, L);
			if (code == null || code == '')
				continue;
			uvCode.add('\t{ // ' + label(L) + '\n');
			uvCode.add('\t\tfloat k = ' + kExpr(L, 'l', 'fx_s0(fx_fromLoc(l)).rgb', 'fx_s0(fx_fromLoc(l)).a') + ';\n');
			uvCode.add('\t\tvec2 n = l;\n');
			uvCode.add(indent(code, 8));
			uvCode.add('\t\tl = mix(l, n, k);\n\t}\n');
		}


		var colCode = new StringBuf();
		var extraTaps = 0;
		for (L in colL)
		{
			var code = L.def().gen(this, L);
			if (code == null || code == '')
				continue;
			colCode.add('\t{ // ' + label(L) + '\n');
			colCode.add('\t\tfloat k = ' + kExpr(L, 'loc', 'fx_rgb', 'fx_a') + ';\n');
			colCode.add(indent(code, 8));
			colCode.add('\t}\n');
			if (L.def().taps != null)
				extraTaps += L.def().taps(L);
		}


		var main = new StringBuf();
		main.add('void main() {\n');
		main.add('\tvec2 l = fx_toLoc(openfl_TextureCoordv.xy);\n');
		main.add(uvCode.toString());
		main.add('\tvec2 uv = fx_fromLoc(l);\n');
		main.add('\tvec2 loc = l;\n');
		main.add(kAssign.toString());
		main.add('\tvec4 c = fx_s' + n + '(uv);\n');
		main.add('\tfx_a = c.a;\n');
		main.add('\tfx_rgb = (c.a > 0.0001) ? c.rgb / c.a : vec3(0.0);\n');
		main.add(colCode.toString());
		main.add('\tfx_a = clamp(fx_a, 0.0, 1.0);\n');
		main.add('\tgl_FragColor = vec4(clamp(fx_rgb, 0.0, 1.0) * fx_a, fx_a);\n');
		main.add('}\n');

		var body = funcs.toString() + main.toString();


		var scan = body;
		var used:Array<String> = [];
		var changed = true;
		var all:Array<Helper> = HELPERS.concat(BLENDS);
		while (changed)
		{
			changed = false;
			for (h in all)
			{
				if (used.indexOf(h.token) >= 0)
					continue;
				if (scan.indexOf(h.token) >= 0)
				{
					used.push(h.token);
					scan += h.code;
					changed = true;
				}
			}
		}
		var helperCode = new StringBuf();
		for (h in all)
			if (used.indexOf(h.token) >= 0)
				helperCode.add(h.code + '\n');

		var usesTime = scan.indexOf('u_time') >= 0;
		var usesBeat = scan.indexOf('u_beat') >= 0;
		var usesFrame = proj.atlasAware;


		var o = new StringBuf();
		o.add('#pragma header\n\n');
		o.add('// Generated by the T-Shader Editor - ' + count + ' layer(s)\n');
		o.add('// u_time: seconds, u_beat: 1 on a beat -> 0, u_frame: atlas frame rect (x, y, w, h) in pixels\n\n');
		if (usesTime)
			o.add('uniform float u_time;\n');
		if (usesBeat)
			o.add('uniform float u_beat;\n');
		if (usesFrame)
			o.add('uniform vec4 u_frame;\n');
		for (d in decls)
			o.add(d + '\n');
		o.add('\nvec3 fx_rgb;\nfloat fx_a;\n');
		o.add(kDecl.toString());
		o.add('\n');
		o.add('vec4 fx_frame() {\n');
		o.add(usesFrame ? '\treturn (u_frame.z > 0.5) ? u_frame : vec4(0.0, 0.0, openfl_TextureSize.x, openfl_TextureSize.y);\n' : '\treturn vec4(0.0, 0.0, openfl_TextureSize.x, openfl_TextureSize.y);\n');
		o.add('}\n');
		o.add('vec2 fx_px() { return 1.0 / openfl_TextureSize; }\n');
		o.add('vec2 fx_toLoc(vec2 p) { vec4 f = fx_frame(); return (p * openfl_TextureSize - f.xy) / max(f.zw, vec2(1.0)); }\n');
		o.add('vec2 fx_fromLoc(vec2 l) { vec4 f = fx_frame(); return (f.xy + l * f.zw) / openfl_TextureSize; }\n');
		o.add('float fx_lum(vec3 col) { return dot(col, vec3(0.299, 0.587, 0.114)); }\n');
		o.add('vec4 fx_s0(vec2 p) {\n');
		o.add('\tvec4 f = fx_frame();\n');
		o.add('\tvec2 q = p * openfl_TextureSize;\n');
		o.add('\tfloat inside = step(f.x - 0.001, q.x) * step(q.x, f.x + f.z + 0.001) * step(f.y - 0.001, q.y) * step(q.y, f.y + f.w + 0.001);\n');
		o.add('\treturn flixel_texture2D(bitmap, p) * inside;\n');
		o.add('}\n\n');
		o.add(helperCode.toString());
		o.add(funcs.toString());
		o.add(main.toString());

		var glsl = o.toString();

		if (count == 0)
			warnings.push('No active layers: the shader only passes the sprite through.');
		var samples = chain + extraTaps * chain;
		if (samples > 250)
			warnings.push('Heavy shader (~' + samples + ' texture fetches per pixel). Lower blur/glow quality or remove layers.');

		return {
			glsl: glsl,
			uniforms: uniforms,
			usesTime: usesTime,
			usesBeat: usesBeat,
			usesFrame: usesFrame,
			warnings: warnings,
			samples: samples,
			layerCount: count,
			lines: glsl.split('\n').length
		};
	}



	public static function sanitizeName(s:String, fallback:String):String
	{
		var out = new StringBuf();
		for (i in 0...s.length)
		{
			var ch = s.charAt(i);
			if (~/^[A-Za-z0-9_\-]$/.match(ch))
				out.add(ch);
			else if (ch == ' ')
				out.add('_');
		}
		var r = out.toString();
		return (r == '') ? fallback : r;
	}

	static function luaStr(s:String):String
		return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', ' ').replace('\r', '') + "'";

	static function luaNum(v:Float):String
		return Std.string(r5(v));

	public static function buildLua(proj:ShaderProject, res:GenResult, shaderName:String):String
	{
		var objects:Array<String> = [];
		var strumGroups:Array<String> = [];
		var notes = 'none';
		var opN = proj.targets.indexOf('opnotes') >= 0;
		var plN = proj.targets.indexOf('plnotes') >= 0;
		if (opN && plN)
			notes = 'both';
		else if (opN)
			notes = 'opponent';
		else if (plN)
			notes = 'player';

		for (t in proj.targets)
		{
			switch (t)
			{
				case 'dad': objects.push('dad');
				case 'boyfriend': objects.push('boyfriend');
				case 'gf': objects.push('gf');
				case 'icons':
					objects.push('iconP1');
					objects.push('iconP2');
				case 'opstrums': strumGroups.push('opponentStrums');
				case 'plstrums': strumGroups.push('playerStrums');
				default:
			}
		}
		for (cName in proj.customTargets.split(','))
		{
			var nm = cName.trim();
			if (nm != '' && objects.indexOf(nm) < 0)
				objects.push(nm);
		}

		var needFrame = res.usesFrame;
		var needLoop = res.usesTime || res.usesBeat || (needFrame && (objects.length + strumGroups.length > 0));

		var b = new StringBuf();
		b.add('-- ============================================================================\n');
		b.add('--  ' + proj.luaName + '.lua   (generated by the Shader Editor)\n');
		b.add('--  Shader: shaders/' + shaderName + '.frag  (same mod folder, or mods/shaders)\n');
		b.add('-- ============================================================================\n\n');
		b.add('local SHADER = ' + luaStr(shaderName) + '\n\n');
		b.add('-- objects that receive the shader (missing ones are skipped silently)\n');
		b.add('local OBJECTS = { ' + objects.map(luaStr).join(', ') + ' }\n');
		b.add('-- strum groups (all 4 strums of each group)\n');
		b.add('local STRUM_GROUPS = { ' + strumGroups.map(luaStr).join(', ') + ' }\n');
		b.add("-- notes: 'none' | 'opponent' | 'player' | 'both'  (applied once, when a note spawns)\n");
		b.add('local NOTES = ' + luaStr(notes) + '\n\n');
		b.add('local targets = {}\n');
		if (res.usesTime)
			b.add('local time = 0\n');
		if (res.usesBeat)
			b.add('local beatAge = 99\n');
		b.add('\n');


		if (res.uniforms.length > 0)
		{
			b.add('-- Uniforms (change them at runtime with setShaderFloat / setShaderFloatArray on any target):\n');
			for (u in res.uniforms)
				b.add('--   ' + u.name + '   ' + u.desc + '\n');
			b.add('\n');
		}

		if (needFrame)
		{
			b.add('-- rectangle of the current atlas frame (so effects are positioned per frame, not per sprite sheet)\n');
			b.add('local function updateFrame(obj)\n');
			b.add("\tsetShaderFloatArray(obj, 'u_frame', {\n");
			b.add("\t\tgetProperty(obj .. '.frame.frame.x'),\n");
			b.add("\t\tgetProperty(obj .. '.frame.frame.y'),\n");
			b.add("\t\tgetProperty(obj .. '.frame.frame.width'),\n");
			b.add("\t\tgetProperty(obj .. '.frame.frame.height')\n");
			b.add('\t})\n');
			b.add('end\n\n');
		}

		b.add('local function applyUniforms(obj)\n');
		var any = false;
		for (u in res.uniforms)
		{
			any = true;
			switch (u.type)
			{
				case 'float': b.add('\tsetShaderFloat(obj, ' + luaStr(u.name) + ', ' + luaNum(u.v) + ')\n');
				case 'vec3':
					var a:Array<Float> = u.v;
					b.add('\tsetShaderFloatArray(obj, ' + luaStr(u.name) + ', { ' + luaNum(a[0]) + ', ' + luaNum(a[1]) + ', ' + luaNum(a[2]) + ' })\n');
				case 'sampler2D': b.add('\tsetShaderSampler2D(obj, ' + luaStr(u.name) + ', ' + luaStr(Std.string(u.v)) + ')\n');
				default:
			}
		}
		if (needFrame)
		{
			any = true;
			b.add('\tupdateFrame(obj)\n');
		}
		if (!any)
			b.add('\t-- nothing to set\n');
		b.add('end\n\n');

		b.add('local function addTarget(obj)\n');
		b.add('\tif setSpriteShader(obj, SHADER) then\n');
		b.add('\t\tapplyUniforms(obj)\n');
		b.add('\t\ttargets[#targets + 1] = obj\n');
		b.add('\t\treturn true\n');
		b.add('\tend\n');
		b.add('\treturn false\n');
		b.add('end\n\n');

		b.add('function onCreatePost()\n');
		b.add('\tinitLuaShader(SHADER)\n');
		b.add('\tfor _, obj in ipairs(OBJECTS) do\n\t\taddTarget(obj)\n\tend\n');
		b.add('\tfor _, group in ipairs(STRUM_GROUPS) do\n');
		b.add("\t\tfor i = 0, 3 do\n\t\t\taddTarget(group .. '.members[' .. i .. ']')\n\t\tend\n");
		b.add('\tend\n');
		b.add('end\n\n');

		if (needLoop)
		{
			b.add('function onUpdate(elapsed)\n');
			if (res.usesTime)
				b.add('\ttime = time + elapsed\n');
			if (res.usesBeat)
			{
				b.add('\tbeatAge = beatAge + elapsed\n');
				b.add('\tlocal beat = math.max(0, 1 - beatAge / (60 / (curBpm or bpm or 120)))\n');
			}
			b.add('\tfor _, obj in ipairs(targets) do\n');
			if (res.usesTime)
				b.add("\t\tsetShaderFloat(obj, 'u_time', time)\n");
			if (res.usesBeat)
				b.add("\t\tsetShaderFloat(obj, 'u_beat', beat)\n");
			if (needFrame)
				b.add('\t\tupdateFrame(obj)\n');
			b.add('\tend\n');
			b.add('end\n\n');
		}

		if (res.usesBeat)
		{
			b.add('function onBeatHit()\n\tbeatAge = 0\nend\n\n');
		}

		if (notes != 'none')
		{
			b.add('-- notes are shaded once when they spawn (time / beat animation stays frozen on notes)\n');
			b.add('function onSpawnNote(id, noteData, noteType, isSustainNote)\n');
			b.add("\tlocal obj = 'notes.members[' .. id .. ']'\n");
			b.add("\tlocal mine = getProperty(obj .. '.mustPress')\n");
			b.add("\tif NOTES == 'both' or (NOTES == 'player' and mine) or (NOTES == 'opponent' and not mine) then\n");
			b.add('\t\tif setSpriteShader(obj, SHADER) then\n');
			b.add('\t\t\tapplyUniforms(obj)\n');
			if (res.usesTime)
				b.add("\t\t\tsetShaderFloat(obj, 'u_time', time)\n");
			if (res.usesBeat)
				b.add("\t\t\tsetShaderFloat(obj, 'u_beat', 0)\n");
			b.add('\t\tend\n');
			b.add('\tend\n');
			b.add('end\n');
		}

		return b.toString();
	}
}
