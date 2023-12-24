#!/bin/bash

# Configuration variables
GITHUB_REPO_URL="https://github.com/huzzyz/dotfiles.git" # Replace with your repository URL
TEMP_DIR="$HOME/temp-dotfiles"
GIT_DIR="$HOME/dotfiles"
WORK_TREE="$TEMP_DIR"
GIT_ALIAS="gitbare"

# Function to setup and process the Git repository
process_git_repo() {
    # Create temp directory
    mkdir -p "$TEMP_DIR"

    # Clone into temp directory
    echo "Cloning repository into temporary directory..."
    git clone --bare "$GITHUB_REPO_URL" "$GIT_DIR"
    alias $GIT_ALIAS="/usr/bin/git --git-dir=$GIT_DIR --work-tree=$WORK_TREE"
    $GIT_ALIAS checkout

    # Copying files from temp to home, replacing existing ones
    echo "Replacing local files with repository versions..."
    rsync -av --progress "$TEMP_DIR/" "$HOME/" --exclude '.git'

    # Cleanup
    echo "Cleaning up..."
    unalias $GIT_ALIAS
    rm -rf "$TEMP_DIR"
    rm -rf "$GIT_DIR"

    echo "Dotfiles restoration complete."
}

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git first."
    exit 1
fi

# Check if Rsync is installed
if ! command -v rsync &> /dev/null; then
    echo "Rsync is not installed. Please install Rsync first."
    exit 1
fi

# Process the Git repository
process_git_repo
