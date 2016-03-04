if [ $# -eq 0 ];then

	echo "No arguments supplied. This script will make a .bat file to run in IGV to make many screenshots given a MAF."
	echo "bash make_igv_screenshots.sh <INPUT> <ANNO>"
echo "bash scripts/make_screenshots_complex.sh /gscuser/rjayasin/projects/Complex_full/complex_indel/data/PCGP/sfoltz_complex/test_folder2/example_info /gscuser/rjayasin/projects/Complex_full/complex_indel/data/PCGP/sfoltz_complex/test_folder2/origdata/TCGA-E2-A105.somatic_filtered_spaced"	
echo "After script finishes running open up .bat in IGV to start screenshots. (.bat file located in location of MAF file and under directory MAF_snaps)"
	exit 1
fi

type=`basename $2|awk -F'.' '{print $2}' |awk -F'_' '{print $1}'` # Get file name
file=`basename $2` # Get file name

path=`readlink -f ${2} | awk '{print $0"_snaps"}'` #Create new directory with name ending in _snaps
mkdir ${path}

> ${path}/${file}.bat
#samples=`cut -f 1 ${1}|uniq | grep -v "^$" ` #Get all unique samples
samples=`cut -f 2 ${2}|awk '{print $1}'|uniq | grep -v "^$" ` #Get all unique samples
echo "genome hg19" >> ${path}/${file}.bat
while read sample
do
echo $sample
##Identify primary and germline samples
	bam_path_primary=`fgrep ${sample} ${1}|cut -f 3`
	bam_path_germline=`fgrep ${sample} ${1}|cut -f 5`
	echo "new" >> ${path}/${file}.bat
	echo "load ${bam_path_primary}" >> ${path}/${file}.bat
	echo "load ${bam_path_germline}" >> ${path}/${file}.bat
	echo "snapshotDirectory ${path}" >> ${path}/${file}.bat

	#mutations=`fgrep ${sample} ${2} |awk -F '\t' '{print $8"_"$10"_"$11"_"$3"_"$5}'`
	###EXAMPLE:GRIK2_H_LC-SJETV028_6_102322609_102322612_4
	#mutations=`fgrep ${sample} ${2} |awk -F'[:\t| ]' '{print $1"_"$2"_"$4"_"$5}' `
	mutations=`fgrep -w ${sample} ${2}|awk 'BEGIN{FS="[:,\t,|,=,;, ]"}{print $1"_"$2"_"$4"_"$5"_"$12"_"$20}' `
	while read mutation
	do
	echo $mutation
		start=`echo "$mutation"|awk '{split($1,a,"_"); print a[5]}'`
		start_new=`expr ${start} - 5`
		stop=`echo "$mutation"|awk '{split($1,a,"_"); print a[5]}'`
		stop_new=`expr ${stop} + 10`	
		chr=`echo "$mutation"|awk '{split($1,a,"_"); print a[4]}'`
	#	position=`echo "$mutation"|awk '{split($1,a,"_"); print a[4]":"a[5]"-"a[6]}'`
	
		echo "goto ${chr}:${start}" >> ${path}/${file}.bat
		echo "sort base" >> ${path}/${file}.bat
		echo "goto ${chr}:${start_new}-${stop_new}" >> ${path}/${file}.bat
		echo "snapshot ${mutation}_somatic.png" >> ${path}/${file}.bat
	done <<< "$mutations"

done <<< "$samples"

echo "Run ${path}/${file}.bat in IGV"
