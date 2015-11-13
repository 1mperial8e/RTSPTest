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

attribute vec4 a_position;
attribute vec2 a_textureCoord;

uniform mat4 u_modelViewProjectionMatrix;

varying lowp vec2 v_texCoord;

void main()
{
    v_texCoord = vec2(a_textureCoord.s, 1.0 - a_textureCoord.t);//flip and mirror texture
    gl_Position = u_modelViewProjectionMatrix * a_position;
}