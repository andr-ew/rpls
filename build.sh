#!/bin/bash

mkdir build
cd ..
zip -r rpls/build/complete-source-code.zip rpls/ -x "rpls/.git/*" "rpls/lib/doc/*" "rpls/build.sh" "rpls/build/*"
