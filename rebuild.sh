#!/bin/sh

#######################
# 概要:
# CircleCIのテストがFailしたら、MAX_REBUILD_CNT回だけrebuildする。
# rebuild時にはCacheを消して失敗したbuildをretryする。
# rebuildの回数はartifactsのbuildCnt.txtに書き込んでおり、
# それを取得して現在何回目のリビルドかを管理している。
# テストが成功するか、MAX_REBUILD_CNT回だけ失敗したらGitHubのpullreqにコメントする。
#######################
abs_path=`echo $(cd $(dirname $0) && pwd)`
. ${abs_path}/github_comment.sh
. ${abs_path}/slack.sh
. ${abs_path}/common_function.sh

# MAX_REBUILD_CNT=2 # 最大何回リビルドするか？build + rebuild = 3回で設定
MAX_REBUILD_CNT=1 # TODO: test
curr_build_id=$CIRCLE_BUILD_NUM #今回のビルドID
rebuild_cnt=0 # リビルド回数
API_END_POINT="https://circleci.com/api/v1/project/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
CIRCLE_TOKEN_PARAM="circle-token=$CIRCLE_REBUILD_TOKEN"
BUILD_RESULT_URL="https://circleci.com/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$curr_build_id"
BUILD_RESULT_FILE=$HOME/result.txt
# ビルド結果は使いまわすのでファイルに書き込む
curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' > $BUILD_RESULT_FILE
BUILD_USER_NAME=$(cat $BUILD_RESULT_FILE | sed -e '1,1d' | jq -r '.user.login')
BUILD_BRANCH=$(cat $BUILD_RESULT_FILE | jq -r '.branch')
SLACK_MENTIONED_NAME=$(get_mention_name $BUILD_USER_NAME $BUILD_BRANCH) # Slackでmentionされる名前(release/hotfixはchannelになる)
echo SLACK_MENTIONED_NAME $SLACK_MENTIONED_NAME

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
  notify_to_slack ":white_check_mark: CircleCIのテストが成功しました！($BUILD_BRANCH) :white_check_mark:" $BUILD_RESULT_URL $BUILD_USER_NAME "good"
  comment_pull_request $pull_request_num "true" $curr_build_id $BUILD_RESULT_URL
  exit 0
fi

echo $test_fail_cnt"個失敗しているテストがあります"

# 現在のリトライ回数を取得する
# 前回のビルド番号
prev_build_id=$(cat $BUILD_RESULT_FILE | sed -e '1,1d' | jq '.retry_of')
echo prev_build_id $prev_build_id
# nullかビルド番号が返ってくるので、数値か文字列かを判定
expr "$prev_build_id" + 1 >/dev/null 2>&1
if [ $? -lt 2 ]; then
  echo "ビルド番号を取得 " $prev_build_id
  echo "前回までのビルド回数を取得します"

  # "buildCnt"が含まれているデータを取得し、artifactsのURLを取得
  artifact_url=$(curl -s $API_END_POINT/$prev_build_id/artifacts?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' | jq -r '.[] | select(contains({path:"buildCnt"})) | .url')
  echo URL " $artifact_url"

  # 正しく通信できているか確認(exit codeが0以外だとエラー)
  exit_code=$(curl -f -I $artifact_url?$CIRCLE_TOKEN_PARAM)
  if [ $? -eq 0 ];then
    echo "curlが成功したので、ビルド回数を取得します"
    rebuild_cnt=$(curl -s $artifact_url?$CIRCLE_TOKEN_PARAM)
  else
    echo "curl失敗です"
    notify_to_slack ":fire: Artifactsを取得する際のcurlで失敗しました :fire:" $BUILD_RESULT_URL $BUILD_USER_NAME
    exit 1
  fi

else
  echo "ビルド番号を取得できませんでした"
fi

echo rebuild_cnt $rebuild_cnt

# 取得できれば指定回数以下かチェック、指定回数以下なら+1回をfileに書き込む & retry
# 数値か判定
expr "$rebuild_cnt" + 1 >/dev/null 2>&1
if [ $? -ge 2 ]; then
  echo "buildCntの値が数値ではありません"
  notify_to_slack ":fire: Artifactsから取得したbuildCntが数値以外の異常な値でした :fire:" $BUILD_RESULT_URL $BUILD_USER_NAME
  exit 1
fi

if [ "$rebuild_cnt" -lt "$MAX_REBUILD_CNT" ]; then
  rebuild_cnt=$((rebuild_cnt+1))
  echo $rebuild_cnt > $CIRCLE_ARTIFACTS/buildCnt.txt
  echo "リトライします"
  # キャッシュの削除
  curl -X DELETE $API_END_POINT/build-cache?$CIRCLE_TOKEN_PARAM
  # リビルド
  curl -X POST $API_END_POINT/$curr_build_id/retry?$CIRCLE_TOKEN_PARAM
else
  echo "指定回数以上リトライ済みなので、リトライしません"
  notify_to_slack ":fire: CircleCIのテストが失敗しました($BUILD_BRANCH) :fire:" $BUILD_RESULT_URL $BUILD_USER_NAME
  comment_pull_request $pull_request_num "false" $curr_build_id $BUILD_RESULT_URL
fi
