#!/bin/sh

echo "Adding the Oban repo";
mix hex.repo add oban https://getoban.pro/repo --fetch-public-key $OBAN_WEB_FETCH_PUBLIC_KEY --auth-key $OBAN_WEB_AUTH_KEY; 