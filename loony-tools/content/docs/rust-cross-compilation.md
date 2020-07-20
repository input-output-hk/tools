# Rust Cross Compilation

Rust--by virtue of being a LLVM based compiler--obtains most of the necessary
infrastructure to be multiple target aware out of the box.  However building
rust in CI (especially in a nix based CI) can lead to compliations.  This is
very visible when trying to cross compile to Windows.

We've adopted an existing `cargo` wrapper for nix called `naersk`, and extended
it to cover cross compilation and subsequently trivial integration of rust
libraries into haskell applications.  The code can be found in
[rust.nix](https://github.com/input-output-hk/rust.nix).
