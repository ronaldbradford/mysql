#!/bin/sh


#-------------------------------------------------------------------------------
# Script Definition
#
SCRIPT_NAME=`basename $0 | sed -e "s/\.sh$//"`
SCRIPT_VERSION="0.10 08-JUN-2011"
SCRIPT_REVISION=""

#-------------------------------------------------------------------------------
# Constants - These values never change
#

#-------------------------------------------------------------------------------
# Script specific variables
#
[ -z "${BACKUP_DIR}" ] && BACKUP_DIR="/backup"
[ -z "${BACKUP_DAYS}" ] && BACKUP_DAYS=7


#-------------------------------------------------------------------- process --
process() {
  local FUNCTION="process()"
  debug "${FUNCTION} $*"

  return 0
}


#------------------------------------------------------------------ bootstrap --
# Essential script bootstrap
#
bootstrap() {
  local DIRNAME=`dirname $0`
  local COMMON_SCRIPT_FILE="${DIRNAME}/common.sh"
  [ ! -f "${COMMON_SCRIPT_FILE}" ] && echo "ERROR: You must have a matching '${COMMON_SCRIPT_FILE}' with this script ${0}" && exit 1
  . ${COMMON_SCRIPT_FILE}
  set_base_paths

  return 0
}

#-------------------------------------------------------------- process_args --
# Process Command Line Arguments
#
process_args() {
  check_for_long_args $*
  debug "Processing supplied arguments '$*'"
  while getopts qv OPTION
  do
    case "$OPTION" in
      q)  QUIET="Y";;
      v)  USE_DEBUG="Y";;
    esac
  done
  shift `expr ${OPTIND} - 1`

  [ $# -gt 0 ] && error "${SCRIPT_NAME} does not accept any arguments"

  return 0
}


#------------------------------------------------------------- pre_processing --
pre_processing() {

  return 0
}

#----------------------------------------------------------------------- help --
# Display Script help syntax
#
help() {
  echo ""
  echo "Usage: ${SCRIPT_NAME}.sh [ -q | -v | --help | --version ]"
  echo ""
  echo "  Required:"
  echo ""
  echo "  Optional:"
  echo "    -q         Quiet Mode"
  echo "    -v         Verbose logging"
  echo "    --help     Script help"
  echo "    --version  Script version (${SCRIPT_VERSION}) ${SCRIPT_REVISION}"
  echo ""
  echo "  Dependencies:"
  echo "    common.sh"

  return 0
}

#----------------------------------------------------------------------- main --
# Main Script Processing
#
main () {
  [ ! -z "${TEST_FRAMEWORK}" ] && return 1
  bootstrap
  process_args $*
  pre_processing
  commence
  process
  complete

  return 0
}

main $*
exit $?

# END
