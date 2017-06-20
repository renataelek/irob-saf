#!/bin/bash
# Set stereo camera focus


uvcdynctrl -v -d video0 --set='Power Line Frequency' 1
uvcdynctrl -v -d video1 --set='Power Line Frequency' 1

uvcdynctrl -v -d video0 --set='Focus, Auto' 0
uvcdynctrl -v -d video1 --set='Focus, Auto' 0

echo video1 autofocus:
uvcdynctrl -v -d video0 --get='Focus, Auto'
echo video2 autofocus:
uvcdynctrl -v -d video1 --get='Focus, Auto'

uvcdynctrl -v -d video0 --set='Focus (absolute)' 50
uvcdynctrl -v -d video1 --set='Focus (absolute)' 55

uvcdynctrl -v -d video0 --set='Focus (absolute)' 85
uvcdynctrl -v -d video1 --set='Focus (absolute)' 85

uvcdynctrl -v -d video0 --set='Focus (absolute)' 63
uvcdynctrl -v -d video1 --set='Focus (absolute)' 71

echo video1 focus:
uvcdynctrl -v -d video0 --get='Focus (absolute)'
echo video2 focus:
uvcdynctrl -v -d video1 --get='Focus (absolute)'
