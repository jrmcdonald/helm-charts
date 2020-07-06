#!/usr/bin/env bash

set -o nounset
set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail
IFS=$'\n\t'

###############################################################################
# Environment
###############################################################################

_ME="$(basename "${0}")"
_SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

###############################################################################
# Error Messaging
###############################################################################

_exit_1() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
  exit 1
}

###############################################################################
# Help
###############################################################################

_print_help() {
  cat <<HEREDOC
  
Initialise a helm chart with a custom starter.

Usage:
  ${_ME} <starter> <service> <namespace>
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

_CHARTS_DIR=charts
_RELEASES_DIR=releases
_FLUX_RELEASE_TEMPLATE_PATH=flux/automated-release-template.yaml

_init() {
  _STARTER=${1:?'Starter name required'}
  _SERVICE=${2:?'Service name required'}
  _NAMESPACE=${3:?'Release namespace required'}

  [ ! -d "${_SCRIPT_DIR}/helm/starters/${_STARTER}" ] && _exit_1 printf "The specified starter does not exist."

  (cd ${_CHARTS_DIR} && XDG_DATA_HOME=${_SCRIPT_DIR} helm create ${_SERVICE} --starter ${_STARTER})

  # workaround required for not being able to template Chart.yaml
  sed -e "s/<CHARTNAME>/${_SERVICE}/g" "${_SCRIPT_DIR}/helm/starters/${_STARTER}/Chart.yaml" > "${_CHARTS_DIR}/${_SERVICE}/Chart.yaml"

  [ ! -d "${_RELEASES_DIR}/${_NAMESPACE}" ] && _exit_1 printf "The specified namespace directory not exist."
  [ ! -f "${_SCRIPT_DIR}/${_FLUX_RELEASE_TEMPLATE_PATH}" ] && _exit_1 printf "The release template does not exist."

  printf "Creating flux release\n"
  sed -e "s/<CHARTNAME>/${_SERVICE}/g" "${_SCRIPT_DIR}/${_FLUX_RELEASE_TEMPLATE_PATH}" > "${_RELEASES_DIR}/${_NAMESPACE}/${_SERVICE}.yaml"

  printf "Complete. Please check for instances of <REPLACE_ME> in the generated charts.\n"
}

###############################################################################
# Main
###############################################################################

_main() {
  if [[ "${1:-}" =~ ^-h|--help$  ]]
  then
    _print_help
  else
    _init "$@"
  fi
}

_main "$@"
