#!/bin/sh

echo "Plan: ${GLOSSIA_PLAN}";

# Since the mix.lock has references to the Oban repository, if we don't delete
# the Oban lines that causes the installation of dependencies to fail.
if [ "$GLOSSIA_PLAN" = "community" ] || [ "$GLOSSIA_PLAN" = "enterprise" ]; then 
    echo "Deleting oban repo from mix.lock";
    sed -i '/oban/d' ./mix.lock;
fi

# Community doesn't legally have access to the enterprise features.
if [ "$GLOSSIA_PLAN" = "community" ]; then 
    echo "Deleting enterprise features";
    rm -rf lib/glossia/features/enterprise; 
fi

# Neither enteprise nor community should have the marketing features.
if [ "$GLOSSIA_PLAN" = "community" ] || [ "$GLOSSIA_PLAN" = "enterprise" ]; then 
    echo "Deleting cloud features";
    rm -rf lib/glossia/features/cloud; 
fi

if [ "$GLOSSIA_PLAN" = "cloud" ] && [ -n "$OBAN_WEB_FETCH_PUBLIC_KEY" ] && [ -n "$OBAN_WEB_AUTH_KEY" ]; then 
    echo "Adding the Oban repo";
    mix hex.repo add oban https://getoban.pro/repo --fetch-public-key $OBAN_WEB_FETCH_PUBLIC_KEY --auth-key $OBAN_WEB_AUTH_KEY; 
fi