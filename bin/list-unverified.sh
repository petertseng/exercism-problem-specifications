dir=$(dirname "$0")

for i in $dir/../exercises/*/; do
  exercise=$(basename "$i")
  if [ -f $i/canonical-data.json ] && [ ! -f $i/verify.rb ]; then
    echo "$exercise"
  fi
done
