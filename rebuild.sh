#!/bin/sh
abs_path=`echo $(cd $(dirname $0) && pwd)`
. ${abs_path}/github_comment.sh

# MAX_REBUILD_CNT=2 # 最大何回リビルドするか？build + rebuild = 3回で設定
MAX_REBUILD_CNT=1 # TODO: test
curr_build_id=$CIRCLE_BUILD_NUM #今回のビルドID
rebuild_cnt=0 # リビルド回数
API_END_POINT="https://circleci.com/api/v1/project/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
CIRCLE_TOKEN_PARAM="circle-token=$CIRCLE_REBUILD_TOKEN"

# 今回のビルドが成功しているかを確認
# 取得できる配列にある、stepのstatus:failedの数を確認する)
test_fail_cnt=$(curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' | jq '[.steps[].actions[] | select(contains({status:"failed"})) | .status] | length')

# pullreqのnumberを取得する
# https://github.com/ikemonn/circleciTest/pull/1 の形で来るので、末尾だけ取得
pull_request_num=$(curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' | jq -r '.pull_request_urls[]' | awk -F / '{print $NF}')

echo test_fail_cnt $test_fail_cnt
if [ $test_fail_cnt -le 0 ]; then
  echo "Testはすべて成功です！"
  comment_pull_request $pull_request_num "true" $curr_build_id
  exit 0
fi

echo $test_fail_cnt"個失敗しているテストがあります"

# 現在のリトライ回数を取得する
# 前回のビルド番号
prev_build_id=$(curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM | sed -e '1,1d' | jq '.retry_of')
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
    echo "curlできているので、ビルド回数を取得します"
    rebuild_cnt=$(curl -s $artifact_url?$CIRCLE_TOKEN_PARAM)
  else
    echo "curl失敗です"
    # TODO: Slackに通知
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
  # TODO: Slackに通知
fi

if [ "$rebuild_cnt" -lt "$MAX_REBUILD_CNT" ]; then
  rebuild_cnt=$((rebuild_cnt+1))
  echo $rebuild_cnt > $CIRCLE_ARTIFACTS/buildCnt.txt
  echo "リトライします"

  # キャッシュの削除
  curl -X DELETE $API_END_POINT/build-cache?$CIRCLE_TOKEN_PARAM
  # リビルド
  curl -X POST $API_END_POINT/$curr_build_id/retry?$CIRCLE_TOKEN_PARAM

  echo "Rebuild without cache"
else
  echo "指定回数以上リトライ済みなので、リトライしません"
  comment_pull_request $pull_request_num "false" $curr_build_id
fi
