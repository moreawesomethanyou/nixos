{ ... }:

{
  #############################################################
  ## Bluetooth
  #############################################################
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;        # показывать заряд наушников
        FastConnectable = true;
      };
      Policy.AutoEnable = "true";
    };
  };
  services.blueman.enable = true;
}