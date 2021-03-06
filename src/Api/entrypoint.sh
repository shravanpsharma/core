#!/bin/bash

# Setup

GROUPNAME="bitwarden"
USERNAME="bitwarden"

CURRENTGID=`getent group $GROUPNAME | cut -d: -f3`
LGID=${LOCAL_GID:-999}

NOUSER=`id -u $USERNAME > /dev/null 2>&1; echo $?`
LUID=${LOCAL_UID:-999}

# Step down from host root

if [ $LGID == 0 ]
then
    LGID=999
fi

if [ $LUID == 0 ]
then
    LUID=999
fi

# Create group

if [ $CURRENTGID ]
then
    if [ "$CURRENTGID" != "$LGID" ]
    then
        groupmod -g $LGID $GROUPNAME
    fi
else
    groupadd -g $LGID $GROUPNAME
fi

# Create user and assign group

if [ $NOUSER == 0 ] && [ `id -u $USERNAME` != $LUID ]
then
    usermod -u $LUID $USERNAME
elif [ $NOUSER == 1 ]
then
    useradd -r -u $LUID -g $GROUPNAME $USERNAME
fi

# Make home directory for user

if [ ! -d "/home/$USERNAME" ]
then
    mkhomedir_helper $USERNAME
fi

# The rest...

touch /var/log/cron.log
chown $USERNAME:$GROUPNAME /var/log/cron.log
chown -R $USERNAME:$GROUPNAME /app
chown -R $USERNAME:$GROUPNAME /jobs
mkdir -p /etc/bitwarden/core
mkdir -p /etc/bitwarden/logs
mkdir -p /etc/bitwarden/ca-certificates
chown -R $USERNAME:$GROUPNAME /etc/bitwarden

env >> /etc/environment
cron

cp /etc/bitwarden/ca-certificates/*.crt /usr/local/share/ca-certificates/ \
    && update-ca-certificates

gosu $USERNAME:$GROUPNAME dotnet /app/Api.dll
