Your replies to the user are as concise as possible, containing all the necessary
information and no unnecessary fluff. They are to-the-point.

Before adding new piece of code:

1. Think if it's a necessary addition
2. Look for parts of the project where this code is already implemented
3. If a function/method/class similar to what you need is already present - use it 
4. If it isn't, but there are other parts that require the same logic - abstract them to a function/class/module
5. If this doesn't exist anywhere, make it in a way where it's readable, reusable (if helpful) and is where needed

Don't place utility functions in the same file where they're being used, look for a module for utils.
When trying to make the functions size smaller, go throught the following three steps:

### Inversion
Avoid `else` statements. It's better to make a simple `if` statement
that accounts for the `else` case before the actual check. this makes the code less nested

Example:
```rust
// Bad practice
fn process(user: Option<&User>) -> &'static str {
    if let Some(user) = user {
        if user.is_active {
            if user.has_permission {
                do_thing(user)
            } else {
                "no permission"
            }
        } else {
            "inactive"
        }
    } else {
        "no user"
    }
}
```
```rust
// Better code:
fn process(user: Option<&User>) -> &'static str {
    let Some(user) = user else {
        return "no user";
    };
    if !user.is_active {
        return "inactive";
    }
    if !user.has_permission {
        return "no permission";
    }
    do_thing(user)
}
```

### Extraction
If the same (or similar) logic is clearly present in more than one place in the project, 
extract it into a new function/method, or even a class. This extraction must make logical sense,
it doesn't have to be forced. Meaning there's no need to make abstractions that have many purposes.

### Naming
Use names that clearly indicate what the variable is used for.

## Comments

Write a comment only when the code will surprise a competent reader. Before
writing one, ask: if I delete this, what does the next person get wrong?
If the answer is "nothing", delete it.
Comments describe the code as it is, never how it got there. The diff, the old
value, the bug you just fixed, and the approach you tried first belong in the
commit message that I will write myself. A reader six months from now has no memory of your change, so
"rather than X", "now", "still", and "was" are usually smuggling a diff into
the source.

- Bad:  // Quiet rather than hidden — it used to appear only on hover

