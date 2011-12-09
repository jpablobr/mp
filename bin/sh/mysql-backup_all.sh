#!/bin/sh
# Usage: mysql-backup
# This script makes it easier to do daily backups of all the databases in a MySQL server. Some editing required.

# The user for the Database.
# root works best for fetching all DBs and tables
USER="root"
PASS=""

if [ -z "${PASS}" ]
then
  echo "Enter the password for \"${USER}\":"
  read -s PASS
fi

# This displays the UTC timestamp 
# example "2024-12-31"
DATE="$(date -u +%F)"

# Place the backups in this directory
BKP_DIR="${HOME}/mysql-bkp"

echo "Creating the directory for backups (if it doesn't exist)"
echo "The Directory is located at \"${BKP_DIR}\""
mkdir -p "${BKP_DIR}/${DATE}"
if [ ! -d "${BKP_DIR}/${DATE}" ]; then
  exit 1
fi

##########################################################

DB_TABLES="$(mysql -e 'show databases' -u ${USER} --password=${PASS} -s --skip-column-names)"
if [ -z "${DB_TABLES}" ]; then
  exit 1;
fi

for DB in ${DB_TABLES}; do
  echo "Dumping ${DB}..."
  mysqldump -u ${USER} --password=${PASS} --opt ${DB} | \
  gzip -c | \
  cat > "${BKP_DIR}/${DATE}/${DB}.sql.gz"
done

echo "Bundling the dumps..."
tar -cf "${BKP_DIR}/${DATE}.tar" -C ~/mysql-bkp ${DATE}

echo "Cleaning up temporary files..."
rm -rf "${BKP_DIR}/${DATE}"
