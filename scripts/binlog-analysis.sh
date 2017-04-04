#!/bin/sh

[ -z "${TMP_DIR}" ] && TMP_DIR=/tmp
TMP_FILE=${TMP_DIR}/binlog.txt.$$

BINARY_LOG_FILE=$1
[ -z "${BINARY_LOG_FILE}" ] && echo "ERROR: You must specify a MySQL binary Log file" && exit 1
shift
BINLOG_ADDITIONAL_ARGS=$*


BINLOG_LOCATION=`grep "^log.bin" /etc/my.cnf /etc/mysql/my.cnf  2>/dev/null | cut -d'=' -f2`
#[ ! -z "${BINLOG_LOCATION}" ] && BINLOG_BASE_DIR=`dirname ${BINLOG_LOCATION}`
if [ ! -f "${BINARY_LOG_FILE}" ] 
then
  BINARY_LOG_FULL_PATH_FILE="${BINLOG_BASE_DIR}/${BINARY_LOG_FILE}"
  
  if [ ! -f "${BINARY_LOG_FULL_PATH_FILE}" ] 
  then
    echo "ERROR: Specify Binary Log with correct path to analyze. Nothing found in ${BINLOG_BASE_DIR}" 
    exit 1
  fi
  BINARY_LOG_FILE="${BINARY_LOG_FULL_PATH_FILE}"
fi


mysqlbinlog ${BINLOG_ADDITIONAL_ARGS} ${BINARY_LOG_FILE}  | \
  sed -e "/^#/d;s/\/\*.*\*\/[;]//;/^$/d" | \
  cut -c1-100 | \
  tr '[A-Z]' '[a-z]' | \
  egrep "^(insert|update|delete|replace|commit|alter|drop|create)" |  \
  sed -e "s/\t/ /g;s/\`//g;s/(.*$//;s/ set .*$//;s/ as .*$//;s/ join .*$//;s/ values .*$//;" | sed -e "s/ where .*$//;s/ignore //g;s/ inner//g;s/ left//g;s/ right//g;s/ from//g;s/ into//g" |  \
   sed -e "s/ \w.*\.\*//" | \
   awk '{ print $1,$2 }' | \
   sort | uniq -c | sort -nr  > ${TMP_FILE}

TOTAL=`awk 'BEGIN {total=0}{total=total+ $1}END{print total}' ${TMP_FILE}`
echo "Analysis of '${BINARY_LOG_FILE}' at "`date`
echo ""
(
echo "%    ${TOTAL} ALL QUERIES"
head -50 ${TMP_FILE} | awk -v TOTAL=${TOTAL} '{printf("%.2f %s\n",$1*100.0/TOTAL, $0)}' 
) | column -t
echo ""
echo "Full Details available in ${TMP_FILE}"
exit 0


# Fancy scripting explanation 
# 1. Strip out comment lines e.g. # at 453
# 2. Strip out inline comments e.g. /*!*/;
# 3. Remove blank lines, generally a result of an entire line being a removed comment
# 4. Reduce line to first 100 characters 
# 5. Lowercase data for ease of parsing
# 6. Restrict to DML/DDL
# 7. Strip out DML/DDL syntax after tablename
# 8. Further limit output to two columns e.g. command table
# 9. Sort and count results
