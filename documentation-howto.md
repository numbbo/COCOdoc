The documentation of the COCO platform is split into several parts:

### Documentation of the COCO source code and its functioning: coco-documentation
The COCO source code itself is documented directly within itself in the code-experiments/ folders
of the numbbo/coco repository and then transformed via doxygen into html and published at
numbbo.github.io/coco-documentation via this repository. More details about how to deal with this 
part can be found below.

### Documentation of generic Coco setting
The generic parts of Coco are documented in two separate documents:
* coco-generic/experimental-setup for the description of the experimental setup (source in
  ../docs/coco-generic/experimental-setup/source and then published via Sphinx to
  https://numbbo.github.io/coco-doc/experimental-setup)
* coco-generic/perf-assessment for the description of the performance assessment, plots, etc. (source in
  ../docs/coco-generic/perf-assessment/source and then published via Sphinx to
  https://numbbo.github.io/coco-doc/perf-assessment)

### Documentation of the test suites
Each test suite will have separate documentations for the function documentation and (potentially) the experimental setting.
For the moment, we have the following documentations:
* bbob-biobj/perf-assessment (source in ../docs/bbob-biobj/perf-assessment/source and then published via Sphinx to 
  https://numbbo.github.io/coco-doc/bbob-biobj/perf-assessment)
* bbob-biobj/functions (source in ../docs/bbob-biobj/functions/source and then published via Sphinx to 
  https://numbbo.github.io/coco-doc/bbob-biobj/functions)
* bbob-largescale/functions (source in ../docs/bbob-largescale/functions/source and then published via Sphinx to 
  https://numbbo.github.io/coco-doc/bbob-largescale/functions)
* bbob-constrained/functions (contours plots (source in ../docs/bbob-constrained/functions/source) and short PDF documentation at 
  https://numbbo.github.io/coco-doc/bbob-constrained)
* bbob-experiments (old documentation available at http://coco.lri.fr/downloads/download15.03/bbobdocfunctions.pdf)
* bbob-functions (old documentation available at http://coco.lri.fr/downloads/download15.03/bbobdocexperiment.pdf)
* bbob-noisy-functions (old documentation available at http://coco.lri.fr/downloads/download15.03/bbobdocnoisyfunctions.pdf)

### Documentations related to the workshops
Web pages for the workshops are also created from reStructuredText via Sphinx. The source files can be found in the 
nummbo/workshops repository.



HowTo: Edit and Publish the experimental setting and function documentations
----------------------------------------------------------------------------
The source files (as reStructuredText) can be found and edited in the subfolders of docs/. Their reStructuredText is
translated into html, latex, or pdf with the help of Sphinx (http://www.sphinx-doc.org). To build the html, latex, or pdf
output for each documentation, you need to install sphinx by typing `pip install -U Sphinx` (if you have installed pip) and then
type `make html`, `make latex`, or `make latexpdf` in the corresponding subfolder of docs/.

For publishing the html to the web, a `make html-topublish` in the corresponding subfolder will create the
same html files than `make html` but instead of the build/ subfolder, it uses the correct folder to be published
directly on the webpage. To make this actually happen, the changes made have to be pushed to the only branch called
`gh-pages` by a simple `git push` command. Due to the git pages functionality, this push will directly update the web page.

#### Summary:
- need: python, sphinx, git
- edit `.rst` sources in docs/FOLDERNAME and commit and push as usual within the only existing branch `gh-pages`
- for checking the output, type `make html`, `make latex`, or `make latexpdf` (output written to build/ subfolder)
- for publishing the changes to the web:
  - create the html with `make html-topublish`
  - commit and push the changes (in the `gh-pages` branch) to update the web page

#### Current documentations and their repositories:
- sources in ../docs/bbob-biobj/functions are written into bbob-biobj/functions folder
- sources in ../docs/bbob-biobj/perf-assessment are written into bbob-biobj/perf-assessment folder
- sources in ../docs/bbob-largescale/functions are written into bbob-largescale/functions folder
- sources in ../docs/bbob-constrained/functions are written into bbob-constrained/functions folder
- sources in ../docs/coco-doc are written directly into the root of the coco-doc repository
  [see also below, because this documentation is partly build from the source code]


HowTo: Edit and Publish the COCO documentation
----------------------------------------------
In addition to the reStructuredText which explains the general functioning of the COCO platform in
../docs/coco-doc/ (which is translated into html via Sphinx as described above), parts of the COCO 
documentation are automatically extracted from the source code.


#### C documentation

The C code in the code-experiments/src/ folder of the numbbo/coco repository for example is translated into html
in the C/ subfolder of this `gh-pages` branch of the numbbo/coco-doc repository with the help of the doxygen tool
(www.doxygen.org/). After installing doxygen, and having a clone of the `master` or `development` branch of the
numbbo/coco github repository in the same folder than your numbbo/coco-doc checkout, you can create the html output
in this directory by simply typing `doxygen` in the docs/coco-doc/C/ folder. Afterwards, commit and push
of this repository will again update the web page directly as described above.
Note that we have tried a few versions of doxygen back in January 2020 and not all were producing the output we wanted.
Hence, we suggest to use Doxygen version 1.8.11.

#### Python documentation

To create and publish the documentation of the `coco-experiment` (`cocoex`)
and `cocopp` modules as well as the examples in `build/python/example`,
using `pydoctor`, see the script `run_pydoctor.sh` at the root for how to.
Then add and commit the changes to the `apidocs` folder.

```bash
cd coco-doc
./run_pydoctor.sh
git add apidocs/*
git commit -m "update documentation for release X.X"
git push  # to the gh-pages branch
```
