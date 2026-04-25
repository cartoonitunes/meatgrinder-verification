# Meat Grinders Association — Verified Source

Verified source code for the **Unicorn Meat Grinder Association** contract deployed by [avsa](https://github.com/alexvandesande) (Alex Van de Sande) on Ethereum mainnet.

## Contract

| Field | Value |
|---|---|
| Address | [0xc7e9dDd5358e08417b1C88ed6f1a73149BEeaa32](https://etherscan.io/address/0xc7e9dDd5358e08417b1C88ed6f1a73149BEeaa32) |
| Block | 1,211,176 (March 24, 2016) |
| Deployer | 0x281055afc982d96fab65b3a49cac8b878184cb16 |
| Bytecode size | 4,640 bytes (runtime) |

## Compiler

| Field | Value |
|---|---|
| Compiler | Solidity 0.2.1 (Emscripten/soljson JS build) |
| Commit | `91a6b35f` |
| Full version string | `0.2.1-91a6b35f/.-Emscripten/clang/int linked to libethereum-` |
| Optimizer | ON |
| Match type | Exact bytecode match |

## Source

Original gist by avsa: https://gist.github.com/alexvandesande/3abc9f741471e08a6356

### Key differences from gist

- `owned` contract does **not** contain `transferOwnership` — it is defined only in `MeatGrindersAssociation`
- Function order in `MeatGrindersAssociation`: constructor → changeVotingRules → changeMeatProvider → newProposal → **checkProposalCode** → vote → transferOwnership → executeProposal → receiveApproval → grindUnicorns → sqrt

These ordering differences affect how the Solidity 0.2.1 optimizer lays out function bodies and subroutines in the bytecode.

## Verification

```bash
# Compile with exact match
node -e "
const solc = require('/tmp/soljson/node_modules/solc');
const soljson = require('/tmp/soljson/soljson-v0.2.1+commit.91a6b35f.js');
const compiler = solc.setupMethods(soljson);
const fs = require('fs');
const source = fs.readFileSync('MeatGrindersAssociation.sol', 'utf8');
const result = compiler.compile(source, 1);
const runtime = result.contracts['MeatGrindersAssociation'].runtimeBytecode;
console.log('Runtime bytes:', runtime.length / 2);
// Compare against on-chain: cast code 0xc7e9dDd5358e08417b1C88ed6f1a73149BEeaa32 --rpc-url mainnet
"
```

## Attribution

Verified by [EthereumHistory](https://ethereumhistory.com) — preserving Ethereum's early history.
