{ runCommand, lib, src, diffutils, glibcLocales, fixPngOptimization }:
let
  # just pngs
  src' = lib.sourceFilesBySuffices src [ ".png" ];
in
runCommand "png-optimization-check"
{
  buildInputs = [ fixPngOptimization diffutils glibcLocales ];
} ''
  set +e
  cp -a ${src'} orig
  cp -a ${src'} png
  chmod -R +w png
  cd png
  fix-png-optimization
  cd ..
  diff --brief --recursive orig png > /dev/null
  EXIT_CODE=$?
  if [[ $EXIT_CODE != 0 ]]
  then
    mkdir -p $out/nix-support
    diff -ur orig png > $out/png.diff
    echo "file none $out/png.diff" > $out/nix-support/hydra-build-products
    echo "*** optipng found changes that need addressed first"
    echo "*** Please run \`nix-shell --run fix-png-optimization\` and commit changes"
    echo "*** or apply the diff generated by hydra if you don't have nix."
    exit $EXIT_CODE
  else
    echo $EXIT_CODE > $out
  fi
''