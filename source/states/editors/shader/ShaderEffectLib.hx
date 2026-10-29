package states.editors.shader;

import states.editors.shader.ShaderConst;
import states.editors.shader.ShaderGen;
import states.editors.shader.ShaderProject;

class ShaderEffectLib
{
	private static var effs:Map<String, EffectDef> = new Map();

	public static function init()
	{
		if (effs.exists('erect_rim')) return;

		var rimParams:Array<ParamDef> = [
			new ParamDef('radius', 'Glow Radius', 'f', 0.25),
			new ParamDef('brightness', 'Glow Intensity', 'f', 1.2),
			new ParamDef('fadeout', 'Edge Fade-Out', 'f', 0.0),
			new ParamDef('gradient', 'Gradient Range', 'f', 0.5),
			new ParamDef('angle', 'Light Axis Angle', 'f', 270.0),
			new ParamDef('colorHex', 'Primary RGB Hex', 'c', 'FFFFFF'),
			new ParamDef('colorHex2', 'Secondary RGB Hex', 'c', 'FFFFFF')
		];
		rimParams[0].min = 0.005; rimParams[0].max = 1.0; rimParams[0].step = 0.005; rimParams[0].dec = 3;
		rimParams[1].min = 0.0;   rimParams[1].max = 10.0; rimParams[1].step = 0.1;
		rimParams[2].min = 0.0;   rimParams[2].max = 0.95; rimParams[2].step = 0.05;
		rimParams[3].min = 0.01;  rimParams[3].max = 2.0;  rimParams[3].step = 0.05;
		rimParams[4].min = 0.0;   rimParams[4].max = 360.0; rimParams[4].step = 1.0;

		var rimDef = new EffectDef('erect_rim', 'Erect Rim Glow', 'Colour', ShaderConst.COL, 'Generates professional multi-color anti-aliased edge glow outline.', rimParams, 
		function(gen:ShaderGen, L:ShaderLayer):String {
			var radAngle = 'radians(' + gen.p(L, 'angle') + ')';
			var offset = 'vec2(cos(' + radAngle + '), sin(' + radAngle + ')) * (' + gen.p(L, 'radius') + ' * 0.03)';
			var c1 = gen.c(L, 'colorHex');
			var c2 = gen.c(L, 'colorHex2');
			
			var code = 'float alphaAlpha = fx_s0(uv - ' + offset + ').a;\n';
			code += 'if (alphaAlpha < 0.9 && fx_a > 0.0) {\n';
			code += '	float edgeGlow = smoothstep(0.9, ' + gen.p(L, 'fadeout') + ' * 0.9, alphaAlpha);\n';
			code += '	float gradientFactor = clamp(loc.y / clamp(' + gen.p(L, 'gradient') + ', 0.01, 2.0), 0.0, 1.0);\n';
			code += '	vec3 mixedColor = mix(' + c1 + ', ' + c2 + ', gradientFactor);\n';
			code += '	float aaFactor = smoothstep(0.0, 0.05, 0.9 - alphaAlpha);\n';
			code += '	fx_rgb += mixedColor * ' + gen.p(L, 'brightness') + ' * edgeGlow * aaFactor;\n';
			code += '}\n';
			return code;
		}, function(L:ShaderLayer):Int { return 1; });
		effs.set('erect_rim', rimDef);

		var chromParams:Array<ParamDef> = [
			new ParamDef('amountX', 'Horizontal Shift', 'f', 0.5),
			new ParamDef('amountY', 'Vertical Shift', 'f', 0.0)
		];
		chromParams[0].min = -5.0; chromParams[0].max = 5.0; chromParams[0].step = 0.1;
		chromParams[1].min = -5.0; chromParams[1].max = 5.0; chromParams[1].step = 0.1;

		var chromDef = new EffectDef('chromatic', 'Chromatic Aberration', 'Sampling', ShaderConst.SMP, 'Splits red and blue color channels across coordinate axes.', chromParams,
		function(gen:ShaderGen, L:ShaderLayer):String {
			var amtX = '(' + gen.p(L, 'amountX') + ' * 0.01)';
			var amtY = '(' + gen.p(L, 'amountY') + ' * 0.01)';
			
			var code = 'vec2 d_offset = vec2(' + amtX + ', ' + amtY + ');\n';
			code += 'res.r = fx_s0(p - d_offset).r;\n';
			code += 'res.b = fx_s0(p + d_offset).b;\n';
			code += 'res.g = fx_s0(p).g;\n';
			code += 'res.a = fx_s0(p).a;\n';
			return code;
		}, function(L:ShaderLayer):Int { return 2; });
		effs.set('chromatic', chromDef);

		var blurParams:Array<ParamDef> = [
			new ParamDef('strength', 'Blur Strength', 'f', 0.3),
			new ParamDef('centerX', 'Center Point X', 'f', 0.5),
			new ParamDef('centerY', 'Center Point Y', 'f', 0.5)
		];
		blurParams[0].min = 0.0; blurParams[0].max = 3.0; blurParams[0].step = 0.05;
		blurParams[1].min = 0.0; blurParams[1].max = 1.0; blurParams[1].step = 0.05;
		blurParams[2].min = 0.0; blurParams[2].max = 1.0; blurParams[2].step = 0.05;

		var blurDef = new EffectDef('radial_blur', 'Radial Zoom Blur', 'Sampling', ShaderConst.SMP, 'Creates a high-performance kinematic radial zoom trail effect.', blurParams,
		function(gen:ShaderGen, L:ShaderLayer):String {
			var center = 'vec2(' + gen.p(L, 'centerX') + ', ' + gen.p(L, 'centerY') + ')';
			var str = '(' + gen.p(L, 'strength') + ' * 0.05)';
			
			var code = 'vec2 dir = p - ' + center + ';\n';
			code += 'vec4 blurSum = vec4(0.0);\n';
			code += 'float wSum = 0.0;\n';
			code += 'for(int j = 0; j < 6; j++) {\n';
			code += '	float scaleFactor = 1.0 - ' + str + ' * (float(j) / 5.0);\n';
			code += '	vec4 sSample = fx_s0(' + center + ' + dir * scaleFactor);\n';
			code += '	blurSum += sSample * (1.0 - float(j)/6.0);\n';
			code += '	wSum += (1.0 - float(j)/6.0);\n';
			code += '}\n';
			code += 'res = blurSum / max(wSum, 0.01);\n';
			return code;
		}, function(L:ShaderLayer):Int { return 6; });
		effs.set('radial_blur', blurDef);

		var glitchParams:Array<ParamDef> = [
			new ParamDef('scale', 'Glitch Scale', 'f', 10.0),
			new ParamDef('speed', 'Mutation Speed', 'f', 1.0),
			new ParamDef('threshold', 'Cutoff Threshold', 'f', 0.8)
		];
		glitchParams[0].min = 1.0; glitchParams[0].max = 50.0; glitchParams[0].step = 0.5;
		glitchParams[1].min = 0.0; glitchParams[1].max = 10.0; glitchParams[1].step = 0.1;
		glitchParams[2].min = 0.1; glitchParams[2].max = 0.99; glitchParams[2].step = 0.01;

		var glitchDef = new EffectDef('glitch_matrix', 'Matrix Digital Glitch', 'UV', ShaderConst.UV, 'Warps texture coordinates row-by-row utilizing hardware hash blocks.', glitchParams,
		function(gen:ShaderGen, L:ShaderLayer):String {
			var scale = gen.p(L, 'scale');
			var speed = gen.p(L, 'speed');
			var thresh = gen.p(L, 'threshold');
			
			var code = 'float blockTime = floor(u_time * ' + speed + ' * 12.0);\n';
			code += 'float rowNoise = fx_hash(vec2(floor(l.y * ' + scale + '), blockTime));\n';
			code += 'if (rowNoise > ' + thresh + ') {\n';
			code += '	float shiftX = (fx_hash(vec2(blockTime, rowNoise)) * 2.0 - 1.0) * 0.04;\n';
			code += '	n.x = clamp(n.x + shiftX, 0.0, 1.0);\n';
			code += '}\n';
			return code;
		}, function(L:ShaderLayer):Int { return 0; });
		effs.set('glitch_matrix', glitchDef);
	}

	public static function get(id:String):EffectDef
	{
		init();
		return effs.get(id);
	}

	public static function list():Array<EffectDef>
	{
		init();
		return [for (e in effs) e];
	}
}