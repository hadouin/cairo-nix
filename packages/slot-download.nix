# While I'm trying to fix the build, I'm using the prebuilt artifacts instead.
# I'll remove this once I've fixed the build.
{
  lib,
  pkgs,
  ...
}: let
  version = "0.56.0";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "linux_amd64";
        sha256 = "a3b92e67fdcdfb7c89c0d196414a42b2d7c8b1f83b6f4202cc5748b20c33800d";
      };
      aarch64-linux = {
        suffix = "linux_arm64";
        sha256 = "d8ff041673488ecb989673781f6973bd44bea642c8ce7e55063c4c81d40b810f";
      };
      x86_64-darwin = {
        suffix = "darwin_amd64";
        sha256 = "6508ca92fc62deacba880b199a2b8f3e28879aed6e9da7c743e8dca4fb06d913";
      };
      aarch64-darwin = {
        suffix = "darwin_arm64";
        sha256 = "b48a5fb17ba4d60c01911547dfe6989df013a1ada9dc1b0d779322d33374d3e3";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  buildTargz = builtins.fetchurl {
    url = "https://github.com/cartridge-gg/slot/releases/download/v${version}/slot_v${version}_${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "slot-artifacts";
    src = buildTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  isLinux = hostPlatform.isLinux;
in
  pkgs.stdenv.mkDerivation rec {
    name = "slot";
    src = artifacts;

    nativeBuildInputs = with pkgs; [makeWrapper] ++ lib.optionals isLinux [autoPatchelfHook];
    buildInputs = with pkgs; [stdenv.cc.cc] ++ lib.optionals isLinux [glibc];

    installPhase =
      ''
        runHook preInstall

        mkdir -p $out/bin
        cp ${name} $out/bin
      ''
      + lib.optionalString isLinux ''
        wrapProgram $out/bin/${name} \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.glibc]}"
      ''
      + ''

        runHook postInstall
      '';
  }
