#!/bin/sh
notify_to_slack() {
  MSG=${1:-"rebuild中にエラーが起きました"}
  BUILD_URL=${2:-"https://circleci.com/"}
  MENTIONED_NAME=$3
  COLOR=${4:-"danger"}
  CHANNEL="#test_ikemonn"
  USER_NAME="circleci_rebuild"

  # リッチなフォーマットでpostする(https://api.slack.com/docs/attachments)
  post_data=`cat <<-EOF
  payload={
    "channel": "$CHANNEL",
    "username": "$USER_NAME",
    "attachments": [
      {
        "fallback": "Fallback $MSG",
        "color": "$COLOR",
        "pretext": "@$MENTIONED_NAME",
        "title": "$MSG\n$BUILD_URL",
        "title_link": "$BUILD_URL"
      }
    ]
  }
EOF`

  curl -X POST $CIRCLE_CI_WEBHOOK --data-urlencode "$post_data"
}
