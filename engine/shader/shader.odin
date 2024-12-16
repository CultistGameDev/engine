package engine

import "core:fmt"

import gl "vendor:OpenGL"

Program :: u32
Shader :: u32

CompileProgram :: proc(vert, frag: ^cstring) -> Program {
	vertShader := compile_shader(vert, gl.VERTEX_SHADER)
	fragShader := compile_shader(frag, gl.FRAGMENT_SHADER)

	program := gl.CreateProgram()
	gl.AttachShader(program, vertShader)
	gl.AttachShader(program, fragShader)
	gl.LinkProgram(program)

	{
		success: i32
		gl.GetProgramiv(program, gl.LINK_STATUS, &success)
		if success == 0 {
			infoLog := make([^]u8, 512)
			gl.GetProgramInfoLog(program, 512, nil, infoLog)
			fmt.printfln("Error Program: %s", cstring(infoLog))
		}
	}

	return program
}

compile_shader :: proc(source: ^cstring, t: u32) -> u32 {
	shader := gl.CreateShader(t)
	gl.ShaderSource(shader, 1, source, nil)
	gl.CompileShader(shader)

	{
		success: i32
		gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
		if success == 0 {
			infoLog := make([^]u8, 512)
			gl.GetShaderInfoLog(shader, 512, nil, infoLog)

			shaderType: string
			if t == gl.VERTEX_SHADER {
				shaderType = "Vertex"
			} else {
				shaderType = "Fragment"
			}

			fmt.printfln("Error (%s Shader): %s", shaderType, cstring(infoLog))
		}
	}
	return shader
}
