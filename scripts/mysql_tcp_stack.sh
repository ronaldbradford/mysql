#!/bin/sh


[ -z "${TMP_DIR}" ] && TMP_DIR="/tmp"
[ -z "${DIGESTER}" ] && DIGESTER="pt-query-digest"
[ -z `which ${DIGESTER} 2>/dev/null` ] && echo "'${DIGESTER}' not found. Try wget http://percona.com/get/${DIGESTER}; chmod +x ${DIGESTER}; sudo mv ${DIGESTER} /usr/local/bin" && exit 1

TCPDUMP=/usr/sbin/tcpdump
[ -z `which ${TCPDUMP} 2>/dev/null` ] && echo "'${TCPDUMP}' not found. Try sudo yum install -y tcpdump" && exit 2

SUDO="sudo"
[ `id -u` -eq 0 ] && SUDO=""

# Need a check also for
# sudo sum install -y perl-Time-HiRes


[ ! -z "${QUIET}" ] && exec 2>/dev/null

[ -z "${SIZE}" ] && SIZE=10000
DT=`date +%y%m%d.%H%M%S`
echo "Generating data at ${DT}"
FILE="${TMP_DIR}/${DT}"

${SUDO} ${TCPDUMP} -i any -w ${FILE}.tcp -s 0 "port 3306 and tcp[1] & 7 == 2 and tcp[3] & 7 == 2" -c ${SIZE} #2>/dev/null
${SUDO} ${TCPDUMP} -r ${FILE}.tcp -nn -x -q -tttt | ${DIGESTER} --type tcpdump --limit 100%:500 > ${FILE}.out #--report-format=profile | cut -c40- | sort -nr > ${FILE}.out

${SUDO} rm -f ${FILE}.tcp ${TMP_DIR}/pt-query-digest-errors*
if [ ! -z "${BATCH}" ]
then
  sed -e "/^# Query 1:/,\$d" ${FILE}.out
else
  more ${FILE}.out
fi

echo "Check ${FILE}.out for more info"

exit 0
