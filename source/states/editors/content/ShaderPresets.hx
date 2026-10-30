package states.editors.content;

import states.editors.content.ShaderProject.ShaderLayer;

class ShaderPresets
{
	public static final names:Array<String> = [
		'Light', 'Neon', 'VHS Tape', 'Glitch', 'Hologram', 'Night Tint', 'Underwater', 'Heat Haze', 'Dissolve Out', 'Comic',
		'Old Film', 'Vaporwave', 'Toon + Ink', 'Shine', 'Beat Pulse', 'Pixel', 'Ghost Echo', 'Blur'
	];

	static function mk(p:ShaderProject, type:String, ?vals:Dynamic, opacity:Float = 1.0, ?mask:Array<Dynamic>, ?anim:Array<Dynamic>):ShaderLayer
	{
		var l = p.addLayer(type);
		if (vals != null)
			for (f in Reflect.fields(vals))
				l.setV(f, Reflect.field(vals, f));
		l.opacity = opacity;
		if (mask != null)
		{
			l.maskMode = mask[0];
			var arr:Array<Dynamic> = mask[1];
			for (i in 0...arr.length)
				l.mask[i] = arr[i];
			if (mask.length > 2)
				l.maskInvert = mask[2];
		}
		if (anim != null)
		{
			l.animParam = anim[0];
			l.animMode = anim[1];
			l.animSpeed = anim[2];
			l.animAmt = anim[3];
			if (anim.length > 4)
				l.animPhase = anim[4];
		}
		return l;
	}

