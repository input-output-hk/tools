# Unboxed Tuples

GHC's Interpreter (which is also used in ghcide), has a severe limitation around
unboxed tuples.  These simply cannot be used with the interpreter unless one
falls back to using object-code, which in turn doesn't work with ghcide properly.

We are trying to make the GHC Interpreter Unboxed Tuple aware, which should
improve ghcide performance and thus allow us to load large plutus programs (even
the whole plutus repository into ghcide).