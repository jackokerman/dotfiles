#!/usr/bin/env python3
"""
Configure Finder sidebar favorites.
This script manages the Finder sidebar items using the LSSharedFileList framework.

Usage:
    configure-finder-sidebar.py configure    # Apply default configuration
    configure-finder-sidebar.py add <path>   # Add a specific path
    configure-finder-sidebar.py remove <path> # Remove a specific path
"""

import sys
import os

# Configuration: Define what sidebar items should exist
ITEMS_TO_REMOVE = [
    "~/Documents",
    "/Applications",
]

ITEMS_TO_ADD = [
    "~/Screenshots",
    "~/Downloads",
    "~/Desktop",
    "~/dotfiles",
]

def check_dependencies():
    """Check if required dependencies are available."""
    try:
        from Foundation import NSURL
        from LaunchServices import (
            LSSharedFileListCreate,
            kLSSharedFileListFavoriteItems,
        )
        return True
    except ImportError as e:
        print("ERROR: Required Python modules not available.", file=sys.stderr)
        print("", file=sys.stderr)
        print("PyObjC framework is required to manage Finder sidebar.", file=sys.stderr)
        print("", file=sys.stderr)
        print("To install, run:", file=sys.stderr)
        print("  pip3 install pyobjc-framework-LaunchServices", file=sys.stderr)
        print("", file=sys.stderr)
        print("Or configure your Finder sidebar manually:", file=sys.stderr)
        print("  1. Open Finder", file=sys.stderr)
        print("  2. Go to Finder > Settings > Sidebar", file=sys.stderr)
        print("  3. Customize your favorites", file=sys.stderr)
        print("", file=sys.stderr)
        return False

def get_sidebar_list():
    """Get the Finder sidebar favorites list."""
    from LaunchServices import LSSharedFileListCreate, kLSSharedFileListFavoriteItems
    return LSSharedFileListCreate(None, kLSSharedFileListFavoriteItems, None)

def get_current_items(sidebar_list):
    """Get current items in the sidebar."""
    from LaunchServices import LSSharedFileListCopySnapshot
    snapshot, _ = LSSharedFileListCopySnapshot(sidebar_list, None)
    return list(snapshot) if snapshot else []

def get_item_url(item):
    """Get the URL for a sidebar item."""
    from LaunchServices import (
        LSSharedFileListItemCopyResolvedURL,
        kLSSharedFileListNoUserInteraction,
        kLSSharedFileListDoNotMountVolumes,
    )
    flags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes
    url, _ = LSSharedFileListItemCopyResolvedURL(item, flags, None)
    return url

def remove_item(sidebar_list, path, quiet=False):
    """Remove an item from the sidebar by path."""
    from LaunchServices import LSSharedFileListItemRemove
    items = get_current_items(sidebar_list)
    path = os.path.expanduser(path)

    for item in items:
        url = get_item_url(item)
        if url and url.path() == path:
            LSSharedFileListItemRemove(sidebar_list, item)
            if not quiet:
                print(f"Removed: {path}")
            return True

    if not quiet:
        print(f"Not in sidebar: {path}")
    return False

def add_item(sidebar_list, path, quiet=False):
    """Add an item to the sidebar."""
    from Foundation import NSURL
    from LaunchServices import LSSharedFileListInsertItemURL

    path = os.path.expanduser(path)

    # Check if path exists
    if not os.path.exists(path):
        if not quiet:
            print(f"Warning: Path does not exist, skipping: {path}")
        return False

    # Check if item already exists
    items = get_current_items(sidebar_list)
    for item in items:
        url = get_item_url(item)
        if url and url.path() == path:
            if not quiet:
                print(f"Already in sidebar: {path}")
            return False

    # Add the item
    url = NSURL.fileURLWithPath_(path)
    LSSharedFileListInsertItemURL(sidebar_list, None, None, None, url, None, None)
    if not quiet:
        print(f"Added: {path}")
    return True

def configure_sidebar():
    """Apply the default sidebar configuration."""
    print("Configuring Finder sidebar...")

    sidebar_list = get_sidebar_list()

    # Remove unwanted items
    print("\nRemoving unwanted items:")
    for path in ITEMS_TO_REMOVE:
        remove_item(sidebar_list, path)

    # Add desired items
    print("\nAdding favorites:")
    for path in ITEMS_TO_ADD:
        add_item(sidebar_list, path)

    print("\nFinder sidebar configured successfully!")
    return True

def main():
    """Main function to configure sidebar."""
    if len(sys.argv) < 2:
        print("Usage: configure-finder-sidebar.py [configure|add|remove] [path]")
        print("")
        print("Commands:")
        print("  configure        Apply default sidebar configuration")
        print("  add <path>       Add a specific path to sidebar")
        print("  remove <path>    Remove a specific path from sidebar")
        sys.exit(1)

    # Check dependencies first
    if not check_dependencies():
        sys.exit(1)

    action = sys.argv[1]

    if action == 'configure':
        success = configure_sidebar()
        sys.exit(0 if success else 1)

    elif action in ['add', 'remove']:
        if len(sys.argv) < 3:
            print(f"Error: Path required for '{action}' command")
            sys.exit(1)

        path = sys.argv[2]
        sidebar_list = get_sidebar_list()

        if action == 'add':
            add_item(sidebar_list, path)
        elif action == 'remove':
            remove_item(sidebar_list, path)

    else:
        print(f"Invalid action: {action}")
        print("Usage: configure-finder-sidebar.py [configure|add|remove] [path]")
        sys.exit(1)

    # Force Finder to update (only for add/remove commands)
    if action in ['add', 'remove']:
        os.system("killall Finder 2>/dev/null || true")

if __name__ == '__main__':
    main()
