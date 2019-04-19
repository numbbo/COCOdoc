.. title:: COCO: The Large Scale Black-Box Optimization Benchmarking (bbob-largescale) Test Suite

$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
COCO: The Large Scale Black-Box Optimization Benchmarking (``bbob-largescale``) Test Suite
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

.. the next two lines are necessary in LaTeX. They will be automatically
  replaced to put away the \chapter level as ??? and let the "current" level
  become \section.

.. CHAPTERTITLE
.. CHAPTERUNDERLINE



.. |
.. |
.. .. sectnum::
  :depth: 3


  :numbered:
.. .. contents:: Table of Contents
  :depth: 2
.. |
.. |

.. raw:: html

   See also: <I>ArXiv e-prints</I>,
   <A HREF="http://arxiv.org/abs/XXXX.XXXXX">arXiv:XXXX.XXXXX</A>, 2019.

.. raw:: latex

  % \tableofcontents TOC is automatic with sphinx and moved behind abstract by swap...py
  \begin{abstract}

The ``bbob-largescale`` test suite, containing 24 single-objective
functions in continuous domain, extends the well-known
single-objective noiseless ``bbob`` test suite [HAN2009]_, which has been used since 2009 in
the `BBOB workshop series`_, to large dimension. The core idea is to make the rotational
transformations :math:`\textbf{R}, \textbf{Q}` in search space that
appear in the ``bbob`` test suite computationally cheaper while retaining some desired
properties. This documentation presents an approach that replaces a full rotational transformation with a combination of a block-diagonal matrix and two permutation matrices in order to construct test functions whose computational and memory costs scale linearly in the dimension of the problem.

.. raw:: latex

  \end{abstract}
  \newpage



.. _`BBOB workshop series`: http://numbbo.github.io/workshops
.. _COCO: https://github.com/numbbo/coco
.. _COCOold: http://coco.gforge.inria.fr
.. |coco_problem_t| replace::
  ``coco_problem_t``
.. _coco_problem_t: http://numbbo.github.io/coco-doc/C/coco_8h.html#a408ba01b98c78bf5be3df36562d99478

.. |f| replace:: :math:`f`



.. Some update:
   - Step ellipsoid: It has been updated the condition: \hat{z}_i > 0.5 (old) --> |\hat{z}_i| > 0.5
   - Schwefel function:
        (1) \mathbf{z} = 100 (\mathbf{\Lambda}^{10} (\mathbf{\hat{z}} - \mathbf{x}^{\text{opt}}) + \mathbf{x}^{\text{opt}}) --> \mathbf{z} = 100 (\mathbf{\Lambda}^{10} (\mathbf{\hat{z}} - 2|\mathbf{x}^{\text{opt}}|) + 2|\mathbf{x}^{\text{opt}}|)
        (2) - frac{1}{D} sum(...) --> - frac{1}{100D} sum(...)
        (3) \hat{z}_1 = \hat{x}_1, \hat{z}_{i+1}=\hat{x}_{i+1} + 0.25 (\hat{x}_{i} - x_i^{\text{opt}}), \text{ for } i=1, \dots, n-1 --> \hat{z}_1 = \hat{x}_1, \hat{z}_{i+1}=\hat{x}_{i+1} + 0.25 (\hat{x}_{i} - 2|x_i^{\text{opt}}|), \text{ for } i=1, \dots, n-1
..


.. #################################################################################
.. #################################################################################
.. #################################################################################




Introduction
============
In the ``bbob-largescale`` test suite, we consider single-objective, unconstrained minimization problems
of the form

.. math::
    \min_{x \in \mathbb{R}^n} \ f(x),

with problem dimensions :math:`n \in \{20, 40, 80, 160, 320, 640\}.`

The objective is to find, as quickly as possible, one or several solutions :math:`x` in the search
space :math:`\mathbb{R}^n` with *small* value(s) of :math:`f(x)\in\mathbb{R}`. We
generally measure the *time* of an optimization run as the number of calls to (queries of) the objective function :math:`f`.

We remind in the next sections some notations and definitions.

Terminology
-----------
*function*
    We talk about an objective *function* |f| as a parametrized mapping
    :math:`\mathbb{R}^n\to\mathbb{R}` with scalable input space, that is,
    :math:`n` is not (yet) determined. Functions are parametrized such that
    different *instances* of the "same" function are available, e.g. translated
    or rotated versions.

*problem*
    We talk about a *problem*, |coco_problem_t|_, as a specific *function
    instance* on which an optimization algorithm is run. Specifically, a problem
    can be described as the triple ``(dimension, function, instance)``. A problem
    can be evaluated and returns an :math:`f`-value. In the context of performance
    assessment, a target :math:`f`- or indicator-value is attached to each problem.
    That is, a target value is added to the above triple to define a single problem
    in this case.

*runtime*
    We define *runtime*, or *run-length* as the *number of evaluations*
    conducted on a given problem, also referred to as number of *function* evaluations.
    Our central performance measure is the runtime until a given target value
    is hit.

*suite*
    A test- or benchmark-suite is a collection of problems, typically between
    twenty and a hundred.


.. |n| replace:: :math:`n`
.. |theta| replace:: :math:`\theta`
.. |i| replace:: :math:`i`
.. |j| replace:: :math:`j`
.. |t| replace:: :math:`t`
.. |fi| replace:: :math:`f_i`


Functions, Instances and Problems
---------------------------------
Each function is *parametrized* by the (input) dimension, |n|, its identifier |i|, and the instance number, |j|,
that is:

.. math::
    f_i^j \equiv f(n, i, j): \mathbb{R}^n \to \mathbb{R} \quad x \mapsto f_i^j (x) = f(n, i, j)(x).

Varying |n| or |j| leads to a variation of the same function |i| of a given suite.
By fixing |n| and |j| for function |fi|, we define an optimization **problem**
:math:`(n, i, j)\equiv(f_i, n, j)` that can be presented to the optimization algorithm.
Each problem receives again an index in the suite, mapping the triple :math:`(n, i, j)` to a single
number.

We can think of |j| as an index to a continuous parameter vector setting,
as it parametrizes, among others things, translations and rotations. In
practice, |j| is the discrete identifier for single instantiations of
these parameters.


Runtime and Target Values
-------------------------

