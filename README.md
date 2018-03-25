ubuntu-tor-simply-setup
=======================

This script simply add the Tor repository to your Ubuntu GNU/Linux distribution, and setup this Tor as a relay node.

Try:

```
$ curl https://github.com/PeterDaveHello/ubuntu-tor-simply-setup/raw/master/setup.sh -Lo- | sudo bash
```

or
```
$ wget https://github.com/PeterDaveHello/ubuntu-tor-simply-setup/raw/master/setup.sh -O- | sudo bash
```

By default, we'll use 21 port to run tor service, the bandwidth rate and the burst will be limited by 1MB and 2MB, see `setup.sh` and `/etc/tor/torrc` for more details.
