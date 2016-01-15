#!/bin/sh
# release/hotfixブランチかを判定
get_is_deploy_branch() {
  BRANCH_NAME=$1
  result="false"
  # dashなのでbashの文法が使えない
  if expr "$BRANCH_NAME" : '^release\/\|hotfix\/' >/dev/null;then
    result="true"
  fi
  echo $result
}

# mentionするユーザ名を取得
get_mention_name() {
  MENTIONED_NAME=$1
  BRANCH_NAME=$2
  if [$(get_is_deploy_branch $BRANCH_NAME) = "true"]; then
    MENTIONED_NAME="channel"
  fi
  echo $MENTIONED_NAME
}
