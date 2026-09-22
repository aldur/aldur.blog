{
  description = "Package Jekyll and its gems for 'aldur.blog'";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # More ergonomical fork of bundlerEnv
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ruby-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        name = "aldur.github.io";

        pkgs = import nixpkgs { inherit system; };

        # NOTE: We require this to exist.
        gemset = ./gemset.nix;

        # If you want to override gem build config, see
        #   https://github.com/NixOS/nixpkgs/blob/master/pkgs/
        #   development/ruby-modules/gem-config/default.nix
        gemConfig = { };

        expectedRubyVersion = pkgs.lib.trim (builtins.readFile ./.ruby-version);
        rubyPackage = pkgs.ruby_3_4;
        actualRubyVersion = toString rubyPackage.version;
        parseVersion =
          v:
          let
            parts = pkgs.lib.splitVersion v;
          in
          {
            major = builtins.elemAt parts 0;
            minor = builtins.elemAt parts 1;
            patch = builtins.elemAt parts 2;
          };
        expected = parseVersion expectedRubyVersion;
        actual = parseVersion actualRubyVersion;
        majorMinorMatch = expected.major == actual.major && expected.minor == actual.minor;
        patchMatch = expected.patch == actual.patch;
        rubyUnwrapped =
          assert pkgs.lib.assertMsg majorMinorMatch
            "Ruby version mismatch: .ruby-version specifies ${expectedRubyVersion} but nixpkgs provides ${actualRubyVersion}";
          if patchMatch then
            rubyPackage
          else
            # Rationale:
            # Pinning to a version outside of nixpkgs would require
            # low-powered machines to compile Ruby from source
            (builtins.trace (
              "warning: Ruby patch version differs: "
              + ".ruby-version specifies ${expectedRubyVersion} "
              + "but nixpkgs provides ${actualRubyVersion}"
            ) rubyPackage);

        # Node, used by the OG renderer (bin/og-render.mjs). `.node-version`
        # pins Cloudflare's Node; assert its major matches the flake's, the way
        # we do for Ruby.
        expectedNodeVersion = pkgs.lib.trim (builtins.readFile ./.node-version);
        nodePackage = pkgs.nodejs_22;
        nodejs =
          assert pkgs.lib.assertMsg
            ((parseVersion expectedNodeVersion).major == (parseVersion nodePackage.version).major)
            "Node major version mismatch: .node-version specifies ${expectedNodeVersion} but nixpkgs provides ${nodePackage.version}";
          nodePackage;

        # --- Here's what's happening below. ---
        # First we call the function `ruby-nix.lib` by passing it `pkgs`.
        # This returns a function, that accepts a set (having a `name`), etc.
        # The resulting function has a bunch of attributes.
        # We are only interested in `env.
        inherit
          ((ruby-nix.lib pkgs) {
            inherit gemset name;
            ruby = rubyUnwrapped;
            gemConfig = pkgs.defaultGemConfig // gemConfig;
          })
          env
          ruby
          ;

        jekyllArgs = "--trace --drafts --future";

        # The og_image plugin renders images with `node bin/og-render.mjs`,
        # which needs `node_modules`. The nix sandbox has no network, so pin the
        # deps as a fixed-output derivation (pnpm 10, to match Cloudflare).
        # To refresh after editing package.json: set `hash = pkgs.lib.fakeHash`,
        # run `nix build .#default`, and copy the reported hash back in.
        pnpmSrc = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./package.json
            ./pnpm-lock.yaml
          ];
        };
        ogPackage = pkgs.lib.importJSON "${pnpmSrc}/package.json";
        ogNodeModules = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = ogPackage.name;
          inherit (ogPackage) version;
          src = pnpmSrc;
          nativeBuildInputs = [
            nodejs
            pkgs.pnpm_10
            pkgs.pnpmConfigHook
          ];
          pnpmDeps = pkgs.fetchPnpmDeps {
            pnpm = pkgs.pnpm_10;
            inherit (finalAttrs) pname version src;
            fetcherVersion = 3;
            hash = "sha256-ORTcmASa9ZzcMak9v4ZukkOfjZFjNFdhKXSygJ1DSk4=";
          };
          dontBuild = true;
          # `${ogNodeModules}` is the populated node_modules directory.
          installPhase = ''
            runHook preInstall
            cp -R node_modules "$out"
            runHook postInstall
          '';
        });

        # The renderer and its node_modules, co-located in the store, so `node`
        # resolves dependencies from there — no node_modules in the working
        # tree. The plugin finds the script via OG_RENDER_SCRIPT.
        ogRenderer = pkgs.runCommand "og-renderer" { } ''
          mkdir -p "$out"
          cp ${./bin/og-render.mjs} "$out/og-render.mjs"
          ln -s ${ogNodeModules} "$out/node_modules"
        '';

        jekyllEnv = pkgs.buildEnv {
          name = "jekyll-env";
          paths = [
            env
            nodejs
          ];
        };
        buildJekyll = pkgs.stdenv.mkDerivation {
          name = "jekyll-build";
          src = pkgs.lib.cleanSource ./.;
          buildInputs = [ jekyllEnv ];
          # A failed OG render aborts the build, so this check also guarantees
          # every post/micro ends up with its image.
          OG_RENDER_SCRIPT = "${ogRenderer}/og-render.mjs";
          buildPhase = ''
            unset BUNDLE_PATH
            ${jekyllEnv}/bin/bundler exec -- ruby test/relative_links_test.rb
            ${jekyllEnv}/bin/bundler exec -- jekyll build ${jekyllArgs};
            mkdir $out;
            mv _site $out;
          '';
        };

        slug = ''
          slug=$(echo "$@" | \
            ${pkgs.iconv}/bin/iconv -t ascii//TRANSLIT | \
            ${pkgs.gnused}/bin/sed -E -e 's/[^[:alnum:]]+/-/g' -e 's/^-+|-+$//g' | \
            ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')
        '';

        usage = ''
          if [ "$#" -eq 0 ]; then
            echo "Usage: $0 <title>"
            exit 1
          fi

          if [[ "$1" == "-options" ]]; then
            echo "Ignoring '-options' and exiting: see https://aldur.blog/micros/2025/07/23/micro-options/"
            exit 0
          fi
        '';

        mkApp = description: package: {
          type = "app";
          program = pkgs.lib.getExe package;
          meta = { inherit description; };
        };
      in
      {
        checks = {
          jekyll-build = buildJekyll;
          default = buildJekyll;
        };

        packages = {
          lockGemset = pkgs.writeShellScriptBin "lock" ''
            unset BUNDLE_PATH
            echo "Locking Gemfile..."
            ${jekyllEnv}/bin/bundler lock
            echo "Locking Gemfile.lock to gemset.nix..."
            ${pkgs.bundix}/bin/bundix -l
          '';

          default = buildJekyll;

          serveJekyll = pkgs.writeShellScriptBin "serve" ''
            unset BUNDLE_PATH
            export PATH="${jekyllEnv}/bin:$PATH"
            export OG_RENDER_SCRIPT="${ogRenderer}/og-render.mjs"
            ${jekyllEnv}/bin/bundler exec -- jekyll serve \
                ${jekyllArgs} --livereload
          '';

          cleanJekyll = pkgs.writeShellScriptBin "clean" ''
            unset BUNDLE_PATH
            ${jekyllEnv}/bin/bundler exec -- jekyll clean \
                ${jekyllArgs}
          '';

          regenerateOgImages = pkgs.writeShellScriptBin "og" ''
            unset BUNDLE_PATH
            export PATH="${jekyllEnv}/bin:$PATH"
            export OG_RENDER_SCRIPT="${ogRenderer}/og-render.mjs"
            FORCE_OG=1 ${jekyllEnv}/bin/bundler exec -- jekyll build ${jekyllArgs}
          '';

          newPost = pkgs.writeShellScriptBin "new" ''
            ${usage}

            ${slug}
            output=_posts/$(${pkgs.coreutils}/bin/date +"%Y-%m-%d")-$slug.md
            echo "---
            title: '$@'
            excerpt: >
              TODO
            ---

            #### Footnotes
            " > $output
            echo "Created file \"$output\"."
          '';

          newMicro = pkgs.writeShellScriptBin "micro" ''
            # Check for -b flag
            checkout_branch=false
            args=()
            for arg in "$@"; do
              if [[ "$arg" == "-b" ]]; then
                checkout_branch=true
              else
                args+=("$arg")
              fi
            done

            # Use remaining args as title
            set -- "''${args[@]}"

            ${usage}

            ${slug}
            output=_micros/$slug.md
            echo "---
            title: '$@'
            date: $(${pkgs.coreutils}/bin/date +"%Y-%m-%d")
            ---

            " > $output
            echo "Created file \"$output\"."

            # Checkout branch if -b flag was provided
            if $checkout_branch; then
              ${pkgs.git}/bin/git checkout -b "micro/$slug"
              echo "Checked out new branch \"micro/$slug\"."
            fi
          '';
        };

        apps =
          let
            inherit (self.packages.${system})
              serveJekyll
              lockGemset
              cleanJekyll
              regenerateOgImages
              newPost
              newMicro
              ;
          in
          {
            default = mkApp "Serve Jekyll" serveJekyll;
            lock = mkApp "Lock Gemfile and update gemset.nix" lockGemset;
            clean = mkApp "Clean build artifacts" cleanJekyll;
            og = mkApp "Regenerate all OG images" regenerateOgImages;
            new = mkApp "Create a new blog post" newPost;
            micro = mkApp "Create a new micro post" newMicro;
          };

        devShells =
          let
            shellEnv = {
              # Ignore the current machine's platform and install only ruby
              # platform gems. As a result, gems with native extensions will be
              # compiled from source.
              # https://bundler.io/v2.4/man/bundle-config.1.html
              BUNDLE_FORCE_RUBY_PLATFORM = "true";

              # Vendor gems locally instead of in Nix store.
              BUNDLE_PATH = "vendor/bundle";

              # Lets a manual `bundle exec jekyll build/serve` in the shell find
              # the OG renderer (and its node_modules) in the store.
              OG_RENDER_SCRIPT = "${ogRenderer}/og-render.mjs";
            };

            # Everything needed for the everyday build/serve/write loop.
            # `node` (for the OG renderer) comes from `jekyllEnv`.
            corePackages = [
              jekyllEnv
              ruby
              self.packages.${system}.newPost
              self.packages.${system}.newMicro
            ]
            ++ (with pkgs; [
              ruby-lsp
            ]);
          in
          {
            # Lean shell loaded by `direnv` / `nix develop`. Kept small so the
            # first build (and every `nix-direnv` cache miss) stays fast.
            default = pkgs.mkShell (shellEnv // { packages = corePackages; });

            # Heavier maintenance shell: `bundix` (gem locking) and
            # `html-proofer` (link checking). These are rarely needed and pull
            # in large closures — `bundix` alone drags in a second copy of Nix,
            # git, and the full Perl LWP stack — so they stay out of `default`.
            # Enter with `nix develop .#full`. Note: gem locking is also
            # available without this shell via `nix run .#lock`.
            full = pkgs.mkShell (
              shellEnv
              // {
                packages =
                  corePackages
                  ++ (with pkgs; [
                    bundix
                    html-proofer
                    # For refreshing pnpm-lock.yaml (`pnpm install`).
                    pnpm_10
                    libwebp
                  ]);
              }
            );
          };
      }
    );
}
