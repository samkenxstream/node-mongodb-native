#!/bin/bash

set -o errexit  # Exit the script with error if any of the commands fail

source "${PROJECT_DIRECTORY}/.evergreen/init-node-and-npm-env.sh"

# set up keytab
mkdir -p "$(pwd)/.evergreen"
export KRB5_CONFIG="$(pwd)/.evergreen/krb5.conf.empty"
echo "Writing keytab"
# DON'T PRINT KEYTAB TO STDOUT
set +o verbose
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ${KRB5_NEW_KEYTAB} | base64 -D > "$(pwd)/.evergreen/drivers.keytab"
else
    echo ${KRB5_NEW_KEYTAB} | base64 -d > "$(pwd)/.evergreen/drivers.keytab"
fi
echo "Running kdestroy"
kdestroy -A
echo "Running kinit"
kinit -k -t "$(pwd)/.evergreen/drivers.keytab" -p ${KRB5_PRINCIPAL}

set -o xtrace
npm install kerberos@">=2.0.0-beta.0"
npm run check:kerberos

if [ "$NODE_LTS_VERSION" != "latest" ] && [ $NODE_LTS_VERSION -lt 20 ]; then
  npm install kerberos@"^1.1.7"
  npm run check:kerberos
fi

set +o xtrace

# destroy ticket
kdestroy
