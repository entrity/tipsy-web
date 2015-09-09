#!/bin/bash

PROJ_DIR=$HOME/tipsy
CUR_DIR=$(pwd)

prompt_1 ()
{
	echo "What action do you wish to take?"
	echo "1. publish Revision (Drink)"
	echo "2. publish Photo"
	echo "3. publish Ingredient Revision"
	printf "? "
	read -r DECISION_1
}

prompt_2 ()
{
	echo "By what selector?"
	echo "1. $MODEL record id"
	echo "2. (all $MODEL records) for user id"
	echo "3. (all $MODEL records) for drink/ingredient id"
	printf "? "
	read -r DECISION_2
}

cd $PROJ_DIR

while [[ ! $DECISION_1 ]]; do
	prompt_1
	case $DECISION_1 in
	1)
		MODEL=Revision
		MODEL_ID_SELECTOR="drink_id"
		;;
	2)
		MODEL=Photo
		MODEL_ID_SELECTOR="drink_id"
		;;
	3)
		MODEL="IngredientRevision"
		MODEL_ID_SELECTOR="ingredient_id"
		;;
	*)
		echo "Invalid choice"
		DECISION_1=
		;;
	esac
done

while [[ ! $DECISION_2 ]]; do
	prompt_2
	case $DECISION_2 in
	1)
		SELECTOR="id"
		;;
	2)
		SELECTOR="user_id"
		;;
	3)
		SELECTOR=$MODEL_ID_SELECTOR
		;;
	*)
		echo "Invalid choice"
		DECISION_2=
		;;
	esac
done

printf "enter id: "
read -r ID

RCMD="$MODEL.where($SELECTOR:$ID).each{|record| record.publish! unless record.status == Flaggable::APPROVED }"
echo "$RCMD"
RAILS_ENV=production bundle exec rails runner "$RCMD"

cd $CUR_DIR
