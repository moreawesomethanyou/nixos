# Железо стационарного компьютера.
#
# Обычно этот файл генерирует установщик (nixos-generate-config), и тогда
# диски в нём записаны по UUID — числам, которые появляются только после
# форматирования. Здесь он написан заранее и потому опирается не на UUID,
# а на МЕТКИ разделов: они задаются при форматировании и известны заранее.
# Команды из инструкции (УСТАНОВКА.md, шаг 3) создают ровно эти метки:
#
#   NIXBOOT   раздел EFI (vfat), 1 ГиБ  -> /boot
#   nixroot   корень (ext4)             -> /
#   nixswap   подкачка                  -> swap
#
# Если разметка другая (другие метки, отдельный /home, шифрование, btrfs) —
# возьми файл, который сгенерировал установщик, и положи его сюда вместо
# этого. Сравнить их полезно в любом случае: см. шаг 6 инструкции.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Модули, нужные initrd, чтобы вообще увидеть диск: NVMe, SATA, USB.
  # Перечислены с запасом — лишние просто не загрузятся.
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];        # аппаратная виртуализация AMD
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixroot";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/nixswap"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
