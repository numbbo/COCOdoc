#!/bin/bash
# Required: coco-experiment/scripts/fabricate has been run recently
# The first argument is the folder where the repository folders 
#   coco-experiment and coco-postprocess can be found, typically
#   it may be ".."
# was: first argument is path/to/coco , which doesn't work anymore, 
#      because coco now lives in multiple repositories

pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocopp' "$1"/coco-postprocess/src/cocopp > err-pydoc-cocopp.txt
echo "  to catch new files execute 'git add apidocs/cocopp'"

touch "$1"/coco-experiment/build/python/example/__init__.py
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/coco-experiment/build/python/example > err-pydoc-example.txt
# after checking: apidocs/example/index.html
echo "  to catch new files execute 'git add apidocs/example'"

# the following requires to have run the build for cocoex via scripts/fabricate (maybe from the folder code-postprocessing)
mkdir tmp
cp -r "$1"/coco-experiment/build/python/src/cocoex tmp
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocoex' tmp/cocoex > err-pydoc-cocoex.txt
echo "  to catch new files execute 'git add apidocs/cocoex'"
rm -r tmp

# replaced by the above --html-output='apidocs/example'
# pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example/example_experiment2.py
