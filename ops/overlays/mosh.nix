final: prev:
{
  mosh = prev.mosh.overrideDerivation (drv: {
    src = fetchTarball {
	url = "https://github.com/mobile-shell/mosh/archive/03087e7.tar.gz";
        sha256 = "170m3q9sxw6nh8fvrf1l0hbx0rjjz5f5lzhd41143kd1rps3liw8";
    };
    patches = [
    <nixpkgs/pkgs/tools/networking/mosh/ssh_path.patch>
    <nixpkgs/pkgs/tools/networking/mosh/utempter_path.patch>
    # Fix w/c++17, ::bind vs std::bind
    #(fetchpatch {
    #  url = "https://github.com/mobile-shell/mosh/commit/e5f8a826ef9ff5da4cfce3bb8151f9526ec19db0.patch";
    #  sha256 = "15518rb0r5w1zn4s6981bf1sz6ins6gpn2saizfzhmr13hw4gmhm";
    #})
    (final.fetchpatch { url = "https://github.com/mobile-shell/mosh/pull/1054.patch"; sha256 = "1hmzp3dlr4nlqir2za6d5g91q30w7fxh759y4lvfi9zmi0d23pq7"; })
    ];
  });
}
