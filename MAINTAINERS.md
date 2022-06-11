## Update package

1. Update `ICECATCOMMIT` from https://git.savannah.gnu.org/cgit/gnuzilla.git and `FFVERSION` which refers to the Firefox ESR release version number.

```bash
vim build/build.sh
vim debian/rules
```

2. Increment debian changelog entry.

```bash
cd debian
dch -i
```

## Build package locally

1. Download and build package.

```bash
cd build
./build.sh download
./build.sh build_deb
```

## Build source package for OBS

1. Download and build source package.

```bash
cd build
./build.sh create_includes
./build.sh create_service
./build.sh build_source
```

2. Test build for OBS locally. `x86_64` may be replaced with other arches such as `i586`. This depends on what arches are available on OBS.

```bash
osc build x86_64 Debian_11 --local-package --clean
```

3. Deploy to OBS (where it will be built).

```bash
osc ar
osc commit
```
