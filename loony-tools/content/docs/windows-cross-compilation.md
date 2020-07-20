# Windows Cross Compilation

 Building applications on windows in Continuous Integration (CI) can be a rather
 tricky endeavour.  Especially if all the existing CI infrastructure is primarily
 linux based.  For macOS, we can mostly treat it like linux, mostly.  For Windows,
 not so much.  Furthermore obtaining server licenses and the additional costs
 associated with windows servers can be annoying to manage, especially if only
 required in short burts.  Thus it is qutie attractive to build Windows
 applications on non-windows machines.

 We have extended GHC to be able to properly cross compile all of IOHKs haskell
 sourcecode to Windows.