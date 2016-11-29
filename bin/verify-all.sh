dir=$(dirname "$0")

home=$(pwd)

fails=""

for i in $dir/../exercises/*/; do
  exercise=$(basename "$i")
  if [ -f $i/verify.rb ]; then
    if which time ; then
      time ruby $i/verify.rb
    else
      ruby $i/verify.rb
    fi
    if [ $? -eq 0 ]; then
      echo "\033[1;34m^^^ $exercise ^^^\033[0m"
    else
      fails="$fails\n$exercise"
      echo "\033[1;31m^^^ $exercise ^^^\033[0m"
    fi
  fi
done

if [ -n "$fails" ]; then
  echo "Failing exercises:$fails"
  exit 1
fi
