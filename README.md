# TCL_workshop_July23
task1.sh is the shell script which calls the tcl script task2.tcl
Comments are yet to be made, only uploaded the finished code.
**TASK 1**
The way to run the shell script is 'bash task1.sh example.csv'
According to the specifications the shell script must give an error on invalid input, and it does for both the cases.
Case 1 : No input file given
Case 2 : Input provided is not in the same directory
It also prints out a help option on suffixing '-help' to the command
![No input file given](github.com/CHVKartika/TCL_workshop_July23/task1_1.png)
**TASK 2**
The tcl script is called from the shell script.
The algorithm used is similar to what is recommended in the videos. However as I had trouble with a few commands. I had to modify the algorithm.
**Modifications:**
Finding which inputs are bits/buses : On using the command "lsort -unique" to remove duplications, we also lose the order in which the inputs are present which is key for further steps.
The 'count' logic did not work, I kept getting a very high value no matter how hard I tried.
To overcome these I used regexp and arrays to modify and store the input ports and their corresponding row values which I had to recalculate due to the "lsort -unique " command.
I used the regexp {\w+[^(\[\d*:\d*\])]} to split the given line. Stored the values I need into arrays and used these values later while printing into the sdc and defining the boundaries of the rectangle used to search for delays/clocks needed.

