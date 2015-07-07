set terminal tikz color scale 1,.4
set output "../fig/pcie-lane-ratio2.tex"
#set terminal png transparent enhanced font "helvetica,14" fontscale 1.0 size 500, 350
#set output "hoge.png"

set border 3 front linetype -1 linewidth 1.000
set boxwidth 0.95 absolute
#set style fill transparent solid 0.8 noborder
set style fill transparent solid 0.8 border
set grid nopolar
set grid noxtics nomxtics ytics nomytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
#set key bmargin left horizontal Left reverse noenhanced autotitles columnhead nobox
#set key outside rght top vertical Left reverse noenhanced autotitles columnhead nobox
#set key invert samplen 4 spacing 1 width 0 height 0 
set key samplen 1 spacing 1

set grid layerdefault linetype 0 linewidth 1.000,  linetype 0 linewidth 1.000
set style histogram clustered gap 1 title  offset character 2, 0.25, 0
set style data histograms
set ytics border in scale 0,0 mirror norotate  offset character 0, 0, 0 autojustify
set ztics border in scale 0,0 nomirror norotate  offset character 0, 0, 0 autojustify
set cbtics border in scale 0,0 mirror norotate  offset character 0, 0, 0 autojustify
set rtics axis in scale 0,0 nomirror norotate  offset character 0, 0, 0 autojustify
set xtics border in scale 0,0 nomirror offset character 0, 0, 0 autojustify

set bmargin 0
set tmargin 0
set lmargin 9
set rmargin 0
set yrange [0:100]
set xlabel "Lane width"
set ylabel "Throughput (\\%)"
set title "\\% of Theoretical Max. TX Throughput"
#plot 'pcielane.dat' using 1:xtic(1) ti col, '' u 2 ti col, '' u 3 ti col, '' u 4 ti col, '' u 5 ti col
plot 'pcie-lane-ratio.dat' u 2:xtic(1) ti col, '' u 3 ti col, '' u 4 ti col, '' u 5 ti col

