package main

import "core:c"
import "core:fmt"
import "core:os"

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

VALIDATION_LAYERS := [?]cstring{"VK_LAYER_KHRONOS_validation"}

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

	when ODIN_DEBUG {
		layerCount: u32
		vk.EnumerateInstanceLayerProperties(&layerCount, nil)
		layers := make([]vk.LayerProperties, layerCount)
		vk.EnumerateInstanceLayerProperties(&layerCount, raw_data(layers))

		outer: for name in VALIDATION_LAYERS {
			for layer in layers {
				if name == cstring(&layer.layerName[0]) do continue outer
			}
			fmt.eprintfln("ERROR: Validation layer %1 not available", name)
			os.exit(1)
		}

		createInfo.ppEnabledLayerNames = &VALIDATION_LAYERS[0]
		createInfo.enabledLayerCount = len(VALIDATION_LAYERS)
		fmt.println("Validation Layers Loaded")
	} else {
		createInfo.enabledLayerCount = 0
	}
	if vk.CreateInstance(&createInfo, nil, &instance) != .SUCCESS {
		fmt.println("Failed to create instance")
		return
	}

	fmt.println("Instance Created")
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
