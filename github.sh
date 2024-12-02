#!/bin/bash

# List of specific files to add
#!/bin/bash

# Adding individual files

git add dashboard.R
git add gateway.R
git add github.sh

# Adding entire folders
git add endpoints

# Check if a commit message is provided
if [ -z "$1" ]; then
    commit_message="Latest updates"
else
    commit_message="$1"
fi

# Commit the changes with a message
git commit -m "$commit_message"

# Push to the master branch
git push origin master
