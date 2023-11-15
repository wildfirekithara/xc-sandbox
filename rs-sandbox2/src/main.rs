
use expanduser::expanduser;

fn savefile() {
    let filename = expanduser("~/Library/Application Support/Ryujinx/bis/user/save/0000000000000004/0/bf3game02.sav").unwrap();
    let filebytes = std::fs::read(filename).unwrap();
    let mut savefile = recordkeeper::SaveFile::from_bytes(&filebytes).unwrap();
    let save = savefile.save();


    let party_members = save.party_characters;
    save.

    // println!("controlled character: {}", save.

}

fn models() {
    let pyramd = expanduser("~/code/re2/xc2d/f5c5e0de22c9a5ba87bf714835f223e8/1/bf2-1/model/bl/bl000101.wimdo").unwrap();
    let pyramt = expanduser("~/code/re2/xc2d/f5c5e0de22c9a5ba87bf714835f223e8/1/bf2-1/model/bl/bl000101.wismt").unwrap();
    // let db = xc3_model::shader_database::ShaderDatabase::from_file("./modelo.json");

    let niamd = expanduser("~/code/re2/xc3/0/1/bf3/chr/ch/ch03001010.wimdo").unwrap();
    let niamt = expanduser("~/code/re2/xc3/0/1/bf3/chr/ch/ch03001010.wismt").unwrap();


    let glimmermd_face = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141011.wimdo").unwrap();
    let glimmermt_face = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141011.wismt").unwrap();
    let glimmermd_hair = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141012.wimdo").unwrap();
    let glimmermt_hair = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141012.wismt").unwrap();
    let glimmermd_body = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141013.wimdo").unwrap();
    let glimmermt_body = expanduser("~/code/re2/xc3d4/0/0/bf3_dlc04/chr/ch/ch41141013.wismt").unwrap();

    let mut mxmd = xc3_lib::mxmd::Mxmd::from_file(pyramd).unwrap();
    let mut msrd = xc3_lib::msrd::Msrd::from_file(pyramt).unwrap();
    // print version
    println!("pyra mxmd version: {}", mxmd.version);
    println!("pyra msrd version: {}", msrd.version);

    println!("pyra {mxmd:#?}");

    let nmxmd = xc3_lib::mxmd::Mxmd::from_file(niamd).unwrap();
    let nmsrd = xc3_lib::msrd::Msrd::from_file(niamt).unwrap();

    println!("niamd version: {}", nmxmd.version);
    println!("niamt version: {}", nmsrd.version);

    println!("nia {nmxmd:#?}");

    let glimmermxmd_face = xc3_lib::mxmd::Mxmd::from_file(glimmermd_face).unwrap();
    let glimmermsrd_face = xc3_lib::msrd::Msrd::from_file(glimmermt_face).unwrap();
    let glimmermxmd_hair = xc3_lib::mxmd::Mxmd::from_file(glimmermd_hair).unwrap();
    let glimmermsrd_hair = xc3_lib::msrd::Msrd::from_file(glimmermt_hair).unwrap();
    let glimmermxmd_body = xc3_lib::mxmd::Mxmd::from_file(glimmermd_body).unwrap();
    let glimmermsrd_body = xc3_lib::msrd::Msrd::from_file(glimmermt_body).unwrap();

    println!("glimmermd_face version: {}", glimmermxmd_face.version);
    println!("glimmermt_face version: {}", glimmermsrd_face.version);
    println!("glimmermd_hair version: {}", glimmermxmd_hair.version);
    println!("glimmermt_hair version: {}", glimmermsrd_hair.version);
    println!("glimmermd_body version: {}", glimmermxmd_body.version);
    println!("glimmermt_body version: {}", glimmermsrd_body.version);

    println!("glimmer_face {glimmermxmd_face:#?}");
    println!("glimmer_hair {glimmermxmd_hair:#?}");
    println!("glimmer_body {glimmermxmd_body:#?}");

    // Save to disk after making any changes.
    mxmd.write_to_file("out.wimdo").unwrap();
    msrd.write_to_file("out.wismt").unwrap();
}

fn main() {

    savefile();
}
