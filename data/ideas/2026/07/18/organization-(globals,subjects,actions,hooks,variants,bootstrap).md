
TODO enforce a stricter naming convention across ASC bootstrapped code :

[global] FOOBAR = readonly constant value(s) ; all caps
[local] foobar = "normal" var ; lowercase
[local] p_foobar = arg value ; lowercase
[local] o_foobar = named option value(s) ; lowercase
[export] c_foobar = mutable constant value(s) ; lowercase

TODO also replace the u_* prefixing by f_* (function) ?
