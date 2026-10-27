#!/bin/bash

# This script triggers the infrastructure recovery workflow
# Commit and push this script to trigger GitHub Actions recovery

echo "=== Infrastructure Recovery Trigger ==="
echo ""
echo "This script will:"
echo "1. Commit and push a change to trigger GitHub Actions"
echo "2. The workflow will automatically:"
echo "   - Recreate NAT gateway if deleted"
echo "   - Recreate EKS node group if failed"
echo "   - Wait for nodes to be ready"
echo ""
echo "To run manually:"
echo "  git add ."
echo "  git commit -m 'Trigger infrastructure recovery'"
echo "  git push origin main"
echo ""
echo "Or go to GitHub Actions and run 'Infrastructure Recovery' workflow manually"