	public static function apply(name:String, p:ShaderProject)
	{
		switch (name)
		{
			case 'Light':
				mk(p, 'rim', {ca: 'FFFFFF', cb: 'FFFFFF', size: 10, ang: 270, thr: 0.9, fade: 0, bright: 1.2});
			case 'Neon':
				mk(p, 'coloradjust', {sat: 1.2, contrast: 1.1});
				mk(p, 'glow', {mode: 0, color: 'FF00E5', rad: 14, int: 2.0});
				mk(p, 'outline', {color: 'FF9CF5', thick: 2, pos: 0}, 1.0, null, ['opacity', 1, 1.5, 0.15]);
			case 'VHS Tape':
				mk(p, 'glitchblocks', {amt: 0.03, bands: 40, speed: 6, chance: 0.15});
				mk(p, 'chroma', {amt: 4, ang: 0});
				mk(p, 'coloradjust', {sat: 0.8, contrast: 1.1, bright: 0.02});
				mk(p, 'scanlines', {dens: 160, int: 0.3});
				mk(p, 'grain', {amt: 0.14});
			case 'Glitch':
				mk(p, 'glitchblocks', {amt: 0.1, bands: 18, speed: 14, chance: 0.4});
				mk(p, 'chroma', {amt: 6, ang: 0}, 1.0, null, ['amt', 5, 1, 6]);
				mk(p, 'shake', {amp: 0.006, speed: 30});
			case 'Hologram':
				mk(p, 'chroma', {amt: 2});
				mk(p, 'hologram', {color: '00E5FF', dens: 260, scan: 0.55, flick: 0.2, alpha: 0.85});
				mk(p, 'glow', {mode: 0, color: '00E5FF', rad: 8, int: 1.0});
			case 'Night Tint':
				mk(p, 'coloradjust', {bright: -0.08, sat: 0.7, contrast: 1.05});
				mk(p, 'tint', {color: '3A4FB5', blend: 2}, 0.8);
				mk(p, 'rim', {ca: '9DB8FF', cb: '9DB8FF', size: 8, ang: 300, bright: 1.0});
			case 'Underwater':
				mk(p, 'wave', {ax: 0.012, ay: 0.006, freq: 14, speed: 2.5});
				mk(p, 'tint', {color: '2AA7C9', blend: 2}, 0.7);
				mk(p, 'noiseover', {ca: '000000', cb: 'BFFFFF', scale: 5, sx: 0.08, sy: -0.05, con: 1.6, blend: 3}, 0.35);
				mk(p, 'blur', {rad: 1.5, quality: 1});
			case 'Heat Haze':
				mk(p, 'heat', {amp: 0.012, scale: 9, speed: 2});
				mk(p, 'coloradjust', {sat: 1.2, bright: 0.03, hue: -8});
				mk(p, 'glow', {mode: 1, color: 'FF8844', rad: 10, int: 0.6, thr: 0.4});
			case 'Dissolve Out':
				mk(p, 'dissolve', {th: 0.0, scale: 14, ew: 0.08, ecol: 'FF7A00', ep: 3}, 1.0, null, ['th', 2, 0.25, 0.5, 0.25]);
			case 'Comic':
				mk(p, 'posterize', {lv: 6});
				mk(p, 'halftone', {size: 6, ang: 45, mode: 1, soft: 0.15}, 0.85);
				mk(p, 'outline', {color: '111111', thick: 2, pos: 0});
			case 'Old Film':
				mk(p, 'shake', {amp: 0.0025, speed: 12});
				mk(p, 'sepia', null, 0.9);
				mk(p, 'coloradjust', {contrast: 1.1}, 1.0, null, ['bright', 5, 1, 0.06]);
				mk(p, 'grain', {amt: 0.18, fps: 18});
				mk(p, 'vignette', {color: '000000', rad: 0.65, soft: 0.6}, 0.8);
			case 'Vaporwave':
				mk(p, 'chroma', {amt: 3});
				mk(p, 'gradover', {ca: 'FF71CE', cb: '01CDFE', ang: 90, blend: 4}, 0.9);
				mk(p, 'scanlines', {dens: 90, int: 0.25});
				mk(p, 'rainbow', {scale: 0.6, speed: 0.1, sat: 0.6, blend: 5}, 0.35);
			case 'Toon + Ink':
				mk(p, 'toon', {steps: 3, smooth: 0.06});
				mk(p, 'outline', {color: '000000', thick: 2, pos: 0});
				mk(p, 'rim', {ca: 'FFFFFF', cb: 'FFFFFF', size: 7, ang: 300, bright: 0.8});
			case 'Shine':
				mk(p, 'coloradjust', {sat: 1.15, contrast: 1.05});
				mk(p, 'rim', {ca: 'FFE08A', cb: 'FFB300', grad: 0.6, size: 9, ang: 300, bright: 1.4});
				mk(p, 'shine', {color: 'FFFFFF', ang: 30, width: 0.14, speed: 0.5, gap: 1.2, int: 1.2});
			case 'Beat Pulse':
				mk(p, 'transform', {zx: 1.0, zy: 1.0}, 1.0, null, ['zx', 6, 1, 0.06]);
				mk(p, 'flash', {color: 'FFFFFF', pow: 3, int: 0.5});
				mk(p, 'chroma', {amt: 0}, 1.0, null, ['amt', 6, 1, 5]);
			case 'Pixel':
				mk(p, 'pixelate', {size: 4});
				mk(p, 'posterize', {lv: 16});
				mk(p, 'dither', {lv: 8, str: 0.6, size: 1}, 0.7);
			case 'Ghost Echo':
				mk(p, 'echo', {ox: 14, oy: 0, fade: 0.6, int: 0.7, tint: '9DB8FF', copies: 2}, 1.0, null, ['ox', 1, 1.2, 8]);
				mk(p, 'alpha', {mult: 0.9, pow: 1});
			case 'Blur':
				mk(p, 'blur', {rad: 3, quality: 1});
				mk(p, 'glow', {mode: 1, color: 'FFFFFF', rad: 16, int: 0.9, thr: 0.35});
				mk(p, 'coloradjust', {sat: 1.15, bright: 0.04, contrast: 0.95});
				mk(p, 'vignette', {color: 'FFD6F5', rad: 0.7, soft: 0.8}, 0.4);
			default:
		}
	}
}
