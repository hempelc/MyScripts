# Import the time module to make a countdown and the random module to
# randomly select rock, paper, or scissors
import time, random

# Define the countdown function
def countdown(t):
    while t>0:
        print(t)
        t -= 1
        time.sleep(1)

# Define a winning statement function
def win_statement(c):
    print("Hahaaaaaaaa, nice try, but I picked " + c + "! You lose!\nDo you want to play again? [yes/no]")

# Define a loosing statement function
def loose_statement(c):
    print("Dammit, I picked " + c + "! So you win! Well done.\nDo you want to play again? [yes/no]")

# Make player indicate if they want to play
print("Let's play Rock, Paper, Scissors! Wanna play with me? [yes/no]")
while True:
    play=input()
    if play.lower() not in ["yes", "no"]:
        print('You have to say "yes" or "no"... Try again. [yes/no]')
    else:
        break

# Start a while loop to be able to play again if wanted
while True:
    # If player picked no, then exit
    if play.lower()=="no":
        print("Awwwww, that\'s sad :-( But okay! Byyyyeeeee...!")
        break

    # Let the computer randomly pick Rock, Paper, or Scissors
    computer_choice_list=["Rock", "Paper", "Scissors"]
    computer_choice=random.choice(computer_choice_list)

    # Print some stuff to the console to talk to the player and let the played pick
    print("\nAlright, I'll pick first. Let me see...")
    time.sleep(2)
    print("Okay, I made my choice!\nWhich one do you pick? [Rock/Paper/Scissors]")
    while True:
        player_choice=input()
        if player_choice.lower() not in ["rock", "paper", "scissors"]:
            print('You didn\'t pick "Rock", "Paper", or "Scissors". Pick again. [Rock/Paper/Scissors]')
        else:
            break

    # Evaluate the result
    print("Are you sure that was the right choice...? Let\'s see who won! Ready?")
    time.sleep(1)
    countdown(3)
    if computer_choice==player_choice.capitalize():
        print("Ooooohhhh no, we both picked " + computer_choice + " and tied... How boring. Do you want to play again? [yes/no]")
        play=input()
    elif computer_choice=="Rock":
        if player_choice.lower()=="scissors":
            win_statement(computer_choice)
        else:
            loose_statement(computer_choice)
        play=input()
    elif computer_choice=="Scissors":
        if player_choice.lower()=="paper":
            win_statement(computer_choice)
        else:
            loose_statement(computer_choice)
        play=input()
    else:
        if player_choice.lower()=="rock":
            win_statement(computer_choice)
        else:
            loose_statement(computer_choice)
        play=input()
