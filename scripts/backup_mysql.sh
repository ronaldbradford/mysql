#!/bin/sh
#-------------------------------------------------------------------------------
# Name:     backup_mysql.sh
# Purpose:  A script for managing mysqldump backups of MySQL
# Website:  http://ronaldbradford.com
# Author:   Ronald Bradford  http://ronaldbradford.com
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Script Definition
#
SCRIPT_NAME=`basename $0 | sed -e "s/\.sh$//"`
SCRIPT_VERSION="1.1  23-MAR-2015"
SCRIPT_REVISION=""

#-------------------------------------------------------------------------------
# Constants - These values never change
#
MASTER_OPTIONS="--master-data=2"
SLAVE_OPTIONS="--dump-slave=2"

#-------------------------------------------------------------------------------
# Script specific variables
#

#------------------------------------------------------------------ backup_db --
backup_db() {
  local FUNCTION="backup_db()"
  debug "${FUNCTION} $*"

  [ $# -lt 2 ] && fatal "${FUNCTION} This function requires two arguments"
  local FLUSH="$1"
  local SCHEMA="$2"

  # Parameter Validation
  [ -z "${FLUSH}" ] && fatal "${FUNCTION} \$FLUSH was not specified."
  [ -z "${SCHEMA}" ] && fatal "${FUNCTION} \$SCHEMA was not specified."

  # Global Parameter validation
  [ -z "${BACKUP_DIR}" ] && fatal "${FUNCTION} \$BACKUP_DIR was not defined."
  [ -z "${MYSQLDUMP}" ] && fatal "${FUNCTION} \$MYSQLDUMP was not defined."
  [ -z "${MYSQL}" ] && fatal "${FUNCTION} \$MYSQL was not defined."

  DEFAULTS_FILE=""
  [ -f "${DEFAULT_MY_CNF_FILE}" ] && DEFAULTS_FILE="--defaults-file=${DEFAULT_MY_CNF_FILE}"


  info "Generating '${SCHEMA}' schema definition"
  SCHEMA_SQL_OUTPUT="${BACKUP_DIR}/${SCHEMA}.schema.${DATE}.sql"
  debug ".. ${SCHEMA_SQL_OUTPUT}"
  ${MYSQLDUMP} ${DEFAULTS_FILE} --add-drop-database --databases ${SCHEMA} --no-data --skip-triggers > ${SCHEMA_SQL_OUTPUT}
  RC=$?
  [ ${RC} -ne 0 ] && warn "dump of schema definition failed with [${RC}]" && EXIT_STATUS=$RC

  info "Generating '${SCHEMA}' objects definition"
  SCHEMA_OBJECTS_OUTPUT="${BACKUP_DIR}/${SCHEMA}.objects.${DATE}.sql"
  debug ".. ${SCHEMA_OBJECTS_OUTPUT}"
  ${MYSQLDUMP} ${DEFAULTS_FILE} --databases ${SCHEMA} --no-data --no-create-info --triggers --routines > ${SCHEMA_OBJECTS_OUTPUT}
  RC=$?
  [ ${RC} -ne 0 ] && warn "dump of schema objects failed with [${RC}]" && EXIT_STATUS=$RC


  [ "${FLUSH}" = "Y" ] && ${FLUSH_OPTIONS}="--flush-logs"

  info "Generating '${SCHEMA}' data with additional options '${BACKUP_OPTIONS} ${FLUSH_OPTIONS}'"
  DATA_FILE="${BACKUP_DIR}/${SCHEMA}.data.${DATE}.sql"
  debug ".. ${DATA_FILE}"
  ${MYSQLDUMP} ${DEFAULTS_FILE} ${BACKUP_OPTIONS} ${FLUSH_OPTIONS} --databases ${SCHEMA} --single-transaction --no-create-info --skip-triggers --skip-events > ${DATA_FILE}
  RC=$?
  [ ${RC} -ne 0 ] && warn "dump of data failed with [${RC}]. Stopping backup process" && return $RC

  LS=`ls -lh ${DATA_FILE}`
  info "${LS}"
  MD5=`md5sum ${DATA_FILE}`
  info "${MD5}"

  gzip -f ${DATA_FILE}
  RC=$?
  [ ${RC} -ne 0 ] && warn "compress of data failed with [${RC}]" && EXIT_STATUS=$RC

  LS=`ls -lh ${DATA_FILE}.gz`
  info "${LS}"
  MD5=`md5sum ${DATA_FILE}.gz`
  info "${MD5}"

  return ${EXIT_STATUS}
}

#-------------------------------------------------------------------- process --
process() {
  local FUNCTION="process()"
  debug "${FUNCTION} $*"

  [ $# -lt 2 ] && fatal "${FUNCTION} This function requires two arguments"
  local FLUSH="$1"
  local SCHEMA="$2"

  # Primary processing of script
  #
  # 1. Gather DB statistics (if available)
  # 2. Flush Logs (if specified)
  # 3. Backup specified schema/data/objects
  # 4. Sync Backup files (if specified)
  # 5. Sync Binary Logs (if specified)


  info "MySQL backup processing of Host '${SHORT_HOSTNAME}' Schema '${SCHEMA}'"

  backup_db $*
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

  PARAM_FLUSH="N"
  while getopts d:fqv OPTION
  do
    case "$OPTION" in
      d)  PARAM_SCHEMA=${OPTARG};;
      f)  PARAM_FLUSH="Y";;
      q)  QUIET="Y";;
      v)  USE_DEBUG="Y";;
    esac
  done
  shift `expr ${OPTIND} - 1`

  [ -z "${PARAM_SCHEMA}" ] && error "You must specify a database schema with -d. See --help for full instructions."

  [ $# -gt 0 ] && error "${SCRIPT_NAME} does not accept any arguments."

  return 0
}


#------------------------------------------------------------- pre_processing --
pre_processing() {
  local FUNCTION="pre_processing()"
  debug "${FUNCTION} $*"

  # Verify MySQL command access
  mysql_binaries

  # Load environment specific default configuration
  [ -f "${DEFAULT_CNF_FILE}" ] && . ${DEFAULT_CNF_FILE}

  # Define some global defaults
  [ -z "${BACKUP_DIR}" ] && BACKUP_DIR="/backup"
  [ -z "${BACKUP_DAYS}" ] && BACKUP_DAYS=7

  [ ! -d "${BACKUP_DIR}" ] && error "The defined backup directory of '${BACKUP_DIR}' does not exist."

  [ ! -f "${DEFAULT_MY_CNF_FILE}" ] && warn "The recommended my.cnf '${DEFAULT_MY_CNF_FILE}' was not found."

  return 0
}

#----------------------------------------------------------------------- help --
# Display Script help syntax
#
help() {
  echo ""
  echo "Usage: ${SCRIPT_NAME}.sh -d <schema> [ -f | -q | -v | --help | --version ]"
  echo ""
  echo "  Required:"
  echo "    -d         MySQL Database schema"
  echo ""
  echo "  Optional:"
  echo "    -f         Flush Logs before backup"
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
  process ${PARAM_FLUSH} ${PARAM_SCHEMA}
  complete

  return 0
}

main $*
exit $?

# END
