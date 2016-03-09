#!/bin/sh
merge_pull_request() {
  echo "マージします。"
}


check_label() {
  local TARGET_LABEL=$1
  local PULL_REQUEST_NUM=$2
  local END_POINT="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
  echo url $END_POINT/issues/$PULL_REQUEST_NUM
  curl $END_POINT/issues/$PULL_REQUEST_NUM
  local LABEL_LIST=$(curl $END_POINT/issues/$PULL_REQUEST_NUM | jq -r '.labels[].name')
  # local LABEL_LIST=$(curl -s -H "Authorization:token $GITHUB_API_TOKEN" $END_POINT/issues/$PULL_REQUEST_NUM | jq -r '.user.login')
  echo "リスト:" $LABEL_LIST
  for label in $LABEL_LIST;
  do
    echo "らべる: " $label
    if [ "$label" = "$TARGET_LABEL" ]; then
      echo "自動マージ用に設定されたラベルがありました。マージします。"
      exit 0
    fi
  done
  echo "自動マージ用に設定されたラベルはありませんでした。終了します。"
  echo 1
}
