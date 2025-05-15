package blend_images

import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import "core:time"

import stbi "./vendor/stb/image"
import gl "vendor:OpenGL"
import SDL "vendor:sdl3"

Image :: struct {
	pixels:        []u8,
	width, height: i32,
}

load_img :: proc(filename: string, allocator := context.allocator) -> Image {
	f := strings.clone_to_cstring(filename, allocator)
	w, h: i32
	channels, rgb_alpha: i32 = 3, 4
	stbi.set_flip_vertically_on_load(1)
	pixels := stbi.load(f, &w, &h, &channels, rgb_alpha)
	return Image{pixels = slice.from_ptr(pixels, int(w * h * 4)), width = w, height = h}
}

gl_check_errors :: proc() {
	err := gl.GetError()
	for err != gl.NO_ERROR {
		switch err {
		case gl.INVALID_ENUM:
			fmt.eprintln("enumeration parameter is not a legal enumeration for that function")
		case gl.INVALID_VALUE:
			fmt.eprintln("value parameter is not a legal value for that function")
		case gl.INVALID_OPERATION:
			fmt.eprintln(
				"the set of state for a command is not legal for the parameters given to that command",
			)
		case gl.STACK_OVERFLOW:
			fmt.eprintln(
				"stack pushing operation cannot be done because it would overflow the limit of that stack's size",
			)
		case gl.STACK_UNDERFLOW:
			fmt.eprintln(
				"stack popping operation cannot be done because the stack is already at its lowest point",
			)
		case gl.OUT_OF_MEMORY:
			fmt.eprintln(
				"performing an operation that can allocate memory, and the memory cannot be allocated",
			)
		case gl.INVALID_FRAMEBUFFER_OPERATION:
			fmt.eprintln(
				"doing anything that would attempt to read from or write/render to a framebuffer that is not complete",
			)
		case gl.CONTEXT_LOST:
			fmt.eprintln("OpenGL context has been lost, due to a graphics card reset")
		}
		err := gl.GetError()
	}
}

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

main :: proc() {
	WINDOW_WIDTH :: 854
	WINDOW_HEIGHT :: 480

	assert(SDL.Init({.VIDEO}))
	defer SDL.Quit()

	window := SDL.CreateWindow("blend images", WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL, .RESIZABLE})
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GL_CONTEXT_PROFILE_CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DestroyContext(gl_context)

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vertex_src, fragment_src :=
		#load("shaders/shader.vert", string), #load("shaders/shader.frag", string)

	program, program_ok := gl.load_shaders_source(vertex_src, fragment_src)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	{
		img := load_img("monkeys.jpg")
		defer stbi.image_free(raw_data(img.pixels))
		gl.ActiveTexture(gl.TEXTURE0)
		texture: u32
		gl.GenTextures(1, &texture)
		gl.BindTexture(gl.TEXTURE_2D, texture)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGBA,
			img.width,
			img.height,
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			raw_data(img.pixels),
		)
	}

	gl_check_errors()

	// start_tick := time.tick_now()

	loop: for {
		// duration := time.tick_since(start_tick)
		// t := f32(time.duration_seconds(duration))

		event: SDL.Event
		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .KEY_DOWN:
				#partial switch event.key.scancode {
				case .ESCAPE:
					break loop
				}
			case .MOUSE_BUTTON_UP:
				released_pos: [2]f32
				_mouse_flags := SDL.GetMouseState(&released_pos[0], &released_pos[1])
				// screen:
				//    0
				// 0    854
				//   480
				//
				// opengl:
				//    1
				// -1 0 1
				//   -1
				remaped := [2]f32 {
					math.remap(released_pos.x, 0.0, WINDOW_WIDTH, -1.0, 1.0),
					math.remap(released_pos.y, 0.0, WINDOW_HEIGHT, 1.0, -1.0),
				}
				gl.Uniform2f(uniforms["mouse_pos"].location, remaped.x, remaped.y)
			case .QUIT:
				break loop
			}
		}

		{
			w, h: i32
			SDL.GetWindowSize(window, &w, &h)
			gl.Viewport(0, 0, w, h)
		}
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)

		SDL.GL_SwapWindow(window)
	}
}
