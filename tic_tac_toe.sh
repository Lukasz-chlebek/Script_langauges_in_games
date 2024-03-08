declare -A board

num_rows=3
num_columns=3

PLAYER_X=-1
PLAYER_O=0
PLAYER_TURN=0

UNDECIDED=-1
DRAW_STATE=0
X_PLAYER_WON=1
O_PLAYER_WON=2

HORIZONTAL_STATE=$UNDECIDED
VERTICAL_STATE=$UNDECIDED
DIAGONAL_STATE=$UNDECIDED
GAME_STATE=$UNDECIDED
MORE_MOVE_STATE=0

BOARD_STATE=""

function print_board(){
    for((i=0; i<num_rows; i++)); do
        echo
        for((j=0; j<num_columns; j++)); do
            if [ "${board[$i,$j]}" == "$PLAYER_X" ]; then
                printf "%5s" "x"
            elif [ "${board[$i,$j]}" == "$PLAYER_O" ]; then
                printf "%5s" "o"
            else
                printf "%5s" "${board[$i,$j]}"
            fi
        done
    done
    echo
}

function save_board_state(){
    BOARD_STATE=""
    for ((i=0; i<num_rows; i++)); do
        for ((j=0; j<num_columns; j++)); do
            BOARD_STATE+="${board[$i,$j]};"
        done 
    done
    BOARD_STATE+="$PLAYER_TURN;"
    printf "%s" "$BOARD_STATE" > savedGame.txt
    exit 0
}

function initialize_new_board(){
    local x=1
    for ((i=0; i<num_rows; i++)); do
        for ((j=0; j<num_columns; j++)); do
            board[$i,$j]=$x
            x=$((x + 1))
        done 
    done
}

function load_saved_game(){
    local content="$1"
    IFS=';' read -ra elements <<< "$content"
    local x=0
    for ((i=0; i<num_rows; i++)); do
        for ((j=0; j<num_columns; j++)); do
            local value=${elements[$x]}
            x=$((x + 1))
            if [ "$value" != "0" ] && [ "$value" != "-1" ]; then
                board[$i,$j]=$x
            else
                board[$i,$j]=$value
            fi
        done 
    done
    PLAYER_TURN=${elements[9]}
}

function initialize_board(){
    local file="savedGame.txt"
    if [ -e "$file" ]; then
        content=$(<"$file")
        load_saved_game "$content"
        rm -i $file
    else
        initialize_new_board
    fi
}

function check_is_more_move(){
    MORE_MOVE_STATE=0
    for ((i=0; i<num_rows; i++)); do
        for ((j=0; j<num_columns; j++)); do
            if [ "${board[$i,$j]}" != "$PLAYER_X" ] || [ "${board[$i,$j]}" != "$PLAYER_O" ]; then
                MORE_MOVE_STATE=$((result + 1))
            fi
        done 
    done
}

function check_horizontal(){
    for ((i=0; i<num_rows; i++)); do
        if [[ "${board[$i,0]}" == "${board[$i,1]}" && "${board[$i,1]}" == "${board[$i,2]}" ]]; then
            if [ "${board[$i,0]}" == "$PLAYER_X" ]; then
                HORIZONTAL_STATE="$X_PLAYER_WON"
            elif [ "${board[$i,0]}" == "$PLAYER_O" ]; then
                HORIZONTAL_STATE="$O_PLAYER_WON"
            fi
        fi  
    done
}

function check_vertical(){
    for ((j=0; j<num_columns; j++)); do
        if [[ "${board[0,$j]}" == "${board[1,$j]}" && "${board[1,$j]}" == "${board[2,$j]}" ]]; then
            if [ "${board[0,$j]}" == "$PLAYER_X" ]; then
                VERTICAL_STATE="$X_PLAYER_WON"
            elif [ "${board[0,$j]}" == "$PLAYER_O" ]; then
                VERTICAL_STATE="$O_PLAYER_WON"
            fi
        fi  
    done
}

function check_diagonal(){
    if [[ "${board[0,0]}" == "${board[1,1]}" && "${board[1,1]}" == "${board[2,2]}" ]]; then
        if [ "${board[0,0]}" == "$PLAYER_X" ]; then
            DIAGONAL_STATE="$X_PLAYER_WON"
        elif [ "${board[0,0]}" == "$PLAYER_O" ]; then
            DIAGONAL_STATE="$O_PLAYER_WON"
        fi
    elif [[ "${board[0,2]}" == "${board[1,1]}" && "${board[1,1]}" == "${board[2,0]}" ]]; then
        if [ "${board[0,2]}" == "$PLAYER_X" ]; then
            DIAGONAL_STATE="$X_PLAYER_WON"
        elif [ "${board[0,2]}" == "$PLAYER_O" ]; then
            DIAGONAL_STATE="$O_PLAYER_WON"
        fi
    fi
}

function check_game_state(){
    check_diagonal
    check_horizontal
    check_vertical
    check_is_more_move
    if [ "$DIAGONAL_STATE" != "$UNDECIDED" ]; then
       GAME_STATE=$DIAGONAL_STATE
    fi
    if [ "$HORIZONTAL_STATE" != "$UNDECIDED" ]; then
       GAME_STATE=$HORIZONTAL_STATE
    fi
    if [ "$VERTICAL_STATE" != "$UNDECIDED" ]; then
       GAME_STATE=$VERTICAL_STATE
    fi
    if [ "$MORE_MOVE_STATE" == "0" ]; then
        GAME_STATE=$DRAW_STATE
    fi
}

function get_player_input(){
    local i=-1
    local j=-1
    read -p "Enter index of your move(1-9) or type '99' to save state and close game: " index
    if [ "$index" -eq 99 ]; then
        save_board_state
    elif [ "$index" -lt "1" ] || [ "$index" -gt 9 ]; then
        printf "Invalide move, try again"
    else
        if [ "$index" -eq 1 ]; then
            i=0
            j=0
        elif [ "$index" -eq 2 ]; then
           i=0
           j=1
        elif [ "$index" -eq 3 ]; then
            i=0
            j=2
        elif [ "$index" -eq 4 ]; then
            i=1
            j=0
        elif [ "$index" -eq 5 ]; then
            i=1
            j=1
        elif [ "$index" -eq 6 ]; then
            i=1
            j=2
        elif [ "$index" -eq 7 ]; then
            i=2
            j=0
        elif [ "$index" -eq 8 ]; then
            i=2
            j=1
        elif [ "$index" -eq 9 ]; then
            i=2
            j=2
        fi
    fi

    if [ "$index" -ne 99 ]; then
        if [ "${board[$i,$j]}" == "$PLAYER_X" ] || [ "${board[$i,$j]}" == "$PLAYER_O" ]; then
            printf "Invalide move, try again"
        else
            board[$i,$j]="$PLAYER_TURN"
            if [ "$PLAYER_TURN" == "$PLAYER_O" ];then
                PLAYER_TURN="$PLAYER_X"
            elif [ "$PLAYER_TURN" == "$PLAYER_X" ];then
                PLAYER_TURN="$PLAYER_O" 
            fi
        fi
    fi
}

initialize_board
while :; do
    
    print_board
    get_player_input
    check_game_state
    
    if [ "$GAME_STATE" != "$UNDECIDED" ]; then
        print_board
        if [ "$GAME_STATE" == "$X_PLAYER_WON" ]; then
            echo "PLAYER X WON"
        elif [ "$GAME_STATE" == "$O_PLAYER_WON" ]; then
            echo "PLAYER O WON"
        else
            echo "DRAW"
        fi
        exit 0
    fi
done