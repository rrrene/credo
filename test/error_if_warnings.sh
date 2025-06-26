grep -E "^warning: .+" --after-context=6 <&0

if [ $? -eq 0 ]
then
  echo "error: Runtime warnings detected. Exiting ..."
  exit 255
else
  exit 0
fi
