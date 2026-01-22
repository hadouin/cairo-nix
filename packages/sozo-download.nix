{
  lib,
  pkgs,
  ...
}: let
  version = "1.8.5";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "linux_amd64";
        sha256 = "75a82d2bc0c1b308f91fa31d0b86184864db3b53384cb2fd27d18a847a8dcec9";
      };
      aarch64-linux = {
        suffix = "linux_arm64";
        sha256 = "95f2c8db966bdf09feeafabeecaa34bb57634b20dc66cc9e3797a980e1e5f70e";
      };
      x86_64-darwin = {
        suffix = "darwin_amd64";
        sha256 = "54d9b507790fd712cd3daccc86e060c7430177cacae6cb0bda10348bd46a70d8";
      };
      aarch64-darwin = {
        suffix = "darwin_arm64";
        sha256 = "c16d471f2d7f0a7c3d5834b34371417289a5928ddc44fc91f92a3a77771cc060";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  sozoTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/dojo/releases/download/sozo%2Fv${version}/sozo_v${version}_${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "sozo-artifacts";
    src = sozoTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  isLinux = hostPlatform.isLinux;
in
  pkgs.stdenv.mkDerivation rec {
    name = "sozo";
    inherit version;
    src = artifacts;

    nativeBuildInputs = with pkgs; [makeWrapper] ++ lib.optionals isLinux [autoPatchelfHook];
    buildInputs = with pkgs; [stdenv.cc.cc zlib] ++ lib.optionals isLinux [glibc];

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
