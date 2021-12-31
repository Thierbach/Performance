# Dependencies
# 	pdftk
# 	pdfseparate
# 	pdfunite
# 	ocrmypdf
# 	ghostscript
# 	verapdf

if [ $1 = "-h" ]; then
	echo -e "parallelOCR Version 0.1 \nAufruf ./parallelOCR.sh <PDF Name> \nparallelOCR.sh -h diese Ausgabe"
	exit
fi


rm converted-combinedPDF* combinedPDF* pg_* result-A2b.pdf

d1=$(date +"%T.%3N")
origfile=$1

# zerlege das Original-PDF in einzelne Seiten
# pdfseparate $origfile page-%d.pdf 
pdftk $origfile burst 

# lese die einzeln Filenamen der Seiten in ein Array
array=($(ls -v pg_*.pdf))
# echo ${array[@]}

# ermittle die Anzahl der Seiten
pageNumber="${#array[@]}"
# echo $pageNumber

# Seiten zusammenführen
step=0
count=0
while [ $step -le $pageNumber ]
	do
	 page1=${array[$step]}
	 page2=${array[$step + 1]}
	 page3=${array[$step + 2]}
	 page4=${array[$step + 3]}
	 page5=${array[$step + 4]}
#	 echo $page1 $page2 $page3 $page4 $page5
	
	 # führe Seiten zusammen
	 pdfunite $page1 $page2 $page3 $page4 $page5 combinedPDF$count.pdf


	# konvertiere PDF Fragmente zu TIFF 
	gs -q  -dBATCH \
		-dNOPAUSE \
		-sDEVICE=tiffscaled24 \
		-r200x200 \
		-sOutputFile=combinedPDF$count.tif \
		combinedPDF$count.pdf \
		-c quit


	 count=$((count + 1))
	 step=$((step + 5))
done		

# lese die Dateinamen mit den zusammengeführten Seiten
array2=($(ls -v combinedPDF*.tif))
# array2=($(ls -v combinedPDF*.pdf))
# echo ${array2[@]}

# d3=$(date +"%T.%3N")
# echo $d1
# echo $d1


# Parallisiere die Konvertierung
for i in "${array2[@]}"
	do 
	# echo "ocrmypdf für $i"
	# ocrmypdf --output-type pdf -l deu --skip-text -j 2 $i --rotate-pages-threshold 55 converted-$i &
	ocrmypdf --output-type pdf -l deu --force-ocr -j 2 --rotate-pages-threshold 55 --image-dpi 300 $i converted-$i &
	done

# count=$((count -2))
# echo converted-combinedPDF$count.pdf

array4=($())

# warten, bis alle Files konvertiert sind
while [ "${#array4[@]}" != "${#array2[@]}" ]
do
	array4=($(ls -v converted-combinedPDF*.tif))
	# array4=($(ls -v converted-combinedPDF*.pdf))
        # echo "Konvertierung läuft noch ..."
        sleep 1
done


# lese die ocr'ten Files ein
# array3=($(ls -v converted-combinedPDF*.pdf))
array3=($(ls -v converted-combinedPDF*.tif))
# echo ${array3[@]}

# pdftk ${array3[@]} cat output temp.pdf 

gs      -dPDFA=2                                \
        -dBATCH                                 \
        -dNOPAUSE                               \
	-dUseCIEColor				\
        -sProcessColorModel=DeviceCMYK          \
        -sDEVICE=pdfwrite                       \
        -sPDFCompatibilityPolicy=1              \
        -dColorImageDownsampleType=/Bicubic     \
        -dColorImageResolution=150              \
        -dGrayImageDownsampleType=/Bicubic      \
        -dGrayImageResolution=150               \
        -dMonoImageDownsampleType=/Subsample    \
        -dMonoImageResolution=150               \
        -sOutputFile=result-A2b.pdf             \
 	${array3[@]}  

d2=$(date +"%T.%3N")
echo $d1
echo $d2

echo "----> Verify PDF/A2-b Compliance"
../verapdf/verapdf ./result-A2b.pdf





