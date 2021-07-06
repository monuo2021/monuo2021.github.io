# 如果没有消息后缀，默认提交信息为 `:pencil: update content`
# info=$1
# if ["$info" = ""];
# then info=":pencil: update content"
# fi
read content
git add .
git commit -m "$content"
git push origin hexo