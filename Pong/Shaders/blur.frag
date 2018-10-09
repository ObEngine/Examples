uniform sampler2D texture;
uniform float blur_radius;
uniform float intensity;
uniform float spread;

void main()
{
	vec2 offx = vec2(blur_radius, 0.0);
	vec2 offy = vec2(0.0, blur_radius);

	vec4 pixel = texture2D(texture, gl_TexCoord[0].xy * spread)                 * 4.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy - offx))        * spread * 2.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy + offx))        * spread * 2.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy - offy))        * spread * 2.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy + offy))        * spread * 2.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy - offx - offy)) * spread * 1.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy - offx + offy)) * spread * 1.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy + offx - offy)) * spread * 1.0 * intensity +
				 texture2D(texture, (gl_TexCoord[0].xy + offx + offy)) * spread * 1.0 * intensity;

	gl_FragColor =  gl_Color * (pixel / 16.0);
}