package main

import "core:math"

vec2f :: [2]f32
vec3f :: [3]f32

normalize_vec3f :: proc(vec: vec3f) -> (normalized_vec: vec3f) {
    normalized_vec = vec * (1 / math.sqrt_f32(dot_vec3f(vec, vec)))
    return
}

dot_vec3f :: proc(a: vec3f,b: vec3f) -> f32 {
    return ((a.x * b.x) + (a.y * b.y) + (a.z * b.z))
}