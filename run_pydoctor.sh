#!/bin/bash
# first argument is path/to/coco
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocopp' "$1"/code-postprocessing/cocopp
touch "$1"/code-experiments/build/python/example/__init__.py
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example
# after checking: apidocs/example/index.html
# git add apidocs/example

# the following requires to have run the build for cocoex via scripts/fabricate (maybe from the folder code-postprocessing)
mkdir tmp
cp -r "$1"/code-experiments/build/python/src/cocoex tmp
pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/cocoex' tmp/cocoex
rm -r tmp

# replaced by the above --html-output='apidocs/example'
# pydoctor --docformat=restructuredtext --make-html --html-output='apidocs/example' "$1"/code-experiments/build/python/example/example_experiment2.py
