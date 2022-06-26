## Dependencies

These are a list of dependencies for the process as a packager (i.e. running all the commands below), not for the build system (e.g. see the "Build package locally" section below).

```bash
tar
wget
dpkg-source
# Only needed if you're building locally.
debuild
# Only needed if you're using OBS.
osc
```

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

When building locally on Debian, you'll need to manually install the build dependencies (OBS handles this for you).

```bash
mk-build-deps --install debian/control
```

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
