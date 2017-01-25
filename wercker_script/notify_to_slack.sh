#!/bin/sh
usage() { echo "Usage: $0 [-m <message>] [-l <link url>] [-u <user name>] [-c <channel>] [-k <color>] [-w <webhook url>]" 1>&2; exit 1;}
while getopts "m:l:u:c:k:w:" opts
do
  case $opts in
    m)
      MSG=$OPTARG
      ;;
    l)
      LINK_URL=$OPTARG
      ;;
    u)
      USER_NAME=$OPTARG
      ;;
    c)
      CHANNEL=$OPTARG
      ;;
    k)
      COLOR=$OPTARG
      ;;
    w)
      WEBHOOK_URL=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done


notify_to_slack() {
  MSG=${1:-$WERCKER_FAILED_STEP_MESSAGE}
  BUILD_URL=${2:-$WERCKER_BUILD_URL}
  USER_NAME=${3:-"wercker"}
  CHANNEL=${4:-"#critical_incidents"}
  COLOR=${5:-"danger"}

  echo MSG: $MSG
  echo BUILD_URL: $BUILD_URL
  echo USER_NAME: $USER_NAME
  echo CHANNEL: $CHANNEL
  echo COLOR: $COLOR
  echo webhook: $WEBHOOK_URL

  echo WEBHOOK_URL: $WEBHOOK_URL

  # リッチなフォーマットでpostする(https://api.slack.com/docs/attachments)
  post_data=`cat <<-EOF
  payload={
    "channel": "$CHANNEL",
    "username": "$USER_NAME",
    "attachments": [
      {
        "fallback": "$MSG",
        "color": "$COLOR",
        "title": "$MSG\n$LINK_URL",
        "title_link": "$LINK_URL"
      }
    ]
  }
EOF`
  echo $post_data
  curl -X POST $WEBHOOK_URL --data-urlencode "$post_data"
}
#TODO: 消す
notify_to_slack ${MSG} ${LINK_URL} ${USER_NAME} ${CHANNEL} ${COLOR} ${WEBHOOK_URL}

# notify_to_slack ${MSG} ${LINK_URL} ${USER_NAME} ${CHANNEL} ${COLOR} ${WEBHOOK_URL}
