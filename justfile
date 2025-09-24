pwd := `pwd`

default:
    just -l

fmt:
    cargo +nightly fmt

check:
    cargo +nightly fmt --check
    cargo clippy --all-targets --all-features --workspace --locked -- -D warnings
    cargo clippy --all-targets --all-features --workspace --release --locked -- -D warnings
    cargo deny check

check-nightly:
    cargo +nightly fmt --check
    cargo +nightly clippy --all-targets --all-features --workspace --locked -- -D warnings
    cargo +nightly clippy --all-targets --all-features --workspace --release --locked -- -D warnings
    cargo +nightly deny check

check-msvc:
    cargo +nightly fmt --check
    RUSTFLAGS='-Clink-arg=-fuse-ld=lld' cargo xwin clippy --all-targets --all-features --workspace --locked --target aarch64-pc-windows-msvc -- -D warnings
    RUSTFLAGS='-Clink-arg=-fuse-ld=lld' cargo xwin clippy --all-targets --all-features --workspace --release --locked --target aarch64-pc-windows-msvc -- -D warnings
    cargo deny check

build:
    cargo +nightly build --locked

buildr:
    cargo +nightly build --locked --release

build-msvc:
    cargo +nightly xwin build --locked --target aarch64-pc-windows-msvc

buildr-msvc:
    cargo +nightly xwin build --locked --release --target aarch64-pc-windows-msvc

run +ARGS:
    cargo +nightly run --locked -- {{ARGS}}

runr +ARGS:
    cargo +nightly run --locked --release -- {{ARGS}}

runq +ARGS:
    cargo +nightly run --locked --profile=quick -- {{ARGS}}

ink-cross TARGET:
    docker run -it --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    ghcr.io/cargo-prebuilt/ink-cross:nightly-{{TARGET}} \
    build --verbose --workspace --locked --target {{TARGET}}

ink-crossr TARGET:
    docker run -it --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    ghcr.io/cargo-prebuilt/ink-cross:nightly-{{TARGET}} \
    build --verbose --workspace --locked --release --target {{TARGET}}

default_log_level := 'INFO'
sup-lint LOG_LEVEL=default_log_level:
    docker run \
    -t --rm --pull=always \
    --platform=linux/amd64 \
    -e LOG_LEVEL={{LOG_LEVEL}} \
    -e RUN_LOCAL=true \
    -e SHELL=/bin/bash \
    -e DEFAULT_BRANCH=main \
    -e LINTER_RULES_PATH=/tmp/lint \
    -e VALIDATE_ALL_CODEBASE=true \
    -e VALIDATE_JSCPD=false \
    -e VALIDATE_RUST_2015=false \
    -e VALIDATE_RUST_2018=false \
    -e VALIDATE_RUST_2021=false \
    -e VALIDATE_RUST_2024=false \
    -e VALIDATE_RUST_CLIPPY=false \
    -v {{pwd}}:/tmp/lint \
    ghcr.io/super-linter/super-linter:slim-latest

docker:
    docker run -it --rm --pull=always \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross:stable-native

hack:
    docker run -it --rm --pull=always \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross:stable-native \
    -c 'cargo prebuilt --ci cargo-hack && cargo hack check --each-feature --no-dev-deps --verbose --workspace --locked && cargo hack check --feature-powerset --no-dev-deps --verbose --workspace --locked'

msrv:
    docker run -it --rm --pull=always \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross:stable-native \
    -c 'cargo prebuilt --ci cargo-msrv && cargo msrv find -- cargo check --verbose --locked'

msrv-verify:
    docker run -it --rm --pull=always \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross:stable-native \
    -c 'cargo prebuilt --ci cargo-msrv && cargo msrv verify -- cargo check --verbose --release --locked'
