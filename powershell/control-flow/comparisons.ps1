# All the following comparisons should be true
# just showing what comparion operator to use in each case

#==============================
# nubmers
#==============================
      -not    0
2     -le     3
2     -eq     2

#==============================
# strings
#==============================
           -not     ""
"apple"    -eq      "apple"
"test.txt" -match   "\.(txt|jpg)"