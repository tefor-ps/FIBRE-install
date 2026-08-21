#!/usr/bin/env bash

# Bootstrap installer for the file system based database (fsdb).
#
# This script owns repository-related installation work:
#   * prerequisite checks
#   * manifest parsing and validation
#   * required/optional module selection
#   * exact-tag verification
#   * staging and cloning
#   * hand-off to fsdb-core/install/initializeFsdb.sh

set -Eeuo pipefail

SCRIPT_NAME=$(basename -- "$0")
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
MANIFEST="${SCRIPT_DIR}/manifest.yaml"

INSTALL_BASE="${HOME}"
INSTALL_BASE_SET=0
LIST_ONLY=0
ALL_OPTIONAL=0
OPTIONAL_REQUESTS=()
STAGE_ROOT=""
RELEASE_VERSION=""

# Pinned bootstrap release used only when Mike Farah yq v4+ is not already available.
YQ_BOOTSTRAP_VERSION="v4.53.3"
YQ_INSTALL_PATH="/usr/local/bin/yq"
YQ_TMPDIR=""

ALL_MODULES=()
SELECTED_MODULES=()
declare -A MODULE_REPOSITORY=()
declare -A MODULE_VERSION=()
declare -A MODULE_DIRECTORY=()
declare -A MODULE_OPTIONAL=()
declare -A SELECTED_SET=()
declare -A EXPECTED_COMMITS=()

intro() {
    if [[ -t 2 ]]; then
        printf '\r\e[2K\t\e[36;1m%s\e[0m\n' "$*" >&2
    else
        printf '%s\n' "$*" >&2
    fi
}

warn() {
    if [[ -t 2 ]]; then
        printf '\r\e[2K\t\e[33;1mWARNING: %s\e[0m\n' "$*" >&2
    else
        printf 'WARNING: %s\n' "$*" >&2
    fi
}

fail() {
    if [[ -t 2 ]]; then
        printf '\r\e[2K\t\e[31;1mERROR: %s\e[0m\n' "$*" >&2
    else
        printf 'ERROR: %s\n' "$*" >&2
    fi
    exit 1
}

usage() {
    cat <<USAGE
Usage:
  ${SCRIPT_NAME} [OPTIONS] [INSTALL_BASE]

Required modules are always installed. Optional modules are installed only when
explicitly requested.

Options:
  -o, --optional MODULE   Also install optional MODULE. May be repeated.
      --all-optional      Install every optional module in manifest.yaml.
  -l, --list-modules      List modules from manifest.yaml and exit.
  -h, --help              Show this help and exit.

INSTALL_BASE:
  Existing directory below which initializeFsdb.sh will create the fsdb
  installation. Defaults to HOME.

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} /srv
  ${SCRIPT_NAME} --optional drive-connector /srv
  ${SCRIPT_NAME} --all-optional /srv
  ${SCRIPT_NAME} --list-modules
USAGE
}

cleanup() {
    if [[ -n "$STAGE_ROOT" && -d "$STAGE_ROOT" ]]; then
        rm -rf -- "$STAGE_ROOT"
    fi

    if [[ -n "$YQ_TMPDIR" && -d "$YQ_TMPDIR" ]]; then
        rm -rf -- "$YQ_TMPDIR"
    fi
}

