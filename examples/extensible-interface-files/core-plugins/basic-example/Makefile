diff: vanilla core-inline
	diff -u vanilla.core inlined.core

vanilla:
	ghc -odir vanilla -hidir vanilla -c Lib.hs
	ghc -odir vanilla -hidir vanilla Main.hs -o VanillaMain -ddump-prep > vanilla.core

# I get a lot of errors with not being able to find modules properly if I use commands
# like the vanilla version. This seems to work, but I would like to figure out what
# causes the actual problem.
core-inline:
	mkdir -p inlined
	cd inlined; \
		ghc -odir . -hidir . ../Example.hs -package ghc -dynamic; \
		ghc -odir . -hidir . -fplugin Example -c ../Lib.hs -dynamic; \
		ghc -odir . -hidir . -fplugin Example -c ../Main.hs -dynamic -o ../InlinedMain -ddump-prep > ../inlined.core

clean:
	rm -rf vanilla inlined vanilla.core inlined.core VanillaMain InlinedMain

# Launch ghcid for instant-feedback type-checking
ghcid:
	ghcid --command="ghci Main.hs Lib.hs Example.hs -package ghc"
