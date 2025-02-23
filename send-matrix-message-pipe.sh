#!/usr/bin/bash
# This script reads from stdin and sends the message to matrix. It expects
# the following environment variables to be set:
#
# MATRIX_ACCESS_TOKEN='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
# MATRIX_ROOM='roomid' # i.e. !PXIaWDrERmYDpEGUlW:matrix.org'
# MATRIX_SERVER='server'
# 
# It takes stdin and formats it into JSON using jq, then passes that to
# the matrix API for sending a message [2]. It prepends the message with
# $HOSTNAME and then formats the piped data as <code>, which is usually
# what you want. 
# 
# The `timeout` command used here is to workaround a systemd issue [1]
# because otherwise we'd wait forever since no EOF is ever sent. While
# ugly, this is a good workaround for our limited use case here.
#
# [1] https://github.com/systemd/systemd/issues/11793
# [2] https://spec.matrix.org/latest/client-server-api/#mtext

set -eu -o pipefail
# For the matrix room replace the `!` character at the beginning
# with %21, which is unicode for `!`.
UNICODE_MATRIX_ROOM="%21${MATRIX_ROOM:1}"
ENDPOINT="${MATRIX_SERVER}/_matrix/client/r0/rooms/${UNICODE_MATRIX_ROOM}/send/m.room.message?access_token=${MATRIX_ACCESS_TOKEN}"

timeout 1s cat                                     | \
    (echo "$HOSTNAME<code>"; cat ; echo '</code>') | \
    jq --null-input --raw-input --slurp              \
        '{ msgtype: "m.text",
           format: "org.matrix.custom.html",
           body: "see formatted_body",
           formatted_body: inputs }'               | \
    curl --json @- $ENDPOINT
echo
