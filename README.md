# send-matrix-message-pipe

This repository holds a script and a set of systemd units that will send messages
to a matrix channel. The script just takes input on STDIN and sends a message as
a user and to a channel on a server configured by environment variables.

```
MATRIX_ACCESS_TOKEN='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
MATRIX_ROOM='roomid' # i.e. !PXIaWDrERmYDpEGUlW:matrix.org'
MATRIX_SERVER='https://matrix.org'
echo hello | ./send-matrix-message-pipe.sh
```

The script will send a message to the matrix channel with the hostname on the
first line of the message and the piped text as a `<code>` formatted block.

In order for this to work you do have to have an existing user account with a
username/password. Once you have that you can get an access token via the API:

```
MATRIX_DEVICE_ID='example-app'
MATRIX_USER='mybot'
MATRIX_PASSWORD='xxxxxxxxxxxxxxxxxxxx'
cat <<EOF | curl --json @- https://matrix.org/_matrix/client/r0/login; echo
{
  "type": "m.login.password",
  "user": "${MATRIX_USER}",
  "password": "${MATRIX_PASSWORD}",
  "device_id": "${MATRIX_DEVICE_ID}"
}
EOF
```

The returned access token can be used for setting the `MATRIX_ACCESS_TOKEN`
environment variable to then be passed to the `send-matrix-message-pipe.sh`
script.

Taking this a step further you can use the systemd unit files in this
repo to make it easy to send messages to the channel from a system/host.

The `send-matrix-message-pipe.socket` creates a FIFO file that can be
written to. Upon write it will activate `send-matrix-message-pipe.service`
which just loads the `MATRIX_ACCESS_TOKEN`, `MATRIX_ROOM`, and
`MATRIX_SERVER` environment variables from `send-matrix-message-pipe.env`
and then runs `send-matrix-message-pipe.sh` with the socket (FIFO) as
STDIN.

Once this is wired up you can then configure other units to perform specific
actions (i.e. periodic check of disk usage, report OS version on boot, etc) and
then write to the FIFO to send a message to a matrix channel. This in a sense
is a very light weight and limited way to do basic periodic checkins.

```
(. /etc/os-release && echo $VERSION) > /run/systemd/matrix-send-message-pipe
```
