## Dependencies

These are a list of dependencies for the process as a packager (i.e. running all the commands below), not for the build system (e.g. see the [Build package locally](#build-package-locally) section below).

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

If you have the `obs-service-download_url` package installed, you will need to remove it to create the `_service` file.

```bash
cd build
./build.sh create_includes
./build.sh create_service
./build.sh download
./build.sh build_source
```

2. Checkout OBS repository and then copy new and delete old source files.

```bash
osc co home:losuler:icecat
cp _service *.debian.tar.xz *.dsc *.orig.tar.gz home:losuler:icecat/icecat/
rm icecat_$OLD_VERSION.debian.tar.xz icecat_$OLD_VERSION.dsc icecat_$OLD_VERSION.orig.tar.gz
```

3. Test build for OBS locally. `x86_64` may be replaced with other arches such as `i586`. This depends on what arches are available on OBS.

If you removed the `obs-service-download_url` package earlier, you'll need to re-install it again in order to run the build.

```bash
osc build x86_64 Debian_11 --local-package --clean
```

4. Deploy to OBS (where it will be built).

```bash
osc ar
osc commit
```