In order to measure the runtime of an algorithm on a problem, we
establish a hitting time condition.
For a given problem |p|, we prescribe a **target value** |t| as a specific |f|-value
of interest [HAN2016perf]_.
For a single run, when an algorithm reaches or surpasses the target value |t|
on problem |p|, we say that it has *solved the problem* |pt| --- it was successful. [#]_

The **runtime** is, then, the evaluation count when the target value |t| was
reached or surpassed for the first time.
That is, the runtime is the number of |f|-evaluations needed to solve the problem
|pt|. [#]_
*Measured runtimes are the only way how we assess the performance of an
algorithm.*
Observed success rates are generally translated into runtimes on a subset of
problems.


.. _Recommendations: https://www.github.com


If an algorithm does not hit the target in a single run, its runtime remains
undefined --- while, then, this runtime is bounded from below by the number of evaluations
in this unsuccessful run.
The number of available runtime values depends on the budget the
algorithm has explored (the larger the budget, the more likely the target-values are reached).
Therefore, larger budgets are preferable --- however they should not come at
the expense of abandoning reasonable termination conditions. Instead,
restarts should be done [HAN2016ex]_.

.. [#] Note the use of the term *problem* in two meanings: as the problem the
    algorithm is benchmarked on, |p|, and as the problem, |pt|, an algorithm can
    solve by hitting the target |t| with the runtime, |RT(pt)|, or may fail to solve.
    Each problem |p| gives raise to a collection of dependent problems |pt|.
    Viewed as random variables, the events |RT(pt)| given |p| are not
    independent events for different values of |t|.

.. [#] Target values are directly linked to a problem, leaving the burden to
    properly define the targets with the designer of the benchmark suite.
    The alternative is to present final |f|-values as results,
    leaving the (rather unsurmountable) burden to interpret these values to the
    reader.
    Fortunately, there is an automatized generic way to generate target values
    from observed runtimes, the so-called run-length based target values
    [HAN2016perf]_.


.. |k| replace:: :math:`k`
.. |p| replace:: :math:`(f_i, n, j)`
.. |pt| replace:: :math:`(f_i, n, j, t)`
.. |RT(pt)| replace:: :math:`\mathrm{RT}(f_i, n, j, t)`


Overview of the Proposed ``bbob-largescale`` Test Suite
=======================================================
The ``bbob-largescale`` test suite provides 24 functions in six dimensions (20, 40, 80, 160, 320 and 640) within
the COCO_ framework [HAN2016co]_. It is derived from the existing single-objective, unconstrained ``bbob`` test suite with
modifications that allow the user to benchmark algorithms on high dimensional problems efficiently.
We will explain in this section how the ``bbob-largescale`` test suite is built.


The single-objective ``bbob`` functions
---------------------------------------
The ``bbob`` test suite relies on the use of a number of raw functions from
which 24 ``bbob`` functions are generated. Initially, so-called *raw* functions
are designed. Then, a series of transformations on these raw functions, such as
linear transformations (e.g., translation, rotation, scaling) and/or non-linear
transformations (e.g., :math:`T_{\text{osz}}, T_{\text{asy}}`)
will be applied to obtain the actual ``bbob`` test functions. For example, the test function
:math:`f_{13}(\mathbf{x})` (`Sharp Ridge function`_) with (vector) variable :math:`\mathbf{x}`
is derived from a raw function defined as follows:

.. _Sharp Ridge function: http://coco.lri.fr/downloads/download15.03/bbobdocfunctions.pdf#page=65

.. math::
    f_{\text{raw}}^{\text{Sharp Ridge}}(\mathbf{z}) = z_1^2 + 100\sqrt{\sum_{i=2}^{n}z_i^2}.

Then one applies a sequence of transformations:
a translation by using the vector :math:`\mathbf{x}^{\text{opt}}`;
then a rotational transformation :math:`\mathbf{R}`; then a scaling transformation
:math:`\mathbf{\Lambda}^{10}`; then another rotational transformation :math:`\mathbf{Q}`
to get the relationship
:math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{10}\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})`; and finally
a translation in objective space by using :math:`\mathbf{f}_{\text{opt}}` to obtain the final
function in the testbed:

.. Dimo: the above paragraph explains things in the wrong order, isn't it?
.. Wassim: Right, the transformations are applied in the reverse order

.. math::
    f_{13}(\mathbf{x}) = f_{\text{raw}}^{\text{Sharp Ridge}}(\mathbf{z}) + \mathbf{f}_{\text{opt}}.


There are two main reasons behind the use of transformations here:

(i) provide non-trivial problems that cannot be solved by simply exploiting some of their properties (separability, optimum at fixed position, ...) and
(ii) allow to generate different instances, ideally of similar difficulty, of the same problem by using different (pseudo-)random transformations.


Rotational transformations are used to avoid separability and thus coordinate system dependence in the test functions.
The rotational transformations consist in applying
an orthogonal matrix to the search space: :math:`x \rightarrow z = \textbf{R}x`, where :math:`\textbf{R}` is the
orthogonal matrix.
While the other transformations used in the ``bbob`` test suite could be naturally extended to
the large scale setting due to their linear complexity, rotational transformations have quadratic time and
space complexities. Thus, we need to reduce the complexity of these transformations in order for them to be usable, in practice, in the large scale setting.

Extension to large scale setting
--------------------------------
Our objective is to construct a large scale test suite where the cost of a function call is
acceptable in higher dimensions while preserving the main characteristics of the original functions in the ``bbob``
test suite.
To this end, we will replace the full orthogonal matrices of the rotational transformations,
which would be too expensive in our large scale setting, with orthogonal transformations
that have linear complexity in the problem dimension: *permuted orthogonal block-diagonal matrices* ([AIT2016]_).

Specifically, the matrix of a rotational transformation :math:`\textbf{R}`
will be represented as:

.. math::
    \textbf{R} = P_{\text{left}}BP_{\text{right}}.

Here, :math:`P_{\text{left}} \text{ and } P_{\text{right}}` are two permutation matrices [#]_ and :math:`B` is a
block-diagonal matrix of the form:

.. math::
    B = \left(\begin{matrix}
    B_1 & 0 & \dots & 0 \\
    0 & B_2 & \dots & 0 \\
    0 & 0 & \ddots & 0 \\
    0 & 0 & \dots & B_{n_b}
    \end{matrix}
    \right),

where :math:`n_b` is the number of blocks and :math:`B_i, 1 \leq i \leq n_b`
are square matrices of sizes :math:`s_i \times s_i` satisfying :math:`s_i \geq 1`
and :math:`\sum_{i=1}^{n_b}s_i = n`. In this case, the matrices
:math:`B_i, 1 \leq i \leq n_b` are all orthogonal. Thus, the matrix :math:`B`
is also an orthogonal matrix.

This representation allows the rotational transformation :math:`\textbf{R}` to satisfy three
desired properties:

1. Have (almost) linear cost (due to the block structure of :math:`B`).
2. Introduce non-separability.
3. Preserve the eigenvalues and therefore the condition number of the original function when it is convex quadratic (since :math:`\textbf{R}` is orthogonal).

.. [#] A *permutation matrix* is a square binary matrix that has exactly one entry of
    1 in each row and each column and 0s elsewhere.

Generating the orthogonal block matrix :math:`B`
------------------------------------------------
The block-matrices :math:`B_i, i=1,2,...,n_b` will be uniformly distributed in the set of
orthogonal matrices of the same size. To this end, we first generate square matrices with
sizes :math:`s_i` (`i=1,2,...,n_b`) whose entries are i.i.d. standard normally distributed.
Then we apply the Gram-Schmidt process to orthogonalize these matrices.

The parameters of this procedure include:

- the dimension of the problem :math:`n`,
- the block sizes :math:`s_1, \dots, s_{n_b}`, where :math:`n_b` is the number of blocks. In this test suite, we set :math:`s_i = s := \min\{n, 40\} \forall i=1,2,...,n_b` (except, maybe, for the last block which can be smaller) [#]_ and thus :math:`n_b = \lceil n/s \rceil`.

.. [#] This setting allows to have the problems in dimensions 20 and 40 overlap between the ``bbob`` test suite and its large-scale extension since in these dimensions, the block sizes coincide with the problem dimensions.

Generating the permutation matrices :math:`P`
---------------------------------------------
In order to generate the permutation matrix :math:`P`, we start from the identity matrix and apply, successively, a set of so-called *truncated uniform swaps*.
Each row/column (up to a maximum number of swaps) is swapped with a row/column chosen uniformly from the set of rows/columns within a fixed range :math:`r_s`.
A random order of the rows/columns is generated to avoid biases towards the first rows/columns.

.. Dimo: can someone please check whether the above paragraph is okay and/or improve on it?
.. Wassim: the rows/columns are selected without replacement so it’s not correct

Let :math:`i` be the index of the first
variable/row/column to be swapped and :math:`j` be the index of the second swap variable. Then

.. math::
    j \sim U(\{l_b(i), l_b(i) + 1, \dots, u_b(i)\} \backslash \{i\}),

where :math:`U(S)` is the uniform distribution over the set :math:`S` and :math:`l_b(i) = \max(1,i-r_s)`
and :math:`l_b(i) = \min(n,i+r_s)` with :math:`r_s` a parameter of the approach.
If :math:`r_s \leq (n-1)/2`, the average distance between
the first and the second swap variable ranges from :math:`(\sqrt{2}-1)r_s + 1/2` (in the case of an
asymmetric choice for :math:`j`, i.e. when :math:`i` is chosen closer to :math:`1` or :math:`n` than :math:`r_s`) to
:math:`r_s/2 + 1/2` (in the case of a symmetric choice for :math:`j`). It is maximal when the first swap variable is at least :math:`r_s`
away from both extremes or is one of them.

.. Dimo: What is `d` here? Shouldn't it be `n`? And why is it `(d-1)/2` and not `n/2`?
.. Dimo: I have to say, I don't fully understand the second sentence here...
.. Wassim: the original paper should probably be referenced and I don’t think the explanation needs to be included here anyway

**Algorithm 1** below describes the process of generating a permutation using a
series of truncated uniform swaps with the following parameters:

- :math:`n`, the number of variables,
- :math:`n_s`, the number of swaps.
- :math:`r_s`, the swap range.

Starting with the identity permutation :math:`p` and another permuation :math:`\pi`, drawn uniform
at random, we apply the swaps defined above
by taking :math:`p_{\pi}(1), p_{\pi}(2), \dots, p_{\pi}(n_s)`, successively, as
first swap variable. The resulting vector :math:`p` will be the desired permutation.

*Algorithm 1: Truncated Uniform Permutations*

- Inputs: problem dimension :math:`n`, number of swaps :math:`n_s`, swap range :math:`r_s.`

- Output: a vector :math:`\textbf{p} \in \mathbb{N}^n`, defining a permutation.

1. :math:`\textbf{p} \leftarrow (1, \dots, n)`
2. Generate a permutation :math:`\pi` uniformly at random
3. :math:`\textbf{for } 1 \leq k \leq n_s \textbf{ do}`
4. * :math:`i \leftarrow \pi(k)`, i.e., :math:`\textbf{p}_{\pi(k)}` is the first swap variable
5. * :math:`l_b \leftarrow \max(1, i-r_s)`
6. * :math:`u_b \leftarrow \min(n, i+r_s)`
7. * :math:`S \leftarrow \{l_b, l_b + 1, \dots, u_b\} \backslash \{i\}`
8. * Sample :math:`j` uniformly at random in :math:`S`
9. * Swap :math:`\textbf{p}_i` and :math:`\textbf{p}_j`
10. :math:`\textbf{end for}`
11. :math:`\textbf{return p}`

In this test suite, we set :math:`n_s = n \text{ and } r_s = \lfloor n/3 \rfloor`. Some numerical
results in [AIT2016]_ show that with such parameters, the proportion of variables that are
moved from their original position when applying Algorithm 1 is approximately 100\% for all
dimensions 20, 40, 80, 160, 320, and 640 of the ``bbob-largescale`` test suite.

Implementation
--------------
Now, we describe how these changes to the rotational transformations are implemented
with the realizations of :math:`P_{\text{left}}BP_{\text{right}}`.
This will be illustrated through an example
on the Ellipsoidal function (rotated) :math:`f_{10}(\mathbf{x})` (see the table in the next section), which is defined by

.. math::
    f_{10}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2  + \mathbf{f}_{\text{opt}}, \text{with } \mathbf{z} = T_{\text{osz}} (\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})), \mathbf{R} = P_{1}BP_{2},

as follows:

(i) First, we obtain the three matrices needed for the transformation, :math:`B, P_1, P_2`,
as follows:

    .. code-block:: c

        coco_compute_blockrotation(B, seed1, n, s, n_b);
        coco_compute_truncated_uniform_swap_permutation(P1, seed2, n, n_s, r_s);
        coco_compute_truncated_uniform_swap_permutation(P2, seed3, n, n_s, r_s);

(ii) Then, whereever in the ``bbob`` test suite, we use the following

    .. code-block:: c

        problem = transform_vars_affine(problem, R, b, n);

    to make a rotational transformation, then in the ``bbob-largescale`` test suite, we replace it with the three transformations

    .. code-block:: c

        problem = transform_vars_permutation(problem, P2, n);
        problem = transform_vars_blockrotation(problem, B, n, s, n_b);
        problem = transform_vars_permutation(problem, P1, n);

.. Wassim: the output of the above is not correct, the sentence is displayed inside the code-block. And the phrasing in kinda weird

Here, :math:`n` is again the problem dimension, :math:`s` the size of the blocks in :math:`B`, :math:`n_b:`
the number of blocks, :math:`n_s:` the number of swaps, and :math:`r_s:` the swap range as presented previously.

**Important remark:** Although the complexity of ``bbob`` test suite is reduced considerably by the above replacement of
rotational transformations, we recommend running the experiment on the ``bbob-largescale`` test suite in parallel.

.. Wassim: I’m not sure this is the appropriate place for this remark, it’s more a general remark on the use of this test suite, and any test suite for that matter. It’s always preferable to run independent experiments in parallel


Functions in ``bbob-largescale`` test suite
=============================================
The table below presents the definition of all 24 functions of the ``bbob-largescale`` test suite in detail. Beside the important
modification on rotational transformations, we also make two changes to the raw functions in the ``bbob`` test suite.

- All functions, except for the Schwefel, Schaffer, Weierstrass, Gallagher, Griewank-Rosenbrock and Katsuura functions which by definition are normalized with dimension, are normalized by the parameter :math:`\gamma(n) = \min(1, 40/n)` to have uniform target values that are comparable, in difficulty, over a wide range of dimensions.

- The Discus, Bent Cigar and Sharp Ridge functions are generalized such that they have a constant proportion of distinct axes that remain consistent with the ``bbob`` test suite.

- For the two Rosenbrock functions and the related Griewank-Rosenbrock function, a different scaling is used than in the original ``bbob`` functions: instead of the factor :math:`\max (1, \frac{\sqrt{n}}{8})` with :math:`n` being the problem dimension, we scale the rotated search vector by the factor :math:`\max (1, \frac{\sqrt{s}}{8})` with :math:`s` being the block size in the matrix :math:`B`. An additional constant is added to the :math:`z` vector to reduce, with high probability, the risk to move important parts of the test function's characteristics out of the domain of interest. Without these adjustments, the original functions become significantly easier in higher dimensions due to the optimum being too close to the origin. For more details, we refer the interested reader to the discussion on the `corresponding github issue <https://github.com/numbbo/coco/issues/1733>`_.

For a better understanding of the properties of these functions and for the definitions
of the used transformations and abbreviations, we refer the reader to the original
``bbob`` `function documention`__ for details.

.. _bbobfunctiondoc: http://coco.lri.fr/downloads/download15.03/bbobdocfunctions.pdf

__ bbobfunctiondoc_


.. raw:: latex

    \begin{sidewaystable}
        \centering
        \caption{Function descriptions of the separable, moderate, and ill-conditioned function groups of the {\ttfamily bbob-largescale} test suite.}
        \scriptsize

.. tabularcolumns:: |p{0.18 \textwidth}|p{0.41 \textwidth}|p{0.41 \textwidth}|

.. table::
    :widths: 20 50 30


    +----------------------------------+------------------+------------------+
    |                                  | Formulation      | Transformations  |
    +==================================+==================+==================+
    | **Group 1: Separable functions**                                       |
    +----------------------------------+------------------+------------------+
    | Sphere Function                  | |def-f1|         | |trafo-f1|       |
    +----------------------------------+------------------+------------------+
    | Ellipsoidal Function             | |def-f2|         | |trafo-f2|       |
    +----------------------------------+------------------+------------------+
    | Rastrigin Function               | |def-f3|         | |trafo-f3|       |
    +----------------------------------+------------------+------------------+
    | Bueche-Rastrigin Function        | |def-f4-1|       | |trafo-f4-1|     |
    |                                  | |def-f4-2|       | |trafo-f4-2|     |
    |                                  |                  | |trafo-f4-3|     |
    +----------------------------------+------------------+------------------+
    | Linear Slope                     | |def-f5|         | |trafo-f5-1|     |
    |                                  |                  | |trafo-f5-2|     |
    |                                  |                  | |trafo-f5-3|     |
    |                                  |                  | |trafo-f5-4|     |
    +----------------------------------+------------------+------------------+


.. |def-f1| replace:: :math:`f_1(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} z_i^2 + \mathbf{f}_{\text{opt}}`
.. |trafo-f1| replace:: :math:`\mathbf{z} = \mathbf{x} - \mathbf{x}^{\text{opt}}`
.. |def-f2| replace:: :math:`f_2(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2+ \mathbf{f}_{\text{opt}}`
.. |trafo-f2| replace:: :math:`\mathbf{z} = T_{\text{osz}}\left(\mathbf{x} - \mathbf{x}^{\text{opt}}\right)`
.. |def-f3| replace:: :math:`f_3(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||z||^2\right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f3| replace:: :math:`\mathbf{z} = \mathbf{\Lambda}^{10} T_{\text{asy}}^{0.2} \left( T_{\text{osz}}\left(\mathbf{x} - \mathbf{x}^{\text{opt}}\right) \right)`
.. |def-f4-1| replace:: :math:`f_4(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||z||^2\right)`
.. |def-f4-2| replace:: :math:`+ 100f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f4-1| replace:: :math:`z_i = s_i T_{\text{osz}}\left(x_i - x_i^{\text{opt}}\right) \text{for } i = 1,\dots, n\hspace{6cm}`
.. |trafo-f4-2| replace:: :math:`s_i = \begin{cases} 10 \times 10^{\frac{1}{2} \frac{i-1}{n-1}} & \text{if } z_i >0 \text{ and } i \text{ odd} \\ 10^{\frac{1}{2} \frac{i-1}{n-1}} & \text{otherwise} \end{cases}`
.. |trafo-f4-3| replace:: :math:`\text{ for } i = 1,\dots, n`
.. |def-f5| replace:: :math:`f_5(\mathbf{x}) = \gamma(n)\times \sum_{i=1}^{n}\left( 5 \vert s_i \vert - s_i z_i \right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f5-1| replace:: :math:`z_i = \begin{cases} x_i & \text{if } x_i^{\mathrm{opt}}x_i < 5^2 \\ x_i^{\mathrm{opt}} & \text{otherwise} \end{cases}`
.. |trafo-f5-2| replace:: :math:`\text{ for } i=1, \dots, n,\hspace{3.5cm}`
.. |trafo-f5-3| replace:: :math:`s_i = \text{sign} \left(x_i^{\text{opt}}\right) 10^{\frac{i-1}{n-1}} \text{ for } i=1, \dots, n,\hspace{4cm}`
.. |trafo-f5-4| replace:: :math:`\mathbf{x}^{\text{opt}} = \mathbf{z}^{\text{opt}} = 5\times \mathbf{1}_{-}^+`


.. .. raw:: latex

    \end{sidewaystable}

    \begin{sidewaystable}
        \centering
        \caption{Your caption here}
        \scriptsize

.. tabularcolumns:: |p{0.18 \textwidth}|p{0.41 \textwidth}|p{0.41 \textwidth}|

.. table::
    :widths: 20 50 30


    +----------------------------------+------------------+------------------+
    | **Group 2: Functions with low or moderate conditioning**               |
    +----------------------------------+------------------+------------------+
    | Attractive Sector Function       | |def-f6|         | |trafo-f6-1|     |
    |                                  |                  | |trafo-f6-2|     |
    |                                  |                  | |trafo-f6-3|     |
    |                                  |                  | |trafo-f6-4|     |
    +----------------------------------+------------------+------------------+
    | Step Ellipsoidal Function        | |def-f7|         | |trafo-f7-1|     |
    |                                  |                  | |trafo-f7-2|     |
    |                                  |                  | |trafo-f7-3|     |
    |                                  |                  | |trafo-f7-4|     |
    +----------------------------------+------------------+------------------+
    | Rosenbrock Function, original    | |def-f8|         | |trafo-f8-1|     |
    |                                  |                  | |trafo-f8-2|     |
    +----------------------------------+------------------+------------------+
    | Rosenbrock Function, rotated     | |def-f9|         | |trafo-f9-1|     |
    |                                  |                  | |trafo-f9-2|     |
    |                                  |                  | |trafo-f9-3|     |
    +----------------------------------+------------------+------------------+



.. |def-f6| replace:: :math:`f_6(\mathbf{x}) = T_{\text{osz}}\left(\gamma(n) \times \sum_{i=1}^{n}\left( s_i z_i\right)^2 \right)^{0.9} + \mathbf{f}_{\text{opt}}`
.. |trafo-f6-1| replace:: :math:`\mathbf{z} = \mathbf{Q} \mathbf{\Lambda}^{10} \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})`
.. |trafo-f6-2| replace:: :math:`\hspace{0.2cm} \text{ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},\hspace{1.5cm}`
.. |trafo-f6-3| replace:: :math:`s_i = \begin{cases} 10^2 & \text{if } z_i \times x_i^{\mathrm{opt}} > 0\\ 1 & \text{otherwise}\end{cases}`
.. |trafo-f6-4| replace:: :math:`\text{ for } i=1,\dots, n`
.. |def-f7| replace:: :math:`f_7(\mathbf{x}) = \gamma(n) \times 0.1 \max\left(\vert \hat{z}_1\vert/10^4, \sum_{i=1}^{n}10^{2\frac{i - 1}{n - 1}}z_i^2\right) + f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f7-1| replace:: :math:`\mathbf{\hat{z}} = \mathbf{\Lambda}^{10} \mathbf{R}(\mathbf{x}-\mathbf{x}^{\text{opt}})  \text{ with }\mathbf{R} = P_{11}B_1P_{12},\hspace{4.5cm}`
.. |trafo-f7-2| replace:: :math:`\tilde{z}_i= \begin{cases} \lfloor 0.5 + \hat{z}_i \rfloor & \text{if }  |\hat{z}_i| > 0.5 \\ \lfloor 0.5 + 10 \hat{z}_i \rfloor /10 & \text{otherwise} \end{cases}`
.. |trafo-f7-3| replace:: :math:`\text{ for } i=1,\dots, n,\hspace{1.5cm}`
.. |trafo-f7-4| replace:: :math:`\mathbf{z} = \mathbf{Q} \mathbf{\tilde{z}} \text{ with } \mathbf{Q} = P_{21}B_2P_{22}`
.. |def-f8| replace:: :math:`f_8(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \left(100 \left(z_{i}^2 - z_{i+1}\right)^2 + \left(z_{i} - 1\right)^2\right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f8-1| replace:: :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)(\mathbf{x} - \mathbf{x}^{\text{opt}})+ \mathbf{1},`
.. |trafo-f8-2| replace:: :math:`\mathbf{x}^{\text{opt}} \in [-3, 3]^n`
.. |def-f9| replace:: :math:`f_9(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \left(100 \left(z_{i}^2 - z_{i+1}\right)^2 + \left(z_{i} - 1\right)^2\right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f9-1| replace:: :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})+ \mathbf{1}`
.. |trafo-f9-2| replace:: :math:`\text{ with }\mathbf{R} = P_{1}BP_{2},`
.. |trafo-f9-3| replace:: :math:`\mathbf{x}^{\text{opt}} \in [-3, 3]^n`

