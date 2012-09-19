[p2xmp](http://github.com/vosbergw/p2xmp) is a utility to update the 
Crop & Rotate filter of Darktable from the command line.

I successfully used this when moving my images from Picasa to Darktable to
apply the same Crop & Rotate I had used in Picasa to the images in Darktable.

The basic (and only tested) flow is:

* use [metaSave](http://projects.mindtunnel.com/blog/2012/08/30/metasave/) to
extract all the Picasa data to .meta files
* import the original images into Darktable
* create a simple Crop & Rotate style in Darktable (rotate .1 degrees and crop
a couple pixels off each side) and apply this to all the raw original images
  * this will create a sidecar .xmp file for every image.  the Crop & Rotate
	settings here will be replaced with your values from Picasa (including
	setting back to 0 rotate, 0 crop if that was what was in Picasa)
* exit Darktable and run p2xmp to restore the old Crop & Rotate

You can run p2xmp manualy on each file:

```
$ p2xmp
usage: /usr/local/bin/p2xmp <file>.xmp ang,cx,cy,cw,ch
```

Or, use the following bash similiar to the following to do them all at once.
A couple notes on this script:

* it should run from the directory containing the Darktable image and xmp files.
* it expects .meta files as created by [metaSave](http://projects.mindtunnel.com/blog/2012/08/30/metasave/)
* after updating it will move the .meta files to the current directory (which is the first place it will look as well)
* note the .png checks: the Picasa files were .png and that is what I used when
 metaSave was run.  Darktable doesn't support .png on import so I had to 
 convert them (convert <.png> -quality 100% -compress LossLess <.jpg>) for 
 (hence the difference in names)

```
#!/bin/bash

if [[ ${#1} == 0 ]]
then
	echo "usage: $0 <meta dir>"
else
	META="$1"

	for f in *.jpg # $(ls *.jpg)
	do
		B=$(basename "$f" .jpg)
		MFN="$f.meta"
		MFP="$META/$B.png.meta"
		MFJ="$META/$B.jpg.meta"

		echo "-------------------------------------"
		echo "file: $f"
		if [[ -f "$MFN" ]]
		then
			MF="$MFN"
		elif [[ -f "$MFP" ]]
		then
			MF="$MFP"
		elif [[ -f "$MFJ" ]]
		then
			MF="$MFJ"
		else
			# special case:
			if [[ -f "$META/$B.png.jpg.meta" ]]
			then
				MF="$META/$B.png.jpg.meta"
			else
				echo "no meta found for $f in $META"
				exit
			fi
		fi
		echo "meta: $MF"
		tilt=$(grep -aF 'pmp.filters.tilt' "$MF" | cut -d: -f2)
		cropxy=$(grep -aF 'pmp.filters.crop64xy' "$MF" | cut -d: -f2)
		width=$(grep -aF 'pmp.width' "$MF" | cut -d: -f2)
		height=$(grep -aF 'pmp.height' "$MF" | cut -d: -f2)
		rotate=$(grep -aF 'pmp.rotate' "$MF" | cut -d: -f2)

		if [[ ${#tilt} == 0 ]]
		then
			tilt=$(grep -aF 'ini.filters:tilt' "$MF" | cut -d"," -f2)
			if [[ ${#tilt} == 0 ]]
			then
				tilt="0.0"
			else
				tilt=$(dc -e "$tilt _10.0 * p")
			fi
		fi
		if [[ ${#cropxy} == 0 ]]
		then
			cropxy=$(grep -aF 'ini.cropxy' "$MF" | cut -d: -f2)
			if [[ ${#cropxy} == 0 ]]
			then
				cropxy="0.0,0.0,1.0,1.0"
			fi
		fi

		if [[ ${#rotate} != 0 ]]
		then
			rotate=$(grep -aF 'ini.rotate' "$MF" | cut -d: -f2)
		fi
			
		if [[ ${#rotate} != 0 ]]
		then
			if [[ $rotate == "rotate(1)" ]]
			then
				echo "adding 90 degrees to the tilt"
				tilt=$(dc -e "$tilt 90.0 + p")
			elif [[ $rotate == "rotate(3)" ]]
			then
				echo "subtracting 90 degrees from the tilt"
				tilt=$(dc -e "$tilt 90.0 - p")
			elif [[ $rotate == "rotate(2)" ]]
			then
				echo "adding 180 degrees to the tilt"
				tilt=$(dc -e "$tilt 180.0 + p")
			else
				echo "what is rotate??"
				exit
			fi
		fi
		echo "tilt: $tilt"
		echo "cropxy: $cropxy"
		echo "width: $width"
		echo "height: $width"
		echo "rotate: $rotate"
		#echo "first crop - numbers directly from picasa"
		echo "p2xmp $f.xmp $tilt,$cropxy"
		p2xmp "$f.xmp" $tilt,$cropxy
		#
		# skip second crop -- first is correct
		#if [[ $cropxy != "0.0,0.0,1.0,1.0" ]]
		#then
		#	echo "second crop - assume picasa is x1,y1 x2,y2 and covert to x,y w,h"
		#	cx=$(echo "$cropxy" | cut -d"," -f1)
		#	cy=$(echo "$cropxy" | cut -d"," -f2)
		#	cxx=$(echo "$cropxy" | cut -d"," -f3)
		#	cyy=$(echo "$cropxy" | cut -d"," -f4)
		#	cw=$(dc -e "$cxx $cx - p")
		#	ch=$(dc -e "$cyy $cy - p")
		#	echo "p2xmp $f.xmp $tilt,$cx,$cy,$cw,$ch"
		#	p2xmp "$f.xmp" $tilt,$cx,$cy,$cw,$ch
		#fi
		#

		if [[ ! -f  "$f".meta ]]
		then
			mv "$MF" "$f".meta
		else
			echo "$f.meta already exists!"
		fi
	done
fi
```
