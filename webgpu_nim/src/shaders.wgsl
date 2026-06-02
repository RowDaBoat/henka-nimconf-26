/////////////////////////////////////////////////////////
// henka-nimconf-26  WebGPU + Jolt Cubes demo           //
// ISC License                                          //
// Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat //
//////////////////////////////////////////////////////////

struct Uniforms {
    aspect: f32,
    ambient: f32,
    lightView: vec4<f32>,
};
@group(0) @binding(0) var<uniform> u: Uniforms;

struct Instances {
    transform: array<mat4x4<f32>, 50>};
@group(0) @binding(1) var<uniform> instances: Instances;

struct VSIn {
    @location(0) position: vec4<f32>,
};

struct VSOut {
    @builtin(position)pos: vec4<f32>,
    @location(0) viewPos: vec3<f32>,
    @location(1) color: vec3<f32>,
};

const draculaLen = 12;
const dracula = array<vec3<f32>, draculaLen>(
    vec3(40.0, 42.0, 54.0) / 255.0,
    vec3(98.0, 114.0, 164.0) / 255.0,
    vec3(68.0, 71.0, 90.0) / 255.0,
    vec3(248.0, 248.0, 242.0) / 255.0,
    vec3(98.0, 114.0, 164.0) / 255.0,
    vec3(255.0, 85.0, 85.0) / 255.0,
    vec3(255.0, 184.0, 108.0) / 255.0,
    vec3(241.0, 250.0, 140.0) / 255.0,
    vec3(80.0, 250.0, 123.0) / 255.0,
    vec3(139.0, 233.0, 253.0) / 255.0,
    vec3(189.0, 147.0, 249.0) / 255.0,
    vec3(255.0, 121.0, 198.0) / 255.0,
);

@vertex
fn vs_main(in: VSIn, @builtin(instance_index) instanceIndex: u32) -> VSOut {
    let world = instances.transform[instanceIndex] * in.position;
    let viewPos = vec3<f32>(world.x, world.y, world.z - 10.0);

    // Right-handed perspective mapping depth to [0, 1] (WebGPU convention)
    let f = 1.0 / tan(1.0 * 0.5); // matches fovY
    let near = 0.1;
    let far = 100.0;
    let nf = 1.0 / (near - far);
    let proj = mat4x4<f32>(
        f / u.aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, far * nf, -1.0,
        0.0, 0.0, far * near * nf, 0.0,
    );

    var out: VSOut;
    out.pos = proj * vec4<f32>(viewPos, 1.0);
    out.viewPos = viewPos;
    out.color = dracula[instanceIndex % draculaLen];

    return out;
}

fn faceforward(N: vec3<f32>, I: vec3<f32>, Nref: vec3<f32>) -> vec3<f32> {
    if dot(Nref, I) < 0.0 {
        return N;
    } else {
        return -N;
    }
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
    var n = normalize(cross(dpdx(in.viewPos), dpdy(in.viewPos)));
    let V = normalize(- in.viewPos);
    n = faceforward(n, -V, n);

    // Point light with distance attenuation
    let toLight = u.lightView.xyz - in.viewPos;
    let dist = length(toLight);
    let L = toLight / dist;
    let diff = max(dot(n, L), 0.0);
    let atten = 1.0 / (1.0 + 0.0125 * dist * dist);

    let H = normalize(L + V);
    let shininess = 64.0;
    let spec = pow(max(dot(n, H), 0.0), shininess);
    let albedo = in.color;

    let diffuseTerm = diff * atten;
    let specularTerm = 2.0 * spec * atten;

    let ambientTerm = u.ambient;

    let color = albedo * (ambientTerm + diffuseTerm + 0.2 * specularTerm);
    return vec4<f32>(color, 1.0);
}
