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
            "version": "1.3.0"
        }
    }
}
```

#### Options

- `version` (string): Bun version to install. Defaults to latest. (example: `1.3.0`)

### `zig`

Installs the [Zig](https://ziglang.org/) programming language - a general-purpose programming language and toolchain for maintaining robust, optimal, and reusable software.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/scaryrawr/dev-feats/zig:1": {
            "version": "0.15.2"
        }
    }
}
```

#### Options

- `version` (string): Zig version to install. Defaults to master. (example: `0.15.2`)

## Usage

To use these features in your dev container:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/scaryrawr/dev-feats/bun:1": {},
        "ghcr.io/scaryrawr/dev-feats/zig:1": {}
    }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
