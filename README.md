# nixos-config

Две машины — NixOS + Hyprland — описаны здесь:

| Хост      | Что это                                        |
|-----------|------------------------------------------------|
| `nixos`   | ноутбук Huawei MateBook (Intel + встроенка)    |
| `desktop` | стационарный компьютер (AMD + видеокарта AMD)  |

Каналов (`nix-channel`) больше нет: версии пакетов зафиксированы в `flake.lock`.
Обе машины собираются из одного и того же `flake.lock`, то есть версии пакетов
на них совпадают до коммита.

## Что где лежит

```
flake.nix                     точка входа: входные nixpkgs/home-manager + обе машины
flake.lock                    точные версии всего. Меняется только через nix flake update
hosts/
  common.nix                  ВСЁ ОБЩЕЕ: сервисы, systemPackages, локаль, шрифты, звук
  nixos/configuration.nix     только ноутбучное: батарея, крышка, графика Intel
  nixos/hardware-configuration.nix
  desktop/configuration.nix   только десктопное: amdgpu, amd_pstate
  desktop/hardware-configuration.nix
home/
  roman.nix                   Home Manager: всё, что живёт в /home/roman
  files/                      сами дотфайлы (hypr, waybar, kitty, mako, wofi, fastfetch)
  bin/                        скрипты, которые попадают в ~/.local/bin
pkgs/wallpaperengine-gui.nix  пакет, которого нет в nixpkgs
sotavpn-nix/                  VPN: пакет + модуль, взяты как есть, не трогать
```

## Повседневные команды

| Команда      | Что делает |
|--------------|------------|
| `rebuild`    | пересобрать и применить (`nixos-rebuild switch --flake ~/nixos-config`) |
| `update`     | `nix flake update` + пересборка — единственный способ обновить пакеты |
| `nixconf`    | открыть конфиг ЭТОЙ машины (`hosts/<имя хоста>/configuration.nix`) |
| `commonconf` | открыть общую часть (`hosts/common.nix`) |
| `homeconf`   | открыть конфиг Home Manager |
| `hyprconf`   | открыть конфиг Hyprland |
| `garbage`    | удалить старые поколения и мусор из стора |

`rebuild` намеренно без `#nixos`: `nixos-rebuild` сам берёт конфигурацию по
имени хоста, поэтому одна и та же команда работает на обеих машинах. Собрать
чужой конфиг, не применяя (например, проверить десктоп с ноутбука):

```
nixos-rebuild build --flake ~/nixos-config#desktop
```

Откат, если сборка оказалась неудачной: `sudo nixos-rebuild switch --rollback`,
либо выбрать предыдущее поколение в меню загрузчика при старте.

## Как что-то поменять

**Добавить программу.** В `hosts/common.nix`, в `environment.systemPackages` —
тогда она появится на обеих машинах. Если нужна только на одной, то же самое,
но в `hosts/<машина>/configuration.nix`. Затем `rebuild`. Если программа нужна
только пользователю и настраивается через Home Manager — в `home.packages` в
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

## Чем отличаются машины

Различий немного, и разведены они тремя разными способами — каждый там, где
он уместен:

* **Система** — отдельные файлы `hosts/nixos/` и `hosts/desktop/`. Там
  графические драйверы, батарея с крышкой (ноутбук), `amdgpu` и `amd_pstate`
  (десктоп). Всё остальное лежит в `hosts/common.nix` в одном экземпляре.

* **Hyprland** — один файл на обе машины, `home/files/hypr/hyprland.lua`.
  Он на Lua, поэтому просто смотрит, есть ли в системе батарея (раздел
  «КАКАЯ ЭТО МАШИНА»), и от этого зависят мониторы, клавиши яркости,
  реакция на крышку и жесты тачпада. **Мониторы десктопа настраиваются
  именно здесь**, в разделе «МОНИТОРЫ».

* **Панель** — два файла: `waybar/config.jsonc` (ноутбук, с батареей и
  яркостью) и `waybar/config-desktop.jsonc` (десктоп, без них, и температура
  берётся с AMD). Нужный выбирается в `home/roman.nix` по имени хоста.
  У waybar конфиг на JSON, а в нём нельзя написать «если», отсюда и два файла:
  **правишь панель для красоты — правь оба**. Стиль `style.css` общий.

## Что сюда намеренно не входит

Своё изменяемое состояние, которое программы переписывают сами и которое
бессмысленно держать декларативно: `fcitx5` (раскладки и словари mozc),
Chrome, Discord, Spotify, Steam, `dconf`. Они как были, так и остались
обычными файлами в `~/.config`.

## Заметки

* `nix-shell -p foo` и `nix run nixpkgs#foo` берут тот же самый запиненный
  nixpkgs, что и система, — это настроено через `nix.registry` и `nix.nixPath`
  в `hosts/common.nix`.
* Подсказки «команда не найдена, поставь пакет X» больше нет: она работает
  только через каналы. Замена, если понадобится, — `programs.nix-index`.
* При первом переходе Home Manager сохранил прежние версии всех файлов
  рядом с ними, с суффиксом `.hm-bak`. Когда убедишься, что всё в порядке,
  их можно удалить:
  `find ~/.config ~/.local/bin ~/.icons -name '*.hm-bak' -delete`
