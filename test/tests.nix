{
  pkgs,
  buildJekyll,
  jekyllEnv,
}:
{
  test-cloudflare-redirects = buildJekyll.overrideAttrs (_: {
    name = "test-cloudflare-redirects";
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby test/cloudflare_redirects_test.rb
    '';
    installPhase = "touch $out";
  });
  test-markdown-references = buildJekyll.overrideAttrs (_: {
    name = "test-markdown-references";
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby test/markdown_references_test.rb
    '';
    installPhase = "touch $out";
  });
  test-relative-links = buildJekyll.overrideAttrs (_: {
    name = "test-relative-links";
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby test/relative_links_test.rb
    '';
    installPhase = "touch $out";
  });
  test-rendered-links = buildJekyll.overrideAttrs (old: {
    name = "test-rendered-links";
    buildInputs = old.buildInputs ++ [
      pkgs.python3
      pkgs.html-proofer
    ];
    buildPhase = ''
      unset BUNDLE_PATH
      ${jekyllEnv}/bin/bundler exec -- ruby test/rendered_links_test.rb
    '';
    installPhase = "touch $out";
  });
  test-og-render = buildJekyll.overrideAttrs (_: {
    name = "test-og-render";
    buildPhase = ''
      node --test bin/og-render.test.mjs
    '';
    installPhase = "touch $out";
  });
}
