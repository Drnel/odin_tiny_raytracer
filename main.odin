package main

import "core:os"
import "core:fmt"

main :: proc() {
    render()
}

render :: proc() {
    width :: 1024
    height :: 768
    vec3 :: [3]f32
    frame_buffer := make([]vec3, width * height)
    defer delete(frame_buffer)

    for j in 0..<height {
        for i in 0..<width {
            frame_buffer[i + (j * width)] = vec3{f32(j)/height, f32(i)/width, 0}
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