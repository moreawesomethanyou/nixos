# Sota Connect (sotavpn) на NixOS

Апстрим публикует только `.deb`, `.rpm` и `.pkg.tar.zst`. Здесь то же самое,
переупаковано в Nix: бинарники берутся из официального Arch-пакета, патчатся
`autoPatchelfHook` под пути nix store, демон поднимается штатным модулем NixOS.

## Что внутри

| Файл | Назначение |
|---|---|
| `package.nix` | Деривация: качает `sotavpn-latest-x64.pkg.tar.zst`, патчит ELF, ставит GUI + демон |
| `module.nix` | Модуль NixOS: `services.sotavpn.enable`, юнит `sotad.service` |
| `flake.nix` | Флейк: `packages.sotavpn`, `nixosModules.default`, `overlays.default` |
| `update.sh` | Перепинить хэш и версию, когда апстрим выпустит обновление |

## Установка (flakes)

В `flake.nix` конфигурации:

```nix
{
  inputs.sotavpn.url = "path:/etc/nixos/sotavpn-nix";  # или git+https://...
  inputs.sotavpn.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, sotavpn, ... }: {
    nixosConfigurations.<хост> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        sotavpn.nixosModules.default
        { services.sotavpn.enable = true; }
      ];
    };
  };
}
```

## Установка (без flakes)

В `configuration.nix`:

```nix
{
  imports = [ /etc/nixos/sotavpn-nix/module.nix ];
  services.sotavpn.enable = true;
  services.sotavpn.package = pkgs.callPackage /etc/nixos/sotavpn-nix/package.nix { };
}
```

## Пакет несвободный

```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (nixpkgs.lib.getName pkg) [ "sotavpn" ];
```

Или просто `nixpkgs.config.allowUnfree = true;`.

## Опции модуля

| Опция | По умолчанию | Что делает |
|---|---|---|
| `services.sotavpn.enable` | `false` | Включает `sotad.service` |
| `services.sotavpn.installGui` | `true` | Кладёт GUI и `.desktop` в systemPackages |
| `services.sotavpn.fhsCompat` | `true` | Bind-mount демона в `/usr/libexec/sota-daemon` внутри неймспейса юнита |
| `services.sotavpn.splitTunnelAppDiscovery` | `true` | Подсовывает демону `/usr/share/applications` и `/usr/share/icons`, чтобы работал пер-аппный split tunnel |

## Проверено

Собрано и проверено на живой NixOS (VM, 2026-08-20): демон стартует, GUI
работает, трафик идёт, IP меняется — **с включённым фаерволом**.

## Обновление

Апстрим отдаёт только «latest» — фиксированного URL под версию нет. Когда Sota
выкатит новую сборку, `nix build` упадёт на несовпадении хэша. Тогда:

```sh
./update.sh && nixos-rebuild switch
```

## Что пришлось учесть (и почему)

- **`sing-box`** демон ищет рядом с собой, а не по абсолютному пути — в бинарнике
  нет строки `/usr/libexec/sota-daemon`. Поэтому store-путь работает как есть;
  `WorkingDirectory` и bind-mount оставлены подстраховкой.
- **`ip route` / `ip link` / `ip addr`** демон вызывает как внешние команды. У
  systemd-юнита PATH минимальный, поэтому в модуле прописан `iproute2` — без
  этого маршруты не поднимутся.
- **`libjvm.so`** не резолвится у `libdartjni.so` — ровно так же, как в
  оригинальном Arch-пакете. Плагин на Linux не грузится; зависимость внесена в
  `autoPatchelfIgnoreMissingDeps`.
- **GUI — Flutter-бандл**: `data/` и `lib/` ищутся относительно `/proc/self/exe`,
  поэтому каталог копируется целиком, а `bin/sotavpn` — обёртка, а не symlink
  в другое место.
- **Трей** требует `libayatana-appindicator` + `libayatana-indicator` +
  `ayatana-ido` + `libdbusmenu` (в nixpkgs атрибут называется `ayatana-ido`,
  без префикса `lib`).
- **GUI ↔ демон** общаются через TCP `127.0.0.1:16697`, никаких unix-сокетов
  в путях — правок под NixOS не потребовалось.
- **Фаервол NixOS** обязан доверять `tun0`, иначе VPN поднимается мёртвым:
  маршруты, правила и `tun0` настраиваются верно, `sing-box` живой, а трафика
  ноль. Модуль выставляет `networking.firewall.trustedInterfaces = [ "tun0" ]`.
  На Arch эта проблема не проявляется, если фаервол не настроен вовсе.
- **`checkReversePath = "loose"`** — строгий reverse-path filter конфликтует с
  policy-роутингом, которым пользуется sing-box (правила 9000-9010 → таблица
  2022). Причиной поломки оказался не он, но для такой схемы это правильный
  режим, и он совпадает с тем, что де-факто работает на Arch.
- **SELinux-модуль** из пакета не ставится: на NixOS он не нужен.
