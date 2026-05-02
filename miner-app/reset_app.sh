#!/bin/bash

# Set QUANTUS_HOME if not set
if [ -z "$QUANTUS_HOME" ]; then
    QUANTUS_HOME="$HOME/.quantus"
fi

echo "Resetting Quantus Miner App..."
echo "QUANTUS_HOME: $QUANTUS_HOME"

# Define paths
NODE_BINARY_PATH="$QUANTUS_HOME/bin/quantus-node"
EXTERNAL_MINER_BINARY_PATH="$QUANTUS_HOME/bin/quantus-miner"
NODE_KEY_PATH="$QUANTUS_HOME/node_key.p2p"
REWARDS_ADDRESS_PATH="$QUANTUS_HOME/rewards-address.txt"
REWARDS_PREIMAGE_PATH="$QUANTUS_HOME/rewards-preimage.txt"
NODE_DATA_PATH="$QUANTUS_HOME/node_data"
BIN_DIR="$QUANTUS_HOME/bin"

echo ""
echo "=== Deleting Binaries ==="

# Delete the node binary
if [ -f "$NODE_BINARY_PATH" ]; then
    echo "Deleting node binary: $NODE_BINARY_PATH"
    rm -f "$NODE_BINARY_PATH"
else
    echo "Node binary not found: $NODE_BINARY_PATH"
fi

# Delete the external miner binary
if [ -f "$EXTERNAL_MINER_BINARY_PATH" ]; then
    echo "Deleting external miner binary: $EXTERNAL_MINER_BINARY_PATH"
    rm -f "$EXTERNAL_MINER_BINARY_PATH"
else
    echo "External miner binary not found: $EXTERNAL_MINER_BINARY_PATH"
fi

# Delete the entire bin directory if it exists and is empty
if [ -d "$BIN_DIR" ]; then
    echo "Cleaning up bin directory: $BIN_DIR"
    # Remove any leftover tar.gz files
    rm -f "$BIN_DIR"/*.tar.gz
    # Remove directory if empty
    rmdir "$BIN_DIR" 2>/dev/null || echo "Bin directory not empty, keeping it"
fi

echo ""
echo "=== Deleting Configuration Files ==="

# Delete node key file
if [ -f "$NODE_KEY_PATH" ]; then
    echo "Deleting node key file: $NODE_KEY_PATH"
    rm -f "$NODE_KEY_PATH"
else
    echo "Node key file not found: $NODE_KEY_PATH"
fi

# Delete rewards address file
if [ -f "$REWARDS_ADDRESS_PATH" ]; then
    echo "Deleting rewards address file: $REWARDS_ADDRESS_PATH"
    rm -f "$REWARDS_ADDRESS_PATH"
else
    echo "Rewards address file not found: $REWARDS_ADDRESS_PATH"
fi

# Delete rewards preimage file
if [ -f "$REWARDS_PREIMAGE_PATH" ]; then
    echo "Deleting rewards preimage file: $REWARDS_PREIMAGE_PATH"
    rm -f "$REWARDS_PREIMAGE_PATH"
else
    echo "Rewards preimage file not found: $REWARDS_PREIMAGE_PATH"
fi

echo ""
echo "=== Deleting Node Data Directory ==="

# Delete the node data directory
if [ -d "$NODE_DATA_PATH" ]; then
    echo "Deleting node data directory: $NODE_DATA_PATH"
    rm -rf "$NODE_DATA_PATH"
else
    echo "Node data directory not found: $NODE_DATA_PATH"
fi

echo ""
echo "=== Cleanup Complete ==="

# Remove the entire .quantus directory if it's empty
if [ -d "$QUANTUS_HOME" ]; then
    rmdir "$QUANTUS_HOME" 2>/dev/null && echo "Removed empty QUANTUS_HOME directory: $QUANTUS_HOME" || echo "QUANTUS_HOME directory not empty, keeping it: $QUANTUS_HOME"
fi

echo ""
echo "🎉 App reset complete! You can now run the setup process again." 