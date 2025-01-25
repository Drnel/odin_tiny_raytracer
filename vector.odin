package main

import "core:math"

vec2 :: [2]f32
vec3 :: [3]f32

normalize_vec3 :: proc(vec: vec3) -> vec3 {
    return vec * (1 / norm_vec3(vec))
}

dot_vec3 :: proc(a: vec3,b: vec3) -> f32 {
    return ((a.x * b.x) + (a.y * b.y) + (a.z * b.z))
}

norm_vec3 :: proc(vec: vec3) -> f32 {
    return math.sqrt_f32(dot_vec3(vec, vec))
}