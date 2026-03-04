#!/bin/bash

export LC_NUMERIC=C

TOLERANCE="1e-2"

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
    P_values=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000)
    if [ "${G}" -eq 10 ]; then
        P_values+=(1000000 10000000 10000000)
    fi

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

        if awk -v v1="${gen_time_v1}" -v v2="${gen_time_v2}" 'BEGIN { exit (v2 < v1) }'; then
            test_failed=1
            {
                echo "=> V1 was faster at generating the matrix"
                echo "V1=${gen_time_v1}s <= V2=${gen_time_v2}s"
                echo
            } >> "${test_report}"
        fi

        rm -f "${time_v1}" "${time_v2}"

        coeff_v1=$(mktemp)
        coeff_v2=$(mktemp)

        # Extract the coefficients (first line) from the outputs
        head -n 1 "${v1_out}" > "${coeff_v1}"
        head -n 1 "${v2_out}" > "${coeff_v2}"

        # Split at the space
        sed 's/ /\n/g' <<< "$(cat "${coeff_v1}")" > "${coeff_v1}"
        sed 's/ /\n/g' <<< "$(cat "${coeff_v2}")" > "${coeff_v2}"

        # Number the coefficients
        nl -v 0 -s ' ' <<< "$(cat "${coeff_v1}")" > "${coeff_v1}"
        nl -v 0 -s ' ' <<< "$(cat "${coeff_v2}")" > "${coeff_v2}"

        # Compare the coefficients considering numerical error
        diff_coeff=$(mktemp)
        paste "${coeff_v1}" "${coeff_v2}" | awk -v tol="${TOLERANCE}" '{
            diff = ($2 - $4 < 0) ? $4 - $2 : $2 - $4
            if (diff > tol) { 
                printf "%5s %-25s | %5s %-25s (Diff: %f)\n", $1, $2, $3, $4, diff
                exit 1 
            }
        }' > "${diff_coeff}"

        # Compare the coefficients and show differences
        diff_coeff=$(mktemp)
        if [ ${?} -ne 0 ]; then
            test_failed=1
            {
                echo "=> Coefficients mismatch"
                cat "${diff_coeff}"
                echo
            } >> "${test_report}"
        fi

        rm -f "${coeff_v1}" "${coeff_v2}" "${diff_coeff}"

        residue_v1=$(mktemp)
        residue_v2=$(mktemp)

        # Extract residues (all lines between first and last)
        sed '1d;$d' "${v1_out}" > "${residue_v1}"
        sed '1d;$d' "${v2_out}" > "${residue_v2}"

        # Split at the space
        sed 's/ /\n/g' <<< "$(cat "${residue_v1}")" > "${residue_v1}"
        sed 's/ /\n/g' <<< "$(cat "${residue_v2}")" > "${residue_v2}"

        # Number the residues
        nl -v 0 -s ' ' <<< "$(cat "${residue_v1}")" > "${residue_v1}"
        nl -v 0 -s ' ' <<< "$(cat "${residue_v2}")" > "${residue_v2}"

        # Compare the residues and show differences
        diff_residue=$(mktemp)
        paste "${residue_v1}" "${residue_v2}" | awk -v tol="${TOLERANCE}" '{
            diff = ($2 - $4 < 0) ? $4 - $2 : $2 - $4
            if (diff > tol) { 
                printf "%5s %-25s | %5s %-25s (Diff: %f)\n", $1, $2, $3, $4, diff
                exit 1 
            }
        }' > "${diff_residue}"

        if [ ${?} -ne 0 ]; then
            test_failed=1
            {
                echo "=> Residues mismatch"
                cat "${diff_residue}"
                echo
            } >> "${test_report}"
        fi

        rm -f "${residue_v1}" "${residue_v2}" "${diff_residue}"
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