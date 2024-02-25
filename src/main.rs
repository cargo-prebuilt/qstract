use flate2::bufread::GzDecoder;
use std::{
    env,
    fs::File,
    io::{BufReader, Read},
    path::PathBuf,
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

ARGS:
  <FILE>       Tar file to extract
";

struct Args {
    gzip: bool,
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
        output: if let Some(p) =
            pargs.opt_value_from_os_str("-C", |s| Ok::<PathBuf, String>(PathBuf::from(s)))?
        {
            p
        }
        else {
            env::current_dir()?
        },
        input: pargs.free_from_os_str(|s| Ok::<PathBuf, String>(PathBuf::from(s)))?,
    };

    let file = File::open(args.input)?;
    let file = BufReader::new(file);

    let file: Box<dyn Read> =
        if args.gzip { Box::new(GzDecoder::new(file)) } else { Box::new(file) };

    let mut archive = Archive::new(file);
    archive.unpack(args.output)?;

    Ok(())
}
