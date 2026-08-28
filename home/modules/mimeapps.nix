{ ... }:

{
  #############################################################
  ## Чем открывать файлы и ссылки
  #############################################################
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                    = "google-chrome.desktop";
      "x-scheme-handler/http"        = "google-chrome.desktop";
      "x-scheme-handler/https"       = "google-chrome.desktop";
      "x-scheme-handler/about"       = "google-chrome.desktop";
      "x-scheme-handler/unknown"     = "google-chrome.desktop";
      "x-scheme-handler/claude-cli"  = "claude-code-url-handler.desktop";
      "x-scheme-handler/tg"          = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite"     = "org.telegram.desktop.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/bmp" = "org.gnome.eog.desktop";
      "image/tiff" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";
      "image/x-icon" = "org.gnome.eog.desktop";

      "text/plain" = [ "org.gnome.gedit.desktop" ];
      "text/markdown" = [ "org.gnome.gedit.desktop" ];
      "text/x-log" = [ "org.gnome.gedit.desktop" ];
      "application/x-shellscript" = [ "org.gnome.gedit.desktop" ];
      "application/json" = [ "org.gnome.gedit.desktop" ];
      "application/xml" = [ "org.gnome.gedit.desktop" ];
    };
    associations.added = {
      "x-scheme-handler/tg"      = [ "org.telegram.desktop.desktop" ];
      "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
      "image/jpeg" = [ "org.gnome.eog.desktop" ];
      "image/png" = [ "org.gnome.eog.desktop" ];
      "text/plain" = [ "org.gnome.gedit.desktop" ];
    };
  };
}