parse_arguments() {
    while (($#)); do
        case "$1" in
            -o|--optional)
                (($# >= 2)) || fail "$1 requires a module name."
                OPTIONAL_REQUESTS+=("$2")
                shift 2
                ;;
            --all-optional)
                ALL_OPTIONAL=1
                shift
                ;;
            -l|--list-modules)
                LIST_ONLY=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                (($# <= 1)) || fail "Only one INSTALL_BASE may be specified."
                if (($# == 1)); then
                    INSTALL_BASE="$1"
                    INSTALL_BASE_SET=1
                fi
                break
                ;;
            -*)
                fail "Unknown option: $1"
                ;;
            *)
                ((INSTALL_BASE_SET == 0)) || fail "Only one INSTALL_BASE may be specified."
                INSTALL_BASE="$1"
                INSTALL_BASE_SET=1
                shift
                ;;
        esac
    done
}

download_file() {
    local url=$1 destination=$2

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error \
            --retry 3 --connect-timeout 15 \
            --output "$destination" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --tries=3 --timeout=15 \
            --output-document="$destination" "$url"
    else
        fail "Installing yq requires either curl or wget. Neither is available."
    fi
}

validate_mikefarah_yq_executable() {
    local executable=$1 detected major

    [[ -x "$executable" ]] || return 1
    detected=$("$executable" --version 2>&1) || return 1

    [[ "$detected" == *"github.com/mikefarah/yq"* ]] || return 1

    if [[ "$detected" =~ version[[:space:]]+v?([0-9]+)\. ]]; then
        major=${BASH_REMATCH[1]}
    else
        return 1
    fi

    ((major >= 4)) || return 1
    printf '%s\n' "$detected"
}

install_mikefarah_yq() {
    local answer machine yq_arch asset base_url
    local binary checksums hashes_order sha_line sha_column
    local expected_sha actual_sha installed_version

    warn "Mike Farah yq v4+ is required but no compatible 'yq' is currently available."
    printf 'Install Mike Farah yq %s to %s now? [y/N] ' \
        "$YQ_BOOTSTRAP_VERSION" "$YQ_INSTALL_PATH" >&2

    if [[ ! -t 0 ]]; then
        printf '\n' >&2
        fail "Cannot ask for installation permission in a non-interactive session. Install Mike Farah yq v4+ manually and rerun the installer."
    fi

    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]] || fail \
        "Installation cancelled: Mike Farah yq v4+ is required."

    [[ "$(uname -s)" == "Linux" ]] || fail \
        "Automatic yq installation is currently supported only on Linux."

    machine=$(uname -m)
    case "$machine" in
        x86_64|amd64)
            yq_arch="amd64"
            ;;
        aarch64|arm64)
            yq_arch="arm64"
            ;;
        armv7l|armv7*|armv6l|armv6*)
            yq_arch="arm"
            ;;
        i386|i486|i586|i686)
            yq_arch="386"
            ;;
        *)
            fail "Unsupported CPU architecture for automatic yq installation: ${machine}"
            ;;
    esac

    command -v sha256sum >/dev/null 2>&1 || fail \
        "Installing yq securely requires sha256sum."
    command -v install >/dev/null 2>&1 || fail \
        "Installing yq requires the 'install' command."
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        fail "Installing yq requires either curl or wget. Neither is available."
    fi
    if ((EUID != 0)); then
        command -v sudo >/dev/null 2>&1 || fail \
            "Installing yq to ${YQ_INSTALL_PATH} requires sudo."
    fi

    asset="yq_linux_${yq_arch}"
    base_url="https://github.com/mikefarah/yq/releases/download/${YQ_BOOTSTRAP_VERSION}"

    YQ_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/fsdb-yq.XXXXXXXX") || fail \
        "Unable to create a temporary directory for yq installation."
    binary="${YQ_TMPDIR}/${asset}"
    checksums="${YQ_TMPDIR}/checksums"
    hashes_order="${YQ_TMPDIR}/checksums_hashes_order"

    intro "Downloading Mike Farah yq ${YQ_BOOTSTRAP_VERSION} (${asset})..."
    download_file "${base_url}/${asset}" "$binary" || fail \
        "Unable to download ${asset} from the official Mike Farah yq release."
    download_file "${base_url}/checksums" "$checksums" || fail \
        "Unable to download the yq release checksums."
    download_file "${base_url}/checksums_hashes_order" "$hashes_order" || fail \
        "Unable to download the yq checksum hash-order file."

    # Mike Farah's release 'checksums' file stores the filename in column 1,
    # followed by hash columns in the order listed by checksums_hashes_order.
    # Therefore SHA-256's checksum column is its line number in that file + 1.
    sha_line=$(awk '$0 == "SHA-256" {print NR; exit}' "$hashes_order")
    [[ "$sha_line" =~ ^[0-9]+$ ]] || fail \
        "The yq release metadata does not define a SHA-256 checksum column."
    sha_column=$((sha_line + 1))

    expected_sha=$(awk -v file="$asset" -v column="$sha_column" \
        '$1 == file {print $column; exit}' "$checksums")
    [[ "$expected_sha" =~ ^[[:xdigit:]]{64}$ ]] || fail \
        "Could not extract the SHA-256 checksum for ${asset}."

    actual_sha=$(sha256sum "$binary" | awk '{print $1}')
    if [[ "${actual_sha,,}" != "${expected_sha,,}" ]]; then
        fail "SHA-256 verification failed for ${asset}. Expected ${expected_sha}, got ${actual_sha}."
    fi
    intro "SHA-256 verification passed."

    chmod 0755 "$binary" || fail "Unable to mark the downloaded yq binary executable."
    installed_version=$(validate_mikefarah_yq_executable "$binary") || fail \
        "The downloaded binary is not a valid Mike Farah yq v4+ executable."

    intro "Installing ${installed_version} as ${YQ_INSTALL_PATH}"
    if ((EUID == 0)); then
        install -d -m 0755 -- "$(dirname -- "$YQ_INSTALL_PATH")" || fail \
            "Unable to create $(dirname -- "$YQ_INSTALL_PATH")."
        install -m 0755 -- "$binary" "$YQ_INSTALL_PATH" || fail \
            "Unable to install yq as ${YQ_INSTALL_PATH}."
    else
        sudo install -d -m 0755 -- "$(dirname -- "$YQ_INSTALL_PATH")" || fail \
            "Unable to create $(dirname -- "$YQ_INSTALL_PATH") with sudo."
        sudo install -m 0755 -- "$binary" "$YQ_INSTALL_PATH" || fail \
            "Unable to install yq as ${YQ_INSTALL_PATH} with sudo."
    fi

    rm -rf -- "$YQ_TMPDIR"
    YQ_TMPDIR=""

    # Ensure the just-installed binary wins over an incompatible yq elsewhere
    # on PATH, and clear Bash's command lookup cache.
    case ":${PATH}:" in
        *:"$(dirname -- "$YQ_INSTALL_PATH")":*) ;;
        *) PATH="$(dirname -- "$YQ_INSTALL_PATH"):${PATH}" ;;
    esac
    export PATH
    hash -r

    installed_version=$(validate_mikefarah_yq_executable "$YQ_INSTALL_PATH") || fail \
        "yq was installed but post-install validation failed."
    intro "Installed ${installed_version}"
}

