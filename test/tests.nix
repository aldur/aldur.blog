{
  pkgs,
  buildJekyll,
  jekyllEnv,
}:
{
  default = buildJekyll;
  jekyll-build = buildJekyll;
  rendered-links = buildJekyll.overrideAttrs (old: {
    name = "jekyll-rendered-links";
    buildInputs = old.buildInputs ++ [
      pkgs.python3
      pkgs.html-proofer
    ];
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby test/relative_links_test.rb
      ${jekyllEnv}/bin/bundler exec -- ruby test/rendered_links_test.rb
    '';
    installPhase = "touch $out";
  });
}
