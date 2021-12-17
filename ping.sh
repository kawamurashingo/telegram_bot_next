#!/bin/bash

DOMAIN="
google.com
yahoo.com
etc...
"

echo "$DOMAIN" | xargs -P10 -n1 -IXXX bash -c "ping -c1 -w1 XXX > /dev/null 2> /dev/null && echo OK XXX || echo NG XXX" |sort -k1,2
