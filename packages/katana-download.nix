{
  lib,
  pkgs,
  ...
}: let
  version = "1.7.0";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "linux_amd64";
        sha256 = "7177fa8e562d2ebae83eaa0781a88b81074172b32906260cacc0db55a24dbba5";
      };
      aarch64-linux = {
        suffix = "linux_arm64";
        sha256 = "24d73e9c5567ee42c397ba3009337d25e5e39acc69e76ef6b5d2a74b26b2ac1c";
      };
      x86_64-darwin = {
        suffix = "darwin_amd64";
        sha256 = "5837d1a14b1f7e469d9731ab51a8f83d673e3cb65d6a3e5375c4a8bb95f44868";
      };
      aarch64-darwin = {
        suffix = "darwin_arm64";
        sha256 = "adc46e8f4f0933e097609418e80b126034f8f47b29ec353768122c5de3b9cf62";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  katanaTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/katana/releases/download/v${version}/katana_v${version}_${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "katana-artifacts";
    src = katanaTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  isLinux = hostPlatform.isLinux;
in
  pkgs.stdenv.mkDerivation rec {
    name = "katana";
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
