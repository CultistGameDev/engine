package main

import "core:c"
import "core:fmt"

import shader "engine/shader"

import "vendor:glfw"
import vk "vendor:vulkan"

ENGINE_NAME: string : "Engine"
ENGINE_MAJOR_VERSION: int : 0
ENGINE_MINOR_VERSION: int : 1

Context :: struct {
	window:   glfw.WindowHandle,
	instance: vk.Instance,
}

window_width: i32 = 800
window_height: i32 = 600

main :: proc() {
	fmt.printfln("Hello %s!", ENGINE_NAME)

	using ctx: Context
	initWindow(&ctx)

	initVulkan(&ctx)
	mainLoop(&ctx)
	cleanup(&ctx)
}

initWindow :: proc(using ctx: ^Context) {
	if (glfw.Init() != glfw.TRUE) {
		fmt.println("Failed to initialise GLFW")
		return
	}

	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)
	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)

	window = glfw.CreateWindow(window_width, window_height, cstring(ENGINE_NAME), nil, nil)
	if window == nil {
		fmt.println("Unable to create window")
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	glfw.SetKeyCallback(window, inputCallback)
}

initVulkan :: proc(using ctx: ^Context) {
	get_proc_address :: proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetInstanceProcAddress((^vk.Instance)(context.user_ptr)^, name)
	}
	context.user_ptr = &instance
	vk.load_proc_addresses(get_proc_address)
	createInstance(ctx)
}

createInstance :: proc(using ctx: ^Context) {
	appInfo: vk.ApplicationInfo
	appInfo.sType = .APPLICATION_INFO
	appInfo.pApplicationName = cstring(ENGINE_NAME)
	appInfo.applicationVersion = vk.MAKE_VERSION(
		u32(ENGINE_MAJOR_VERSION),
		u32(ENGINE_MINOR_VERSION),
		0,
	)
	appInfo.pEngineName = cstring(ENGINE_NAME)
	appInfo.engineVersion = vk.MAKE_VERSION(
		u32(ENGINE_MAJOR_VERSION),
		u32(ENGINE_MINOR_VERSION),
		0,
	)
	appInfo.apiVersion = vk.API_VERSION_1_0

	glfwExtensions := glfw.GetRequiredInstanceExtensions()

	createInfo := vk.InstanceCreateInfo{}
	createInfo.sType = .INSTANCE_CREATE_INFO
	createInfo.pApplicationInfo = &appInfo
	createInfo.enabledExtensionCount = cast(u32)len(glfwExtensions)
	createInfo.ppEnabledExtensionNames = raw_data(glfwExtensions)
	createInfo.enabledLayerCount = 0

	if vk.CreateInstance(&createInfo, nil, &instance) != .SUCCESS {
		fmt.println("Failed to create instance")
	}
}

mainLoop :: proc(using ctx: ^Context) {
	for (!glfw.WindowShouldClose(window)) {
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

cleanup :: proc(using ctx: ^Context) {
	vk.DestroyInstance(instance, nil)

	glfw.DestroyWindow(window)
	glfw.Terminate()
}

inputCallback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		glfw.SetWindowShouldClose(window, true)
	}
}
