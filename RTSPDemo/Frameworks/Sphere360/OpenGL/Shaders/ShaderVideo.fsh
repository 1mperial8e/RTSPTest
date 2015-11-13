//  iOS 360° Player
//  Copyright (C) 2015  Giroptic
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

varying lowp vec2 v_texCoord;
precision mediump float;

uniform sampler2D SamplerUV;
uniform sampler2D SamplerY;
uniform mat3 colorConversionMatrix;

void main()
{
    mediump vec3 yuv;
	lowp vec3 rgb;
    
    // Subtract constants to map the video range start at 0
    yuv.x = (texture2D(SamplerY, v_texCoord).r - (16.0/255.0));
    yuv.yz = (texture2D(SamplerUV, v_texCoord).ra - vec2(0.5, 0.5));
    
    rgb =   yuv*colorConversionMatrix;
    
    gl_FragColor = vec4(rgb,1);
    
}
