# histree.zsh
# histree-zsh: A zsh plugin to log your command history along with execution directory context.
#
# This script logs executed commands with the following details:
#   1. Timestamp, ULID, and the execution directory (tab-separated)
#   2. The command's exit status
#   3. The executed command (if multi-line, base64-encoded into one line)
#   4. An empty line as a record separator
#
# Logs are stored under $HOME/.zsh_pwd_log in separate files per directory.
# The directory file name is generated by computing an MD5 hash of the directory path.
#
# To retrieve logs for the current directory (including subdirectories), run the function "histree".
#
# Requirements:
#   - md5sum (for generating unique file names)
#   - base64 (for encoding/decoding commands)

# Set the log directory; change ZSH_PWD_LOG_DIR to override the default.
export ZSH_PWD_LOG_DIR="${HOME}/.zsh_pwd_log"
mkdir -p "$ZSH_PWD_LOG_DIR"

# Function: sanitize_dir
# Generates a unique file name by hashing the full directory path using MD5.
sanitize_dir() {
  # $1: directory path
  if command -v md5sum > /dev/null 2>&1; then
    printf "%s" "$1" | md5sum | awk '{print $1}'
  else
    # Fallback: use base64 encoding (removing characters that may conflict)
    printf "%s" "$1" | base64 | tr -d '=+/\\\n'
  fi
}

# Function: generate_ulid
# Generates a ULID (Universally Unique Lexicographically Sortable Identifier).
# Uses the 'ulid' command if available; otherwise, creates a simple unique ID.
generate_ulid() {
  if command -v ulid > /dev/null 2>&1; then
    ulid
  else
    # Simple ULID: combine the current timestamp with a random value.
    printf "%s%04X" "$(date +%s)" $(( RANDOM ))
  fi
}

# Global temporary variables for logging (used by preexec and precmd).
__last_log_timestamp=""
__last_log_ulid=""
__last_log_dir=""
__last_log_command=""

# Function: preexec
# Called just before a command is executed.
# Stores the command and its context in temporary variables.
preexec() {
  __last_log_timestamp=$(date +%s)
  __last_log_ulid=$(generate_ulid)
  __last_log_dir=$PWD
  __last_log_command=$1
}

# Function: precmd
# Called immediately after a command executes.
# Writes the log record to the appropriate log file.
precmd() {
  local status=$?
  if [[ -n "$__last_log_command" ]]; then
    local sanitized_dir
    sanitized_dir=$(sanitize_dir "$__last_log_dir")
    local log_file="${ZSH_PWD_LOG_DIR}/${sanitized_dir}.log"
    # Encode the command using base64 to preserve newlines in a single line.
    local encoded_command
    encoded_command=$(printf "%s" "$__last_log_command" | base64 | tr -d '\n')
    {
      printf "%s\t%s\t%s\n" "$__last_log_timestamp" "$__last_log_ulid" "$__last_log_dir"
      printf "%s\n" "$status"
      printf "%s\n" "$encoded_command"
      printf "\n"
    } >> "$log_file"

    # Ensure the log file doesn't exceed 10,000 lines.
    if [ -f "$log_file" ]; then
      local line_count
      line_count=$(wc -l < "$log_file")
      if [ "$line_count" -gt 10000 ]; then
        tail -n 10000 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
      fi
    fi

    # Clear temporary log variables.
    unset __last_log_timestamp __last_log_ulid __last_log_dir __last_log_command
  fi
}

# Function: histree
# Retrieves and displays log records for the current directory and its subdirectories.
# Decodes the base64-encoded command to restore any newlines.
histree() {
  local curr_dir="$PWD"
  for logfile in "$ZSH_PWD_LOG_DIR"/*.log; do
    [ -f "$logfile" ] || continue
    # Process records (separated by an empty line)
    awk -v RS="" -v ORS="\n\n" -v curr_dir="$curr_dir" '
      {
        # Split the header (first line) by tab to get the directory.
        split($1, header, "\t");
        if (header[3] == curr_dir || index(header[3], curr_dir "/") == 1) {
          print $0;
        }
      }
    ' "$logfile" | while IFS= read -r record; do
      # Each record is assumed to have:
      #   Line 1: header (timestamp<TAB>ulid<TAB>dir)
      #   Line 2: result status (exit code)
      #   Line 3: encoded command (base64)
      local header status encoded_cmd
      header=$(printf "%s" "$record" | sed -n '1p')
      status=$(printf "%s" "$record" | sed -n '2p')
      encoded_cmd=$(printf "%s" "$record" | sed -n '3p')
      # Decode the base64 command to restore original formatting (with newlines).
      local decoded_cmd
      decoded_cmd=$(printf "%s" "$encoded_cmd" | base64 -d 2>/dev/null)
      printf "%s\n%s\n%s\n\n" "$header" "$status" "$decoded_cmd"
    done
  done
}
