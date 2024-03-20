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

nbuild:
    cargo +nightly build -Z build-std=std,panic_abort --target aarch64-apple-darwin --release
    cargo +nightly build -Z build-std=std,panic_abort --target aarch64-apple-darwin --profile=small
    cargo +nightly build -Z build-std=std,panic_abort --target aarch64-apple-darwin --profile=zmall

docker:
    docker run -it --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    -w /project \
    rust:latest \
    bash

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
    -w /project \
    rust:latest \
    bash -c "curl --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-prebuilt/cargo-prebuilt/main/scripts/install-cargo-prebuilt.sh | bash \
    && cargo prebuilt cargo-hack --ci \
    && cargo hack check --each-feature --no-dev-deps --verbose --workspace \
    && cargo hack check --feature-powerset --no-dev-deps --verbose --workspace"

msrv:
    docker run -t --rm --pull=always \
    -e CARGO_TARGET_DIR=/ptarget \
    --mount type=bind,source={{pwd}},target=/project \
    --mount type=bind,source=$HOME/.cargo/registry,target=/usr/local/cargo/registry \
    -w /project \
    rust:latest \
    bash -c 'cargo install cargo-msrv --version 0.16.0-beta.20 --profile=dev && cargo msrv -- cargo check --verbose --locked'
