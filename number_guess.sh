#!/bin/bash

# Connect to PostgreSQL database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Get username
echo "Enter your username:"
read USERNAME

# Check if username exists in database
USER_RESULT=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")


if [[ -z $USER_RESULT ]]
then
  # User doesn't exist, insert new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # User exists, get their stats
  IFS='|' read GAMES_PLAYED BEST_GAME <<< $USER_RESULT
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
read GUESS
GUESS_COUNT=1

# Loop until the correct number is guessed
while [[ $GUESS -ne $SECRET_NUMBER ]]
do
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
  
  read GUESS
  (( GUESS_COUNT++ ))
done

# User guessed correctly
echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

# Update user stats in the database
USER_STATS=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
IFS='|' read GAMES_PLAYED BEST_GAME <<< $USER_STATS

# Increment games played
(( GAMES_PLAYED++ ))

# Update best game if this game was better or if it's their first game
if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]
then
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$GUESS_COUNT WHERE username='$USERNAME'")
else
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'")
fi