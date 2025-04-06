#!/bin/bash
# SSH and SCP aliases for compatibility with older systems
alias oldscp='scp -o HostKeyAlgorithms=ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa "$@"'
alias oldssh='ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa "$@"'
alias oldssh2='ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 "$@"'