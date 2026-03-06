#!/bin/bash

export LC_NUMERIC=C

echo "===============> Compiling <==============="
echo

make all > /dev/null

total_tests=0
failed_count=0
failed_tests=()
failed_report="failed_report.txt"
echo "" > "${failed_report}"

for G in 10 1000
do
    P_values=(64)
    #P_values=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000)

    # if [ "${G}" -eq 10 ]; then
    #     P_values+=(1000000 10000000 100000000)
    # fi

    for P in "${P_values[@]}"
    do
        total_tests=$((total_tests + 1))
        test_report=$(mktemp)

        echo "===============> Testing with P=${P} and G=${G} <==============="
        test_failed=0

        v1_out=$(mktemp)
        v2_out=$(mktemp)

        ./gera_entrada "${P}" "${G}" | ./ajustePol > "${v1_out}"
        ./gera_entrada "${P}" "${G}" | ./ajustePolV2 > "${v2_out}"

        time_v1=$(mktemp)
        time_v2=$(mktemp)
        
        # Extract the last line (time) from the outputs
        tail -n 1 "${v1_out}" > "${time_v1}"
        tail -n 1 "${v2_out}" > "${time_v2}"

        # Split at the space
        sed 's/ /\n/g' <<< "$(cat "${time_v1}")" > "${time_v1}"
        sed 's/ /\n/g' <<< "$(cat "${time_v2}")" > "${time_v2}"

        # Extract the generation and solving times
        gen_time_v1=$(sed -n '2p' "${time_v1}")
        gen_time_v2=$(sed -n '2p' "${time_v2}")
        solve_time_v1=$(sed -n '3p' "${time_v1}")
        solve_time_v2=$(sed -n '3p' "${time_v2}")

        if awk -v v1="${gen_time_v1}" -v v2="${gen_time_v2}" 'BEGIN { exit (v2 <= v1) }'; then
            test_failed=1
            {
                echo "=> V1 was faster at generating the matrix"
                echo "V1=${gen_time_v1}s <= V2=${gen_time_v2}s"
                echo
            } >> "${test_report}"
        fi

        rm -f "${time_v1}" "${time_v2}"

        pol_v1=$(mktemp)
        pol_v2=$(mktemp)

        # Extract the polynomial (first line) from the outputs
        head -n 1 "${v1_out}" > "${pol_v1}"
        head -n 1 "${v2_out}" > "${pol_v2}"

        # Split at the space
        sed 's/ /\n/g' <<< "$(cat "${pol_v1}")" > "${pol_v1}"
        sed 's/ /\n/g' <<< "$(cat "${pol_v2}")" > "${pol_v2}"

        # Number the terms
        nl -v 0 -s ' ' <<< "$(cat "${pol_v1}")" > "${pol_v1}"
        nl -v 0 -s ' ' <<< "$(cat "${pol_v2}")" > "${pol_v2}"

        # Compare the polynomial
        diff_pol=$(mktemp)
        paste "${pol_v1}" "${pol_v2}" | awk '{
            if ($2 != $4) { 
                printf "%5s %-25s | %5s %-25s (Diff: %f)\n", $1, $2, $3, $4, $2 - $4
                exit 1 
            }
        }' > "${diff_pol}"

        # Compare the polynomial and show differences
        diff_pol=$(mktemp)
        if [ ${?} -ne 0 ]; then
            test_failed=1
            {
                echo "=> Polynomial mismatch"
                cat "${diff_pol}"
                echo
            } >> "${test_report}"
        fi

        rm -f "${pol_v1}" "${pol_v2}" "${diff_pol}"
        rm -f "${v1_out}" "${v2_out}"

        if [ "${test_failed}" -ne 0 ]; then
            failed_count=$((failed_count + 1))
            failed_tests+=("P=${P}, G=${G}")
            {
                echo "===> Test with P=${P} and G=${G} failed"
                cat "${test_report}"
                echo
            } >> "${failed_report}"
            echo "========> XXX FAILED "
        else
            echo "========> PASSED"
        fi

    done
done

echo
echo "===============> Failure Summary <==============="
echo "Total failed tests: ${failed_count} / ${total_tests}"
echo

if [ "${failed_count}" -gt 0 ]; then
    echo "===============> Report <==============="
    cat "${failed_report}"
fi

echo "===============> Cleaning <==============="
make purge > /dev/null