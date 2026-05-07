#!/bin/bash
# Reproducible byte-for-byte verification for MeatGrindersAssociation
# Compares compiled output of MeatGrindersAssociation.sol (soljson v0.2.1+commit.91a6b35f, optimizer ON)
# against on-chain runtime + creation bytecode for 0xc7e9dDd5358e08417b1C88ed6f1a73149BEeaa32.

set -e

ADDRESS="0xc7e9dDd5358e08417b1C88ed6f1a73149BEeaa32"
SOLJSON="${SOLJSON:-/tmp/soljson/soljson-v0.2.1+commit.91a6b35f.js}"
SOLC_WRAPPER="${SOLC_WRAPPER:-/tmp/soljson/node_modules/solc}"
CREATION_TX="0xe9653360212cb38996a13def35272cb05b3e06f4344c1673514973c92367f054"
RPC="${RPC:-https://ethereum-rpc.publicnode.com}"

if [ ! -f "$SOLJSON" ]; then
  echo "soljson not found at $SOLJSON. Set SOLJSON env var or run setup-soljson.sh." >&2
  exit 1
fi
if [ ! -d "$SOLC_WRAPPER" ]; then
  echo "solc wrapper not found at $SOLC_WRAPPER. Run: cd /tmp/soljson && npm install solc@0.4.26" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap "rm -rf $WORK" EXIT

# Fetch on-chain runtime
curl -s -X POST "$RPC" -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDRESS\",\"latest\"],\"id\":1}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result'][2:])" > "$WORK/onchain_runtime.hex"

# Fetch on-chain creation calldata
curl -s -X POST "$RPC" -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionByHash\",\"params\":[\"$CREATION_TX\"],\"id\":1}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['input'][2:])" > "$WORK/onchain_creation.hex"

# Compile
node -e "
const fs = require('fs');
const solcWrapper = require('$SOLC_WRAPPER');
const soljson = require('$SOLJSON');
const compiler = solcWrapper.setupMethods(soljson);
const src = fs.readFileSync('MeatGrindersAssociation.sol', 'utf8');
const r = compiler.compile(src, 1);  // 1 = optimizer ON
const c = r.contracts['MeatGrindersAssociation'];
fs.writeFileSync('$WORK/compiled_runtime.hex', c.runtimeBytecode);
fs.writeFileSync('$WORK/compiled_creation.hex', c.bytecode);
"

RUNTIME_OK=0
CREATION_OK=0
if [ "$(cat $WORK/compiled_runtime.hex)" = "$(cat $WORK/onchain_runtime.hex)" ]; then
  echo "EXACT runtime match  (4640 bytes)"
  RUNTIME_OK=1
else
  echo "Runtime MISMATCH"
fi

# Creation = init code + runtime + constructor args (192 bytes for 6 args).
# Compiled bytecode == on-chain creation prefix (without ctor args).
COMPILED_CREATION="$(cat $WORK/compiled_creation.hex)"
ONCHAIN_CREATION="$(cat $WORK/onchain_creation.hex)"
PREFIX="${ONCHAIN_CREATION:0:${#COMPILED_CREATION}}"
if [ "$PREFIX" = "$COMPILED_CREATION" ]; then
  echo "EXACT creation match (5040 bytes init+runtime, +192 bytes constructor args)"
  CREATION_OK=1
else
  echo "Creation prefix MISMATCH"
fi

if [ $RUNTIME_OK = 1 ] && [ $CREATION_OK = 1 ]; then
  echo
  echo "EXACT MATCH  soljson v0.2.1+commit.91a6b35f, optimizer ON"
  exit 0
fi
exit 1
