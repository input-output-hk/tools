# default to ghc, but allow us to override the compiler used by providing
# HC, e.g. HC=/path/to/ghc-stage2 make ...
HC ?= ghc
# Same for HC_FLAGS (e.g. HC_FLAGS="-v").
# We'll *always* add -dynamic to it though.
#
# Need -dynamic, otherwise ghc will complain.
# it appears it defaults to loading dyn_o
# plugins.
#
# <no location info>: fatal:
#    cannot find object file ‘./Example.dyn_o’
#    while linking an interpreted expression
HC_FLAGS += -dynamic
diff: vanilla core-inline
	diff -u vanilla.core inlined.core
vanilla:
	mkdir -p vanilla
	cd vanilla && $(HC) $(HC_FLAGS) -odir . -hidir . ../Example.hs -package ghc
	cd vanilla && $(HC) $(HC_FLAGS) -odir . -hidir . -fplugin Example -c ../Lib.hs
	cd vanilla && $(HC) $(HC_FLAGS) -odir . -hidir . -fplugin Example -c ../Main.hs -o ../VanillaMain | tee ../vanilla.core
# I get a lot of errors with not being able to find modules properly if I use commands
# like the vanilla version. This seems to work, but I would like to figure out what
# causes the actual problem.
#
# There are a variety of bugs with plugins and locating them. Unless we package the
# Example plugin into it's own package,  ghc will complain about
#
#   attempting to use module ‘main:Example’ (Example.hs) which is not loaded
#
# in the final linking step; which makes little sense.
core-inline:
	mkdir -p inlined
	cd inlined && $(HC) $(HC_FLAGS) -odir . -hidir . ../Example.hs -package ghc
	cd inlined && $(HC) $(HC_FLAGS) -odir . -hidir . -fplugin Example -fplugin-opt Example:inline -c ../Lib.hs
	cd inlined && $(HC) $(HC_FLAGS) -odir . -hidir . -fplugin Example -fplugin-opt Example:inline -c ../Main.hs -o ../InlinedMain | tee ../inlined.core
clean:
	rm -rf vanilla inlined vanilla.core inlined.core VanillaMain InlinedMain
# Launch ghcid for instant-feedback type-checking
ghcid:
	ghcid --command="ghci Main.hs Lib.hs Example.hs -package ghc"
