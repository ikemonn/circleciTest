#!/bin/sh

#######################
# 概要:
# CircleCIの結果を、GitHubのpullreqにコメントする。
#######################
abs_path=`echo $(cd $(dirname $0) && pwd)`
. ${abs_path}/github_comment.sh
. ${abs_path}/common_function.sh

curr_build_id=$CIRCLE_BUILD_NUM #今回のビルドID
CIRCLE_DOMAIN="circleci.com" # エンプラ版とドメインが違う
if [ "$IS_ENTERPRISE" = "true" ]; then
  # enterprise
  CIRCLE_DOMAIN="circleci.karte.io"
fi
API_END_POINT="https://${CIRCLE_DOMAIN}/api/v1/project/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
CIRCLE_TOKEN_PARAM="circle-token=$CIRCLE_REBUILD_TOKEN"
BUILD_RESULT_URL="https://${CIRCLE_DOMAIN}/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${curr_build_id}"
BUILD_RESULT_FILE=$HOME/result.txt
# ビルド結果は使いまわすのでファイルに書き込む
curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' > $BUILD_RESULT_FILE

# ビルドがCancelされたら何もせずに終了
test_canceled_cnt=$(cat $BUILD_RESULT_FILE | sed -e '1,1d' | jq '[.steps[].actions[] | select(contains({status:"canceled"})) | .status] | length')
echo test_canceled_cnt $test_canceled_cnt
if [ $test_canceled_cnt -gt 0 ]; then
  echo "テストがCancelされました"
  exit 0
fi

# 今回のビルドが成功しているかを確認
# APIから取得できる配列内の、status:failedの数を確認する
test_fail_cnt=$(cat $BUILD_RESULT_FILE | sed -e '1,1d' | jq '[.steps[].actions[] | select(contains({status:"failed"})) | .status] | length')

# pullreqのnumberを取得する
# https://github.com/ikemonn/circleciTest/pull/1 の形で来るので、末尾だけ取得
pull_request_num=$(cat $BUILD_RESULT_FILE | sed -e '1,1d' | jq -r '.pull_request_urls[]' | awk -F / '{print $NF}')
echo pull_request_num $pull_request_num
echo test_fail_cnt $test_fail_cnt
if [ $test_fail_cnt -le 0 ]; then
  echo "Testはすべて成功です！"
  comment_pull_request $pull_request_num "true" $curr_build_id $BUILD_RESULT_URL
else
  echo test_fail_cnt "個の失敗したテストがあります。"
  comment_pull_request $pull_request_num "false" $curr_build_id $BUILD_RESULT_URL
fi

exit 0
