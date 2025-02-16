# Install vagrant https://thenets.org/running-vagrant-libvirt-on-bluefin-or-aurora/
[group('Apps')]
install-vagrant:
    #!/usr/bin/env bash
    # Install the libvirt-devel - libvirt-devel already installed in KompassOS
    # rpm-ostree install libvirt-devel
    # Add the hashicorp/tap repo
    brew tap hashicorp/tap
    # Install vagrant for Linux
    brew install hashicorp/tap/vagrant
    # Install the vagrant-libvirt plugin
    vagrant plugin install vagrant-libvirt