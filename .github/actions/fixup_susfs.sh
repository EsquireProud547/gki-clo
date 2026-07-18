#!/bin/bash
# ============================================
# SUSFS patch context fixup for CLO kernels
# ============================================
# The SUSFS 50_add_susfs_in_gki-android15-6.6.patch
# is designed for AOSP GKI kernel. Capybara CLO kernel
# has slightly different code context in some files.
#
# This script pre-adjusts those files so the SUSFS
# patch applies cleanly.
# ============================================

set -e
echo "[+] Running SUSFS context fixup for CLO kernel..."

KERNEL_ROOT="${1:-.}"
cd "$KERNEL_ROOT"

# --------------------------------------------------
# Fix 1: fs/proc/base.c - missing <linux/dma-buf.h>
# --------------------------------------------------
# SUSFS patch expects:
#   #include <linux/cpufreq_times.h>
#   #include <linux/dma-buf.h>
#   #include <trace/events/oom.h>
#
# CLO kernel has:
#   #include <linux/cpufreq_times.h>
#   #include <trace/events/oom.h>
#
# Add the missing include so the patch context matches.

BASE_C="fs/proc/base.c"
if grep -q '#include <linux/dma-buf.h>' "$BASE_C" 2>/dev/null; then
    echo "  [✓] fs/proc/base.c: <linux/dma-buf.h> already present"
else
    echo "  [*] fs/proc/base.c: adding <linux/dma-buf.h> for SUSFS context..."
    # Insert after #include <linux/cpufreq_times.h>
    sed -i '/#include <linux\/cpufreq_times.h>/a #include <linux/dma-buf.h>' "$BASE_C"
    if grep -q '#include <linux/dma-buf.h>' "$BASE_C"; then
        echo "  [✓] Added successfully"
    else
        echo "  [✗] Failed to add include"
        exit 1
    fi
fi

# --------------------------------------------------
# Fix 2: security/selinux/hooks.c - offset adjustments
# --------------------------------------------------
# The patch has hunks with offsets, which is fine.
# But if there are more failures we can fix them here.
# Currently only fs/proc/base.c hunk #1 fails.

# --------------------------------------------------
# Fix 3: Any future context mismatches can be added here
# --------------------------------------------------

echo "[+] Context fixup complete. Ready to apply SUSFS patch."
