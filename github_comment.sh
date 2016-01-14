#!/bin/sh

comment_pull_request() {
  PULL_REQUEST_NUM=$1
  IS_SUCCESS=$2
  BUILD_NUM=$3
  BUILD_URL=$4
  USER_NAME="circleCI"
  END_POINT="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$PULL_REQUEST_NUM/comments"

  build_result="Failed"
  emoji=":fire:"
  if [ "$IS_SUCCESS" = "true" ]; then
    build_result="Success!"
    emoji=":white_check_mark:"
  fi
  echo $END_POINT
  curl -u "circleci_rebuild:$GITHUB_API_TOKEN" -d "{\"body\": \"@USER_NAME\nCircleCI Test $build_result $emoji\n$BUILD_URL\"}" $END_POINT/issues/$PULL_REQUEST_NUM/comments
}


# comment_pull_request 1 "true" 44
