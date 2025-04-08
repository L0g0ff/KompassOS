# KompassOS &nbsp; [![bluebuild build badge](https://github.com/l0g0ff/kompassos/actions/workflows/build.yml/badge.svg)](https://github.com/l0g0ff/kompassos/actions/workflows/build.yml)

## About

KompassOS is a developer-friendly operating system based on Fedora Silverblue Aurora, designed specifically for DevOps engineers, system administrators, and network engineers. It offers a KDE-exclusive environment with pre-installed tools and applications, ensuring a ready-to-use workstation with minimal configuration. With features like automatic updates, enhanced security, and support for virtualization, KompassOS provides a robust and efficient platform for professionals.

## Vision for the Future

We believe that immutable, cloud-native, layered images represent the future of operating systems. This approach offers several key advantages:

1. **Enhanced Security**: Immutable images ensure that the base system cannot be tampered with, reducing the attack surface and making it easier to detect unauthorized changes.

2. **Simplified Updates**: Layered images allow for atomic updates, where only the changed layers are downloaded and applied. This minimizes downtime and ensures a consistent state across deployments.

3. **Reproducibility**: With immutable images, you can guarantee that every deployment is identical, eliminating "it works on my machine" issues and improving reliability in production environments.

4. **Cloud-Native Compatibility**: Layered images integrate seamlessly with containerized and cloud-native workflows, enabling faster deployments and better scalability.

5. **Developer Productivity**: By providing a consistent and pre-configured environment, developers can focus on building and deploying applications rather than managing system configurations.

KompassOS embraces this philosophy by leveraging Fedora Silverblue Aurora's immutable architecture and layering capabilities. This ensures that our users benefit from a modern, secure, and efficient operating system tailored for professional use cases. We are committed to driving innovation in this space and contributing to the broader adoption of immutable systems.

### Blue-Build Integration

KompassOS is built using [Blue-Build](https://blue-build.org), a powerful CI/CD framework designed for creating and maintaining layered operating system images. Blue-Build simplifies the process of managing complex builds by automating tasks such as dependency resolution, image layering, and signing. By integrating Blue-Build, KompassOS ensures a streamlined development workflow, enabling rapid iteration and consistent quality across releases. This partnership reflects our commitment to leveraging cutting-edge tools to deliver the best possible experience for our users.

## Desktop

![KompassOS Desktop](https://www.kompassos.nl/assets/aurora-hero.png)

## Installation


To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/l0g0ff/kompassos-dx-hwe:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/l0g0ff/kompassos-dx-hwe:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

You can download the ISO from [www.kompassos.nl](https://www.kompassos.nl). The ISO provides a bootable image that allows you to try out KompassOS without installing it on your system. It is ideal for testing or running a live session.

### How to Use the ISO

1. **Download the ISO**: Visit [www.kompassos.nl](https://www.kompassos.nl) and download the latest ISO file.
2. **Create a Bootable USB**: Use tools like [Rufus](https://rufus.ie/) (Windows), [Etcher](https://www.balena.io/etcher/) (cross-platform), or the `dd` command (Linux/macOS) to create a bootable USB drive.
3. **Boot from USB**: Restart your computer and boot from the USB drive. You may need to adjust your BIOS/UEFI settings to enable USB booting.
4. **Explore KompassOS**: Once booted, you can explore KompassOS in a live environment or proceed with installation if desired.

For detailed instructions on creating a bootable USB or troubleshooting boot issues, refer to the [official documentation](https://www.kompassos.nl/docs).

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/l0g0ff/kompassos
```

## Contribution

This code is part of a collaborative project, and contributions are highly appreciated. 
If you have suggestions for improvements, bug fixes, or new features, feel free to submit 
a pull request or open an issue. Your input helps make this project better for everyone. 
Thank you for your support and collaboration!
