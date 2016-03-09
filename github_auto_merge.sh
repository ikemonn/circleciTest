#!/bin/sh
merge_pull_request() {
  echo "マージします。"
  local PULL_REQUEST_NUM=$1
  local END_POINT="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
  local HASH_NUM=$(curl $END_POINT/pulls/$PULL_REQUEST_NUM | jq -r '.head.sha')
  echo $HASH_NUM
  echo $END_POINT/pulls/$PULL_REQUEST_NUM/merge
  echo "{'commit_message': "", 'sha':$HASH_NUM}"
  curl -X PUT -d "{'commit_message': '', 'sha':$HASH_NUM}" $END_POINT/pulls/$PULL_REQUEST_NUM/merge
}


check_label() {
  local TARGET_LABEL=$1
  local PULL_REQUEST_NUM=$2
  local END_POINT="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
  echo url $END_POINT/issues/$PULL_REQUEST_NUM
  curl $END_POINT/issues/$PULL_REQUEST_NUM
  label_list=$(curl $END_POINT/issues/$PULL_REQUEST_NUM | jq -r '.labels[].name')
  # local label_list=$(curl -s -H "Authorization:token $GITHUB_API_TOKEN" $END_POINT/issues/$PULL_REQUEST_NUM | jq -r '.user.login')
  echo "リスト:" $label_list
  for label in $label_list;
  do
    echo "らべる: " $label
    if [ "$label" = "$TARGET_LABEL" ]; then
      echo "自動マージ用に設定されたラベルがありました。マージします。"
      merge_pull_request $PULL_REQUEST_NUM
      exit
    fi
  done
  echo "自動マージ用に設定されたラベルはありませんでした。終了します。"
  echo 1
}
