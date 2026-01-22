# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "1.8.0";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "linux_amd64";
        sha256 = "510095cc71905c9bafe74c1db7cdbdf5ab625b724263010d681f0f371aeda7d2";
      };
      aarch64-linux = {
        suffix = "linux_arm64";
        sha256 = "7d3da856801b26ff56453c199b7975522faba25b887ed82e443c27a7fef6abcd";
      };
      x86_64-darwin = {
        suffix = "darwin_amd64";
        sha256 = "9408c0b53e2bd0af991a60e9c3051217782fdcd444caa489a910a07dae9aa93c";
      };
      aarch64-darwin = {
        suffix = "darwin_arm64";
        sha256 = "1e00cce1f998b550bac3994d16079b20847558bab95eaa1554a3fbaaed8c896e";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  dojoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/v${version}/dojo_v${version}_${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  isLinux = hostPlatform.isLinux;

  artifacts = pkgs.stdenv.mkDerivation {
    name = "dojo-artifacts";
    src = dojoTargz;
    phases = ["unpackPhase" "installCheckPhase"];

    nativeBuildInputs = with pkgs; lib.optionals isLinux [autoPatchelfHook makeWrapper];
    buildInputs = with pkgs;
      [
        stdenv.cc.cc
        zlib
        openssl
      ]
      ++ lib.optionals isLinux [glibc];
    doInstallCheck = true;

    unpackPhase =
      ''
        mkdir -p $out/bin
        tar -xzf $src -C $out/bin
      ''
      + lib.optionalString isLinux ''
        # Run autoPatchelf to fix the interpreter and add missing libraries
        autoPatchelf $out/bin
      ''
      + ''
        runHook postInstall
      '';

    installCheckPhase = ''
      echo "Validating sozo..."
      $out/bin/sozo --version || (echo "Error: sozo failed to launch" && exit 1)
    '';
  };
in {
  dojo = artifacts;
}
