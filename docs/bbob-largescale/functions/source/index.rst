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
   <A HREF="http://arxiv.org/abs/XXXX.XXXXX">arXiv:XXXX.XXXXX</A>, 2016.

.. raw:: latex

  % \tableofcontents TOC is automatic with sphinx and moved behind abstract by swap...py
  \begin{abstract}

The ``bbob-largescale`` test suite, containing 24 single-objective
functions in continuous domain, is an extension to large dimensions of the well-known
single-objective noiseless ``bbob`` test suite [HAN2009]_. The latter has been used since 2009 in
the `BBOB workshop series`_. The core idea of the extension to larger dimensions is to make the rotational
transformations :math:`\textbf{R}, \textbf{Q}` in the search space that
appear in the ``bbob`` test suite computationally cheaper while retaining some desired
properties. This documentation presents an approach that replaces a full rotational transformation with a combinations of a block-diagonal matrix and two permutation matrices in order to construct test functions whose computational and memory costs scale linearly in the dimension of the problem.

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
    twenty and a hundred, where the number of objectives :math:`m` is fixed.


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
We prescribe a **target value**, |t|, which is an |f|- or
indicator-value [HAN2016perf]_ [BRO2016]_.
For a single run, when an algorithm reaches or surpasses the target value |t|
on problem |p|, we say that it has *solved the problem* |pt| --- it was successful. [#]_

The **runtime** is, then, the evaluation count when the target value |t| was
reached or surpassed for the first time.
That is, the runtime is the number of |f|-evaluations needed to solve the problem
|pt|. [#]_
*Measured runtimes are the only way we assess the performance of an
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
    The alternative is to present final |f|- or indicator-values as results,
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
the COCO framework. It is derived from the existing single-objective, unconstrained ``bbob`` test suite with
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

Then one applies a sequence of transformations: a
rotational transformation :math:`\mathbf{Q}`; then a scaling transformation
:math:`\mathbf{\Lambda}^{10}`; then another rotational transformation :math:`\mathbf{R}`; then
a translation by using the vector :math:`\mathbf{x}^{\text{opt}}` to get the relationship
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
acceptable in the higher dimensions while preserving the main characteristics of the original functions in the ``bbob``
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

.. Dimo: such a matrix will not exist in all dimensions, right? What for example if :math:`n` is prime? We should be more careful in the definition here (e.g. restricting the potential dimensions or allowing :math:`B_{n_b}` to be smaller than :math:`s_ \times s_i`).
.. Wassim: I don’t see how :math:`n` being a prime would be a problem. Up to this point, we only require the sum of the block-sizes to be equal to :math:`n`; later, we will define the values of these block-sizes and then, I agree, we should mention that the last block can be, in theory, smaller (all dimensions larger than 40 are multiples of 40 in our case)

This representation allows the rotational transformation :math:`\textbf{R}` to satisfy three
desired properties:

1. Have linear cost (due to the block structure of :math:`B`) in the problem dimension.
2. Introduce non-separability.
3. Preserve the eigenvalues and therefore the condition number of the original function when it is convex quadratic (since :math:`\textbf{R}` is orthogonal).

.. [#] A *permutation matrix* is a square binary matrix that has exactly one entry at
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
If :math:`r_s \leq (d-1)/2`, the average distance between
the first and the second swap variable ranges from :math:`(\sqrt{2}-1)r_s + 1/2` (in the case of an
asymmetric choice for :math:`j`, i.e. when :math:`i` is chosen closer to :math:`1` or :math:`n` than :math:`r_s`) to
:math:`r_s/2 + 1/2` (in the case of a symmetric choice for :math:`j`). It is maximal when the first swap variable is at least :math:`r_s`
away from both extremes or is one of them.

.. Dimo: What is `d` here? Shouldn't it be `n`? And why is it `(d-1)/2` and not `n/2`?
.. Wassim: yes, it should be `n` and `n-1` is because the variable itself is not included
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
Now, we describe how these changes to the rotational transformations are implemented.
This will be illustrated through an example
on the Ellipsoidal function (rotated) :math:`f_{10}(\mathbf{x})` (see the table in the next section), which is defined by

.. math::
    f_{10}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2  + \mathbf{f}_{\text{opt}}, \text{with } \mathbf{z} = T_{\text{osz}} (\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})), \mathbf{R} = P_{1}BP_{2},

as follows:

(i) First, we the three matrices needed for the transformation,:math:`B, P_1, P_2`, are obtained as follows:

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

- All functions, except for the Schwefel function, are normalized by the parameter :math:`\gamma(n) = \min(1, 40/n)` to have uniform target values that are comparable, in difficulty, over a wide range of dimensions.

- The Discus, Bent Cigar and Sharp Ridge functions are generalized such that they have a constant proportion of distinct axes that remain consistent with the ``bbob`` test suite.

For a better understanding of the properties of these functions and for the definitions
of the used transformations and abbreviations, we refer the reader to the original
``bbob`` `function documention`__ for details.

.. _bbobfunctiondoc: http://coco.lri.fr/downloads/download15.03/bbobdocfunctions.pdf

__ bbobfunctiondoc_

.. list-table::
    :header-rows: 1
    :widths: 3 9 6
    :stub-columns: 0

    *  -
       -  Formulation
       -  Transformations

    *  -  **Group 1: Separable functions**
       -
       -

    *  - Sphere Function
       - :math:`f_1(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} z_i^2 + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{x} - \mathbf{x}^{\text{opt}}`

    *  - Ellipsoidal Function
       - :math:`f_2(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2+ \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = T_{\text{osz}}\left(\mathbf{x} - \mathbf{x}^{\text{opt}}\right)`

    *  - Rastrigin Function
       - :math:`f_3(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||z||^2\right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{\Lambda}^{10} T_{\text{asy}}^{0.2} \left( T_{\text{osz}}\left(\mathbf{x} - \mathbf{x}^{\text{opt}}\right) \right)`

    *  - Bueche-Rastrigin Function
       - :math:`f_4(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||z||^2\right) +` \\ :math:`+ 100f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`z_i = s_i T_{\text{osz}}\left(x_i - x_i^{\text{opt}}\right), \text{for } i = 1,\dots, n`\\ :math:`s_i = \begin{cases} 10 \times 10^{\frac{1}{2} \ \frac{i-1}{n - 1}} & \text{if } z_i >0 \text{ and } i \text{ odd}\\ 10^{\frac{1}{2} \ \frac{i - 1}{n - 1}} & \text{otherwise} \end{cases}` \\ :math:`\text{ \ \ \ \ \ \ for } i = 1,\dots, n`

    *  - Linear Slope
       - :math:`f_5(\mathbf{x}) = \gamma(n)\times \sum_{i=1}^{n}\left( 5 \vert s_i \vert - s_i z_i \right) + \mathbf{f}_{\text{opt}}`
       - :math:`z_i = \begin{cases} x_i & \text{if } x_i^{\mathrm{opt}}x_i < 5^2 \\ x_i^{\mathrm{opt}} & \text{otherwise} \end{cases}` \\ :math:`\text{ \ \ \ \ \ \ for } i=1, \dots, n,` \\ :math:`s_i = \text{sign} \left(x_i^{\text{opt}}\right) 10^{\frac{i-1}{n-1}}, \text{ for } i=1, \dots, n,` \\ :math:`\mathbf{x}^{\text{opt}} = \mathbf{z}^{\text{opt}} = 5\times \mathbf{1}_{-}^+`

    *  -  **Group 2: Functions with low or moderate conditioning**
       -
       -

    *  - Attractive Sector Function
       - :math:`f_6(\mathbf{x}) = T_{\text{osz}}\left(\gamma(n) \times \sum_{i=1}^{n}\left( s_i z_i\right)^2 \right)^{0.9} + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{Q} \mathbf{\Lambda}^{10} \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},` \\ :math:`s_i = \begin{cases} 10^2 & \text{if } z_i \times x_i^{\mathrm{opt}} > 0\\ 1 & \text{otherwise}\end{cases}` \\ :math:`\text{ \ \ \ \ \ \ for } i=1,\dots, n`

    *  - Step Ellipsoidal Function
       - :math:`f_7(\mathbf{x}) = \gamma(n) \times 0.1 \max\left(\vert \hat{z}_1\vert/10^4, \sum_{i=1}^{n}10^{2\frac{i - 1}{n - 1}}z_i^2\right) + f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{\hat{z}} = \mathbf{\Lambda}^{10} \mathbf{R}(\mathbf{x}-\mathbf{x}^{\text{opt}})  \text{ with }\mathbf{R} = P_{11}B_1P_{12},`\\ :math:`\tilde{z}_i= \begin{cases} \lfloor 0.5 + \hat{z}_i \rfloor & \text{if }  |\hat{z}_i| > 0.5 \\ \lfloor 0.5 + 10 \hat{z}_i \rfloor /10 & \text{otherwise} \end{cases}` \\ :math:`\text{ \ \ \ \ \ \ for } i=1,\dots, n,` \\ :math:`\mathbf{z} = \mathbf{Q} \mathbf{\tilde{z}} \text{ with } \mathbf{Q} = P_{21}B_2P_{22}`

    *  - Rosenbrock Function, original
       - :math:`f_8(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \left(100 \left(z_{i}^2 - z_{i+1}\right)^2 + \left(z_{i} - 1\right)^2\right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)(\mathbf{x} - \mathbf{x}^{\text{opt}})+ \mathbf{1},`\\ :math:`\mathbf{z}^{\text{opt}} = \mathbf{1}`

    *  - Rosenbrock Function, rotated
       - :math:`f_9(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \left(100 \left(z_{i}^2 - z_{i+1}\right)^2 + \left(z_{i} - 1\right)^2\right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})+ \mathbf{1}` \\ :math:`\text{ with }\mathbf{R} = P_{1}BP_{2},`\\ :math:`\mathbf{z}^{\text{opt}} = \mathbf{1}`

    *  -  **Group 3: Functions with high conditioning and unimodal**
       -
       -

    *  - Ellipsoidal Function
       - :math:`f_{10}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n}10^{6\frac{i - 1}{n - 1}} z_i^2  + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = T_{\text{osz}} (\mathbf{R} (\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`

    *  - Discus Function
       - :math:`f_{11}(\mathbf{x}) = \gamma(n) \times\left(10^6\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + \sum_{i=\lceil n/40 \rceil+1}^{n}z_i^2\right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = T_{\text{osz}}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`

    *  - Bent Cigar Function
       - :math:`f_{12}(\mathbf{x}) = \gamma(n) \times\left(\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + 10^6\sum_{i=\lceil n/40 \rceil + 1}^{n}z_i^2 \right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{R} T_{\text{asy}}^{0.5}(\mathbf{R}((\mathbf{x} - \mathbf{x}^{\text{opt}})) \text{ with }\mathbf{R} = P_{1}BP_{2}`

    *  - Sharp Ridge Function
       - :math:`f_{13}(\mathbf{x}) = \gamma(n) \times\left(\sum_{i=1}^{\lceil n/40 \rceil}z_i^2 + 100\sqrt{\sum_{i=\lceil n/40 \rceil + 1}^{n}z_i^2} \right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{10}\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`

    *  - Different Powers Function
       - :math:`f_{14}(\mathbf{x}) = \gamma(n) \times\sum_{i=1}^{n} \vert z_i\vert ^{\left(2 + 4 \times \frac{i-1}{n- 1}\right)} + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}) \text{ with }\mathbf{R} = P_{1}BP_{2}`

    *  -  **Group 4: Multi-modal functions with adequate global structure**
       -
       -

    *  - Rastrigin Function
       - :math:`f_{15}(\mathbf{x}) = \gamma(n) \times\left(10n - 10\sum_{i=1}^{n}\cos\left(2\pi z_i \right) + ||\mathbf{z}||^2\right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{R} \mathbf{\Lambda}^{10} \mathbf{Q} T_{\text{asy}}^{0.2} \left(T_{\text{osz}} \left(\mathbf{R}\left(\mathbf{x} - \mathbf{x}^{\text{opt}} \right) \right) \right)` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`

    *  - Weierstrass Function
       - :math:`f_{16}(\mathbf{x}) = 10\left( \dfrac{1}{n} \sum_{i=1}^{n} \sum_{k=0}^{11} \dfrac{1}{2^k} \cos \left( 2\pi 3^k \left( z_i + 1/2\right) \right) - f_0\right)^3 +` \\ :math:`+\dfrac{10}{n}f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{R}\mathbf{\Lambda}^{1/100}\mathbf{Q}T_{\text{osz}}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},`\\ :math:`f_0= \sum_{k=0}^{11} \dfrac{1}{2^k} \cos(\pi 3^k)`

    *  - Schaffers F7 Function
       - :math:`f_{17}(\mathbf{x}) = \left(\dfrac{1}{n-1} \sum_{i=1}^{n-1} \left(\sqrt{s_i} + \sqrt{s_i}\sin^2\left( 50 (s_i)^{1/5}\right)\right)\right)^2 +` \\ :math:`+ 10 f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{\Lambda}^{10} \mathbf{Q} T_{\text{asy}}^{0.5}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},` \\ :math:`s_i= \sqrt{z_i^2 + z_{i+1}^2}, i=1,\dots, n-1`

    *  - Schaffers F7 Function, moderately ill-conditioned
       - :math:`f_{18}(\mathbf{x}) = \left(\dfrac{1}{n-1} \sum_{i=1}^{n-1} \left(\sqrt{s_i} + \sqrt{s_i}\sin^2\left( 50 (s_i)^{1/5}\right)\right)\right)^2 +` \\ :math:`+ 10 f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{\Lambda}^{1000} \mathbf{Q} T_{\text{asy}}^{0.5}(\mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}}))` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},`\\ :math:`s_i= \sqrt{z_i^2 + z_{i+1}^2}, i=1,\dots, n-1`

    *  - Composite Griewank-Rosenbrock Function F8F2
       - :math:`f_{19}(\mathbf{x}) = \gamma(n)\times\left(\dfrac{10}{n-1} \sum_{i=1}^{n-1} \left( \dfrac{s_i}{4000} - \cos\left(s_i \right)\right) + 10 \right) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \max\left(1, \dfrac{\sqrt{s}}{8}\right)\mathbf{R} \mathbf{x} + \dfrac{\mathbf{1}}{2}` \\ :math:`\text{ \ \ \ \ \ \ with }\mathbf{R} = P_{1}BP_{2},` \\ :math:`s_i= 100(z_i^2 - z_{i+1})^2 + (z_i - 1)^2,` \\ :math:`\text{ \ \ \ \ \ \ for } i=1,\dots, n-1,` \\ :math:`\mathbf{z}^{\text{opt}} = \mathbf{1}`

    *  -  **Group 5: Multi-modal functions with weak global structure**
       -
       -

    *  - Schwefel Function
       - :math:`f_{20}(\mathbf{x}) = -\dfrac{1}{n} \sum_{i=1}^{n} z_i\sin\left(\sqrt{\vert z_i\vert}\right) + 4.189828872724339 +` \\ :math:`+ 100f_{pen}(\mathbf{z}/100)+\mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{\hat{x}} = 2 \times \mathbf{1}_{-}^{+} \otimes \mathbf{x},` \\ :math:`\hat{z}_1 = \hat{x}_1, \hat{z}_{i+1}=\hat{x}_{i+1} + 0.25 \left(\hat{x}_{i} - 2\left|x_i^{\text{opt}}\right|\right),` \\ :math:`\text{ \ \ \ \ \ \ for } i=1, \dots, n-1,` \\ :math:`\mathbf{z} = 100 \left(\mathbf{\Lambda}^{10} \left(\mathbf{\hat{z}} - 2\left|\mathbf{x}^{\text{opt}}\right|\right) + 2\left|\mathbf{x}^{\text{opt}}\right|\right),` \\ :math:`\mathbf{x}^{\text{opt}} = 4.2096874633/2 \mathbf{1}_{-}^{+}`

    *  - Gallagher's Gaussian 101-me Peaks Function
       - :math:`f_{21}(\mathbf{x}) = T_{\text{osz}}\left(10 - \max_{i=1}^{101} w_i \exp\left(- \dfrac{1}{2n} (\mathbf{z} - \mathbf{y}_i)^T\mathbf{B}^T\mathbf{C_i}\mathbf{B} (\mathbf{z} - \mathbf{y}_i) \right) \right)^2 +` \\ :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`w_i = \begin{cases} 1.1 + 8 \times \dfrac{i-2}{99} & \text{for } 2 \leq i \leq 101\\ 10 & \text{for } i = 1 \end{cases}`\\ :math:`\mathbf{B} \text{ is a block-diagonal matrix without}` \\ :math:`\text{permuations of the variables.}`\\ :math:`\mathbf{C_i} = \Lambda^{\alpha_i}/\alpha_i^{1/4} \text{where } \Lambda^{\alpha_i} \text{ is defined as usual,}` \\ :math:`\text{but with randomly permuted diagonal elements.}` \\ :math:`\text{For } i=1,\dots, 101, \alpha_i \text{ is drawn uniformly}` \\ :math:`\text{from the set } \left\{1000^{2\frac{j}{99}}, j = 0,\dots, 99 \right\} \text{without}` \\ :math:`\text{replacement, and } \alpha_i = 1000 \text{ for } i = 1.` \\ :math:`\text{The local optima } \mathbf{y}_i \text{ are uniformly drawn}` \\ :math:`\text{from the domain } [-5,5]^n \text{ for }` \\ :math:`i = 2,...,101 \text{ and } \mathbf{y}_1 \in [-4,4]^n.` \\ :math:`\text{The global optimum is at } \mathbf{x}^{\text{opt}} = \mathbf{y}_1.`

    *  - Gallagher's Gaussian 21-hi Peaks Function
       - :math:`f_{22}(\mathbf{x}) = T_{\text{osz}}\left(10 - \max_{i=1}^{21} w_i \exp\left(- \dfrac{1}{2n} (\mathbf{z} - \mathbf{y}_i)^T \mathbf{B}^T\mathbf{C_i}\mathbf{B} (\mathbf{z} - \mathbf{y}_i) \right) \right)^2 +` \\ :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`w_i = \begin{cases} 1.1 + 8 \times \dfrac{i-2}{19} & \text{for } 2 \leq i \leq 21\\ 10 & \text{for } i = 1 \end{cases}` \\ :math:`\mathbf{B} \text{ is a block-diagonal matrix without}` \\ :math:`\text{permuations of the variables.}`\\ :math:`\mathbf{C_i} = \Lambda^{\alpha_i}/\alpha_i^{1/4} \text{where } \Lambda^{\alpha_i} \text{ is defined as usual,}` \\ :math:`\text{but with randomly permuted diagonal elements.}` \\ :math:`\text{For } i=1,\dots, 21, \alpha_i \text{ is drawn uniformly}` \\ :math:`\text{from the set } \left\{1000^{2\frac{j}{19}}, j = 0,\dots, 19 \right\} \text{without}` \\ :math:`\text{replacement, and } \alpha_i = 1000^2 \text{ for } i = 1.` \\ :math:`\text{The local optima } \mathbf{y}_i \text{ are uniformly drawn}` \\ :math:`\text{from the domain } [-4.9,4.9]^n \text{ for }` \\ :math:`i = 2,...,21 \text{ and } \mathbf{y}_1 \in [-3.92,3.92]^n.`  \\ :math:`\text{The global optimum is at } \mathbf{x}^{\text{opt}} = \mathbf{y}_1.`

    *  - Katsuura Function
       - :math:`f_{23}(\mathbf{x}) = \left(\dfrac{10}{n^2} \prod_{i=1}^{n} \left( 1 + i \sum_{j=1}^{32} \dfrac{\vert 2^j z_i - [2^j z_i]\vert}{2^j}\right)^{10/n^{1.2}} - \dfrac{10}{n^2}\right) +` \\ :math:`+ f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{100} \mathbf{R}(\mathbf{x} - \mathbf{x}^{\text{opt}})`\\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22}`


    *  - Lunacek bi-Rastrigin Function
       - :math:`f_{24}(\mathbf{x}) = \gamma(n)\times\Big(\min\big( \sum_{i=1}^{n} (\hat{x}_i - \mu_0)^2, n + s\sum_{i=1}^{n}(\hat{x}_i - \mu_1)^2\big) +` \\ :math:`+ 10 \big(n - \sum_{i=1}^{n}\cos(2\pi z_i) \big)\Big) + 10^{4}f_{pen}(\mathbf{x}) + \mathbf{f}_{\text{opt}}`
       - :math:`\mathbf{\hat{x}} = 2 \text{sign}(\mathbf{x}^{\text{opt}}) \otimes \mathbf{x}, \mathbf{x}^{\text{opt}} = 0.5 \mu_0 \mathbf{1}_{-}^{+}` \\ :math:`\mathbf{z} = \mathbf{Q}\mathbf{\Lambda}^{100}\mathbf{R}(\mathbf{\hat{x}} - \mu_0\mathbf{1})` \\ :math:`\text{ \ \ \ \ \ \ with } \mathbf{R} = P_{11}B_1P_{12}, \mathbf{Q} = P_{21}B_2P_{22},`\\ :math:`\mu_0 = 2.5, \mu_1 = -\sqrt{\dfrac{\mu_0^{2} - 1}{s}},` \\ :math:`s = 1 - \dfrac{1}{2\sqrt{n + 20} - 8.2}`


.. _`Coco framework`: https://github.com/numbbo/coco





.. raw:: html

    <H2>Acknowledgments</H2>

.. raw:: latex

    \section*{Acknowledgments}

This work was supported by the grant ANR-12-MONU-0009 (NumBBO)
of the French National Research Agency.




.. ############################# References #########################################
.. raw:: html

    <H2>References</H2>

.. [AIT2016] O. Ait Elhara, A. Auger, N. Hansen (2016). `Permuted Orthogonal Block-Diagonal
    Transformation Matrices for Large Scale Optimization Benchmarking`__. GECCO 2016, Jul 2016, Denver,
    United States.
.. __: https://hal.inria.fr/hal-01308566

.. [BRO2016] D. Brockhoff, T. Tusar, D. Tusar, T. Wagner, N. Hansen, A. Auger, (2016).
    `Biobjective Performance Assessment with the COCO Platform`__. *ArXiv e-prints*, `arXiv:1605.01746`__.
..  __: http://numbbo.github.io/coco-doc/bbob-biobj/perf-assessment
..  __: http://arxiv.org/abs/1605.01746


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
