# Firmware de fábrica, TWRP y root para tablets Rockchip RK3126 (rk30sdk, Android 5.1.1)

[Read in English](README.md)

Volcado completo de particiones de una tablet genérica Rockchip RK3126 (`tablet_PC`, placa `rk30sdk`, Android 5.1.1,
build `LMY48Y`), un recovery TWRP compatible con esta placa y documentación para recuperarla, respaldarla y rootearla.
La documentación técnica de `docs/` está en inglés.

Este firmware se distribuyó con varias marcas. El fingerprint lo identifica como **Emerson EM756**, y también contiene
identificadores de **Polaroid**, **X-View** y **Skyth-tek**.

> [!WARNING]
> Flashear imágenes de otro firmware puede dejar inservible un dispositivo Rockchip con memoria NAND.
> Verificá la [compatibilidad](#compatibilidad) antes de flashear y leé [LEGAL.md](LEGAL.md).

## Descargas

Los binarios no están dentro del repositorio. Los dos espejos tienen los mismos archivos:

- [**GitHub Releases**](https://github.com/Neo236/rk3126-stock-firmware-twrp-root-unbrick/releases)
- [**Internet Archive**](https://archive.org/details/rk3126-tablet-pc-lmy48y-stock-firmware-20160831), que además ofrece cada imagen de partición por separado

| Archivo | Tamaño | Contenido |
|---|---|---|
| `rk3126-tablet_PC-LMY48Y-20160831-boot-kit.zip` | 20 MB | `parameter`, `uboot`, `resource`, `kernel`, `boot`, `twrp` |
| `rk3126-tablet_PC-LMY48Y-20160831-system.zip` | 525 MB | `system` |

| Imagen | Partición | Origen | Descripción |
|---|---|---|---|
| `parameter.img` | `parameter` | Fábrica | Tabla de particiones y cmdline del kernel ([texto](device/parameter.txt)) |
| `uboot.img` | `uboot` | Fábrica | U-Boot 2014.10, compatible con Rockusb y fastboot |
| `resource.img` | `resource` | Fábrica | Logo de arranque y device tree |
| `kernel.img` | `kernel` | Fábrica | Linux 3.10.0 |
| `boot.img` | `boot` | Fábrica | Kernel y ramdisk |
| `system.img` | `system` | Fábrica + SuperSU 2.82 | Ver [nota sobre system.img](#nota-sobre-systemimg) |
| `twrp.img` | `recovery` | Terceros | TWRP 3.1.0-0 ([origen](docs/twrp.md#about-the-image)) |

Todas las imágenes son volcados crudos y completos de cada partición. Verificalas antes de flashear:

```bash
sha256sum -c --ignore-missing SHA256SUMS
```

### Nota sobre system.img

`system.img` se volcó después de rootear. Es el sistema de fábrica con SuperSU 2.82 instalado en `/system`; ningún otro
archivo fue modificado y no contiene datos personales ([lista completa de cambios](docs/image-formats.md#this-is-not-a-pristine-factory-system)).
La app de SuperSU incluida en `/system` es un stub de 28 KiB, por lo que en un dispositivo con `userdata` borrado hay que
instalar la app completa por ADB antes de que `su` funcione ([detalles](docs/root.md)).

## Compatibilidad

Compará con `adb shell getprop` en tu dispositivo. Archivo completo: [device/build.prop](device/build.prop).

| Propiedad | Valor |
|---|---|
| `ro.build.display.id` | `tablet_PC_2016-08-31` |
| `ro.build.id` | `LMY48Y` |
| `ro.build.version.release` | `5.1.1` |
| `ro.build.fingerprint` | `Emerson/EM756/EM756:5.1.1/LMY48Y/jingy08311656:user/release-keys` |
| `ro.product.board` | `rk30sdk` |
| `ro.board.platform` | `rk312x` |
| `ro.fota.oem` | `skyth-tek-RK3126_5.1` |

El valor de `mtdparts` en tu `/proc/cmdline` también tiene que ser idéntico al de [device/cmdline.txt](device/cmdline.txt).
Si difiere, el dispositivo usa otro firmware y no se deben flashear estas imágenes.

**Hardware:** Rockchip RK3126 (4x Cortex-A7, 32 bits), memoria NAND cruda mediante el driver `rknand` de Rockchip (no eMMC),
Linux 3.10.0, U-Boot 2014.10. Tabla de particiones: [docs/partition-layout.md](docs/partition-layout.md).

## Recuperación (unbrick)

Con el dispositivo en modo Loader (`adb reboot bootloader`), RKDevTool o AndroidTool en Windows, o
[rkdeveloptool](https://github.com/rockchip-linux/rkdeveloptool) en Linux, pueden reescribir todas las particiones:

1. Cargar `parameter.txt`.
2. Asignar `uboot`, `resource`, `kernel`, `boot`, `recovery` (`twrp.img`) y `system` a sus imágenes.
3. Flashear y luego borrar `data` y `cache` desde TWRP con *Advanced Wipe*.

Esto recupera soft bricks (bootloops, `system` dañado, recovery roto). Un dispositivo que solo responde en modo MaskROM
requiere además un MiniLoader RK312x, que no está incluido. El procedimiento completo todavía no se probó de punta a punta
con estos archivos.

## TWRP

TWRP no detecta ninguna partición hasta cargar el módulo del driver NAND. Desde `adb shell` en TWRP:

```sh
insmod /rk30xxnand_ko.ko.3.10.0
```

[scripts/twrp-init-nand.sh](scripts/twrp-init-nand.sh) carga el módulo y verifica el resultado.

> [!CAUTION]
> - Leer `/proc/mtd` con este driver provoca un kernel panic.
> - En este TWRP, *Factory Reset* también borra `system`. Usá *Advanced Wipe* y seleccioná solo *Data*.

Métodos de instalación y detalles: [docs/twrp.md](docs/twrp.md).

## Root

Probado en este dispositivo. En TWRP, después de cargar el driver NAND, ejecutar el instalador de SuperSU incluido:

```bash
adb shell sh /supersu/install-supersu.sh
```

Luego iniciar Android e instalar la app completa de SuperSU 2.82 (`common/Superuser.apk` de `SuperSU-v2.82-201705271822.zip`):

```bash
adb install -r Superuser.apk
```

Guía paso a paso y solución de problemas: [docs/root.md](docs/root.md).

## Documentación

| Documento | Contenido |
|---|---|
| [docs/partition-layout.md](docs/partition-layout.md) | Tabla de particiones, offsets, conversión de sectores |
| [docs/image-formats.md](docs/image-formats.md) | Cabeceras de imagen, extracción, cambios en `system` |
| [docs/twrp.md](docs/twrp.md) | Origen de TWRP, instalación, driver NAND |
| [docs/root.md](docs/root.md) | Root con SuperSU |
| [docs/dumping.md](docs/dumping.md) | Volcado de particiones desde un dispositivo |
| [device/README.md](device/README.md) | Notas sobre `build.prop`, cmdline del kernel y `parameter` |
| [scripts/README.md](scripts/README.md) | Scripts auxiliares, requisitos y pruebas |

## Contribuir

Todavía no están disponibles los siguientes archivos. Se aceptan aportes de un dispositivo idéntico, con su SHA-256:

- Imagen `system` de fábrica nunca rooteada
- Imagen `recovery` de fábrica
- MiniLoader RK312x para recuperación desde MaskROM

## Licencia

La documentación y los scripts se distribuyen bajo la [licencia MIT](LICENSE). Las imágenes de firmware pertenecen a sus
respectivos titulares y no están cubiertas por esta licencia; ver [LEGAL.md](LEGAL.md).

## Apoyo

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/neo236)
