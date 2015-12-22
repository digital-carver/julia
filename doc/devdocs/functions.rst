.. _devdocs-functions:

*******************
Julia Functions
*******************

.. currentmodule:: Base

This document will explain how functions, method definitions, and method tables work.

Method Tables
-------------

Every function in Julia is a generic function. A generic function is conceptually a single
function, but consists of many definitions, or methods. The methods of a generic
function are stored in a method table.
Method tables (type ``MethodTable``) are associated with ``TypeName``\s. A ``TypeName``
describes a family of parameterized types. For example ``Complex{Float32}`` and
``Complex{Float64}`` share the same ``Complex`` type name object.

All objects in Julia are potentially callable, because every object has a type, which
in turn has a ``TypeName``.


Function calls
--------------

Given the call ``f(x,y)``, the following steps are performed: first, the method table
to use is accessed as ``typeof(f).name.mt``. Second, an argument tuple type is formed,
``Tuple{typeof(f), typeof(x), typeof(y)}``. Note that the type of the function itself
is the first element. This is because the type might have parameters, and so needs to
take part in dispatch. This tuple type is looked up in the method table.

This dispatch process is performed by ``jl_apply_generic``, which takes two arguments:
a pointer to an array of the values f, x, and y, and the number of values (in this
case 3).

Throughout the system, there are two kinds of APIs that handle functions and argument
lists: those that accept the function and arguments separately, and those that accept
a single argument structure. In the first kind of API, the "arguments" part does *not*
contain information about the function, since that is passed separately. In the
second kind of API, the function is the first element of the argument structure.

For example, the following function for looking up a specialization accepts a single
tuple type, so the first element of the tuple type will be the type of the function::

    jl_lambda_info_t *jl_get_specialization1(jl_tupletype_t *types, void *cyclectx);

This entry point for the same functionality accepts the function separately, so the
``types`` tuple does not contain the type of the function::

    jl_lambda_info_t *jl_get_specialization(jl_function_t *f, jl_tupletype_t *types, void *cyclectx);


Adding methods
--------------

Given the above dispatch process, conceptually all that is needed to add a new
method is (1) a tuple type, and (2) code for the body of the method.
``jl_method_def`` implements this operation.
``jl_first_argument_datatype`` is called to extract the relevant method table
from what would be the type of the first argument. This is much more complicated
than the corresponding procedure during dispatch, since the argument tuple
type might be abstract. For example, we can define::

    (::Union{Foo{Int},Foo{Int8}})(x) = 0

which works since all possible matching methods would belong to the same method
table.


Creating generic functions
--------------------------

Since every object is callable, nothing special is needed to create a generic
function. Therefore ``jl_new_generic_function`` simply creates a new singleton
(0 size) subtype of ``Function`` and returns its instance.
A function can have a mnemonic "display name" which is used in debug info and
when printing objects. For example the name of ``Base.sin`` is ``sin``. By
convention, the name of the created *type* is the same as the function name,
with a ``#`` prepended. So ``typeof(sin)`` is ``Base.#sin``.


Closures
--------

A closure is simply a callable object with field names corresponding to
captured variables. For example, the following code::

    function adder(x)
        return y->x+y
    end

is lowered to (roughly)::

    immutable ##1{T}
        x::T
    end

    (_::##1)(y) = _.x + y

    function adder(x)
        return ##1(x)
    end


Constructors
------------

A constructor call is just a call to a type. The type of most types is ``DataType``,
so the method table for ``DataType`` contains most constructor definitions.
One wrinkle is the fallback definition that makes all types callable via ``convert``::

    (::Type{T}){T}(args...) = convert(T, args...)::T

In this definition the function type is abstract, which is not normally supported.
To make this work, all subtypes of ``Type`` (``Type``, ``TypeConstructor``, ``Union``, and
``DataType``) currently share a method table via special arrangement.


Builtins
--------

The "builtin" functions, defined in the ``Core`` module, are::

    is typeof sizeof issubtype isa typeassert throw tuple getfield setfield! fieldtype
    nfields isdefined arrayref arrayset arraysize applicable invoke apply_type _apply
    _expr svec

These are all singleton objects whose types are subtypes of ``Builtin``, which is
a subtype of ``Function``. Their purpose is to expose entry points in the run time
that use the "jlcall" calling convention::

    jl_value_t *(jl_value_t*, jl_value_t**, uint32_t)

The method tables of builtins are empty. Instead, they have a single catch-all method
cache entry (``Tuple{Vararg{Any}}``) whose jlcall fptr points to the correct function.
This is kind of a hack but works reasonably well.


Keyword arguments
-----------------

Keyword arguments work by associating a special, hidden function object with each
method table that has definitions with keyword arguments.
This function is called the "keyword argument sorter" or "keyword sorter", or
"kwsorter", and is stored in the ``kwsorter`` field of ``MethodTable`` objects.
Every definition in the kwsorter function has the same arguments as some definition
in the normal method table, except with a single ``Array`` argument prepended.
This array contains alternating symbols and values that represent the passed
keyword arguments.
The kwsorter's job is to move keyword arguments into their canonical positions based
on name, plus evaluate and substite any needed default value expressions.
The result is a normal positional argument list, which is then passed to yet another
function.

The easiest way to understand the process is to look at how a keyword argument
method definition is lowered.
The code::

    function circle(center, radius; color = black, fill::Bool = true, options...)
        # draw
    end

actually produces *three* method definitions.
The first is a function that accepts all arguments (including keywords) as
positional arguments, and includes the code for the method body.
It has an auto-generated name::

    function #circle#1(color, fill::Bool, options, circle, center, radius)
        # draw
    end

The second method is an ordinary definition for the original ``circle`` function,
which handles the case where no keyword arguments are passed::

    function circle(center, radius)
        #circle#1(black, true, Any[], center, radius)
    end

This simply dispatches to the first method, passing along default values.
Finally there is the kwsorter definition::

    function (::Core.kwftype(typeof(circle)))(kw::Array, circle, center, radius)
        options = Any[]
        color = arg associated with :color, or black if not found
        fill = arg associated with :fill, or true if not found
        # push remaining elements of kw into options array
        #circle#1(color, fill, options, circle, center, radius)
    end

The front end generates code to loop over the ``kw`` array and pick out
arguments in the right order, evaluating default expressions when
an argument is not found.

The function ``Core.kwftype(t)`` fetches (and creates, if necessary) the
field ``t.name.mt.kwsorter``.

This design has the feature that call sites that don't use keyword arguments
require no special handling; everything works as if they were not part of
the language at all.
Call sites that do use keyword arguments are dispatched directly to the
called function's kwsorter.
For example the call::

    circle((0,0), 1.0, color = red; other...)

is lowered to::

    kwfunc(circle)(Any[:color,red,other...], circle, (0,0), 1.0)

The unpacking procedure represented here as ``other...`` actually
further unpacks each *element* of ``other``, expecting each one to
contain two values (a symbol and a value).
``kwfunc`` (also in ``Core``) fetches the kwsorter for the called function.
Notice that the original ``circle`` function is passed through, to
handle closures.
