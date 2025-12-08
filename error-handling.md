---
title: Error Handling
author: Esben Inglev
theme: gaia
date: Jan 2026
paginate: true
style: |
  section {
    font-size: 24px;
  }
---

# Error Handling

---

### Error Handling

**Why Error Handling Matters**

- Programs fail: invalid input, missing data, network issues
- Imperative approach: try-catch, null checks, error codes
- Functional approach: **make errors explicit in types**

**The Goal**

- Errors as values, not exceptions
- Clear function signatures that show success AND failure
- Compose functions naturally, even when they can fail

---

### Our Simple Example: User Registration

**The Task**

Register a user with these steps:

1. Validate email format
2. Check email isn't already taken
3. Hash the password
4. Save to database

Each step can fail. How do we handle it elegantly?

---

### The Naive Approach: Exceptions

```fsharp
let validateEmail email =
    if email.Contains("@") then email
    else failwith "Invalid email"

let checkNotTaken email =
    if email = "taken@test.com" then
        failwith "Email already exists"
    else email

let hashPassword password =
    if String.length password < 6 then
      failwith "Password too short"
    password + "_hashed"

let saveUser email password =
    // save user to db
    "Success"
```

---

### The Problem with Exceptions

```fsharp
let registerUser email password =
    try
        let validEmail = validateEmail email
        let availableEmail = checkNotTaken validEmail
        let hashedPw = hashPassword password
        saveUser availableEmail hashedPw
    with
    | ex -> "Error: " + ex.Message
```

**Issues:**

- Errors hidden in function signatures
- Can't see what might fail by reading types
- Hard to handle different error cases differently

---

### The Solution: The Result Type

```fsharp
type Result<'Success, 'Failure> =
    | Ok of 'Success
    | Error of 'Failure
```

**Two tracks:**

- **Success track**: `Ok` contains the value
- **Failure track**: `Error` contains the error

Flow is always forward moving.
Functions return `Result` instead of throwing exceptions.

---

### Rewriting with Result

```fsharp
let validateEmail email =
    if email.Contains("@") then Ok email
    else Error "Invalid email format"

let checkNotTaken email =
    if email = "taken@test.com" then Error "Email already exists"
    else Ok email

let hashPassword password =
    if String.length password < 6 then Error "Password too short"
    else Ok (password + "_hashed")

let saveUser email password =
    // save user to db
    Ok (sprintf "Saved user: %s" email)
```

---

### The Composition Problem

```fsharp
let registerUser email password =
    let result1 = validateEmail email
    match result1 with
    | Error e -> Error e
    | Ok validEmail ->
        let result2 = checkNotTaken validEmail
        match result2 with
        | Error e -> Error e
        | Ok availableEmail ->
            let result3 = hashPassword password
            match result3 with
            | Error e -> Error e
            | Ok hashedPw ->
                saveUser availableEmail hashedPw
```

**This is tedious!** We need a better way to chain these functions.

---

### The Bind Function: Switching Tracks

```fsharp
let bind nextFunction result =
    match result with
    | Ok value -> nextFunction value
    | Error e -> Error e
```

**What bind does:**

- If `Ok`: apply the next function (stay on success track)
- If `Error`: skip the function (stay on error track)

Bind lets us **compose functions that return Result**.

---

### Clean Composition with Bind

```fsharp
let (>>=) result nextFunction =
    bind nextFunction result

let registerUser email password =
    validateEmail email
    >>= checkNotTaken
    >>= (fun validEmail ->
            hashPassword password
            >>= (fun hashedPw ->
                    saveUser validEmail hashedPw))
```

Or with better formatting:

```fsharp
let registerUser email password =
    validateEmail email
    >>= checkNotTaken
    >>= fun email -> saveUser email (password + "_hashed")
```

---

### Railway-Oriented Programming

**The Mental Model**

```
Input ──> [validateEmail] ──> [checkNotTaken] ──> [save] ──> Output
          Success ↓ Error ↓    Success ↓ Error ↓   Success ↓ Error ↓
                   ↓           ↓                    ↓
                   └──────────>└───────────────────> Error Output
```

- Functions on the success track
- Any error switches to error track
- Once on error track, stay there
- Both tracks lead to final result

---

### Result is a Monad

**What makes Result a monad?**

1. **Return**: Put a value in the monad

   ```fsharp
   let return' x = Ok x
   ```

2. **Bind**: Chain operations

   ```fsharp
   let bind f m = match m with
                  | Ok x -> f x
                  | Error e -> Error e
   ```

3. **Monad Laws**: Ensures composition works predictably

---

### Why Monads Matter Here

**Benefits of the monadic structure:**

- **Automatic error propagation**: No manual checking needed
- **Composability**: Chain operations with `>>=`
- **Type safety**: Compiler forces you to handle both tracks
- **Clear intent**: Function signature shows it can fail
- **Separation of concerns**: Business logic separate from error handling

The monad handles the "plumbing" of passing success/failure through the chain.

---
