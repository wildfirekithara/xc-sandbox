use expanduser::expanduser;
use serde::{Deserialize, Serialize};
use std::env;
use xc3_lib::{bc, sar1, hash::murmur3};
use xc3_model::animation::Animation;

const DEBUG_DIR: &str = "./debug";


#[derive(Serialize, Deserialize)]
struct Vector2 {
    x: f32,
    y: f32,
}

#[derive(Serialize, Deserialize)]
struct Vector3 {
    x: f32,
    y: f32,
    z: f32,
}

#[derive(Serialize, Deserialize)]
struct Quat {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
}

#[derive(Serialize, Deserialize)]
struct RenderedAnimationCurve {
    property: String,
    keyframes: Vec<f32>,
    keyframes2: Vec<Vector2>,
    keyframes3: Vec<Vector3>,
    keyframes4: Vec<Quat>,
}

#[derive(Serialize, Deserialize)]
struct RenderedAnimation {
    length: f32,
    fps: f32,
    curves: Vec<RenderedAnimationCurve>,
}


#[derive(Serialize, Deserialize)]
struct BoneState {
    name: String,
    translation: Vector3,
    rotation: Quat,
    scale: Vector3,
}

#[derive(Serialize, Deserialize)]
struct BaseSkeleton {
    bones: Vec<BoneState>,
}

fn write_bytes_to_file(bytes: &[u8], filename: &str, sar_dir: &str) {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;
    std::fs::create_dir_all(sar_dir).unwrap();
    let path = Path::new(sar_dir).join(filename);
    let mut file = File::create(path).unwrap();
    file.write_all(bytes).unwrap();
}

fn write_json_to_file(json: &serde_json::Value, filename: &str, json_dir: &str) {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;
    std::fs::create_dir_all(json_dir).unwrap();
    let path = Path::new(json_dir).join(filename);
    let mut file = File::create(path).unwrap();
    file.write_all(json.to_string().as_bytes()).unwrap();
}

fn handle_bc(filename: &str, model: &xc3_model::ModelRoot, json_dir: &str) {
    let bcf = bc::Bc::from_file(filename).unwrap();
    let anim = match bcf.data {
        bc::BcData::Anim(ref anim) => anim,
        _ => panic!("Not an animation file"),
    };
    handle_anim(filename, anim, model, json_dir);
}

fn handle_bc_bytes(filename: &str, bytes: &[u8], model: &xc3_model::ModelRoot, json_dir: &str) {
    let bcf = bc::Bc::from_bytes(bytes).unwrap();
    let anim = match bcf.data {
        bc::BcData::Anim(ref anim) => anim,
        _ => panic!("Not an animation file"),
    };
    handle_anim(filename, anim, model, json_dir);
}

fn handle_anim(filename: &str, anim: &bc::Anim, model: &xc3_model::ModelRoot, json_dir: &str) {
    let animation = Animation::from_anim(anim);
    // num tracks
    println!("  - Animation file");
    println!("  - frames: {}", animation.frame_count);
    println!("  - tracks: {}", animation.tracks.len());
    let mut rendered_animation = RenderedAnimation {
        length: animation.frame_count as f32 / 30.0,
        fps: 30.0,
        curves: Vec::new(),
    };

    let base_filename = filename.split('/').last().unwrap();

    for track in animation.tracks {
        let mut bone_index = -1;

        if let Some(id) = track.bone_index {
            bone_index = id as i32;
        }

        if let Some(ref hash) = track.bone_hash {
            for (i, bone) in model.groups[0].models[0].skeleton.as_ref().unwrap().bones.iter().enumerate() {
                let ha = murmur3(bone.name.as_bytes());
                if ha == *hash {
                    bone_index = i as i32;
                    break;
                }
            }
        }

    
        if bone_index != -1 {
            let bone = &model.groups[0].models[0].skeleton.as_ref().unwrap().bones[bone_index as usize];
            println!("     - {} ({})", bone.name, bone_index);
            println!(
                "       - translation keyframes: {}",
                track.translation_keyframes.len()
            );
            println!(
                "       - rotation keyframes: {}",
                track.rotation_keyframes.len()
            );
            println!("       - scale keyframes: {}", track.scale_keyframes.len());

            let mut curve_translate = RenderedAnimationCurve {
                property: format!("{}.translation", bone.name),
                keyframes: Vec::new(),
                keyframes2: Vec::new(),
                keyframes3: Vec::new(),
                keyframes4: Vec::new(),
            };

            let mut curve_rotate = RenderedAnimationCurve {
                property: format!("{}.rotation", bone.name),
                keyframes: Vec::new(),
                keyframes2: Vec::new(),
                keyframes3: Vec::new(),
                keyframes4: Vec::new(),
            };

            let mut curve_scale = RenderedAnimationCurve {
                property: format!("{}.scale", bone.name),
                keyframes: Vec::new(),
                keyframes2: Vec::new(),
                keyframes3: Vec::new(),
                keyframes4: Vec::new(),
            };

            for i in 0..animation.frame_count {
                let sample_translate = track.sample_translation(i as f32);
                let sample_rotate = track.sample_rotation(i as f32);
                let sample_scale = track.sample_scale(i as f32);

                curve_translate.keyframes3.push(Vector3 {
                    x: sample_translate.x,
                    y: sample_translate.y,
                    z: sample_translate.z,
                });

                curve_rotate.keyframes4.push(Quat {
                    x: sample_rotate.x,
                    y: sample_rotate.y,
                    z: sample_rotate.z,
                    w: sample_rotate.w,
                });

                curve_scale.keyframes3.push(Vector3 {
                    x: sample_scale.x,
                    y: sample_scale.y,
                    z: sample_scale.z,
                });
            }

            if track.translation_keyframes.len()  > 1 || (curve_translate.keyframes3[0].x != 0.0 && curve_translate.keyframes3[0].y != 0.0 && curve_translate.keyframes3[0].z != 0.0) {
                rendered_animation.curves.push(curve_translate);
            }
            // if track.rotation_keyframes.len() > 1 || (curve_rotate.keyframes3[0].x != 0.0 && curve_rotate.keyframes3[0].y != 0.0 && curve_rotate.keyframes3[0].z != 0.0) {
            rendered_animation.curves.push(curve_rotate);
            // }
            if track.scale_keyframes.len() > 1 || (curve_scale.keyframes3[0].x != 1.0 && curve_scale.keyframes3[0].y != 1.0 && curve_scale.keyframes3[0].z != 1.0) {
                rendered_animation.curves.push(curve_scale);
            }
        }
        let json = serde_json::to_value(&rendered_animation).unwrap();

        write_json_to_file(&json, format!("{}.json", base_filename).as_str(), json_dir);
    }
}

