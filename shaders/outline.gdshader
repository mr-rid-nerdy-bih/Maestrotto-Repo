shader_type canvas_item;
// Draws a solid outline around the opaque pixels of one sprite frame.
// The quad is grown by `width` pixels so the outline can extend past the
// frame's edge, and samples outside the current frame count as transparent
// so neighbouring frames on the sprite sheet don't bleed in.

uniform vec4 outlineColor : source_color = vec4(1.0);
uniform float width = 1.0;
// Current frame on the sheet in UV space: x, y, w, h. Set by VisualComponent.
uniform vec4 frameRect = vec4(0.0, 0.0, 1.0, 1.0);
// Sprite2D.flip_h mirrors the UVs, so the quad has to grow the other way.
uniform bool flipH = false;

varying vec4 vertexColor;

void vertex() {
	vertexColor = COLOR;
	vec2 inFrame = (UV - frameRect.xy) / frameRect.zw; // 0..1 across the frame
	vec2 corner = sign(inFrame - 0.5);
	vec2 grow = corner;
	if (flipH) {
		grow.x = -grow.x;
	}
	VERTEX += grow * width;
	UV += corner * width * TEXTURE_PIXEL_SIZE;
}

bool in_frame(vec2 uv) {
	return uv.x > frameRect.x && uv.y > frameRect.y
		&& uv.x < frameRect.x + frameRect.z && uv.y < frameRect.y + frameRect.w;
}

void fragment() {
	vec4 col = in_frame(UV) ? texture(TEXTURE, UV) : vec4(0.0);
	if (col.a < 0.1) {
		// Outline pixel = transparent pixel with an opaque neighbour.
		// (TEXTURE can't be passed to helper functions, so this is inlined.)
		vec2 step = TEXTURE_PIXEL_SIZE * width;
		vec2 offsets[4] = vec2[](vec2(step.x, 0.0), vec2(-step.x, 0.0), vec2(0.0, step.y), vec2(0.0, -step.y));
		float neighbour = 0.0;
		for (int i = 0; i < 4; i++) {
			vec2 uv = UV + offsets[i];
			if (in_frame(uv)) {
				neighbour = max(neighbour, texture(TEXTURE, uv).a);
			}
		}
		if (neighbour > 0.1) {
			col = outlineColor;
		}
	}
	COLOR = col * vertexColor;
}
