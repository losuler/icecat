<div align="center">
<p align="center">
  <p align="center">
    <h3 align="center">GNU IceCat Deb</h3>
    <p align="center">
      Debian packaging for GNU IceCat.
    </p>
  </p>
</p>
</div>

## About

This is Debian packaging for [GNU IceCat](https://www.gnu.org/software/gnuzilla/). The latest release version of GNU IceCat is based on the outdated Firefox 60.7.0 ESR release, these builds are currently built from the latest commits from the GNU IceCat git repository at https://git.savannah.gnu.org/cgit/gnuzilla.git.

## Builds

Builds are available on OBS at https://build.opensuse.org/package/show/home:losuler:icecat/icecat.

This repo can be added on Debian 10 for example by ([see here](https://software.opensuse.org//download.html?project=home%3Alosuler%3Aicecat&package=icecat) for examples for other Debian releases):

```bash
echo 'deb https://download.opensuse.org/repositories/home:/losuler:/icecat/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/home:losuler:icecat.list
curl -fsSL https://download.opensuse.org/repositories/home:losuler:icecat/Debian_10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_losuler_icecat.gpg > /dev/null
```
