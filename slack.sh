#!/bin/sh

notify_to_slack() {
  CHANNEL="#test_ikemonn"
  USER_NAME="circleci_rebuild"
  MSG=${1:-"rebuild中にエラーが起きました"}
  BUILD_URL=${2:-"https://circleci.com/"}
  MENTIONED_NAME=$3

  # リッチなフォーマットでpostする(https://api.slack.com/docs/attachments)
  post_data=`cat <<-EOF
  payload={
    "channel": "$CHANNEL",
    "username": "$USER_NAME",
    "attachments": [
      {
        "fallback": "Fallback $MSG",
        "color": "danger",
        "author_name": "@$MENTIONED_NAME",
        "title": "$MSG\n$BUILD_URL",
        "title_link": "$BUILD_URL"
      }
    ]
  }
EOF`

  curl -X POST $CIRCLE_CI_WEBHOOK --data-urlencode "$post_data"
}
