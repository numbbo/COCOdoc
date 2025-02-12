#!/bin/bash
# The first argument is the folder where the repository folders
#   coco-postprocess can be found, typically it may be ".."
# was: first argument is path/to/coco , which doesn't work anymore, 
#      because coco now lives in multiple repositories

pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocopp' "$1"/coco-postprocess/src/cocopp > err-pydoc-cocopp.txt
echo "  to catch new files execute 'git add apidocs/cocopp'"

# replaced by the above --html-output='apidocs/example'
# pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example/example_experiment2.py
