package main

import "core:os"
import "core:fmt"
import "core:math"

main :: proc() {
    spheres := make([dynamic]Sphere)
    defer delete(spheres)
    ivory := Material{vec3{0.6, 0.3, 0.1}, vec3{0.4, 0.4, 0.3}, 50}
    red_rubber := Material{vec3{0.9, 0.1, 0}, vec3{0.3, 0.1, 0.1}, 10}
    mirror := Material{vec3{0, 10, 0.8}, vec3{1, 1, 1}, 1425}
    append(&spheres, Sphere{vec3{-3, 0, -16} , 2, ivory})
    append(&spheres, Sphere{vec3{-1, -1.5, -12}, 2, mirror})
    append(&spheres, Sphere{vec3{1.5, -0.5, -18}, 3, red_rubber})
    append(&spheres, Sphere{vec3{7, 5, -18}, 4, mirror})

    lights := make([dynamic]Light)
    defer delete(lights)
    append(&lights, Light{vec3{-20, 20, 20}, 1.5})
    append(&lights, Light{vec3{30, 50, -25}, 1.8})
    append(&lights, Light{vec3{30, 20, 30}, 1.7})

    render(spheres[:], lights[:])
}

Material :: struct {
    albedo: vec3,
    diffuse_color: vec3,
    specular_exponent: f32,
}

Sphere :: struct {
    center: vec3,
    radius: f32,
    material: Material,
}

Light  :: struct {
    position: vec3,
    intensity: f32,
}

render :: proc(spheres: []Sphere, lights: []Light) {
    width :: 1024
    height :: 768
    fov :: math.PI / 3
    frame_buffer := make([]vec3, width * height)
    defer delete(frame_buffer)

    for j in 0..<height {
        for i in 0..<width {
            x: f32 = (2 * ((f32(i) + 0.5)/width) - 1) * math.tan_f32(fov/2) * width/height
            y: f32 = -(2 * ((f32(j)+ 0.5)/height) - 1) * math.tan_f32(fov/2)
            dir := normalize_vec3(vec3{x, y, -1})
            frame_buffer[i + (j * width)] = cast_ray(spheres, vec3{0, 0, 0}, dir, lights)
        }
    }
 
    file, _ := os.open("out.ppm", os.O_RDWR|os.O_CREATE|os.O_TRUNC)
    defer os.close(file)
    fmt.fprintf(file, "P6\n%v %v\n255\n",width, height)

    data := make([]u8, 3 * width * height)
    for i in 0..<len(frame_buffer) {
        max_v := max(frame_buffer[i][0], max(frame_buffer[i][1], frame_buffer[i][2]))
        if max_v > 1 {frame_buffer[i] = frame_buffer[i] * (1/max_v)}
        data[i * 3] = u8(255 * frame_buffer[i].r)
        data[(i * 3) + 1] = u8(255 * frame_buffer[i].g)
        data[(i * 3) + 2] = u8(255 * frame_buffer[i].b)
    }
    defer delete(data)
    os.write(file, data)
}


cast_ray :: proc(spheres: []Sphere, orig: vec3, dir: vec3, lights: []Light, depth: u32 = 0) -> vec3 {
    point: vec3
    N: vec3
    material: Material
    if depth > 4 || !scene_intersect(spheres, orig, dir, &point, &N, &material) {
        return vec3{0.2, 0.7, 0.8} // background color
    }
    reflect_dir := normalize_vec3(reflect(dir, N))
    reflect_orig := dot_vec3(reflect_dir, N) < 0 ? point - (N * 1e-3) : point + (N * 1e-3)
    reflect_color := cast_ray(spheres, reflect_orig, reflect_dir, lights, depth + 1)

    diffuse_light_intensity: f32 = 0
    specular_light_intensity: f32 = 0   
    for light in lights {
        light_dir := normalize_vec3(light.position - point)
        light_distance := norm_vec3(light.position - point)
        sh_orig := dot_vec3(light_dir, N) < 0 ? N * 1e-3 : point + (N * 1e-3)
        sh_point, sh_N: vec3
        t_material: Material
        if  (scene_intersect(spheres, sh_orig, light_dir, &sh_point, &sh_N, &t_material)) &&
            (norm_vec3(sh_point - sh_orig) < light_distance) { continue }
        
        diffuse_light_intensity += light.intensity * max(0, dot_vec3(light_dir, N))
        specular_light_intensity +=
            math.pow_f32(max(0, -dot_vec3(reflect(-light_dir, N), dir)),
            material.specular_exponent) * 
            light.intensity
    }
    return  (material.diffuse_color * diffuse_light_intensity * material.albedo[0]) +
            (vec3{1, 1, 1} * specular_light_intensity * material.albedo[1]) +
            (reflect_color * material.albedo[2])
}

scene_intersect :: proc(
    spheres: []Sphere, orig, dir: vec3, hit, N: ^vec3, material: ^Material,
) -> bool {
    sphere_dist: f32 = math.F32_MAX
    for &sphere in spheres {
        dist_i: f32
        if sphere_ray_intersect(&sphere, orig, dir, &dist_i) && (dist_i < sphere_dist) {
            sphere_dist = dist_i
            hit^ = orig + (dir * dist_i)
            N^ = normalize_vec3(hit^ - sphere.center)
            material^ = sphere.material
        }
    }
    return sphere_dist < 1000
}

sphere_ray_intersect :: proc(sphere: ^Sphere, orig: vec3, dir: vec3, t0: ^f32) -> bool {
    L := sphere.center - orig
    tca := dot_vec3(L, dir)
    d2 := dot_vec3(L, L) - (tca *tca)
    if d2 > (sphere.radius * sphere.radius) { return false}
    thc := math.sqrt_f32((sphere.radius * sphere.radius) - d2)
    t0^ = tca - thc
    t1 := tca + thc
    if t0^ < 0 { t0^ = t1}
    if t0^ < 0 {return false}
    return true
}

reflect :: proc(I: vec3, N: vec3) -> vec3 {
    return I - (N * 2 * dot_vec3(I, N))
}