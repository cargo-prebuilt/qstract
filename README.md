# qstract

[![Rust Build and Test](https://github.com/cargo-prebuilt/qstract/actions/workflows/build.yml/badge.svg?event=push)](https://github.com/cargo-prebuilt/qstract/actions/workflows/build.yml)
[![Rust Checks](https://github.com/cargo-prebuilt/qstract/actions/workflows/checks.yml/badge.svg?event=push)](https://github.com/cargo-prebuilt/qstract/actions/workflows/checks.yml)
[![rustc-msrv](https://img.shields.io/badge/rustc-1.74%2B-blue?logo=rust)](https://www.rust-lang.org/tools/install)

A basic tar/zip extraction program.

## Installation

- You can download the latest prebuilt binaries of qstract [here](https://github.com/cargo-prebuilt/qstract/releases/latest).
<!-- - Cargo install: ```cargo install qstract``` -->
<!-- - Cargo prebuilt: ```cargo prebuilt qstract``` -->
- Cargo binstall: ```cargo binstall qstract --no-confirm```
- Cargo quickinstall: ```cargo quickinstall qstract```
- Install script (unix platforms): ```curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-prebuilt/qstract/main/scripts/install-qstract.sh | bash```
<!-- - For github actions you can use [cargo-prebuilt/cargo-prebuilt-action](https://github.com/cargo-prebuilt/cargo-prebuilt-action) -->

## Args

- `-C` for directory to extract to.
- `-z` for gzip.
- `--zip` for zip. (Only deflate and deflate64)

First positional arg is the file to extract.

### Examples

- `qstract -z -C /tmp /tmp/tar.tar.gz` : Extract gzip file tar.tar.gz to /tmp
- `qstract tar.tar` : Extract file tar.tar to current working directory
