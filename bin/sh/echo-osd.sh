#!/usr/bin/env bash

BG=${OSD_BG_COL:-black}
ER=${OSD_ER_COL:-red}
FG=${OSD_FG_COL:-white}
FN=${OSD_FN:-"sans 14"}

CL=${FG}
for i in ${@}; do
    case ${i} in
        -e|--error) CL=${ER} ;;
        *) ARGS="${ARGS} ${i}" ;;
    esac
    shift
done

killall -u ${USER} aosd_cat >/dev/null 2>&1
echo "${ARGS}" | exec aosd_cat -d 5 -n "${FN}" -s 0 -b 100 -B ${BG} -R ${CL}
