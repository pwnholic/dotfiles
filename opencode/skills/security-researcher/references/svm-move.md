# SVM and Move Runtime Branches

Load only for Solana/SVM programs or Move/object-capability systems. Do not
translate EVM identities, storage, or reentrancy rules mechanically.

## Solana/SVM identity and authority

For every instruction bind:

```text
program id and executable identity
ordered account list
owner / signer / writable flags
PDA seeds, bump, domain separators, invoke_signed authority
deserialized type/discriminator and account length
sysvar and external-program identity
lamports/token value movement
CPI target and propagated privileges
```

Caller-supplied accounts are inputs, not trusted identities. Verify owner,
program ID, seeds, relationships between accounts, mint/authority, and
canonical derivations before use. Search duplicate aliasing, type confusion,
arbitrary program substitution, missing signer/owner checks, PDA seed
collisions, confused deputies, stale authority, close/reinitialize, realloc,
and partial state across CPI failure.

## CPI and token semantics

CPI cannot grant privileges absent from the caller, but signer privileges may
be added for correctly derived PDAs. Trace nested CPI and `invoke_signed`
seeds, reentrancy/call-depth rules, compute budget, writable conflicts, and
which program owns each modified account.

Bind whether Token or Token-2022 is used and which extensions are active,
including transfer hooks, transfer fees, confidential/frozen/default account
state, interest-bearing semantics, and permanent delegate. Interface similarity
does not imply identical value-flow behavior.

## Deployment and runtime state

Record cluster, runtime feature set, loader generation, program ID,
ProgramData, deployed/effective slot, executable hash, upgrade authority,
compute/call limits, and source/build provenance. New or upgraded programs may
have a one-slot visibility boundary; do not treat deployment submission time
as universal execution visibility.

After an upgrade, rebind executable identity, authority, IDL/client artifacts,
and all evidence affected by the new slot. Immutability is an observed
authority state, not a project claim.

## Move and object-capability systems

Model authority through resources, capabilities, object ownership, module
visibility, signer/reference types, abilities, and package upgrade policy.
Track:

- who owns or can borrow/move a resource;
- capability creation, transfer, storage, destruction, and revocation;
- shared/owned object transitions and versioning;
- type identity across packages/modules;
- upgrade compatibility and old object state;
- serialization and bridge/adapter boundaries;
- compiler target and runtime feature semantics.

Language-level linearity or capability safety does not automatically survive a
heterogeneous compilation target. Treat Move-to-EVM or other translations as a
compiler/runtime dependency and validate preservation of authorization,
resource uniqueness, abort/revert behavior, storage, and call identity.

## Validation branch

Use target-native transactions/instructions and state inspection. A harness
that changes account ownership, signer flags, PDA authority, object ownership,
or package capabilities has used synthetic power; disclose it and prove an
attacker-reachable equivalent before claiming exploitability.

## Current semantic sources

- Solana programs and deployment: https://solana.com/docs/core/programs
- Solana CPI: https://solana.com/docs/core/cpi
- Solana verified builds: https://solana.com/docs/programs/verified-builds
- Move-to-EVM security preservation: https://www.usenix.org/conference/usenixsecurity25/presentation/benetollo
