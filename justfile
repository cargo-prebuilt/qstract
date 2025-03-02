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
    RUSTFLAGS='-Clink-arg=-fuse-ld=ld64.lld' cargo xwin clippy --all-targets --all-features --workspace --locked --target aarch64-pc-windows-msvc -- -D warnings
    RUSTFLAGS='-Clink-arg=-fuse-ld=ld64.lld' cargo xwin clippy --all-targets --all-features --workspace --release --locked --target aarch64-pc-windows-msvc -- -D warnings
    cargo deny check

build:
    cargo build --locked

build-msvc:
    cargo xwin build --locked --target aarch64-pc-windows-msvc

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
