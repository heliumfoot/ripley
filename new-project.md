# New Project

Run this prompt to initialize a new project.

```
Ask me:
1. What is the project name?
2. What is a one-sentence description of the project?

Then:
- Create a directory for the project under ~/projects/[project-name]
- Initialize a git repo in that directory
- Create a README.md containing the project name as a top-level heading and the description as the first paragraph
- Make an initial commit with the message "initial commit"
- Create a private GitHub repository named [project-name] using the GitHub CLI, with the same description
- Push the initial commit to GitHub and set the upstream

When done, print the local path and the GitHub URL.
```
