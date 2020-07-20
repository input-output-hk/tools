# Cross Compiler Test Suite

The GHC Test Suite contains a large variety of tests, often distilled from
bugreports.  This testsuite is quite valuable, and is a requirement when merging
new code into GHC.  However the Test Suite has no concept of cross compilation
and as such cross compiler mostly fly blind.  We are therefore adding logic to
the existing GHC Test Suite to also be able to run against Cross Compilers, and
verify their behaviour.