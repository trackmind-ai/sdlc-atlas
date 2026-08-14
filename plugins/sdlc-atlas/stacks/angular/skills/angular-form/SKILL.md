---
name: angular-form
description: Angular Reactive Forms implementation checklist.
when_to_use: Activate whenever building typed Angular forms, validators, or dynamic FormArrays on the Angular stack.
disable-model-invocation: false
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
effort: medium
context: fork
---

1. `FormGroup<{ field: FormControl<Type> }>` — always typed. `{ nonNullable: true }` for required fields.
2. `FormBuilder.nonNullable.group({...})` shorthand for all-required forms.
3. Built-in validators: `Validators.required`, `Validators.email`, `Validators.min(N)`, `Validators.pattern(regex)`.
4. Custom validator: `function noWhitespace(control: AbstractControl): ValidationErrors | null { return /\s/.test(control.value) ? { whitespace: true } : null; }`.
5. Cross-field validator: pass to `FormGroup` as second arg: `new FormGroup({...}, { validators: [passwordMatchValidator] })`. Return `{ mismatch: true }` on group errors.
6. `FormArray`: `new FormArray<FormControl<string>>([])`. Push: `array.push(new FormControl<string>('', { nonNullable: true }))`.
7. Submit button: `[disabled]="form.invalid || form.pending || submitting()"` — never allow invalid submit.
8. Show validation errors: only when `control.invalid && (control.dirty || control.touched)`.
9. Server errors: `form.get('email')?.setErrors({ serverError: 'Email already taken' })`. Clear on next edit.
10. `form.getRawValue()` for submission — includes disabled controls. Never `form.value` for submit payload.
11. `form.reset(initialValues)` after successful submit — restore initial values.
12. Async validator: `asyncValidators: [uniqueEmailValidator]` where validator returns `Observable<ValidationErrors | null>`.
13. `form.statusChanges.pipe(takeUntilDestroyed(this.destroyRef))` to react to validity changes.
14. Disable controls: `form.get('field')?.disable()` — never `[disabled]="condition"` on input (ignores form state).
15. Tests: set values with `form.setValue({...})`, trigger `form.updateValueAndValidity()`, assert `form.valid`, `form.errors`, control errors.
