# OpenCode AI Feature

This feature installs [OpenCode](https://github.com/sst/opencode), an AI coding agent built for the terminal.

## Usage

```json
{
    "features": {
        "ghcr.io/scaryrawr/dev-feats/opencode:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installLocation` | string | _(empty)_ | Installation directory for the opencode binary. Leave empty to use OpenCode's default (`~/.opencode/bin`) |
| `theme` | string | _(empty)_ | Theme name to use for the interface |
| `model` | string | _(empty)_ | Model to use in the format of provider/model, eg `anthropic/claude-3-5-sonnet-20241022` |
| `smallModel` | string | _(empty)_ | Small model to use for tasks like summarization and title generation |
| `username` | string | _(empty)_ | Custom username to display in conversations instead of system username |
| `autoupdate` | boolean | `true` | Automatically update to the latest version |
| `share` | string | `disabled` | Control sharing behavior: `manual`, `auto`, or `disabled` |
| `leaderKey` | string | `ctrl+x` | Leader key for keybind combinations |

## Example with options

```json
{
    "features": {
        "ghcr.io/scaryrawr/dev-feats/opencode:1": {
            "theme": "dracula",
            "model": "anthropic/claude-3-5-sonnet-20241022",
            "smallModel": "anthropic/claude-3-haiku-20240307",
            "username": "developer",
            "autoupdate": true,
            "share": "disabled",
            "leaderKey": "ctrl+x"
        }
    }
}
```

## What gets installed

- **OpenCode binary**: Installed to the specified location (default: `~/.opencode/bin`)
- **PATH configuration**: The installation directory is added to the system PATH
- **Configuration file**: A `config.json` file is created in `~/.opencode/` with the specified options

## After installation

The `opencode` command will be available in your PATH. You can start it by running:

```bash
opencode
```

The configuration file will be automatically created at `~/.opencode/config.json` with your specified options.

## Documentation

For more information about OpenCode configuration and usage, visit:
- [OpenCode Documentation](https://opencode.ai/docs)
- [GitHub Repository](https://github.com/sst/opencode)
- [Configuration Schema](https://opencode.ai/config.json)
