#!/bin/sh
# Substitute ${ZURG_TOKEN} in config.yml with the actual token from the environment,
# then start zurg with the processed config.
sed "s|\${ZURG_TOKEN}|${ZURG_TOKEN}|g" /app/config.yml > /tmp/config.yml
exec /app/zurg -c /tmp/config.yml
