## Summary

What does this PR change?

## Why

What problem does it solve?

## Scope

- [ ] Native engine
- [ ] Docker development
- [ ] Docker production
- [ ] Shared lifecycle / engine contract
- [ ] Security
- [ ] CI / release
- [ ] Documentation only

## Validation performed

Describe the exact commands and environments used.

```text
./scripts/validate-release.sh
# plus any native/Docker checks you ran
```

OS:
Engine (native / Docker development / Docker production):

## Compatibility

Does this change affect:

- supported OS versions?
- deployment engines?
- existing installations?
- backup or restore formats?
- CLI behavior?

## Security impact

Does this change touch:

- root execution?
- secrets or credentials?
- network exposure?
- release integrity / signing?
- update logic?

## Checklist

- [ ] `./scripts/validate-release.sh` passes (canonical local gate)
- [ ] New behavior has tests or a clear manual validation note
- [ ] Documentation is updated where needed
- [ ] No credentials or private data are included
- [ ] Existing behavior remains backward compatible, or the breaking change is documented
