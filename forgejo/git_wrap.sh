#!/bin/sh
if [ "$1" = "replay" ]; then
	echo "git replay has been disabled" >&2
	exit 1
else
	exec git "$@"
fi
