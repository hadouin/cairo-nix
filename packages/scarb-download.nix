# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "2.13.1";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "x86_64-unknown-linux-gnu";
        sha256 = "c3354866901254d1868dcff7b56bb68822ca54f6a522cf8671685b2448ccdf15";
      };
      aarch64-linux = {
        suffix = "aarch64-unknown-linux-gnu";
        sha256 = "0a0a30e57d7255ac0ca5454d846758e5b5d2d4e15d9866d6095b71db95d21964";
      };
      x86_64-darwin = {
        suffix = "x86_64-apple-darwin";
        sha256 = "916644ade05d63296532a1352d1db9cf502b98db9ab3ec2934e9906aaa9748c1";
      };
      aarch64-darwin = {
        suffix = "aarch64-apple-darwin";
        sha256 = "98661e1dcb7f30a3655cffe5b7666d586028ecb71eeb3ce664a313b62d15a496";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  scarbTargz = builtins.fetchurl {
    url = "https://github.com/software-mansion/scarb/releases/download/v${version}/scarb-v${version}-${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "scarb-artifacts";
    src = scarbTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  isLinux = hostPlatform.isLinux;
in
  pkgs.stdenv.mkDerivation {
    name = "scarb";
    src = artifacts;
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = with pkgs; [makeWrapper] ++ lib.optionals isLinux [autoPatchelfHook];
    buildInputs = with pkgs;
      [
        stdenv.cc.cc
        zlib
        openssl
      ]
      ++ lib.optionals isLinux [glibc];

    installPhase =
      ''
        mkdir -p $out/bin
        mv ./scarb-*/* $out
      ''
      + lib.optionalString isLinux ''
        # Run autoPatchelf to fix the interpreter and add missing libraries
        autoPatchelf $out/bin
      '';
  }
