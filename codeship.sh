#!/bin/sh
echo "This is codeship test"
printenv
which jq
curl https://codeship.com/api/v1/projects/${PROJECT_NUM}.json?api_key=${API_KEY} | jq -r ".[].builds[0] | select({'id': $CI_BUILD_NUMBER}) | .status"