.. .. raw:: latex

    \end{sidewaystable}

    \begin{sidewaystable}
        \centering
        \caption{Your caption here}
        \scriptsize

.. tabularcolumns:: |p{0.18 \textwidth}|p{0.41 \textwidth}|p{0.41 \textwidth}|

.. table::
    :widths: 20 50 30

    +----------------------------------+------------------+------------------+
    | **Group 3: Functions with high conditioning and unimodal**             |
    +----------------------------------+------------------+------------------+
    | Ellipsoidal Function             | |def-f10|        | |trafo-f10|      |
    +----------------------------------+------------------+------------------+
    | Discus Function                  | |def-f11|        | |trafo-f11|      |
    +----------------------------------+------------------+------------------+
    | Bent Cigar Function              | |def-f12|        | |trafo-f12|      |
    +----------------------------------+------------------+------------------+
    | Sharp Ridge Function             | |def-f13|        | |trafo-f13-1|    |
    |                                  |                  | |trafo-f13-2|    |
    +----------------------------------+------------------+------------------+
    | Different Powers Function        | |def-f14|        | |trafo-f14|      |
    +----------------------------------+------------------+------------------+



.. |def-f10| replace:: :math:`f_{10}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2  + \mathbf{f}_{\text{opt}}`
.. |trafo-f10| replace:: :math:`\mathbf{z} = T_{\text{osz}} (\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`
.. |def-f11| replace:: :math:`f_{11}(\mathbf{x}) = \gamma(n) \times\left(10^6\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + \sum_{i=\lceil n/40 \rceil+1}^{n}z_i^2\right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f11| replace:: :math:`\mathbf{z} = T_{\text{osz}}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`
.. |def-f12| replace:: :math:`f_{12}(\mathbf{x}) = \gamma(n) \times\left(\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + 10^6\sum_{i=\lceil n/40 \rceil + 1}^{n}z_i^2 \right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f12| replace:: :math:`\mathbf{z} = \mathbf{R} T_{\text{asy}}^{0.5}(\mathbf{R}((\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`
.. |def-f13| replace:: :math:`f_{13}(\mathbf{x}) = \gamma(n) \times\left(\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + 100\sqrt{\sum_{i=\lceil n/40 \rceil + 1}^{n}z_i^2} \right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f13-1| replace:: :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{10}\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})`
.. |trafo-f13-2| replace:: :math:`\text{ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`
.. |def-f14| replace:: :math:`f_{14}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \vert z_i\vert ^{\left(2 + 4 \times \frac{i-1}{n- 1}\right)} + \mathbf{f}_{\text{opt}}`
.. |trafo-f14| replace:: :math:`\mathbf{z} = \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}) \text{ with }\mathbf{R} = P_{1}BP_{2}`



.. raw:: latex

    \end{sidewaystable}

    \begin{sidewaystable}
        \centering
        \caption{Function descriptions of the multi-modal function group with adequate global structure of the {\ttfamily bbob-largescale} test suite.}
        \scriptsize

.. tabularcolumns:: |p{0.18 \textwidth}|p{0.41 \textwidth}|p{0.41 \textwidth}|

.. table::
    :widths: 20 50 30

    +----------------------------------+------------------+------------------+
    |                                  | Formulation      | Transformations  |
    +==================================+==================+==================+
    | **Group 4: Multi-modal functions with adequate global structure**      |
    +----------------------------------+------------------+------------------+
    | Rastrigin Function               | |def-f15|        | |trafo-f15-1|    |
    |                                  |                  | |trafo-f15-2|    |
    +----------------------------------+------------------+------------------+
    | Weierstrass Function             | |def-f16-1|      | |trafo-f16-1|    |
    |                                  | |def-f16-2|      | |trafo-f16-2|    |
    |                                  |                  | |trafo-f16-3|    |
    +----------------------------------+------------------+------------------+
    | Schaffers F7 Function            | |def-f17-1|      | |trafo-f17-1|    |
    |                                  | |def-f17-2|      | |trafo-f17-2|    |
    |                                  |                  | |trafo-f17-3|    |
    +----------------------------------+------------------+------------------+
    | Schaffers F7 Function,           | |def-f18-1|      | |trafo-f18-1|    |
    | moderately ill-conditioned       | |def-f18-2|      | |trafo-f18-2|    |
    |                                  |                  | |trafo-f18-3|    |
    +----------------------------------+------------------+------------------+
    | Composite Griewank-Rosenbrock    | |def-f19|        | |trafo-f19-1|    |
    | Function F8F2                    |                  | |trafo-f19-2|    |
    |                                  |                  | |trafo-f19-3|    |
    |                                  |                  | |trafo-f19-4|    |
    |                                  |                  | |trafo-f19-5|    |
    +----------------------------------+------------------+------------------+



.. |def-f15| replace:: :math:`f_{15}(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||\mathbf{z}||^2\right) + \mathbf{f}_{\text{opt}}`
.. |trafo-f15-1| replace:: :math:`\mathbf{z} = \mathbf{R} \mathbf{\Lambda}^{10} \mathbf{Q} T_{\text{asy}}^{0.2} \left(T_{\text{osz}} \left(\mathbf{R}\left(\mathbf{x} - \mathbf{x}^{\text{opt}} \right) \right) \right) \hspace{5cm}`
.. |trafo-f15-2| replace:: :math:`\text{with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`
.. |def-f16-1| replace:: :math:`f_{16}(\mathbf{x}) = 10\left( \dfrac{1}{n} \sum_{i=1}^{n} \sum_{k=0}^{11} \dfrac{1}{2^k} \cos \left( 2\pi 3^k \left( z_i + 1/2\right) \right) - f_0\right)^3`
.. |def-f16-2| replace:: :math:`+\dfrac{10}{n}f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f16-1| replace:: :math:`\mathbf{z} = \mathbf{R}\mathbf{\Lambda}^{1/100}\mathbf{Q}T_{\text{osz}}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))\hspace{6cm}`
.. |trafo-f16-2| replace:: :math:`\text{with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},\hspace{5.8cm}`
.. |trafo-f16-3| replace:: :math:`f_0= \sum_{k=0}^{11} \dfrac{1}{2^k} \cos(\pi 3^k)`
.. |def-f17-1| replace:: :math:`f_{17}(\mathbf{x}) = \left(\dfrac{1}{n-1} \sum_{i=1}^{n-1} \left(\sqrt{s_i} + \sqrt{s_i}\sin^2\left( 50 (s_i)^{1/5}\right)\right)\right)^2`
.. |def-f17-2| replace:: :math:`+ 10 f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f17-1| replace:: :math:`\mathbf{z} = \mathbf{\Lambda}^{10} \mathbf{Q} T_{\text{asy}}^{0.5}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))`
.. |trafo-f17-2| replace:: :math:`\text{with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},\hspace{1cm}`
.. |trafo-f17-3| replace:: :math:`s_i= \sqrt{z_i^2 + z_{i+1}^2}, i=1,\dots, n-1`
.. |def-f18-1| replace:: :math:`f_{18}(\mathbf{x}) = \left(\dfrac{1}{n-1} \sum_{i=1}^{n-1} \left(\sqrt{s_i} + \sqrt{s_i}\sin^2\left( 50 (s_i)^{1/5}\right)\right)\right)^2`
.. |def-f18-2| replace:: :math:`+ 10 f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f18-1| replace:: :math:`\mathbf{z} = \mathbf{\Lambda}^{1000} \mathbf{Q} T_{\text{asy}}^{0.5}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))`
.. |trafo-f18-2| replace:: :math:`\text{ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},\hspace{0.5cm}`
.. |trafo-f18-3| replace:: :math:`s_i= \sqrt{z_i^2 + z_{i+1}^2}, i=1,\dots, n-1`
.. |def-f19| replace:: :math:`f_{19}(\mathbf{x}) = \dfrac{10}{n-1} \sum_{i=1}^{n-1} \left( \dfrac{s_i}{4000} - \cos\left(s_i \right)\right) + 10 + \mathbf{f}_{\text{opt}}`
.. |trafo-f19-1| replace:: :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)\mathbf{R} \mathbf{x} + \dfrac{\mathbf{1}}{2}`
.. |trafo-f19-2| replace:: :math:`\text{ with }\mathbf{R} = P_{1}BP_{2},\hspace{3.4cm}`
.. |trafo-f19-3| replace:: :math:`s_i= 100(z_i^2 - z_{i+1})^2 + (z_i - 1)^2,`
.. |trafo-f19-4| replace:: :math:`\text{ for } i=1,\dots, n-1,`
.. |trafo-f19-5| replace:: :math:`\mathbf{z}^{\text{opt}} = \mathbf{1}`



