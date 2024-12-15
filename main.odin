package main

import "core:fmt"
import "vendor:glfw"
import vk "vendor:vulkan"

main :: proc() {
	fmt.println("Hello World!")

	if (glfw.Init() != glfw.TRUE) {
		fmt.println("Failed to initialise GLFW")
		return
	}

	glfw.WindowHint(glfw.RESIZABLE, 0)
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)

	window: glfw.WindowHandle = glfw.CreateWindow(800, 600, "Vulkan Window", nil, nil)

	if window == nil {
		fmt.println("Unable to create window")
		return
	}

	vk.load_proc_addresses((rawptr)(glfw.GetInstanceProcAddress))

	extensionCount: u32
	vk.EnumerateInstanceExtensionProperties(nil, &extensionCount, nil)
	fmt.printfln("%d extensions supported", extensionCount)

	running := true

	for (!glfw.WindowShouldClose(window)) {
		glfw.PollEvents()
	}

	glfw.DestroyWindow(window)
	glfw.Terminate()
}