check_mikefarah_yq() {
    local yq_path detected

    if yq_path=$(command -v yq 2>/dev/null); then
        if detected=$(validate_mikefarah_yq_executable "$yq_path"); then
            intro "Found ${detected}"
            return 0
        fi

        detected=$("$yq_path" --version 2>&1 || true)
        warn "The existing yq at ${yq_path} is incompatible: ${detected:-version could not be determined}"
    fi

    install_mikefarah_yq

    yq_path=$(command -v yq 2>/dev/null) || fail \
        "Mike Farah yq was installed but cannot be found on PATH."
    detected=$(validate_mikefarah_yq_executable "$yq_path") || fail \
        "The yq executable selected after installation is not Mike Farah yq v4+: ${yq_path}"
    intro "Using ${detected}"
}

check_prerequisites() {
    ((BASH_VERSINFO[0] >= 4)) || fail "Bash 4 or newer is required."

    local cmd
    for cmd in git awk mktemp realpath rsync; do
        command -v "$cmd" >/dev/null 2>&1 || fail "Missing prerequisite: ${cmd}"
    done

    if ((EUID != 0)); then
        command -v sudo >/dev/null 2>&1 || fail \
            "Missing prerequisite: sudo is required to invoke initializeFsdb.sh."
    fi

    check_mikefarah_yq
    [[ -r "$MANIFEST" ]] || fail "Cannot read manifest: ${MANIFEST}"
}

module_exists() {
    [[ -n "${MODULE_REPOSITORY[$1]+x}" ]]
}

