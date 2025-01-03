default:
    just -l

pwd := `pwd`

run +ARGS:
    cargo run -- {{ARGS}}

runr +ARGS:
    cargo run --release -- {{ARGS}}

fmt:
    cargo +nightly fmt

check:
    cargo +nightly fmt --check
    cargo clippy --all-targets --locked --workspace -- -D warnings
    cargo clippy --all-targets --locked --workspace --release -- -D warnings
    cargo deny check

check-nightly:
    cargo +nightly fmt --check
    cargo +nightly clippy --all-targets --locked --workspace -- -D warnings
    cargo +nightly clippy --all-targets --locked --workspace --release -- -D warnings
    cargo +nightly deny check

docker:
    docker run -it --rm --pull=always \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross-dev:stable-native

docker-alpine:
    docker run -it --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    -w /project \
    rust:alpine \
    sh

hack:
    docker run -t --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross-dev:stable-native \
    -c 'cargo prebuilt --ci cargo-hack \
    && cargo prebuilt cargo-hack --ci \
    && cargo hack check --each-feature --no-dev-deps --verbose --workspace \
    && cargo hack check --feature-powerset --no-dev-deps --verbose --workspace'

msrv:
    docker run -t --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    --entrypoint=/bin/bash \
    ghcr.io/cargo-prebuilt/ink-cross-dev:stable-native \
    -c 'cargo prebuilt --ci cargo-msrv && cargo msrv find -- cargo check --verbose --locked'
