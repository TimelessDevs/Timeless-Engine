package states.editors.content;

import states.editors.content.ShaderProject.EffectDef;
import states.editors.content.ShaderProject.ParamDef;
import states.editors.content.ShaderProject.ShaderConst;
import states.editors.content.ShaderProject.ShaderLayer;

using StringTools;

class ShaderEffectLib
{
	public static var categories:Array<String> = ['Color', 'Light', 'Distort', 'Blur', 'Overlay', 'Stylize'];

	static var map:Map<String, EffectDef>;
	static var list:Array<EffectDef>;

	public static function get(id:String):EffectDef
	{
		init();
		return map.get(id);
	}

	public static function all():Array<EffectDef>
	{
		init();
		return list;
	}

	public static function inCategory(cat:String):Array<EffectDef>
	{
		init();
		return list.filter(function(d:EffectDef) return d.cat == cat);
	}

	// ------------------------------------------------------------------ param constructors
	static function F(id:String, label:String, def:Float, min:Float, max:Float, step:Float = 0.05, dec:Int = 2):ParamDef
	{
		var p = new ParamDef(id, label, 'f', def);
		p.min = min;
		p.max = max;
		p.step = step;
		p.dec = dec;
		return p;
	}

	static function C(id:String, label:String, def:String):ParamDef
		return new ParamDef(id, label, 'c', def);

	static function E(id:String, label:String, options:Array<String>, def:Int = 0, cols:Int = 1):ParamDef
	{
		var p = new ParamDef(id, label, 'e', def);
		p.options = options;
		p.cols = cols;
		return p;
	}

	static function B(id:String, label:String, def:Bool):ParamDef
		return new ParamDef(id, label, 'b', def);

	static function T(id:String, label:String, def:String):ParamDef
	{
		var p = new ParamDef(id, label, 't', def);
		p.cols = 3;
		return p;
	}

	static function BL(def:Int = 0):ParamDef
		return E('blend', 'Blend', ShaderConst.BLEND_NAMES, def);

	static function q3(L:ShaderLayer, id:String = 'quality', a:Int = 8, b:Int = 16, c:Int = 32):Int
	{
		var i = L.getI(id);
		return (i <= 0) ? a : (i == 1 ? b : c);
	}

	static function reg(id:String, name:String, cat:String, phase:Int, desc:String, params:Array<ParamDef>, gen:ShaderGen->ShaderLayer->String,
			?taps:ShaderLayer->Int)
	{
		var d = new EffectDef(id, name, cat, phase, desc, params, gen, taps);
		map.set(id, d);
		list.push(d);
	}

	static var QUALITY:Array<String> = ['Low', 'Medium', 'High'];

	// ------------------------------------------------------------------ registr
	static function init()
	{
		if (map != null)
			return;
		map = new Map();
		list = [];
		var UV = ShaderConst.UV;
		var SMP = ShaderConst.SMP;
		var COL = ShaderConst.COL;

		// ============================== DISTORT effects yeah
		reg('wave', 'Wave Distort', 'Distort', UV, 'Sine waves that shake the picture sideways / up and down.',
			[F('ax', 'Amount X', 0.02, -0.5, 0.5, 0.005, 3), F('ay', 'Amount Y', 0.0, -0.5, 0.5, 0.005, 3), F('freq', 'Frequency', 10, 0, 100, 0.5, 1),
			 F('speed', 'Speed', 3, -30, 30, 0.25, 2)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'n.x += sin(l.y * ${P("freq")} + u_time * ${P("speed")}) * ${P("ax")};
n.y += sin(l.x * ${P("freq")} + u_time * ${P("speed")}) * ${P("ay")};';
		});

		reg('ripple', 'Ripple', 'Distort', UV, 'Rings that spread from a point.',
			[F('cx', 'Center X', 0.5, -1, 2, 0.05), F('cy', 'Center Y', 0.5, -1, 2, 0.05), F('amp', 'Amplitude', 0.02, -0.5, 0.5, 0.005, 3),
			 F('freq', 'Frequency', 30, 0, 200, 1, 1), F('speed', 'Speed', 6, -40, 40, 0.5, 1), F('fall', 'Falloff', 2, 0, 20, 0.25)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec2 d = l - vec2(${P("cx")}, ${P("cy")});
float r = length(d);
n = l + ((r > 0.0001) ? d / r : vec2(0.0)) * sin(r * ${P("freq")} - u_time * ${P("speed")}) * ${P("amp")} * exp(-r * ${P("fall")});';
		});

		reg('shake', 'Shake', 'Distort', UV, 'Random jitter of the whole picture.', [F('amp', 'Amount', 0.01, 0, 0.3, 0.0025, 4), F('speed', 'Steps / sec', 24, 1, 120, 1, 0)],
			function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float st = floor(u_time * ${P("speed")});
n = l + (vec2(fx_hash(vec2(st, 1.3)), fx_hash(vec2(st, 7.9))) - 0.5) * 2.0 * ${P("amp")};';
		});

		reg('pixelate', 'Pixelate', 'Distort', UV, 'Big square pixels (size in sprite pixels).', [F('size', 'Pixel size', 8, 1, 128, 1, 0)], function(g, L)
		{
			return 'vec2 cells = max(fx_frame().zw / max(${g.p(L, "size")}, 1.0), vec2(1.0));
n = (floor(l * cells) + 0.5) / cells;';
		});