load_and_validate_manifest() {
    intro "Validating manifest: ${MANIFEST}"

    yq eval '.' "$MANIFEST" >/dev/null 2>&1 || fail "manifest.yaml is not valid YAML."
    yq -e '.schema == 1' "$MANIFEST" >/dev/null 2>&1 || fail \
        "Unsupported or missing manifest schema. This installer requires schema: 1."

    RELEASE_VERSION=$(yq -r '.version // ""' "$MANIFEST")
    [[ -n "$RELEASE_VERSION" && "$RELEASE_VERSION" != "null" ]] || fail \
        "manifest.yaml is missing the top-level version."

    local rows module repository version directory optional extra
    rows=$(yq -r \
        '.modules | to_entries[] | [.key, .value.repository, .value.version, .value.directory, .value.optional] | @tsv' \
        "$MANIFEST" 2>/dev/null) || fail "manifest.yaml is missing a valid modules mapping."

    [[ -n "$rows" ]] || fail "manifest.yaml contains no modules."

    declare -A seen_directories=()

    while IFS=$'\t' read -r module repository version directory optional extra; do
        [[ -z "${extra:-}" ]] || fail "Malformed module record for '${module}'."
        [[ "$module" =~ ^[A-Za-z0-9._-]+$ ]] || fail "Invalid module name: '${module}'"
        [[ -n "$repository" && "$repository" != "null" ]] || fail "Module '${module}' is missing repository."
        [[ -n "$version" && "$version" != "null" ]] || fail "Module '${module}' is missing version."
        [[ -n "$directory" && "$directory" != "null" ]] || fail "Module '${module}' is missing directory."
        [[ "$optional" == "true" || "$optional" == "false" ]] || fail \
            "Module '${module}': optional must be true or false."

        [[ "$directory" =~ ^[A-Za-z0-9._-]+$ && "$directory" != "." && "$directory" != ".." ]] || fail \
            "Module '${module}': unsafe/unsupported directory '${directory}'."

        [[ -z "${seen_directories[$directory]+x}" ]] || fail \
            "Modules '${seen_directories[$directory]}' and '${module}' use the same directory '${directory}'."

        git check-ref-format "refs/tags/${version}" >/dev/null 2>&1 || fail \
            "Module '${module}': '${version}' is not a valid Git tag name."

        ALL_MODULES+=("$module")
        MODULE_REPOSITORY[$module]="$repository"
        MODULE_VERSION[$module]="$version"
        MODULE_DIRECTORY[$module]="$directory"
        MODULE_OPTIONAL[$module]="$optional"
        seen_directories[$directory]="$module"
    done <<< "$rows"

    ((${#ALL_MODULES[@]} > 0)) || fail "manifest.yaml contains no usable modules."
    module_exists core || fail "manifest.yaml must define the 'core' module."
    [[ "${MODULE_OPTIONAL[core]}" == "false" ]] || fail \
        "The 'core' module must be required (optional: false)."

    intro "Manifest schema 1 valid; release set: ${RELEASE_VERSION}"
}

list_modules() {
    local module kind

    printf '%-18s %-10s %-12s %-16s %s\n' \
        "MODULE" "TYPE" "VERSION" "DIRECTORY" "REPOSITORY"
    printf '%-18s %-10s %-12s %-16s %s\n' \
        "------------------" "----------" "------------" "----------------" "----------"

    for module in "${ALL_MODULES[@]}"; do
        [[ "${MODULE_OPTIONAL[$module]}" == "true" ]] && kind="optional" || kind="required"
        printf '%-18s %-10s %-12s %-16s %s\n' \
            "$module" "$kind" "${MODULE_VERSION[$module]}" \
            "${MODULE_DIRECTORY[$module]}" "${MODULE_REPOSITORY[$module]}"
    done
}

select_module() {
    local module=$1
    if [[ -z "${SELECTED_SET[$module]+x}" ]]; then
        SELECTED_MODULES+=("$module")
        SELECTED_SET[$module]=1
    fi
}

select_modules() {
    local module requested

    for module in "${ALL_MODULES[@]}"; do
        [[ "${MODULE_OPTIONAL[$module]}" == "false" ]] && select_module "$module"
    done

    if ((ALL_OPTIONAL)); then
        for module in "${ALL_MODULES[@]}"; do
            [[ "${MODULE_OPTIONAL[$module]}" == "true" ]] && select_module "$module"
        done
    fi

    for requested in "${OPTIONAL_REQUESTS[@]}"; do
        module_exists "$requested" || fail \
            "Requested module '${requested}' is not defined. Use --list-modules to see valid names."
        if [[ "${MODULE_OPTIONAL[$requested]}" == "false" ]]; then
            warn "Module '${requested}' is required and is already selected."
        fi
        select_module "$requested"
    done

    [[ -n "${SELECTED_SET[core]+x}" ]] || fail "Internal error: core was not selected."
}

show_selection() {
    local module kind

    intro "Modules selected for installation:"
    for module in "${SELECTED_MODULES[@]}"; do
        [[ "${MODULE_OPTIONAL[$module]}" == "true" ]] && kind="optional" || kind="required"
        printf '  %-18s %-10s %-12s -> %s\n' \
            "$module" "[$kind]" "${MODULE_VERSION[$module]}" "${MODULE_DIRECTORY[$module]}" >&2
    done
}

remote_tag_commit() {
    local repository=$1 version=$2 refs direct peeled

    if ! refs=$(GIT_TERMINAL_PROMPT=0 git ls-remote \
        "$repository" "refs/tags/${version}" "refs/tags/${version}^{}" 2>/dev/null); then
        return 2
    fi

    direct=$(awk -v ref="refs/tags/${version}" '$2 == ref {print $1; exit}' <<< "$refs")
    [[ -n "$direct" ]] || return 1

    peeled=$(awk -v ref="refs/tags/${version}^{}" '$2 == ref {print $1; exit}' <<< "$refs")
    printf '%s\n' "${peeled:-$direct}"
}

verify_selected_tags() {
    local module expected rc

    intro "Checking repository access and exact release tags..."

    for module in "${SELECTED_MODULES[@]}"; do
        printf '  %-18s %-12s ' "$module" "${MODULE_VERSION[$module]}" >&2

        if expected=$(remote_tag_commit \
            "${MODULE_REPOSITORY[$module]}" "${MODULE_VERSION[$module]}"); then
            EXPECTED_COMMITS[$module]="$expected"
            printf 'OK\n' >&2
        else
            rc=$?
            printf 'FAIL\n' >&2
            if ((rc == 1)); then
                fail "Module '${module}': exact tag '${MODULE_VERSION[$module]}' does not exist in ${MODULE_REPOSITORY[$module]}."
            else
                fail "Module '${module}': cannot access repository ${MODULE_REPOSITORY[$module]}."
            fi
        fi
    done
}

stage_module() {
    local module=$1 destination head local_tag_commit expected

    destination="${STAGE_ROOT}/${MODULE_DIRECTORY[$module]}"
    expected=${EXPECTED_COMMITS[$module]}

    intro "Staging ${module} ${MODULE_VERSION[$module]} -> ${destination}"

    GIT_TERMINAL_PROMPT=0 git -c advice.detachedHead=false clone \
        --quiet \
        --depth 1 \
        --single-branch \
        --branch "${MODULE_VERSION[$module]}" \
        -- "${MODULE_REPOSITORY[$module]}" "$destination" \
        || fail "Unable to clone '${module}' at exact tag '${MODULE_VERSION[$module]}'."

    head=$(git -C "$destination" rev-parse HEAD) || fail \
        "Unable to determine staged commit for '${module}'."

    local_tag_commit=$(git -C "$destination" rev-parse \
        "refs/tags/${MODULE_VERSION[$module]}^{commit}" 2>/dev/null || true)

    [[ -n "$local_tag_commit" ]] || fail \
        "Staged module '${module}' does not contain tag '${MODULE_VERSION[$module]}'."

    [[ "$head" == "$expected" && "$local_tag_commit" == "$expected" ]] || fail \
        "Tag verification failed for '${module}': expected ${expected}, staged HEAD is ${head}."
}

stage_modules() {
    local module

    STAGE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/fsdb-install.XXXXXXXX") || fail \
        "Unable to create temporary staging directory."
    trap cleanup EXIT

    intro "Staging selected fsdb release in ${STAGE_ROOT}"

    # Temporary compatibility with the currently pinned initializeFsdb.sh:
    # it still guesses the core repository from the newest directory in the
    # staging root. This can disappear when initializeFsdb.sh is refactored.
    for module in "${SELECTED_MODULES[@]}"; do
        [[ "$module" == "core" ]] && continue
        stage_module "$module"
    done

    stage_module core
    touch -- "${STAGE_ROOT}/${MODULE_DIRECTORY[core]}"
}

validate_install_base() {
    [[ -d "$INSTALL_BASE" ]] || fail \
        "INSTALL_BASE must already exist and be a directory: ${INSTALL_BASE}"

    INSTALL_BASE=$(realpath -- "$INSTALL_BASE")
    [[ "$INSTALL_BASE" != *[[:space:]]* ]] || fail \
        "INSTALL_BASE must not contain whitespace: ${INSTALL_BASE}"
}

invoke_initializer() {
    local init_script
    init_script="${STAGE_ROOT}/${MODULE_DIRECTORY[core]}/install/initializeFsdb.sh"

    [[ -f "$init_script" ]] || fail \
        "The staged core module does not contain install/initializeFsdb.sh: ${init_script}"

    intro "All selected modules were staged and verified successfully."
    intro "Handing the staged release to initializeFsdb.sh."
    intro "Installation base: ${INSTALL_BASE}"

    if ((EUID == 0)); then
        bash "$init_script" "$INSTALL_BASE"
    else
        sudo bash "$init_script" "$INSTALL_BASE"
    fi
}

main() {
    parse_arguments "$@"
    check_prerequisites
    load_and_validate_manifest

    if ((LIST_ONLY)); then
        list_modules
        exit 0
    fi

    select_modules
    validate_install_base
    show_selection
    verify_selected_tags
    stage_modules
    invoke_initializer
}

main "$@"
