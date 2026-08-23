{
  description = "Sota Connect (sotavpn) packaged for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        sotavpn = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.sotavpn;
      };

      overlays.default = final: _prev: {
        sotavpn = final.callPackage ./package.nix { };
      };

      # Builds the package against *your* nixpkgs, not this flake's input,
      # so the GTK libraries it links against are the ones on your system.
      nixosModules.sotavpn = { pkgs, lib, ... }: {
        imports = [ ./module.nix ];
        services.sotavpn.package = lib.mkDefault (pkgs.callPackage ./package.nix { });
      };
      nixosModules.default = self.nixosModules.sotavpn;
    };
}
