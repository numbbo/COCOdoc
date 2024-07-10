#!/bin/bash
# first argument is path/to/coco
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocopp' "$1"/code-postprocessing/cocopp
mkdir tmp
cp -r "$1"/code-experiments/build/python/python tmp/cocoex
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocoex' tmp/cocoex
rm -r tmp
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example/example_experiment2.py
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example/example_experiment_complete.py
