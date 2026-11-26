# Notes

**Why it is correct.** Decorators compile to ARM minLength/maxLength/allowedValues on the parameters object. `accountName` has a default (`stlagbstu001`) so PSRule can expand the template offline.

**Numbers / SKUs.** Name 3–24; SKU allow-list Standard_LRS and Standard_GRS.

**Alternatives.** A user-defined type for the SKU would also work; the tests look at allowedValues.

**The usual mistake.** Constraining the resource property instead of the parameter. The test reads `parameters`.
