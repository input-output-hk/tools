# Extensible Interface Files

GHC tooling in general knows about two build artifacts when compiling haskell code
this is object code contained in the `.o` files, as well as meta information contained
in the `.hi` files.  The information that's contained in `.hi` files is primarily
used to inlines code that was marked as `INLINABLE`, and for type information about
exported symbols.

Extensible Interface Files allows us to embed arbitrary extra data encoded by a key
into `.hi` files.  We want this for plutus, where the plutus compiler needs the
core (one of GHC internal representations) representation of the haskell functions
to properly translate a plutus program.  This is currently done by forcing GHC to
include the represenations using a few specific compilier flags.  Extensible
Interface Files provides this with a solid foundation, and we are currently in the
process of moving the plutus compiler to use the Extensible Interface Files.
