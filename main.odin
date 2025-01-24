package main

import "core:os"
import "core:fmt"
import "core:math"

main :: proc() {
    sphere := Sphere{vec3f{-3, 0, -16}, 2}
    render(sphere)
}

Sphere :: struct {
    center: vec3f,
    radius: f32,
}

render :: proc(sphere: Sphere) {
    width :: 1024
    height :: 768
    fov :: math.PI / 3
    frame_buffer := make([]vec3f, width * height)
    defer delete(frame_buffer)

    for j in 0..<height {
        for i in 0..<width {
            x: f32 = (2 * ((f32(i) + 0.5)/width) - 1) * math.tan_f32(fov/2) * width/height
            y: f32 = -(2 * ((f32(j)+ 0.5)/height) - 1) * math.tan_f32(fov/2)
            dir := normalize_vec3f(vec3f{x, y, -1})
            frame_buffer[i + (j * width)] = cast_ray(sphere, vec3f{0, 0, 0}, dir)
        }
    }
 
    file, _ := os.open("out.ppm", os.O_RDWR|os.O_CREATE|os.O_TRUNC)
    defer os.close(file)
    fmt.fprintf(file, "P6\n%v %v\n255\n",width, height)

    data := make([]u8, 3 * width * height)
    for i in 0..<len(frame_buffer) {
        data[i * 3] = u8(255 * frame_buffer[i].r)
        data[(i * 3) + 1] = u8(255 * frame_buffer[i].g)
        data[(i * 3) + 2] = u8(255 * frame_buffer[i].b)
    }
    defer delete(data)
    os.write(file, data)
}

sphere_ray_intersect :: proc(sphere: Sphere, orig: vec3f, dir: vec3f) -> bool {
    L := sphere.center - orig
    tca := dot_vec3f(L, dir)
    d2 := dot_vec3f(L, L) - (tca *tca)
    if d2 > (sphere.radius * sphere.radius) { return false}
    thc := math.sqrt_f32((sphere.radius * sphere.radius) - d2)
    t0 := tca - thc
    t1 := tca + thc
    if t0 < 0 { t0 = t1}
    if t0 < 0 {return false}
    return true
}

cast_ray :: proc(sphere: Sphere, orig: vec3f, dir: vec3f) -> vec3f {
    if !sphere_ray_intersect(sphere, orig, dir) {
        return vec3f{0.2, 0.7, 0.8}
    }
    return vec3f{0.4, 0.4, 0.3}
}