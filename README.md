# zsh-histree

**zsh-histree** is a zsh plugin that logs your command history along with the execution directory context, allowing you to explore a hierarchical narrative of your shell activity.

This project was developed with the assistance of ChatGPT and GitHub Copilot.

## Features

- **SQLite-Based Storage**  
  Command history is stored in a SQLite database, providing reliable and efficient storage with:
  - Optimized indexes for fast directory-based queries
  - Transaction support for data integrity
  - WAL mode for better concurrent access

- **Directory-Aware History**  
  Commands are stored with their execution directory context, allowing you to view history specific to your current directory and its subdirectories.

- **Session Tracking**
  Each zsh session is uniquely identified with:
  - Hostname of the machine
  - Session start timestamp
  - Process ID
  These are combined into a human-readable session label (e.g., "hostname:20240215-123456:1234")

- **Smart Command Output**
  - Simple format: `command`
  - Verbose format: `timestamp [directory] (session) command`
  - JSON format for programmatic access
  - Proper handling of multi-line commands
  - Intelligent escaping of special characters

## Installation

1. Clone this repository:
    ```sh
    git clone https://github.com/fuba/zsh-histree.git
    ```

2. Run the following command to build and install zsh-histree:
    ```sh
    make install
    ```

The install process will:
- Create the necessary directories
- Build the Go binary
- Add the configuration to your .zshrc
- Set up the default database location

## Configuration

### Database Location
By default, the history database is stored at `$HOME/.histree.db`. You can change this location by setting the `HISTREE_DB` environment variable in your `.zshrc`:

```zsh
export HISTREE_DB="$HOME/.config/histree/history.db"
```

### History Limit
The number of history entries to display can be configured using the `HISTREE_LIMIT` environment variable (default: 100):

```zsh
export HISTREE_LIMIT=500
```

### Command Line Options

When using the histree commands directly, the following options are available:

```sh
-db string      Path to SQLite database (required)
-action string  Action to perform: add or get
-dir string     Current directory for filtering entries
-format string  Output format: json, simple, or verbose (default "simple")
-limit int      Number of entries to retrieve (default 100)
-session string Session label for command history (required for add action)
-exit int       Exit code of the command
-v              Show verbose output (same as -format verbose)
```

## Usage

After installation, zsh-histree will automatically start logging your commands.

View command history in different formats:
```sh
$ histree        # Simple format (like standard history command)
npm install
npm run build
git status

$ histree -v     # Verbose format with all details
2024-02-15T15:04:30Z [/home/user/projects/web-app] <laptop:20240215-150430:1234> npm install
2024-02-15T15:05:15Z [/home/user/projects/web-app] <laptop:20240215-150430:1234> npm run build
2024-02-15T15:06:00Z [/home/user/projects/web-app] <laptop:20240215-150430:1234> git status

$ histree -json  # JSON format for programmatic use
{"command":"npm install","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T15:04:30Z","exit_code":0,"session_label":"laptop:20240215-150430:1234"}
{"command":"npm run build","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T15:05:15Z","exit_code":1,"session_label":"laptop:20240215-150430:1234"}
{"command":"git status","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T15:06:00Z","exit_code":0,"session_label":"laptop:20240215-150430:1234"}
```

The verbose output format (`histree -v`) includes:
- Full timestamp (RFC3339 format)
- Working directory
- Exit code (if non-zero)
- Session identifier
- The command itself

### Example Session

```sh
$ cd ~/projects/web-app
$ npm install           # Installing dependencies
$ npm run build        # Building the project
$ cd dist
$ ls -la              # Checking build output
$ cd ..
$ git status

$ cd ~/another-project
$ vim README.md        # Editing README
$ git add README.md
$ git commit -m "Update README"

$ cd ~/projects/web-app
$ histree -v           # View detailed history in current directory
2024-02-15T10:30:15Z [/home/user/projects/web-app] <laptop:20240215-103012:1234> npm install
2024-02-15T10:31:20Z [/home/user/projects/web-app] <laptop:20240215-103012:1234> npm run build
2024-02-15T10:31:45Z [/home/user/projects/web-app/dist] <laptop:20240215-103012:1234> ls -la
2024-02-15T10:32:10Z [/home/user/projects/web-app] <laptop:20240215-103012:1234> git status

$ histree -json        # View history in JSON format
{"command":"npm install","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T10:30:15Z","session_label":"laptop:20240215-103012:1234"}
{"command":"npm run build","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T10:31:20Z","session_label":"laptop:20240215-103012:1234"}
{"command":"ls -la","directory":"/home/user/projects/web-app/dist","timestamp":"2024-02-15T10:31:45Z","session_label":"laptop:20240215-103012:1234"}
{"command":"git status","directory":"/home/user/projects/web-app","timestamp":"2024-02-15T10:32:10Z","session_label":"laptop:20240215-103012:1234"}

$ cd ~/another-project
$ histree -v           # Different directory shows different history
2024-02-15T10:35:00Z [/home/user/another-project] <laptop:20240215-103012:1234> vim README.md
2024-02-15T10:35:30Z [/home/user/another-project] <laptop:20240215-103012:1234> git add README.md
2024-02-15T10:36:00Z [/home/user/another-project] <laptop:20240215-103012:1234> git commit -m "Update README"
```

This example demonstrates how zsh-histree helps track your development workflow across different directories and projects, maintaining the context of your work.

## Requirements

- Zsh
- Go (for building the binary)
- SQLite

## License

This project is licensed under the MIT License.
