{
  pkgs,
  buildJekyll,
  jekyllEnv,
}:
{
  default = buildJekyll;
  jekyll-build = buildJekyll;
  markdown-references = buildJekyll.overrideAttrs (_: {
    name = "check-markdown-references";
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby bin/check_markdown_references.rb
    '';
    installPhase = "touch $out";
  });
  rendered-links = buildJekyll.overrideAttrs (old: {
    name = "check-rendered-links";
    buildInputs = old.buildInputs ++ [
      pkgs.python3
      pkgs.html-proofer
    ];
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby bin/check_rendered_links.rb
    '';
    installPhase = "touch $out";
  });
}
