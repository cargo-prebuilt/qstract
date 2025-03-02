#![forbid(unsafe_code)]
#![allow(clippy::multiple_crate_versions)]

use flate2::bufread::GzDecoder;
use rc_zip_sync::{ReadZip, rc_zip::parse::EntryKind};
use std::{
    fs::File,
    io::{BufReader, Read},
    path::{Path, PathBuf},
};
use tar::Archive;

const HELP_TEXT: &str = "\
qstract

USAGE:
  qstract [OPTIONS] [FILE]

FLAGS:
  -h, --help    Prints help information
  --version     Prints version information

OPTIONS:
  -z            Extract gzip compressed file
  -C [DIR]      Extract to [DIR]
  --zip         Extract zip compressed file (none, deflate, deflate64)
  --sha256      Hashes the file with sha256 (Ignores -C)
  --sha512      Hashes the file with sha512 (Ignores -C)
  --sha3_256    Hashes the file with sha3_256 (Ignores -C)
  --sha3_512    Hashes the file with sha3_512 (Ignores -C)

ARGS:
  <FILE>        File to run arg on.
                Running with no args requires a tar file.
";

#[allow(clippy::struct_excessive_bools)]
struct Args {
    gzip: bool,
    zip: bool,
    sha256: bool,
    sha512: bool,
    sha3_256: bool,
    sha3_512: bool,
    output: PathBuf,
    input: PathBuf,
}

fn main() -> anyhow::Result<()> {
    let mut pargs = pico_args::Arguments::from_env();

    if pargs.contains("--version") {
        println!("qstract {}", env!("CARGO_PKG_VERSION"));
        std::process::exit(0);
    }

    if pargs.contains(["-h", "--help"]) {
        print!("{HELP_TEXT}");
        std::process::exit(0);
    }

    let args = Args {
        gzip: pargs.contains("-z"),
        zip: pargs.contains("--zip"),
        sha256: pargs.contains("--sha256"),
        sha512: pargs.contains("--sha512"),
        sha3_256: pargs.contains("--sha3_256"),
        sha3_512: pargs.contains("--sha3_512"),
        output: if let Some(p) =
            pargs.opt_value_from_os_str("-C", |s| Ok::<PathBuf, String>(PathBuf::from(s)))?
        {
            p
        } else {
            std::env::current_dir()?
        },
        input: pargs.free_from_os_str(|s| Ok::<PathBuf, String>(PathBuf::from(s)))?,
    };

    let remaining = pargs.finish();
    assert!(
        remaining.is_empty(),
        "Unused arguments left: {remaining:?}.\nUse --help to see supported arguments."
    );

    if [
        &args.gzip,
        &args.zip,
        &args.sha256,
        &args.sha512,
        &args.sha3_256,
        &args.sha3_512,
    ]
    .iter()
    .filter(|x| ***x)
    .count()
        > 1
    {
        panic!(
            "Arguments -z, --zip, --sha256 --sha512, --sha3_256, --sha3_512 must be used independently of each other."
        );
    }

    let file = File::open(args.input)?;
    let file = BufReader::new(file);

    let mut file: Box<dyn Read> = if args.gzip {
        Box::new(GzDecoder::new(file))
    } else {
        Box::new(file)
    };

    if args.zip {
        unzip(&mut file, &args.output)?;
    } else if args.sha256 || args.sha512 || args.sha3_256 || args.sha3_512 {
        hash(&mut file, args.sha256, args.sha512, args.sha3_256)?;
    } else {
        let mut archive = Archive::new(file);
        archive.unpack(args.output)?;
    }

    Ok(())
}

fn unzip(read: &mut Box<dyn Read>, output: &Path) -> anyhow::Result<()> {
    let mut bytes = Vec::new();
    read.read_to_end(&mut bytes)?;
    let reader = bytes.read_zip()?;

    for entry in reader.entries() {
        let Some(name) = entry.sanitized_name() else {
            continue;
        };

        match entry.kind() {
            EntryKind::Directory => {
                let path = output.join(name);
                std::fs::create_dir_all(path.parent().expect("No parent path."))?;
            }
            EntryKind::File => {
                let path = output.join(name);
                std::fs::create_dir_all(path.parent().expect("No parent path."))?;

                let mut w = File::create(path)?;
                let mut r = entry.reader();
                std::io::copy(&mut r, &mut w)?;
            }
            EntryKind::Symlink => eprintln!("Unsupported symlink, skipping {name}"),
        }
    }

    Ok(())
}

fn hash(
    read: &mut Box<dyn Read>,
    sha256: bool,
    sha512: bool,
    sha3_256: bool,
) -> anyhow::Result<()> {
    let mut bytes = Vec::new();
    read.read_to_end(&mut bytes)?;

    let hash: Vec<u8> = if sha256 {
        use sha2::{Digest, Sha256};
        let mut hasher = Sha256::new();
        hasher.update(bytes);
        hasher.finalize().to_vec()
    } else if sha512 {
        use sha2::{Digest, Sha512};
        let mut hasher = Sha512::new();
        hasher.update(bytes);
        hasher.finalize().to_vec()
    } else if sha3_256 {
        use sha3::{Digest, Sha3_256};
        let mut hasher = Sha3_256::new();
        hasher.update(bytes);
        hasher.finalize().to_vec()
    } else {
        use sha3::{Digest, Sha3_512};
        let mut hasher = Sha3_512::new();
        hasher.update(bytes);
        hasher.finalize().to_vec()
    };

    println!("{}", hex::encode(hash));

    Ok(())
}
