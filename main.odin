package main

import "core:c"
import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:glfw"

ENGINE_NAME: string : "Engine"
ENGINE_MAJOR_VERSION: int : 0
ENGINE_MINOR_VERSION: int : 1

GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION: c.int : 0

verticies := [?]f32 {
	// A
	-0.5,
	-0.5,
	0.0,
	// B
	0.5,
	-0.5,
	0.0,
	// C
	0.0,
	0.5,
	0.0,
}

VERTEX_SHADER: cstring = `#version 400 core
layout (location = 0) in vec3 aPos;

void main()  {
  gl_Position = vec4(aPos, 1.0);
}`


FRAGMENT_SHADER: cstring = `#version 400 core
out vec4 FragColor;

void main() {
  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}`


window_width: i32 = 800
window_height: i32 = 600

main :: proc() {
	fmt.printfln("Hello %s!", ENGINE_NAME)

	if (glfw.Init() != glfw.TRUE) {
		fmt.println("Failed to initialise GLFW")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window: glfw.WindowHandle = glfw.CreateWindow(800, 600, cstring(ENGINE_NAME), nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		fmt.println("Unable to create window")
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	glfw.SetKeyCallback(window, input_callback)
	glfw.SetFramebufferSizeCallback(window, framebuffer_resize)

	gl.load_up_to(int(GL_MAJOR_VERSION), int(GL_MINOR_VERSION), glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)


	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verticies), cast(rawptr)&verticies, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), cast(uintptr)0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	program := compile_program(&VERTEX_SHADER, &FRAGMENT_SHADER)

	for (!glfw.WindowShouldClose(window)) {
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(program)
		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

compile_program :: proc(vert, frag: ^cstring) -> u32 {
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

input_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		glfw.SetWindowShouldClose(window, true)
	}
}

framebuffer_resize :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	window_width = width
	window_height = height
	gl.Viewport(0, 0, window_width, window_height)
}
