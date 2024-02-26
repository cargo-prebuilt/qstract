#![forbid(unsafe_code)]
#![allow(clippy::multiple_crate_versions)]

use flate2::bufread::GzDecoder;
use rc_zip_sync::{rc_zip::parse::EntryKind, ReadZip};
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
  -h, --help   Prints help information
  --version    Prints version information

OPTIONS:
  -z           Extract gzip compressed file
  -C [DIR]     Extract to [DIR]
  --zip       Extract zip compressed file (none, deflate, deflate64)

ARGS:
  <FILE>       Tar file to extract
";

struct Args {
    gzip: bool,
    zip: bool,
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
        output: if let Some(p) =
            pargs.opt_value_from_os_str("-C", |s| Ok::<PathBuf, String>(PathBuf::from(s)))?
        {
            p
        }
        else {
            std::env::current_dir()?
        },
        input: pargs.free_from_os_str(|s| Ok::<PathBuf, String>(PathBuf::from(s)))?,
    };

    assert!(
        !(args.gzip && args.zip),
        "Cannot use gzip and zip at the same time."
    );

    let file = File::open(args.input)?;
    let file = BufReader::new(file);

    let mut file: Box<dyn Read> =
        if args.gzip { Box::new(GzDecoder::new(file)) } else { Box::new(file) };

    if args.zip {
        unzip(&mut file, &args.output)?;
    }
    else {
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
        let Some(name) = entry.sanitized_name()
        else {
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