		reg('swirl', 'Swirl', 'Distort', UV, 'Twists the picture around a point.',
			[F('cx', 'Center X', 0.5, -1, 2, 0.05), F('cy', 'Center Y', 0.5, -1, 2, 0.05), F('rad', 'Radius', 0.5, 0.01, 3, 0.05),
			 F('ang', 'Angle', 90, -720, 720, 5, 0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec2 cc = vec2(${P("cx")}, ${P("cy")});
vec2 d = l - cc;
float r = length(d);
float f = max(1.0 - r / max(${P("rad")}, 0.001), 0.0);
float a = radians(${P("ang")}) * f * f;
n = cc + vec2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a));';
		});

		reg('fisheye', 'Fisheye / Barrel', 'Distort', UV, 'Bulges (positive) or pinches (negative) the picture.', [F('str', 'Strength', 0.35, -1.5, 1.5, 0.05)],
			function(g, L)
		{
			return 'vec2 d = l - 0.5;
n = 0.5 + d * (1.0 + ${g.p(L, "str")} * dot(d, d) * 4.0);';
		});

		reg('heat', 'Heat Haze', 'Distort', UV, 'Noise based shimmering, like air above fire.',
			[F('amp', 'Amount', 0.01, 0, 0.2, 0.0025, 4), F('scale', 'Scale', 8, 0.5, 60, 0.5, 1), F('speed', 'Speed', 1.5, -10, 10, 0.25)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float tt = u_time * ${P("speed")};
n = l + (vec2(fx_noise(l * ${P("scale")} + vec2(0.0, tt)), fx_noise(l * ${P("scale")} + vec2(5.2, tt + 1.3))) - 0.5) * 2.0 * ${P("amp")};';
		});

		reg('glitchblocks', 'Glitch Blocks', 'Distort', UV, 'Horizontal bands that jump sideways at random.',
			[F('amt', 'Amount', 0.06, 0, 0.5, 0.005, 3), F('bands', 'Bands', 14, 2, 100, 1, 0), F('speed', 'Speed', 10, 0, 60, 0.5, 1),
			 F('chance', 'Chance', 0.35, 0, 1, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float band = floor(l.y * ${P("bands")});
float tt = floor(u_time * ${P("speed")});
float on = step(1.0 - ${P("chance")}, fx_hash(vec2(band * 1.7, tt)));
n.x = l.x + (fx_hash(vec2(band, tt + 11.0)) - 0.5) * 2.0 * ${P("amt")} * on;';
		});

		reg('mirror', 'Mirror / Flip', 'Distort', UV, 'Mirrors one half onto the other, or flips the picture.',
			[E('mode', 'Mode', ['Mirror X', 'Mirror Y', 'Mirror Both', 'Flip X', 'Flip Y', 'Flip Both'], 0), F('center', 'Mirror line', 0.5, 0, 1, 0.05)],
			function(g, L)
		{
			var C = g.p(L, 'center');
			return switch (g.e(L, 'mode'))
			{
				case 0: 'n.x = ' + C + ' - abs(l.x - ' + C + ');';
				case 1: 'n.y = ' + C + ' - abs(l.y - ' + C + ');';
				case 2: 'n = vec2(' + C + ') - abs(l - vec2(' + C + '));';
				case 3: 'n.x = 1.0 - l.x;';
				case 4: 'n.y = 1.0 - l.y;';
				default: 'n = 1.0 - l;';
			}
		});

		reg('kaleido', 'Kaleidoscope', 'Distort', UV, 'Repeats a slice of the picture around a center.',
			[F('seg', 'Segments', 6, 1, 32, 1, 0), F('rot', 'Rotation', 0, -360, 360, 5, 0), F('zoom', 'Zoom', 1, 0.1, 6, 0.1), F('cx', 'Center X', 0.5, -1, 2, 0.05),
			 F('cy', 'Center Y', 0.5, -1, 2, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec2 cc = vec2(${P("cx")}, ${P("cy")});
vec2 d = l - cc;
float r = length(d);
float seg = 6.2831853 / max(floor(${P("seg")}), 1.0);
float a = mod(atan(d.y, d.x) + radians(${P("rot")}), seg);
a = abs(a - seg * 0.5);
n = cc + vec2(cos(a), sin(a)) * r / max(${P("zoom")}, 0.01);';
		});

		reg('scroll', 'Scroll / Tile', 'Distort', UV, 'Tiles the picture and scrolls it.',
			[F('tx', 'Tiles X', 1, 0.1, 20, 0.25), F('ty', 'Tiles Y', 1, 0.1, 20, 0.25), F('sx', 'Scroll X', 0, -5, 5, 0.05), F('sy', 'Scroll Y', 0, -5, 5, 0.05)],
			function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'n = fract(l * vec2(${P("tx")}, ${P("ty")}) + vec2(${P("sx")}, ${P("sy")}) * u_time);';
		});

		reg('transform', 'Transform', 'Distort', UV, 'Zoom, stretch, offset, rotate and skew. Animate it for bounce effects.',
			[F('zx', 'Zoom X', 1, 0.05, 8, 0.05), F('zy', 'Zoom Y', 1, 0.05, 8, 0.05), F('ox', 'Offset X', 0, -2, 2, 0.01), F('oy', 'Offset Y', 0, -2, 2, 0.01),
			 F('rot', 'Rotation', 0, -360, 360, 1, 1), F('skew', 'Skew', 0, -2, 2, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec2 d = l - 0.5 - vec2(${P("ox")}, ${P("oy")});
float a = radians(${P("rot")});
d = vec2(d.x * cos(a) + d.y * sin(a), -d.x * sin(a) + d.y * cos(a));
d.x += d.y * ${P("skew")};
n = 0.5 + d / max(vec2(${P("zx")}, ${P("zy")}), vec2(0.01));';
		});

		// ============================== blur shit
		reg('blur', 'Blur', 'Blur', SMP, 'Soft blur. Disc, horizontal or vertical.',
			[F('rad', 'Radius (px)', 4, 0, 64, 0.5, 1), E('quality', 'Quality', ['Low (8)', 'Medium (16)', 'High (32)'], 1), E('shape', 'Shape', ['Disc', 'Horizontal', 'Vertical'], 0)],
			function(g, L)
		{
			var T = q3(L);
			var shape = g.e(L, 'shape');
			var r = 'fx_px() * ' + g.p(L, 'rad');
			var tf = ShaderGen.fmt(T);
			var s = 'vec2 r = ' + r + ';\nvec4 acc = prev;\nfor (int i = 0; i < ' + T + '; i++) {\nfloat fi = float(i) + 1.0;\n';
			if (shape == 0)
				s += 'float a = fi * 2.39996323;\nfloat rr = sqrt(fi / ' + tf + ');\nacc += ' + g.sp() + '(p + vec2(cos(a), sin(a)) * rr * r);\n}\n';
			else
			{
				var dir = (shape == 1) ? 'vec2(t, 0.0)' : 'vec2(0.0, t)';
				s += 'float t = (fi / ' + tf + ') * 2.0 - 1.0;\nacc += ' + g.sp() + '(p + ' + dir + ' * r);\n}\n';
			}
			return s + 'res = acc / (' + tf + ' + 1.0);';
		}, function(L) return q3(L));

		reg('motionblur', 'Motion Blur', 'Blur', SMP, 'Blur along a direction.',
			[F('ang', 'Angle', 0, -360, 360, 5, 0), F('len', 'Length (px)', 10, 0, 128, 1, 0), E('quality', 'Quality', ['Low (8)', 'Medium (16)', 'High (32)'], 1)],
			function(g, L)
		{
			var T = q3(L);
			var tf = ShaderGen.fmt(T);
			return 'vec2 d = vec2(cos(radians(${g.p(L, "ang")})), sin(radians(${g.p(L, "ang")}))) * fx_px() * ${g.p(L, "len")};
vec4 acc = vec4(0.0);
for (int i = 0; i < $T; i++) {
float t = float(i) / ($tf - 1.0) - 0.5;
acc += ${g.sp()}(p + d * t);
}
res = acc / $tf;';
		}, function(L) return q3(L));

		reg('zoomblur', 'Zoom Blur', 'Blur', SMP, 'Radial streaks from a center point.',
			[F('cx', 'Center X', 0.5, -1, 2, 0.05), F('cy', 'Center Y', 0.5, -1, 2, 0.05), F('str', 'Strength', 0.08, 0, 0.5, 0.01),
			 E('quality', 'Quality', ['Low (8)', 'Medium (16)', 'High (32)'], 1)], function(g, L)
		{
			var T = q3(L);
			var tf = ShaderGen.fmt(T);
			return 'vec2 cc = fx_fromLoc(vec2(${g.p(L, "cx")}, ${g.p(L, "cy")}));
vec4 acc = vec4(0.0);
for (int i = 0; i < $T; i++) {
float s = 1.0 - ${g.p(L, "str")} * (float(i) / $tf);
acc += ${g.sp()}(cc + (p - cc) * s);
}
res = acc / $tf;';
		}, function(L) return q3(L));

		reg('chroma', 'Chromatic Aberration', 'Blur', SMP, 'Splits the red and blue channels (lens fringing).',
			[F('amt', 'Amount (px)', 3, 0, 60, 0.25, 2), F('ang', 'Angle', 0, -360, 360, 5, 0), E('mode', 'Mode', ['Directional', 'Radial'], 0)], function(g, L)
		{
			var o = (g.e(L, 'mode') == 0) ? 'vec2(cos(radians(${g.p(L, "ang")})), sin(radians(${g.p(L, "ang")}))) * fx_px() * ${g.p(L, "amt")}' : '(fx_toLoc(p) - 0.5) * fx_px() * ${g.p(L, "amt")} * 2.0';
			return 'vec2 o = ' + o + ';
vec4 cr = ${g.sp()}(p + o);
vec4 cb = ${g.sp()}(p - o);
res = vec4(cr.r, prev.g, cb.b, max(prev.a, max(cr.a, cb.a)));';
		}, function(L) return 2);

		reg('sharpen', 'Sharpen', 'Blur', SMP, 'Crisper edges.', [F('amt', 'Amount', 1, 0, 5, 0.1), F('rad', 'Radius (px)', 1, 0.5, 6, 0.25)], function(g, L)
		{
			return 'vec2 o = fx_px() * ${g.p(L, "rad")};
vec4 nb = ${g.sp()}(p + vec2(o.x, 0.0)) + ${g.sp()}(p - vec2(o.x, 0.0)) + ${g.sp()}(p + vec2(0.0, o.y)) + ${g.sp()}(p - vec2(0.0, o.y));
res = prev * (1.0 + 4.0 * ${g.p(L, "amt")}) - nb * ${g.p(L, "amt")};
res = clamp(res, 0.0, 1.0);
res.rgb = min(res.rgb, vec3(res.a));';
		}, function(L) return 4);

		// ============================== color
		reg('coloradjust', 'Color Adjust', 'Color', COL, 'Exposure, brightness, contrast, saturation, hue and gamma in one layer.',
			[F('exp', 'Exposure', 0, -3, 3, 0.05), F('bright', 'Brightness', 0, -1, 1, 0.02), F('contrast', 'Contrast', 1, 0, 3, 0.05), F('sat', 'Saturation', 1, 0, 3, 0.05),
			 F('hue', 'Hue shift', 0, -360, 360, 5, 0), F('gamma', 'Gamma', 1, 0.2, 3, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec3 cc = fx_rgb * exp2(${P("exp")});
cc += ${P("bright")};
cc = (cc - 0.5) * ${P("contrast")} + 0.5;
cc = mix(vec3(fx_lum(cc)), cc, ${P("sat")});
cc = fx_hue(cc, ${P("hue")});
cc = pow(max(cc, vec3(0.0)), vec3(1.0 / max(${P("gamma")}, 0.01)));
fx_rgb = mix(fx_rgb, cc, k);';
		});

		reg('tint', 'Tint / Fill', 'Color', COL, 'Fills or tints the sprite with a colour using any blend mode.', [C('color', 'Color', 'FF3355'), BL(0)], function(g, L)
		{
			return 'fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', g.c(L, 'color')) + ', k);';
		});

		reg('gradmap', 'Gradient Map', 'Color', COL, 'Recolours by brightness: shadows, mids, highlights.',
			[C('c0', 'Shadows', '0B1026'), C('c1', 'Midtones', '7B2D8E'), C('c2', 'Highlights', 'FFD6A5'), F('mid', 'Mid point', 0.5, 0.05, 0.95, 0.05)], function(g, L)
		{
			var mid = 'clamp(' + g.p(L, 'mid') + ', 0.01, 0.99)';
			return 'float lm = fx_lum(fx_rgb);
float md = $mid;
vec3 gm = (lm < md) ? mix(${g.c(L, "c0")}, ${g.c(L, "c1")}, lm / md) : mix(${g.c(L, "c1")}, ${g.c(L, "c2")}, (lm - md) / (1.0 - md));
fx_rgb = mix(fx_rgb, gm, k);';
		});

		reg('posterize', 'Posterize', 'Color', COL, 'Limits the number of colour levels.', [F('lv', 'Levels', 5, 2, 64, 1, 0)], function(g, L)
		{
			return 'float lv = max(${g.p(L, "lv")} - 1.0, 1.0);
fx_rgb = mix(fx_rgb, floor(fx_rgb * lv + 0.5) / lv, k);';
		});

		reg('threshold', 'Threshold (2 colors)', 'Color', COL, 'Pure two colour look (black / white by default).',
			[F('level', 'Level', 0.5, 0, 1, 0.02), F('soft', 'Softness', 0.02, 0, 0.5, 0.01), C('dark', 'Dark', '000000'), C('light', 'Light', 'FFFFFF')], function(g, L)
		{
			var sf = 'max(' + g.p(L, 'soft') + ', 0.001)';
			var lv = g.p(L, 'level');
			return 'float t = smoothstep($lv - $sf, $lv + $sf, fx_lum(fx_rgb));
fx_rgb = mix(fx_rgb, mix(${g.c(L, "dark")}, ${g.c(L, "light")}, t), k);';
		});

		reg('invert', 'Invert', 'Color', COL, 'Negative colours.', [], function(g, L) return 'fx_rgb = mix(fx_rgb, 1.0 - fx_rgb, k);');

		reg('sepia', 'Sepia', 'Color', COL, 'Old photo brown.', [], function(g, L)
		{
			return 'vec3 sp = vec3(dot(fx_rgb, vec3(0.393, 0.769, 0.189)), dot(fx_rgb, vec3(0.349, 0.686, 0.168)), dot(fx_rgb, vec3(0.272, 0.534, 0.131)));
fx_rgb = mix(fx_rgb, sp, k);';
		});

		reg('mixer', 'Channel Mixer', 'Color', COL, 'Each output channel is a mix of R, G, B. Identity by default; swap or boost channels.',
			[F('rr', 'R from R', 1, -2, 2), F('rg', 'R from G', 0, -2, 2), F('rb', 'R from B', 0, -2, 2), F('gr', 'G from R', 0, -2, 2), F('gg', 'G from G', 1, -2, 2),
			 F('gb', 'G from B', 0, -2, 2), F('br', 'B from R', 0, -2, 2), F('bg', 'B from G', 0, -2, 2), F('bb', 'B from B', 1, -2, 2)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec3 mx = vec3(dot(fx_rgb, vec3(${P("rr")}, ${P("rg")}, ${P("rb")})), dot(fx_rgb, vec3(${P("gr")}, ${P("gg")}, ${P("gb")})), dot(fx_rgb, vec3(${P("br")}, ${P("bg")}, ${P("bb")})));
fx_rgb = mix(fx_rgb, mx, k);';
		});

		reg('levels', 'Levels', 'Color', COL, 'Input / output black and white points and gamma.',
			[F('ib', 'In black', 0, 0, 1, 0.02), F('iw', 'In white', 1, 0, 1, 0.02), F('gam', 'Gamma', 1, 0.1, 4, 0.05), F('ob', 'Out black', 0, 0, 1, 0.02),
			 F('ow', 'Out white', 1, 0, 1, 0.02)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec3 cc = clamp((fx_rgb - ${P("ib")}) / max(${P("iw")} - ${P("ib")}, 0.001), 0.0, 1.0);
cc = pow(cc, vec3(1.0 / max(${P("gam")}, 0.01)));
cc = mix(vec3(${P("ob")}), vec3(${P("ow")}), cc);
fx_rgb = mix(fx_rgb, cc, k);';
		});

		reg('replace', 'Color Replace', 'Color', COL, 'Swaps one colour (with tolerance) for another.',
			[C('src', 'Find', 'FF0000'), C('dst', 'Replace', '0066FF'), F('tol', 'Tolerance', 0.35, 0, 1.5, 0.02), F('soft', 'Softness', 0.15, 0, 1, 0.02),
			 E('mode', 'Mode', ['Offset', 'Keep shading'], 1)], function(g, L)
		{
			var src = g.c(L, 'src');
			var dst = g.c(L, 'dst');
			var rep = (g.e(L, 'mode') == 0) ? 'clamp(fx_rgb - $src + $dst, 0.0, 1.0)' : '$dst * (fx_lum(fx_rgb) / max(fx_lum($src), 0.05))';
			return 'float m = 1.0 - smoothstep(${g.p(L, "tol")}, ${g.p(L, "tol")} + max(${g.p(L, "soft")}, 0.001), distance(fx_rgb, $src));
vec3 rp = $rep;
fx_rgb = mix(fx_rgb, rp, m * k);';
		});

		reg('chromakey', 'Chroma Key', 'Color', COL, 'Makes a colour transparent.',
			[C('key', 'Key color', '00FF00'), F('tol', 'Tolerance', 0.35, 0, 1.5, 0.02), F('soft', 'Softness', 0.1, 0, 1, 0.02), F('spill', 'Spill fix', 0.5, 0, 1, 0.05)], function(g, L)
		{
			return 'float m = smoothstep(${g.p(L, "tol")}, ${g.p(L, "tol")} + max(${g.p(L, "soft")}, 0.001), distance(fx_rgb, ${g.c(L, "key")}));
fx_rgb = mix(fx_rgb, vec3(fx_lum(fx_rgb)), (1.0 - m) * ${g.p(L, "spill")} * k);
fx_a *= mix(1.0, m, k);';
		});

		reg('rainbow', 'Rainbow', 'Color', COL, 'Moving rainbow gradient blended over the sprite.',
			[F('ang', 'Angle', 0, -360, 360, 5, 0), F('scale', 'Scale', 1, 0.1, 10, 0.1), F('speed', 'Speed', 0.2, -3, 3, 0.05), F('sat', 'Saturation', 0.8, 0, 1, 0.05),
			 F('val', 'Value', 1, 0, 1, 0.05), BL(5)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float h = fract(dot(loc - 0.5, vec2(cos(radians(${P("ang")})), sin(radians(${P("ang")})))) * ${P("scale")} + u_time * ${P("speed")});
vec3 rb = fx_hsv(h, ${P("sat")}, ${P("val")});
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'rb') + ', k);';
		});

		reg('toon', 'Toon Shade', 'Color', COL, 'Cartoon brightness steps.',
			[F('steps', 'Steps', 3, 2, 12, 1, 0), F('smooth', 'Smoothness', 0.08, 0, 0.5, 0.01), F('boost', 'Boost', 0, -0.5, 0.5, 0.02)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float lm = fx_lum(fx_rgb);
float x = lm * ${P("steps")};
float q = (floor(x) + smoothstep(0.5 - ${P("smooth")}, 0.5 + ${P("smooth")} + 0.001, fract(x))) / ${P("steps")};
vec3 cc = fx_rgb * min(q / max(lm, 0.001), 3.0) + ${P("boost")};
fx_rgb = mix(fx_rgb, clamp(cc, 0.0, 1.0), k);';
		});

		// ============================== light (fahh im so tired to fix this)
		reg('rim', 'Rim Light', 'Light', COL, 'Light on the edge of the sprite from one direction (the original erect-style light). Stack several for more lights.',
			[C('ca', 'Color A', 'FFFFFF'), C('cb', 'Color B', 'FFB347'), F('grad', 'Gradient', 0, 0, 1, 0.05), E('gmode', 'Gradient mode', ['Constant', 'Across sprite'], 0),
			 F('size', 'Size (px)', 10, 0, 100, 0.5, 1), F('ang', 'Angle', 270, -360, 360, 5, 0), F('thr', 'Threshold', 0.9, 0.05, 1, 0.01), F('fade', 'Fade-out', 0, 0, 0.95, 0.05),
			 F('bright', 'Brightness', 1.2, 0, 8, 0.1), BL(1)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var col = (g.e(L, 'gmode') == 0) ? 'mix(${P("ca")}, ${P("cb")}, ${P("grad")})'
				: 'mix(${P("ca")}, mix(${P("ca")}, ${P("cb")}, clamp(dot(loc - 0.5, dir) + 0.5, 0.0, 1.0)), ${P("grad")})';
			return 'vec2 dir = vec2(cos(radians(${P("ang")})), sin(radians(${P("ang")})));
float a2 = ${g.src()}(uv - dir * fx_px() * ${P("size")}).a;
float thr = ${P("thr")};
float rim = (1.0 - smoothstep(${P("fade")} * thr, max(thr, ${P("fade")} * thr + 0.001), a2)) * fx_a;
vec3 rc = $col * ${P("bright")};
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'rc') + ', rim * k);';
		}, function(L) return 1);

		reg('outline', 'Outline', 'Light', COL, 'Outline outside or inside the sprite.',
			[C('color', 'Color', '000000'), F('thick', 'Thickness (px)', 2, 0, 40, 0.5, 1), F('int', 'Intensity', 1, 0, 3, 0.05), E('pos', 'Position', ['Outside', 'Inside'], 0),
			 E('quality', 'Quality', ['Low (8)', 'Medium (16)', 'High (24)'], 1)], function(g, L)
		{
			var N = q3(L, 'quality', 8, 16, 24);
			var nf = ShaderGen.fmt(N);
			var th = g.p(L, 'thick');
			var S = g.src();
			var s = 'float acc = ' + ((g.e(L, 'pos') == 0) ? '0.0' : '1.0') + ';\nfor (int i = 0; i < $N; i++) {\nfloat a = float(i) * 6.2831853 / $nf;\nvec2 o = vec2(cos(a), sin(a)) * fx_px() * $th;\n';
			if (g.e(L, 'pos') == 0)
				s += 'acc = max(acc, $S(uv + o).a);\nacc = max(acc, $S(uv + o * 0.5).a);\n}\nfx_under(' + g.c(L, 'color') + ', acc * ' + g.p(L, 'int') + ' * k);';
			else
				s += 'acc = min(acc, $S(uv + o).a);\nacc = min(acc, $S(uv + o * 0.5).a);\n}\nfx_rgb = mix(fx_rgb, ' + g.c(L, 'color') + ', clamp(fx_a * (1.0 - acc) * ' + g.p(L, 'int') + ', 0.0, 1.0) * k);';
			return s;
		}, function(L) return 2 * q3(L, 'quality', 8, 16, 24));

		reg('glow', 'Bloom', 'Light', COL, 'Outer glow around the sprite, or additive bloom of bright parts.',
			[E('mode', 'Mode', ['Outer glow', 'Bloom (additive)'], 0), C('color', 'Color', 'FFD54F'), F('rad', 'Radius (px)', 10, 1, 80, 0.5, 1), F('int', 'Intensity', 1, 0, 8, 0.05),
			 F('thr', 'Threshold', 0.3, 0, 1, 0.02), E('quality', 'Quality', ['Low (12)', 'Medium (20)', 'High (32)'], 1)], function(g, L)
		{
			var N = q3(L, 'quality', 12, 20, 32);
			var nf = ShaderGen.fmt(N);
			var S = g.src();
			var s = 'vec4 acc = vec4(0.0);\nfloat ws = 0.0;\nfor (int i = 0; i < $N; i++) {\nfloat fi = float(i) + 1.0;\nfloat a = fi * 2.39996323;\nfloat rr = sqrt(fi / $nf);\nfloat w = 1.0 - rr * 0.8;\n'
				+ 'acc += $S(uv + vec2(cos(a), sin(a)) * rr * fx_px() * ' + g.p(L, 'rad') + ') * w;\nws += w;\n}\nacc /= ws;\n';
			if (g.e(L, 'mode') == 0)
				s += 'fx_under(' + g.c(L, 'color') + ', clamp(acc.a * ' + g.p(L, 'int') + ', 0.0, 1.0) * k);';
			else
				s += 'vec3 br = max(acc.rgb - vec3(' + g.p(L, 'thr') + '), vec3(0.0));\nfx_rgb += br * ' + g.c(L, 'color') + ' * ' + g.p(L, 'int') + ' * k;';
			return s;
		}, function(L) return q3(L, 'quality', 12, 20, 32));

		reg('shadow', 'Drop Shadow', 'Light', COL, 'Soft shadow behind the sprite.',
			[C('color', 'Color', '000000'), F('ox', 'Offset X (px)', 6, -60, 60, 1, 0), F('oy', 'Offset Y (px)', 6, -60, 60, 1, 0), F('blur', 'Blur (px)', 4, 0, 40, 0.5, 1),
			 F('int', 'Intensity', 0.6, 0, 1, 0.05)], function(g, L)
		{
			var S = g.src();
			return 'vec2 o = fx_px() * vec2(${g.p(L, "ox")}, ${g.p(L, "oy")});
float acc = $S(uv - o).a;
for (int i = 0; i < 8; i++) {
float a = float(i) * 0.785398;
acc += $S(uv - o + vec2(cos(a), sin(a)) * fx_px() * ${g.p(L, "blur")}).a;
}
fx_under(${g.c(L, "color")}, acc / 9.0 * ${g.p(L, "int")} * k);';
		}, function(L) return 9);

		reg('radial', 'Radial Light', 'Light', COL, 'Round spot of light (or any blend colour) at a point.',
			[C('color', 'Color', 'FFE9B0'), F('cx', 'Center X', 0.5, -1, 2, 0.05), F('cy', 'Center Y', 0.5, -1, 2, 0.05), F('rad', 'Radius', 0.5, 0.01, 3, 0.05),
			 F('soft', 'Softness', 0.35, 0, 2, 0.05), F('int', 'Intensity', 1, 0, 6, 0.05), BL(1)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float m = 1.0 - smoothstep(${P("rad")} - max(${P("soft")}, 0.001), ${P("rad")}, length(loc - vec2(${P("cx")}, ${P("cy")})));
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', g.c(L, 'color') + ' * ' + P('int')) + ', m * k);';
		});

		reg('shine', 'Shine Sweep', 'Light', COL, 'A band of light sweeping across the sprite.',
			[C('color', 'Color', 'FFFFFF'), F('ang', 'Angle', 30, -360, 360, 5, 0), F('width', 'Width', 0.18, 0.01, 1, 0.01), F('speed', 'Speed', 0.4, 0, 5, 0.05),
			 F('gap', 'Pause', 1, 0, 6, 0.25), F('int', 'Intensity', 1, 0, 6, 0.05), BL(1)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float pr = dot(loc - 0.5, vec2(cos(radians(${P("ang")})), sin(radians(${P("ang")})))) + 0.5;
float prog = clamp(fract(u_time * ${P("speed")} / (1.0 + ${P("gap")})) * (1.0 + ${P("gap")}), 0.0, 1.0);
float cc = mix(-${P("width")}, 1.0 + ${P("width")}, prog);
float m = (1.0 - smoothstep(0.0, ${P("width")}, abs(pr - cc))) * fx_a;
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', g.c(L, 'color') + ' * ' + P('int')) + ', m * k);';
		});

		reg('flash', 'Beat Flash', 'Light', COL, 'Flashes a colour on every beat (needs the Lua script, uses u_beat).',
			[C('color', 'Color', 'FFFFFF'), F('pow', 'Decay power', 2, 0.25, 8, 0.25), F('int', 'Intensity', 0.6, 0, 4, 0.05), BL(1)], function(g, L)
		{
			return 'float f = pow(clamp(u_beat, 0.0, 1.0), ${g.p(L, "pow")}) * ${g.p(L, "int")};
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', g.c(L, 'color')) + ', clamp(f, 0.0, 1.0) * k);';
		});

		reg('echo', 'Echo / Afterimage', 'Light', COL, 'Fading ghost copies behind the sprite.',
			[F('ox', 'Offset X (px)', 8, -80, 80, 1, 0), F('oy', 'Offset Y (px)', 0, -80, 80, 1, 0), F('fade', 'Fade', 0.55, 0.05, 1, 0.05), F('int', 'Intensity', 0.6, 0, 1, 0.05),
			 C('tint', 'Tint', 'FFFFFF'), E('copies', 'Copies', ['2', '3', '4'], 1)], function(g, L)
		{
			var N = g.e(L, 'copies') + 2;
			var S = g.src();
			return 'for (int i = 1; i <= $N; i++) {
float fi = float(i);
vec4 s = $S(uv - fx_px() * vec2(${g.p(L, "ox")}, ${g.p(L, "oy")}) * fi);
float sa = s.a * ${g.p(L, "int")} * exp2((fi - 1.0) * log2(max(${g.p(L, "fade")}, 0.001)));
vec3 sc = (s.a > 0.001) ? s.rgb / s.a : vec3(0.0);
fx_under(sc * ${g.c(L, "tint")}, sa * k);
}';
		}, function(L) return L.getI('copies') + 2);

		reg('edge', 'Edge Detect', 'Light', COL, 'Sobel edge lines (sketch / ink look).',
			[E('source', 'Source', ['Luma', 'Alpha', 'Both'], 0), F('thick', 'Thickness (px)', 1, 0.5, 8, 0.25), F('str', 'Strength', 2, 0, 10, 0.1), F('thr', 'Threshold', 0.1, 0, 2, 0.02),
			 C('color', 'Line color', '000000'), C('paper', 'Paper color', 'FFFFFF'), E('mode', 'Mode', ['Overlay lines', 'Only lines'], 0)], function(g, L)
		{
			var S = g.src();
			var src = g.e(L, 'source');
			var V = function(o:String):String
			{
				var s = '$S(uv + $o)';
				return (src == 0) ? 'fx_lum(' + s + '.rgb)' : (src == 1 ? s + '.a' : 'max(fx_lum(' + s + '.rgb), ' + s + '.a)');
			};
			return 'vec2 o = fx_px() * ${g.p(L, "thick")};
float tl = ${V("vec2(-o.x, -o.y)")};
float tt = ${V("vec2(0.0, -o.y)")};
float tr = ${V("vec2(o.x, -o.y)")};
float lf = ${V("vec2(-o.x, 0.0)")};
float rt = ${V("vec2(o.x, 0.0)")};
float bl = ${V("vec2(-o.x, o.y)")};
float bb = ${V("vec2(0.0, o.y)")};
float br = ${V("vec2(o.x, o.y)")};
float gx = -tl - 2.0 * lf - bl + tr + 2.0 * rt + br;
float gy = -tl - 2.0 * tt - tr + bl + 2.0 * bb + br;
float ed = clamp((length(vec2(gx, gy)) - ${g.p(L, "thr")}) * ${g.p(L, "str")}, 0.0, 1.0);
' + ((g.e(L, 'mode') == 0) ? 'fx_rgb = mix(fx_rgb, ${g.c(L, "color")}, ed * k);' : 'fx_rgb = mix(fx_rgb, mix(${g.c(L, "paper")}, ${g.c(L, "color")}, ed), k);');
		}, function(L) return 8);

		reg('emboss', 'Emboss', 'Light', COL, 'Relief look from brightness differences.',
			[F('str', 'Strength', 2, 0, 10, 0.1), F('ang', 'Angle', 135, -360, 360, 5, 0), BL(4)], function(g, L)
		{
			var S = g.src();
			return 'vec2 o = vec2(cos(radians(${g.p(L, "ang")})), sin(radians(${g.p(L, "ang")}))) * fx_px();
float d = fx_lum($S(uv + o).rgb) - fx_lum($S(uv - o).rgb);
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'vec3(0.5 + d * ' + g.p(L, 'str') + ')') + ', k);';
		}, function(L) return 2);

		// ============================== overlay
		reg('gradover', 'Gradient Overlay', 'Overlay', COL, 'Two colour gradient across the sprite.',
			[C('ca', 'Color A', 'FF006E'), C('cb', 'Color B', '3A86FF'), F('ang', 'Angle', 90, -360, 360, 5, 0), F('pos', 'Position', 0.5, -0.5, 1.5, 0.05), F('soft', 'Softness', 0.5, 0.01, 2, 0.05),
			 BL(4)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float t = smoothstep(${P("pos")} - ${P("soft")}, ${P("pos")} + ${P("soft")}, dot(loc - 0.5, vec2(cos(radians(${P("ang")})), sin(radians(${P("ang")})))) + 0.5);
vec3 gc = mix(${P("ca")}, ${P("cb")}, t);
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'gc') + ', k);';
		});

		reg('noiseover', 'Noise / Clouds', 'Overlay', COL, 'Moving fractal noise (fog, clouds, dirt).',
			[C('ca', 'Color A', '000000'), C('cb', 'Color B', 'FFFFFF'), F('scale', 'Scale', 4, 0.5, 40, 0.5, 1), F('sx', 'Speed X', 0.1, -3, 3, 0.05), F('sy', 'Speed Y', 0, -3, 3, 0.05),
			 F('con', 'Contrast', 1.2, 0.1, 6, 0.1), BL(4)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float nz = clamp((fx_fbm(loc * ${P("scale")} + vec2(${P("sx")}, ${P("sy")}) * u_time) - 0.5) * ${P("con")} + 0.5, 0.0, 1.0);
vec3 nc = mix(${g.c(L, "ca")}, ${g.c(L, "cb")}, nz);
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'nc') + ', k);';
		});

		reg('pattern', 'Pattern', 'Overlay', COL, 'Stripes, checker, dots or grid.',
			[E('type', 'Type', ['Stripes', 'Checker', 'Dots', 'Grid'], 0), C('color', 'Color', '000000'), F('scale', 'Scale', 12, 1, 100, 1, 0), F('ang', 'Angle', 45, -360, 360, 5, 0),
			 F('duty', 'Thickness', 0.5, 0.02, 1, 0.02), F('soft', 'Softness', 0.05, 0.001, 0.5, 0.01), BL(0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var m = switch (g.e(L, 'type'))
			{
				case 0: 'float m = 1.0 - smoothstep(${P("duty")} - ${P("soft")}, ${P("duty")} + ${P("soft")}, abs(fract(q.x) - 0.5) * 2.0);';
				case 1: 'float m = mod(floor(q.x) + floor(q.y), 2.0);';
				case 2: 'float m = 1.0 - smoothstep(${P("duty")} - ${P("soft")}, ${P("duty")} + ${P("soft")}, length(fract(q) - 0.5) * 2.0);';
				default: 'vec2 f = abs(fract(q) - 0.5) * 2.0;
float w = ${P("duty")} * 0.2;
float m = max(smoothstep(1.0 - w - ${P("soft")}, 1.0 - w + ${P("soft")}, f.x), smoothstep(1.0 - w - ${P("soft")}, 1.0 - w + ${P("soft")}, f.y));';
			};
			return 'float ca = cos(radians(${P("ang")}));
float sa = sin(radians(${P("ang")}));
vec2 q = vec2(ca * loc.x - sa * loc.y, sa * loc.x + ca * loc.y) * ${P("scale")};
' + m + '
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', g.c(L, 'color')) + ', m * k);';
		});

		reg('texture', 'Image Overlay', 'Overlay', COL, 'Blends any image from images/ (path without .png) over the sprite.',
			[T('tex', 'Image path (images/...)', ''), F('sx', 'Scale X', 1, 0.05, 20, 0.05), F('sy', 'Scale Y', 1, 0.05, 20, 0.05), F('ox', 'Offset X', 0, -2, 2, 0.01),
			 F('oy', 'Offset Y', 0, -2, 2, 0.01), F('scx', 'Scroll X', 0, -3, 3, 0.05), F('scy', 'Scroll Y', 0, -3, 3, 0.05), BL(0)], function(g, L)
		{
			var t = g.tex(L, 'tex');
			if (t == null)
				return '';
			var P = function(id:String) return g.p(L, id);
			return 'vec4 tx = texture2D($t, fract(loc * vec2(${P("sx")}, ${P("sy")}) + vec2(${P("ox")}, ${P("oy")}) + vec2(${P("scx")}, ${P("scy")}) * u_time));
vec3 tc = (tx.a > 0.001) ? tx.rgb / tx.a : vec3(0.0);
fx_rgb = mix(fx_rgb, ' + g.bl(L, 'blend', 'fx_rgb', 'tc') + ', tx.a * k);';
		}, function(L) return 1);

		reg('vignette', 'Vignette / Edge Fade', 'Overlay', COL, 'Darkens (or fades out) towards the edges.',
			[C('color', 'Color', '000000'), F('rad', 'Radius', 0.75, 0, 1.5, 0.05), F('soft', 'Softness', 0.45, 0.01, 1.5, 0.05), F('cx', 'Center X', 0.5, -1, 2, 0.05),
			 F('cy', 'Center Y', 0.5, -1, 2, 0.05), E('target', 'Apply to', ['Color', 'Alpha'], 0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var s = 'float v = smoothstep(${P("rad")}, ${P("rad")} + max(${P("soft")}, 0.001), length((loc - vec2(${P("cx")}, ${P("cy")})) * 2.0));\n';
			return s + ((g.e(L, 'target') == 0) ? 'fx_rgb = mix(fx_rgb, ${g.c(L, "color")}, v * k);' : 'fx_a *= mix(1.0, 1.0 - v, k);');
		});

		reg('scanlines', 'Scanlines', 'Overlay', COL, 'CRT style lines.',
			[F('dens', 'Line count', 120, 5, 800, 1, 0), F('int', 'Darkness', 0.35, 0, 1, 0.05), F('thick', 'Thickness', 0.5, 0.05, 1, 0.05), F('speed', 'Scroll speed', 0, -20, 20, 0.5, 1),
			 E('dir', 'Direction', ['Horizontal', 'Vertical'], 0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var v = (g.e(L, 'dir') == 0) ? 'loc.y' : 'loc.x';
			return 'float s = 0.5 + 0.5 * sin($v * ${P("dens")} * 6.2831853 + u_time * ${P("speed")});
float ln = smoothstep(${P("thick")} - 0.15, ${P("thick")} + 0.15, s);
fx_rgb = mix(fx_rgb, fx_rgb * mix(1.0 - ${P("int")}, 1.0, ln), k);';
		});

		reg('grain', 'Film Grain', 'Overlay', COL, 'Animated noise grain.',
			[F('amt', 'Amount', 0.12, 0, 1, 0.01), F('size', 'Size (px)', 1, 1, 16, 1, 0), F('fps', 'Frames / sec', 24, 1, 60, 1, 0), E('mode', 'Mode', ['Mono', 'Color'], 0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var nz = (g.e(L, 'mode') == 0) ? 'vec3(n0)' : 'vec3(n0, fx_hash(gp + sd + 11.3), fx_hash(gp + sd + 27.1))';
			return 'vec2 gp = floor(loc * fx_frame().zw / max(${P("size")}, 1.0));
vec2 sd = vec2(floor(u_time * ${P("fps")}) * 13.37, 0.0);
float n0 = fx_hash(gp + sd);
fx_rgb += ($nz - 0.5) * ${P("amt")} * k;';
		});

		reg('hologram', 'Hologram', 'Overlay', COL, 'Sci-fi projection: tint, scanlines and flicker.',
			[C('color', 'Color', '00E5FF'), F('dens', 'Line density', 240, 20, 800, 1, 0), F('speed', 'Line speed', 2, -20, 20, 0.5, 1), F('scan', 'Scan amount', 0.5, 0, 1, 0.05),
			 F('flick', 'Flicker', 0.15, 0, 1, 0.05), F('alpha', 'Alpha', 0.8, 0, 1, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float scn = 0.5 + 0.5 * sin(loc.y * ${P("dens")} + u_time * ${P("speed")});
float fl = 1.0 - ${P("flick")} * fx_hash(vec2(floor(u_time * 24.0), 4.2));
vec3 hl = ${g.c(L, "color")} * (0.35 + fx_lum(fx_rgb) * 1.4) * mix(1.0, scn, ${P("scan")}) * fl;
fx_rgb = mix(fx_rgb, hl, k);
fx_a *= mix(1.0, ${P("alpha")} * mix(1.0, scn, ${P("scan")} * 0.5) * fl, k);';
		});

		// ============================== stylize
		reg('halftone', 'Halftone', 'Stylize', COL, 'Comic book dots.',
			[F('size', 'Dot size (px)', 6, 2, 40, 0.5, 1), F('ang', 'Angle', 45, -360, 360, 5, 0), F('soft', 'Softness', 0.12, 0.001, 0.5, 0.01), E('mode', 'Mode', ['Mono', 'Color'], 0),
			 C('ink', 'Ink', '101010'), C('paper', 'Paper', 'F4EBD0')], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			var sf = 'max(' + P('soft') + ', 0.001)';
			var s = 'vec2 pix = loc * fx_frame().zw;\n';
			if (g.e(L, 'mode') == 0)
				s += 'float cov = fx_ht(pix, ${P("size")}, ${P("ang")}, 1.0 - fx_lum(fx_rgb), $sf);\nfx_rgb = mix(fx_rgb, mix(${g.c(L, "paper")}, ${g.c(L, "ink")}, cov), k);';
			else
				s += 'vec3 iv = 1.0 - fx_rgb;\nvec3 cv = vec3(fx_ht(pix, ${P("size")}, ${P("ang")} + 15.0, iv.r, $sf), fx_ht(pix, ${P("size")}, ${P("ang")} + 75.0, iv.g, $sf), fx_ht(pix, ${P("size")}, ${P("ang")}, iv.b, $sf));\nfx_rgb = mix(fx_rgb, (vec3(1.0) - cv) * ${g.c(L, "paper")}, k);';
			return s;
		});

		reg('dither', 'Dither (Bayer)', 'Stylize', COL, 'Retro ordered dithering with few colours.',
			[F('lv', 'Levels', 4, 2, 32, 1, 0), F('str', 'Strength', 1, 0, 2, 0.05), F('size', 'Pixel size', 1, 1, 8, 1, 0)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'vec2 pp = floor(loc * fx_frame().zw / max(${P("size")}, 1.0));
float th = fx_bayer4(pp) - 0.46875;
float lv = max(${P("lv")} - 1.0, 1.0);
vec3 dc = floor(fx_rgb * lv + th * ${P("str")} + 0.5) / lv;
fx_rgb = mix(fx_rgb, clamp(dc, 0.0, 1.0), k);';
		});

		reg('dissolve', 'Dissolve', 'Stylize', COL, 'Noise dissolve with a glowing edge. Animate "Threshold" to burn the sprite away.',
			[F('th', 'Threshold', 0.5, 0, 1, 0.02), F('scale', 'Noise scale', 12, 1, 60, 0.5, 1), F('ew', 'Edge width', 0.06, 0.001, 0.5, 0.005, 3), C('ecol', 'Edge color', 'FF8A00'),
			 F('ep', 'Edge power', 3, 0, 10, 0.1), F('speed', 'Noise speed', 0, -3, 3, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float nz = fx_fbm(loc * ${P("scale")} + vec2(u_time * ${P("speed")}));
float vis = smoothstep(${P("th")}, ${P("th")} + 0.01, nz);
float ed = vis * (1.0 - smoothstep(${P("th")}, ${P("th")} + max(${P("ew")}, 0.001), nz));
fx_rgb += ${g.c(L, "ecol")} * ed * ${P("ep")} * k;
fx_a *= mix(1.0, vis, k);';
		});

		reg('alpha', 'Alpha', 'Stylize', COL, 'Multiplies / curves transparency.', [F('mult', 'Multiply', 1, 0, 2, 0.05), F('pow', 'Curve', 1, 0.1, 4, 0.05)], function(g, L)
		{
			return 'float na = pow(clamp(fx_a * ${g.p(L, "mult")}, 0.0, 1.0), ${g.p(L, "pow")});
fx_a = mix(fx_a, na, k);';
		});

		reg('alphagrad', 'Alpha Gradient', 'Stylize', COL, 'Fades the sprite out along a direction.',
			[F('ang', 'Angle', 90, -360, 360, 5, 0), F('start', 'Start', 0, -0.5, 1.5, 0.05), F('end', 'End', 1, -0.5, 1.5, 0.05)], function(g, L)
		{
			var P = function(id:String) return g.p(L, id);
			return 'float t = dot(loc - 0.5, vec2(cos(radians(${P("ang")})), sin(radians(${P("ang")})))) + 0.5;
fx_a *= mix(1.0, smoothstep(${P("start")}, max(${P("end")}, ${P("start")} + 0.001), t), k);';
		});
	}
}
