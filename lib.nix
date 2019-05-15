rec {
  # generic function to fetch a tarball from a given .json file
  # like those provided in ./pins
  fetchTarballFromJson = jsonFile: with builtins;
    let spec = fromJSON (readFile jsonFile); in fetchTarball {
      inherit (spec) sha256; url = "${spec.url}/archive/${spec.rev}.tar.gz"; };

  # Allow overriding the fetch with a name on the command line so we can use -I
  fetchTarballFromJsonWithOverride = override: srcJson: with builtins;
    let try = tryEval (findFile nixPath override); in
    if try.success then trace "using search host <${override}>" try.value
    else fetchTarballFromJson srcJson;

  importPinned = name:
    import (fetchTarballFromJsonWithOverride name (./pins + "/${name}-src.json"));
}
