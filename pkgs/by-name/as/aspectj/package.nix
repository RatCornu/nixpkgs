{
  lib,
  stdenvNoCC,
  fetchurl,
  jre,
}:

let
  version = "1.9.24";
  versionSnakeCase = builtins.replaceStrings [ "." ] [ "_" ] version;
in
stdenvNoCC.mkDerivation {
  pname = "aspectj";
  inherit version;

  __structuredAttrs = true;

  src = fetchurl {
    url = "https://github.com/eclipse/org.aspectj/releases/download/V${versionSnakeCase}/aspectj-${version}.jar";
    hash = "sha256-p+UOtuP8hNymfvmL/SPg99YrhU7m5GDudtLISqL5TWQ=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ jre ];

  installPhase = ''
    runHook preInstall

    cat >> props <<EOF
    output.dir=$out
    context.javaPath=${jre}
    EOF

    mkdir -p $out
    java -jar $src -text props

    cat >> $out/bin/aj-runtime-env <<EOF
    #! ${stdenvNoCC.shell}

    export CLASSPATH=$CLASSPATH:.:$out/lib/aspectjrt.jar
    EOF

    chmod u+x $out/bin/aj-runtime-env

    runHook postInstall
  '';

  meta = {
    homepage = "https://www.eclipse.org/aspectj/";
    description = "Seamless aspect-oriented extension to the Java programming language";
    license = lib.licenses.epl10;
    platforms = lib.platforms.unix;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
}
