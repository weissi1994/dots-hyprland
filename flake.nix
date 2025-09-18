{
  description = "end_4's Hyprland dotfiles - illogical-impulse quickshell configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      forAllSystems =
        fn: nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      formatter = forAllSystems (pkgs: pkgs.alejandra);

      packages = forAllSystems (
        pkgs:
        let
          quickshell = pkgs.callPackage ./default.nix {
            rev = self.rev or self.dirtyRev or "dirty";
            quickshell = inputs.quickshell.packages.${pkgs.system}.default.withModules [
              pkgs.qt6.qt5compat
              pkgs.qt6.qtpositioning
            ];
          };
        in
        rec {
          illogical-impulse = quickshell;
          default = illogical-impulse;
        }
      );

      devShells = forAllSystems (pkgs: {
        default =
          let
            shell = self.packages.${pkgs.system}.illogical-impulse;
          in
          pkgs.mkShellNoCC {
            inputsFrom = [ shell ];
            packages = with pkgs; [
              # Development dependencies
              python311
              python311Packages.pillow
              python311Packages.material-color-utilities
              python311Packages.requests
              nodejs
              nodePackages.npm
            ];
          };
      });

      # NixOS module for easy integration
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          options.services.illogical-impulse = {
            enable = lib.mkEnableOption "illogical-impulse quickshell configuration";
            package = lib.mkPackageOption self.packages.${pkgs.system} "illogical-impulse" { };
          };

          config = lib.mkIf config.services.illogical-impulse.enable {
            environment.systemPackages = [ config.services.illogical-impulse.package ];

            # Required system dependencies
            programs.hyprland.enable = true;
            services.pipewire.enable = true;
            services.blueman.enable = true;
            hardware.bluetooth.enable = true;
          };
        };

      # Home Manager module for user configuration
      homeModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          illogical-impulse-pkg = self.packages.${pkgs.system}.illogical-impulse;
        in
        {
          imports = [
            (import ./home-manager-module.nix {
              inherit config lib pkgs;
              illogical-impulse = illogical-impulse-pkg;
            })
          ];
        };
    };
}