fn handle_sar(filename: &str, model: &xc3_model::ModelRoot, json_dir: &str) {
    let sar = sar1::Sar1::from_file(filename).unwrap();
    println!("- Archive file");
    // num files
    println!("- items: {}", sar.entries.len());
    for entry in sar.entries {
        println!("  - {}", entry.name);
        write_bytes_to_file(&entry.entry_data, &entry.name, DEBUG_DIR);
        match entry.name.split('.').last() {
            Some(ext) => match ext {
                "anm" => handle_bc_bytes(&entry.name, &entry.entry_data, model, json_dir),
                _ => {
                    println!("Unknown file extension {}", ext);
                }
            },
            None => (),
        }
    }
}

fn dump_sar(filename: &str, sar_dir: &str) {
    let sar = sar1::Sar1::from_file(filename).unwrap();
    println!("- Archive file");
    // num files
    println!("- items: {}", sar.entries.len());
    for entry in sar.entries {
        println!("  - {}", entry.name);
        write_bytes_to_file(&entry.entry_data, &entry.name, sar_dir);
    }
}


fn main() {
    let shader_db_path = expanduser("~/code/ntw/fcam/data/bf2/xc2.json")
        .unwrap()
        .display()
        .to_string();

    let args: Vec<_> = env::args().collect();

    if args.len() == 3 {
        dump_sar(&args[1], &args[2]);
        return;
    }


    if args.len() < 3 {
        println!("Usage: {} <INPUT_MODEL> <INPUT_ANIM> <JSON_OUT_DIR>", args[0]);
        return;
    }


    let json_dir = match args.len() {
        4 => args[3].clone(),
        _ => "./json".to_string(),
    };

    let shader_db = xc3_model::shader_database::ShaderDatabase::from_file(shader_db_path);

    println!("File: {}", args[1]);
    let model = match args[1].split('.').last() {
        Some(ext) => {
            match ext {
                "wimdo" => {
                    let model = xc3_model::load_model(&args[1], Some(&shader_db));

                    println!("- Model file");
                    println!("  - groups: {}", model.groups.len());
                    let mgroup = &model.groups[0];
                    println!("  - group models: {}", mgroup.models.len());
                    let m = &mgroup.models[0];
                    let skel = m.skeleton.as_ref().unwrap();
                    println!("  - skeleton bones: {}", skel.bones.len());

                    let mut base_skeleton = BaseSkeleton {
                        bones: Vec::new(),
                    };
                    for bone in &skel.bones {
                        let (s, r, t) = bone.transform.to_scale_rotation_translation();
                        base_skeleton.bones.push(BoneState {
                            name: bone.name.clone(),
                            translation: Vector3 {
                                x: t.x,
                                y: t.y,
                                z: t.z,
                            },
                            rotation: Quat {
                                x: r.x,
                                y: r.y,
                                z: r.z,
                                w: r.w,
                            },
                            scale: Vector3 {
                                x: s.x,
                                y: s.y,
                                z: s.z,
                            },
                        });
                    }

                    let json = serde_json::to_value(&base_skeleton).unwrap();

                    write_json_to_file(&json, format!("{}--base-skeleton.json", args[1].split('/').last().unwrap()).as_str(), json_dir.as_str());

                    // panic!("lol");
                    model
                }
                _ => {
                    panic!("Unknown model file extension {}", ext);
                }
            }
        }
        None => {
            println!("Not a model file");
            return;
        }
    };

    // file ext
    println!("File: {}", args[2]);
    match args[2].split('.').last() {
        Some(ext) => match ext {
            "anm" => handle_bc(&args[2], &model, &json_dir),
            "motstm_data" => handle_bc(&args[2], &model, &json_dir),
            "mot" => handle_sar(&args[2], &model, &json_dir),
            _ => {
                println!("Unknown animation file extension {}", ext);
            }
        },
        None => {
            println!("Not an animation file");
            return;
        }
    }
}
