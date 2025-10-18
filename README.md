# Dev Container Features

A collection of [dev container Features](https://containers.dev/implementors/features/) for use with development containers.

## Features

### `bun`

Installs the [Bun](https://bun.sh/) JavaScript runtime - a fast all-in-one JavaScript runtime.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/scaryrawr/dev-feats/bun:1": {
            "version": "latest"
        }
    }
}
```

#### Options

- `version` (string): Bun version to install. Defaults to latest. (example: `1.3.0`)

## Usage

To use this Feature in your dev container:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/scaryrawr/dev-feats/bun:1": {}
    }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
