#!/bin/tcsh -f
echo "                                                                    "
echo "   *************************************************************** "
echo "       ********   ********    *          *       *    ********* "  
echo "          *      *            *          *       *        * "
echo "          *      *            *   ***    *       *        * "
echo "          *      *            *          *       *        * "
echo "          *      *            *          *       *        * "
echo "          *      *********    ******     *********    ********* "
echo "                      easy print tcl tool "
echo "   *************************************************************** "

#set  work_dir = 'pwd'
#scenario 1 - no input file given
if [ "$#" -ne 1 ]; then
     echo "Input error : Please provide input .csv file"
     exit 1
elif [ $1 == "-help" ]; then
     echo " this command needs an input .csv file"
     echo " this is the initial shell script"
     echo " this passes the csv file to tcl"
     echo " this is the first interface"
elif [ ! -f $1 ] ; then
     echo "Input error: File not found in the directory"
     exit  1
else
    inp_file=$1
    tclsh task2.tcl $inp_file
fi
