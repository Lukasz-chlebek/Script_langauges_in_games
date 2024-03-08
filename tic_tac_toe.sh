declare -A board

num_rows=3
num_columns=3

function print_board(){
    for((i=0; i<num_rows; i++)); do
        echo
        for((j=0; j<num_columns; j++)); do
            if [ "${board[$i,$j]}" = "-1" ]; then
                printf "%5s" "x"
            elif [ "${board[$i,$j]}" = "0" ]; then
                printf "%5s" "o"
            else
                printf "%5s" "${board[$i,$j]}"
            fi
        done
    done
    echo
}

function initialize_board(){
    x=1
    for ((i=0; i<num_rows; i++)); do
        for ((j=0; j<num_columns; j++)); do
            board[$i,$j]=$x
            x=$((x + 1))
        done 
    done
}

initialize_board
print_board