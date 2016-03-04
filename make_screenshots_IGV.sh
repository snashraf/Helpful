if [ $# -eq 0 ];then

	echo "No arguments supplied. This script will make a .bat file to run in IGV to make many screenshots given a MAF."
	echo "bash make_screenshots_IGV.sh <INPUT> <ANNO>"
echo "After script finishes running open up .bat in IGV to start screenshots. (.bat file located in location of input ANNO file and under directory ANNO_snaps)"
	echo "INPUT: CANCER_TYPE SAMPLE TUMORSAMPLE TUMOR.bam NORMALSAMPLE NORMAL.bam"
	echo "ANNO: CHR START INSERTION DELETION INSERTEDSEQUENCE NORMALSAMPLE TUMORSAMPLE"
	exit 1
fi

type=`basename $2|awk -F'.' '{print $2}' |awk -F'_' '{print $1}'` # Get file name
file=`basename $2` # Get file name

path=`readlink -f ${2} | awk '{print $0"_snaps"}'` #Create new directory with name ending in _snaps
mkdir ${path}

> ${path}/${file}.bat
samples=`cut -f 6 ${2}|awk '{print $1}'|uniq | grep -v "^$" ` #Get all unique samples
echo "genome hg19" >> ${path}/${file}.bat
while read sample
do
echo $sample
##Identify primary and germline samples
	bam_path_primary=`fgrep ${sample} ${1}|cut -f 4`
	bam_path_germline=`fgrep ${sample} ${1}|cut -f 6`
	echo "new" >> ${path}/${file}.bat
	echo "load ${bam_path_primary}" >> ${path}/${file}.bat
	echo "load ${bam_path_germline}" >> ${path}/${file}.bat
	echo "snapshotDirectory ${path}" >> ${path}/${file}.bat

	###EXAMPLE:CHR_START_INSERTION_DELETION_INSERTEDSEQ_NORMALSAMPLE
	mutations=`fgrep -w ${sample} ${2}|awk 'BEGIN{FS="[:,\t,|,=,;, ]"}{print $1"_"$2"_"$3"_"$4"_"$5"_"$6}' `
	while read mutation
	do
	echo $mutation
		start=`echo "$mutation"|awk '{split($1,a,"_"); print a[1]}'`
		start_new=`expr ${start} - 20`
		stop=`echo "$mutation"|awk '{split($1,a,"_"); print a[1]}'`
		stop_new=`expr ${stop} + 100`	
		chr=`echo "$mutation"|awk '{split($1,a,"_"); print a[0]}'`
	
		echo "goto ${chr}:${start}" >> ${path}/${file}.bat
		echo "sort base" >> ${path}/${file}.bat
		echo "goto ${chr}:${start_new}-${stop_new}" >> ${path}/${file}.bat
		echo "snapshot ${mutation}_somatic.png" >> ${path}/${file}.bat
	done <<< "$mutations"

done <<< "$samples"

echo "Run ${path}/${file}.bat in IGV"
