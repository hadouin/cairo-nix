{
  lib,
  pkgs,
  ...
}: let
  version = "1.8.10";
  inherit (pkgs.stdenv) hostPlatform;

  platformInfo =
    {
      x86_64-linux = {
        suffix = "linux_amd64";
        sha256 = "561f52879e9c79d4bbc96a07aca40df327bc732b21c8c8361a6220ba738917ea";
      };
      aarch64-linux = {
        suffix = "linux_arm64";
        sha256 = "5bbadb11e645ae2dd072397175538520e1a6d00431013e3961907733469ca27f";
      };
      x86_64-darwin = {
        suffix = "darwin_amd64";
        sha256 = "3cd7775b258a76c3a0b868916f77f316f9d89ce842bcaf24158c4c06da03b276";
      };
      aarch64-darwin = {
        suffix = "darwin_arm64";
        sha256 = "56f64b46ef72bc13f45f4674ac022b7e06301f2f83a2e51582d37d429476c007";
      };
    }
    .${hostPlatform.system}
    or (throw "Unsupported platform: ${hostPlatform.system}");

  toriiTargz = builtins.fetchurl {
    url = "https://github.com/dojoengine/torii/releases/download/v${version}/torii_v${version}_${platformInfo.suffix}.tar.gz";
    sha256 = platformInfo.sha256;
  };

  artifacts = pkgs.stdenv.mkDerivation {
    name = "torii-artifacts";
    src = toriiTargz;
    phases = ["unpackPhase"];
    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out
    '';
  };

  isLinux = hostPlatform.isLinux;
in
  pkgs.stdenv.mkDerivation rec {
    name = "torii";
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
