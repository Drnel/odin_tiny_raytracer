package main

import "core:os"
import "core:fmt"
import "core:math"

main :: proc() {
    spheres := make([dynamic]Sphere)
    defer delete(spheres)
    ivory := Material{vec3f{0.4, 0.4, 0.3}}
    red_rubber := Material{vec3f{0.3, 0.1, 0.1}}
    append(&spheres, Sphere{vec3f{-3, 0, -16} , 2, ivory})
    append(&spheres, Sphere{vec3f{-1, -1.5, -12}, 2, red_rubber})
    append(&spheres, Sphere{vec3f{1.5, -0.5, -18}, 3, red_rubber})
    append(&spheres, Sphere{vec3f{7, 5, -18}, 4, ivory})

    lights := make([dynamic]Light)
    defer delete(lights)
    append(&lights, Light{vec3f{-20, 20, 20}, 1.5})

    render(spheres[:], lights[:])
}

Material :: struct {
    diffuse_color: vec3f
}

Sphere :: struct {
    center: vec3f,
    radius: f32,
    material: Material,
}

Light  :: struct {
    position: vec3f,
    intensity: f32,
}

render :: proc(spheres: []Sphere, lights: []Light) {
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
            frame_buffer[i + (j * width)] = cast_ray(spheres, vec3f{0, 0, 0}, dir, lights)
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


cast_ray :: proc(spheres: []Sphere, orig: vec3f, dir: vec3f, lights: []Light) -> vec3f {
    point: vec3f
    N: vec3f
    material: Material
    if !scene_intersect(spheres, orig, dir, &point, &N, &material) {
        return vec3f{0.2, 0.7, 0.8} // background color
    }
    diffuse_light_intensity: f32 = 0
    for light in lights {
        light_dir := normalize_vec3f(light.position - point)
        diffuse_light_intensity += light.intensity * max(0, dot_vec3f(light_dir, N))
    }
    return material.diffuse_color * diffuse_light_intensity
}

scene_intersect :: proc(
    spheres: []Sphere, orig, dir: vec3f, hit, N: ^vec3f, material: ^Material,
) -> bool {
    sphere_dist: f32 = math.F32_MAX
    for &sphere in spheres {
        dist_i: f32
        if sphere_ray_intersect(&sphere, orig, dir, &dist_i) && (dist_i < sphere_dist) {
            sphere_dist = dist_i
            hit^ = orig + (dir * dist_i)
            N^ = normalize_vec3f(hit^ - sphere.center)
            material^ = sphere.material
        }
    }
    return sphere_dist < 1000
}

sphere_ray_intersect :: proc(sphere: ^Sphere, orig: vec3f, dir: vec3f, t0: ^f32) -> bool {
    L := sphere.center - orig
    tca := dot_vec3f(L, dir)
    d2 := dot_vec3f(L, L) - (tca *tca)
    if d2 > (sphere.radius * sphere.radius) { return false}
    thc := math.sqrt_f32((sphere.radius * sphere.radius) - d2)
    t0^ = tca - thc
    t1 := tca + thc
    if t0^ < 0 { t0^ = t1}
    if t0^ < 0 {return false}
    return true
}