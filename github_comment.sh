#!/bin/sh -e

comment_pull_request() {
  pull_request_num=$1
  is_success=$2
  build_num=$3
  user_name="circleCI"
  token=$GITHUB_API_TOKEN
  BUILD_URL="https://circleci.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$build_num"
  END_POINT="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$pull_request_num/comments"

  build_result="Failed"
  emoji=":fire:"
  if [ "$is_success" = "true" ]; then
    build_result="Success!"
    emoji=":white_check_mark:"
  fi
  echo $END_POINT
  curl -u "$user_name:$token" -d "{\"body\": \"$emoji$emojiCircleCI Test $build_result$emoji$emoji\n$BUILD_URL\"}" $END_POINT
}


# comment_pull_request 1 "true" 44
