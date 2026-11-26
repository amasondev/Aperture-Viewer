/**
 * @file luminanceF.glsl
 *
 * $LicenseInfo:firstyear=2023&license=viewerlgpl$
 * Second Life Viewer Source Code
 * Copyright (C) 2023, Linden Research, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 2.1 of the License only.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Linden Research, Inc., 945 Battery Street, San Francisco, CA  94111  USA
 * $/LicenseInfo$
 */


/*[EXTRA_CODE_HERE]*/

// take a luminance sample of diffuseRect and emissiveRect

out vec4 frag_color;

in vec2 vary_fragcoord;

uniform sampler2D diffuseRect;
uniform sampler2D emissiveRect;
uniform sampler2D normalMap;
uniform float diffuse_luminance_scale;

float lum(vec3 col)
{
    vec3 l = vec3(0.2126, 0.7152, 0.0722);
    return dot(l, col);
}

#ifdef LUMINANCE_DOWNSAMPLE
// Downsample 256x256 luminance map to 16x16 using an 8x8 grid of bilinear taps
// (each bilinear tap averages a 2x2 block of texels -> exact 16x16 box filter).
void main()
{
    vec2 texel = 1.0 / vec2(textureSize(diffuseRect, 0));
    float sum = 0.0;
    for (int y = 0; y < 8; ++y)
    {
        float oy = (float(y) * 2.0 - 7.0) * texel.y;
        for (int x = 0; x < 8; ++x)
        {
            float ox = (float(x) * 2.0 - 7.0) * texel.x;
            sum += texture(diffuseRect, vary_fragcoord + vec2(ox, oy)).r;
        }
    }
    frag_color = vec4(sum * (1.0 / 64.0));
}
#else
void main()
{
    vec2 tc = vary_fragcoord*0.6+0.2;
    tc.y -= 0.1; // HACK - nudge exposure sample down a little bit to favor ground over sky
    vec3 c = texture(diffuseRect, tc).rgb;

    vec4  norm         = texture(normalMap, tc);

    if (!GET_GBUFFER_FLAG(norm.w, GBUFFER_FLAG_HAS_HDRI) &&
        !GET_GBUFFER_FLAG(norm.w, GBUFFER_FLAG_SKIP_ATMOS))
    {
        // Apply the diffuse luminance scale to objects but not the sky
        // Prevents underexposing when looking at bright environments
        // while still allowing for realistically bright skies.
        c *= diffuse_luminance_scale;
    }

    c += texture(emissiveRect, tc).rgb;

    float L = lum(c);
    frag_color = vec4(max(L, 0.0));
}
#endif