.. raw:: latex

    \end{sidewaystable}

    \begin{sidewaystable}
        \centering
        \caption{Function descriptions of the multi-modal function group with weak global structure of the {\ttfamily bbob-largescale} test suite.}
        \scriptsize

.. tabularcolumns:: |p{0.18 \textwidth}|p{0.41 \textwidth}|p{0.41 \textwidth}|

.. table::
    :widths: 20 50 30

    +----------------------------------+------------------+------------------+
    |                                  | Formulation      | Transformations  |
    +==================================+==================+==================+
    | **Group 5: Multi-modal functions with weak global structure**          |
    +----------------------------------+------------------+------------------+
    | Schwefel Function                | |def-f20-1|      | |trafo-f20-1|    |
    |                                  | |def-f20-2|      | |trafo-f20-2|    |
    |                                  |                  | |trafo-f20-3|    |
    |                                  |                  | |trafo-f20-4|    |
    |                                  |                  | |trafo-f20-5|    |
    +----------------------------------+------------------+------------------+
    | Gallagher's Gaussian             | |def-f21-1|      | |trafo-f21-01|   |
    | 101-me Peaks Function            | |def-f21-2|      | |trafo-f21-02|   |
    |                                  |                  | |trafo-f21-03|   |
    |                                  |                  | |trafo-f21-04|   |
    |                                  |                  | |trafo-f21-05|   |
    |                                  |                  | |trafo-f21-06|   |
    |                                  |                  | |trafo-f21-07|   |
    |                                  |                  | |trafo-f21-08|   |
    |                                  |                  | |trafo-f21-09|   |
    |                                  |                  | |trafo-f21-10|   |
    |                                  |                  | |trafo-f21-11|   |
    |                                  |                  | |trafo-f21-12|   |
    +----------------------------------+------------------+------------------+
    | Gallagher's Gaussian             | |def-f22-1|      | |trafo-f22-01|   |
    | 21-hi Peaks Function             | |def-f22-2|      | |trafo-f22-02|   |
    |                                  |                  | |trafo-f22-03|   |
    |                                  |                  | |trafo-f22-04|   |
    |                                  |                  | |trafo-f22-05|   |
    |                                  |                  | |trafo-f22-06|   |
    |                                  |                  | |trafo-f22-07|   |
    |                                  |                  | |trafo-f22-08|   |
    |                                  |                  | |trafo-f22-09|   |
    |                                  |                  | |trafo-f22-10|   |
    |                                  |                  | |trafo-f22-11|   |
    |                                  |                  | |trafo-f22-12|   |
    +----------------------------------+------------------+------------------+
    | Katsuura Function                | |def-f23-1|      | |trafo-f23-1|    |
    |                                  | |def-f23-2|      | |trafo-f23-2|    |
    +----------------------------------+------------------+------------------+
    | Lunacek bi-Rastrigin Function    | |def-f24-1|      | |trafo-f24-1|    |
    |                                  | |def-f24-2|      | |trafo-f24-2|    |
    |                                  |                  | |trafo-f24-3|    |
    |                                  |                  | |trafo-f24-4|    |
    |                                  |                  | |trafo-f24-5|    |
    +----------------------------------+------------------+------------------+


