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

	for (!glfw.WindowShouldClose(window)) {
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
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
