#/bin/bash

echo "List of existing stacks:"
heat stack-list
echo "Delete any? (y/n)"
read ANSWER
if [ "$ANSWER"=="y" ]; then
	echo "Which stack to delete (stack_name)?"
	read STACK_TO_REMOVE
	heat stack-delete $STACK_TO_REMOVE
else
	return
fi

