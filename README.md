# nixos-config

Вся система — NixOS + Hyprland на Huawei MateBook — описана здесь.
Каналов (`nix-channel`) больше нет: версии пакетов зафиксированы в `flake.lock`.

## Что где лежит

```
flake.nix                     точка входа: входные nixpkgs/home-manager + сборка хоста
flake.lock                    точные версии всего. Меняется только через nix flake update
hosts/nixos/
  configuration.nix           системная часть (загрузчик, сервисы, systemPackages)
  hardware-configuration.nix  диски и железо, сгенерировано установщиком
home/
  roman.nix                   Home Manager: всё, что живёт в /home/roman
  files/                      сами дотфайлы (hypr, waybar, kitty, mako, wofi, fastfetch)
  bin/                        скрипты, которые попадают в ~/.local/bin
pkgs/wallpaperengine-gui.nix  пакет, которого нет в nixpkgs
sotavpn-nix/                  VPN: пакет + модуль, взяты как есть, не трогать
```

## Повседневные команды

| Команда    | Что делает |
|------------|------------|
| `rebuild`  | пересобрать и применить (`nixos-rebuild switch --flake ~/nixos-config#nixos`) |
| `update`   | `nix flake update` + пересборка — единственный способ обновить пакеты |
| `nixconf`  | открыть системный конфиг |
| `homeconf` | открыть конфиг Home Manager |
| `hyprconf` | открыть конфиг Hyprland |
| `garbage`  | удалить старые поколения и мусор из стора |

Откат, если сборка оказалась неудачной: `sudo nixos-rebuild switch --rollback`,
либо выбрать предыдущее поколение в меню загрузчика при старте.

## Как что-то поменять

**Добавить программу.** В `hosts/nixos/configuration.nix`, в
`environment.systemPackages`. Затем `rebuild`. Если программа нужна только
пользователю и настраивается через Home Manager — в `home.packages` в
`home/roman.nix`.

**Поправить Hyprland, waybar или kitty.** Правь файл в `home/files/` — он
подключён «живым» симлинком, изменения действуют сразу: `hyprctl reload`
для Hyprland, перезапуск waybar для панели. Пересборка не нужна. Не забудь
закоммитить.

**Поправить mako, wofi, fastfetch, GTK, fish, mimeapps.** Эти файлы едут через
`/nix/store` и в `~/.config` лежат только для чтения. Правь в репозитории
(`home/files/…` или прямо в `home/roman.nix`) и делай `rebuild`.

**Обновить систему.** `update`. Он меняет `flake.lock`; посмотри
`git diff flake.lock`, и если после обновления что-то сломалось —
`git checkout flake.lock && rebuild` вернёт прежние версии в точности.

## Что сюда намеренно не входит

Своё изменяемое состояние, которое программы переписывают сами и которое
бессмысленно держать декларативно: `fcitx5` (раскладки и словари mozc),
Chrome, Discord, Spotify, Steam, `dconf`. Они как были, так и остались
обычными файлами в `~/.config`.

## Заметки

* `nix-shell -p foo` и `nix run nixpkgs#foo` берут тот же самый запиненный
  nixpkgs, что и система, — это настроено через `nix.registry` и `nix.nixPath`
  в `hosts/nixos/configuration.nix`.
* Подсказки «команда не найдена, поставь пакет X» больше нет: она работает
  только через каналы. Замена, если понадобится, — `programs.nix-index`.
* При первом переходе Home Manager сохранил прежние версии всех файлов
  рядом с ними, с суффиксом `.hm-bak`. Когда убедишься, что всё в порядке,
  их можно удалить:
  `find ~/.config ~/.local/bin ~/.icons -name '*.hm-bak' -delete`