.. |def-f20-1| replace:: :math:`f_{20}(\mathbf{x}) = -\dfrac{1}{100 n} \sum_{i=1}^{n} z_i\sin\left(\sqrt{\vert z_i\vert}\right) + 4.189828872724339`
.. |def-f20-2| replace:: :math:`+ 100f_{pen}(\mathbf{z}/100)+\mathbf{f}_{\text{opt}}`
.. |trafo-f20-1| replace:: :math:`\mathbf{\hat{x}} = 2 \times \mathbf{1}_{-}^{+} \otimes \mathbf{x},`
.. |trafo-f20-2| replace:: :math:`\hat{z}_1 = \hat{x}_1, \hat{z}_{i+1}=\hat{x}_{i+1} + 0.25 \left(\hat{x}_{i} - 2\left|x_i^{\text{opt}}\right|\right),`
.. |trafo-f20-3| replace:: :math:`\text{ for } i=1, \dots, n-1,`
.. |trafo-f20-4| replace:: :math:`\mathbf{z} = 100 \left(\mathbf{\Lambda}^{10} \left(\mathbf{\hat{z}} - 2\left|\mathbf{x}^{\text{opt}}\right|\right) + 2\left|\mathbf{x}^{\text{opt}}\right|\right),`
.. |trafo-f20-5| replace:: :math:`\mathbf{x}^{\text{opt}} = 4.2096874633/2 \mathbf{1}_{-}^{+}`
.. |def-f21-1| replace:: :math:`f_{21}(\mathbf{x}) = T_{\text{osz}}\left(10 - \max_{i=1}^{101} w_i \exp\left(- \dfrac{1}{2n} (\mathbf{z} - \mathbf{y}_i)^T\mathbf{B}^T\mathbf{C_i}\mathbf{B} (\mathbf{z} - \mathbf{y}_i) \right) \right)^2`
.. |def-f21-2| replace:: :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f21-01| replace:: :math:`w_i = \begin{cases} 1.1 + 8 \times \dfrac{i-2}{99} & \text{for } 2 \leq i \leq 101\\ 10 & \text{for } i = 1 \end{cases}`
.. |trafo-f21-02| replace:: :math:`\mathbf{B} \text{ is a block-diagonal matrix without}`
.. |trafo-f21-03| replace:: :math:`\text{permuations of the variables.}`
.. |trafo-f21-04| replace:: :math:`\mathbf{C_i} = \Lambda^{\alpha_i}/\alpha_i^{1/4} \text{where } \Lambda^{\alpha_i} \text{ is defined as usual,}`
.. |trafo-f21-05| replace:: :math:`\text{but with randomly permuted diagonal elements.}`
.. |trafo-f21-06| replace:: :math:`\text{For } i=2,\dots, 101, \alpha_i \text{ is drawn uniformly}`
.. |trafo-f21-07| replace:: :math:`\text{from the set } \left\{1000^{2\frac{j}{99}}, j = 0,\dots, 99 \right\} \text{without}`
.. |trafo-f21-08| replace:: :math:`\text{replacement, and } \alpha_i = 1000 \text{ for } i = 1.`
.. |trafo-f21-09| replace:: :math:`\text{The local optima } \mathbf{y}_i \text{ are uniformly drawn}`
.. |trafo-f21-10| replace:: :math:`\text{from the domain } [-5,5]^n \text{ for }`
.. |trafo-f21-11| replace:: :math:`i = 2,...,101 \text{ and } \mathbf{y}_1 \in [-4,4]^n.`
.. |trafo-f21-12| replace:: :math:`\text{The global optimum is at } \mathbf{x}^{\text{opt}} = \mathbf{y}_1.`
.. |def-f22-1| replace:: :math:`f_{22}(\mathbf{x}) = T_{\text{osz}}\left(10 - \max_{i=1}^{21} w_i \exp\left(- \dfrac{1}{2n} (\mathbf{z} - \mathbf{y}_i)^T \mathbf{B}^T\mathbf{C_i}\mathbf{B} (\mathbf{z} - \mathbf{y}_i) \right) \right)^2`
.. |def-f22-2| replace:: :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f22-01| replace:: :math:`w_i = \begin{cases} 1.1 + 8 \times \dfrac{i-2}{19} & \text{for } 2 \leq i \leq 21\\ 10 & \text{for } i = 1 \end{cases}`
.. |trafo-f22-02| replace:: :math:`\mathbf{B} \text{ is a block-diagonal matrix without}`
.. |trafo-f22-03| replace:: :math:`\text{permuations of the variables.}`
.. |trafo-f22-04| replace:: :math:`\mathbf{C_i} = \Lambda^{\alpha_i}/\alpha_i^{1/4} \text{where } \Lambda^{\alpha_i} \text{ is defined as usual,}`
.. |trafo-f22-05| replace:: :math:`\text{but with randomly permuted diagonal elements.}`
.. |trafo-f22-06| replace:: :math:`\text{For } i=2,\dots, 21, \alpha_i \text{ is drawn uniformly}`
.. |trafo-f22-07| replace:: :math:`\text{from the set } \left\{1000^{2\frac{j}{19}}, j = 0,\dots, 19 \right\} \text{without}`
.. |trafo-f22-08| replace:: :math:`\text{replacement, and } \alpha_i = 1000^2 \text{ for } i = 1.`
.. |trafo-f22-09| replace:: :math:`\text{The local optima } \mathbf{y}_i \text{ are uniformly drawn}`
.. |trafo-f22-10| replace:: :math:`\text{from the domain } [-4.9,4.9]^n \text{ for }`
.. |trafo-f22-11| replace:: :math:`i = 2,...,21 \text{ and } \mathbf{y}_1 \in [-3.92,3.92]^n.`
.. |trafo-f22-12| replace:: :math:`\text{The global optimum is at } \mathbf{x}^{\text{opt}} = \mathbf{y}_1.`
.. |def-f23-1| replace:: :math:`f_{23}(\mathbf{x}) = \left(\dfrac{10}{n^2} \prod_{i=1}^{n} \left( 1 + i \sum_{j=1}^{32} \dfrac{\vert 2^j z_i - [2^j z_i]\vert}{2^j}\right)^{10/n^{1.2}} - \dfrac{10}{n^2}\right)`
.. |def-f23-2| replace:: :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f23-1| replace:: :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{100} \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})`
.. |trafo-f23-2| replace:: :math:`\text{ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`
.. |def-f24-1| replace:: :math:`f_{24}(\mathbf{x}) = \gamma(n)\times\Big(\min\big( \sum_{i=1}^{n} (\hat{x}_i - \mu_0)^2, n + s\sum_{i=1}^{n}(\hat{x}_i - \mu_1)^2\big)`
.. |def-f24-2| replace:: :math:`+ 10 \big(n - \sum_{i=1}^{n}\cos(2\pi z_i) \big)\Big) + 10^{4}f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
.. |trafo-f24-1| replace:: :math:`\mathbf{\hat{x}} = 2 \text{sign}(\mathbf{x}^{\text{opt}}) \otimes \mathbf{x}, \mathbf{x}^{\text{opt}} = 0.5 \mu_0 \mathbf{1}_{-}^{+},`
.. |trafo-f24-2| replace:: :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{100}\mathbf{R}(\mathbf{\hat{x}} - \mu_0\mathbf{1})`
.. |trafo-f24-3| replace:: :math:`\text{ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},`
.. |trafo-f24-4| replace:: :math:`\mu_0 = 2.5, \mu_1 = -\sqrt{\dfrac{\mu_0^{2} - 1}{s}},`
.. |trafo-f24-5| replace:: :math:`s = 1 - \dfrac{1}{2\sqrt{n + 20} - 8.2}`


.. raw:: latex

    \end{sidewaystable}



.. _`Coco framework`: https://github.com/numbbo/coco




.. raw:: html

    <H2>Acknowledgments</H2>

.. raw:: latex

    \section*{Acknowledgments}

This work was supported by the grant ANR-12-MONU-0009 (NumBBO)
of the French National Research Agency.
This work was further supported by a public grant as part of the Investissement d'avenir project, reference ANR-11-LABX-0056-LMH, LabEx LMH, in a joint call with Gaspard Monge Program for optimization, operations research and their interactions with data sciences.




.. ############################# References #########################################
.. raw:: html

    <H2>References</H2>

.. [AIT2016] O. Ait Elhara, A. Auger, N. Hansen (2016). `Permuted Orthogonal Block-Diagonal
    Transformation Matrices for Large Scale Optimization Benchmarking`__. GECCO 2016, Jul 2016, Denver,
    United States.
.. __: https://hal.inria.fr/hal-01308566


.. [HAN2009] N. Hansen, S. Finck, R. Ros, and A. Auger (2009).
   `Real-parameter black-box optimization benchmarking 2009: Noiseless
   functions definitions`__. `Research Report RR-6829`__, Inria, updated
   February 2010.
.. __: http://coco.gforge.inria.fr/
.. __: https://hal.inria.fr/inria-00362633


.. [HAN2016ex] N. Hansen, T. Tusar, A. Auger, D. Brockhoff, O. Mersmann (2016).
  `COCO: The Experimental Procedure`__, *ArXiv e-prints*, `arXiv:1603.08776`__.
.. __: http://numbbo.github.io/coco-doc/experimental-setup/
.. __: http://arxiv.org/abs/1603.08776


.. [HAN2016perf] N. Hansen, A. Auger, D. Brockhoff, D. Tusar, T. Tusar (2016).
    `COCO: Performance Assessment`__. *ArXiv e-prints*, `arXiv:1605.03560`__.
..  __: http://numbbo.github.io/coco-doc/perf-assessment
..  __: http://arxiv.org/abs/1605.03560


.. [HAN2016co] Nikolaus Hansen, Anne Auger, Olaf Mersmann, Tea Tušar, and Dimo Brockhoff (2016).
   `COCO: A Platform for Comparing Continuous Optimizers in a Black-Box
   Setting`__, *ArXiv e-prints*, `arXiv:1603.08785`__.
.. __: http://numbbo.github.io/coco-doc/
.. __: http://arxiv.org/abs/1603.08785
